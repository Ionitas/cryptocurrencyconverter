-- ============================================================================
-- MIGRATION 002: Database Functions
-- ============================================================================
-- All SQL functions for subscription and token management.
--
-- KEY DESIGN PRINCIPLES:
-- 1. get_subscription_status is READ-ONLY (never modifies data)
-- 2. Only EXPIRATION webhook sets status='expired' and zeros tokens
-- 3. sync_subscription links device to existing subscription (doesn't create)
-- 4. process_webhook_event is the only way to create/update subscriptions
-- 5. All status checks trust the 'status' column, not expires_at timestamp
-- ============================================================================

-- ============================================================================
-- HELPER: Find Subscription by Any Identifier
-- ============================================================================
CREATE OR REPLACE FUNCTION find_subscription(
    p_device_id TEXT DEFAULT NULL,
    p_revenuecat_customer_id TEXT DEFAULT NULL,
    p_original_transaction_id TEXT DEFAULT NULL
) RETURNS subscriptions AS $$
DECLARE
    v_subscription subscriptions;
BEGIN
    -- Priority 1: original_transaction_id (most specific)
    IF p_original_transaction_id IS NOT NULL THEN
        SELECT * INTO v_subscription FROM subscriptions 
        WHERE original_transaction_id = p_original_transaction_id
        LIMIT 1;
        IF v_subscription.id IS NOT NULL THEN RETURN v_subscription; END IF;
    END IF;
    
    -- Priority 2: revenuecat_customer_id (cross-device)
    IF p_revenuecat_customer_id IS NOT NULL THEN
        SELECT * INTO v_subscription FROM subscriptions 
        WHERE revenuecat_customer_id = p_revenuecat_customer_id
           OR original_app_user_id = p_revenuecat_customer_id
           OR p_revenuecat_customer_id = ANY(all_aliases)
        ORDER BY updated_at DESC
        LIMIT 1;
        IF v_subscription.id IS NOT NULL THEN RETURN v_subscription; END IF;
    END IF;
    
    -- Priority 3: device_id (fallback)
    IF p_device_id IS NOT NULL THEN
        SELECT * INTO v_subscription FROM subscriptions 
        WHERE device_id = p_device_id
        ORDER BY updated_at DESC
        LIMIT 1;
    END IF;
    
    RETURN v_subscription;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Get Subscription Status (READ-ONLY)
-- Called by app to get current subscription state.
-- NEVER modifies subscription - just reports what's in the database.
-- ============================================================================
CREATE OR REPLACE FUNCTION get_subscription_status(
    p_device_id TEXT DEFAULT NULL,
    p_app_user_id TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions;
    v_tokens_remaining INTEGER;
    v_is_pro BOOLEAN;
BEGIN
    -- Find subscription
    v_subscription := find_subscription(p_device_id, p_app_user_id, NULL);
    
    -- No subscription found = free user
    IF v_subscription.id IS NULL THEN
        RETURN jsonb_build_object(
            'subscription_id', NULL,
            'status', 'free',
            'product_id', NULL,
            'is_trial', false,
            'is_pro', false,
            'auto_renew', false,
            'tokens', jsonb_build_object(
                'allocated', 0,
                'used', 0,
                'remaining', 0
            ),
            'total_tokens_used', 0,
            'period_start', NULL,
            'period_end', NULL,
            'expires_at', NULL,
            'last_sync', NOW()
        );
    END IF;
    
    -- Calculate remaining tokens
    v_tokens_remaining := GREATEST(0, 
        COALESCE(v_subscription.tokens_allocated, 0) - COALESCE(v_subscription.tokens_used, 0)
    );
    
    -- Check if user has pro access (active subscription)
    v_is_pro := v_subscription.status IN ('active', 'trial', 'grace_period');
    
    -- Return current state (READ-ONLY - no modifications!)
    RETURN jsonb_build_object(
        'subscription_id', v_subscription.id,
        'status', COALESCE(v_subscription.status, 'free'),
        'product_id', v_subscription.revenuecat_product_id,
        'is_trial', COALESCE(v_subscription.is_trial, false),
        'is_pro', v_is_pro,
        'auto_renew', COALESCE(v_subscription.auto_renew, false),
        'tokens', jsonb_build_object(
            'allocated', COALESCE(v_subscription.tokens_allocated, 0),
            'used', COALESCE(v_subscription.tokens_used, 0),
            'remaining', v_tokens_remaining
        ),
        'total_tokens_used', COALESCE(v_subscription.total_tokens_used, 0),
        'period_start', v_subscription.period_start,
        'period_end', v_subscription.period_end,
        'expires_at', v_subscription.expires_at,
        'last_token_reset', v_subscription.last_token_reset,
        'last_sync', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Sync Subscription from RevenueCat (READ-ONLY)
-- 
-- This function is now READ-ONLY. It does NOT modify any data.
-- All subscription state changes come from RevenueCat webhooks.
--
-- The Edge Function now uses get_subscription_status() directly for lookups.
-- This function is kept for backward compatibility.
-- ============================================================================
CREATE OR REPLACE FUNCTION sync_subscription_from_revenuecat(
    p_device_id TEXT,
    p_app_user_id TEXT,
    p_revenuecat_product_id TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL,
    p_is_trial BOOLEAN DEFAULT NULL,
    p_expires_at TIMESTAMPTZ DEFAULT NULL,
    p_revenuecat_data JSONB DEFAULT '{}'
) RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions;
    v_tokens_remaining INTEGER;
BEGIN
    -- Find existing subscription (READ-ONLY - no writes)
    v_subscription := find_subscription(p_device_id, p_app_user_id, NULL);
    
    -- No subscription found
    IF v_subscription.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'NO_SUBSCRIPTION_FOUND',
            'message', 'No subscription found. Purchase will be activated when payment is verified.',
            'device_id', p_device_id,
            'app_user_id', p_app_user_id
        );
    END IF;
    
    -- Calculate remaining tokens
    v_tokens_remaining := GREATEST(0, 
        COALESCE(v_subscription.tokens_allocated, 0) - COALESCE(v_subscription.tokens_used, 0)
    );
    
    -- Return subscription data (READ-ONLY - no updates performed)
    RETURN jsonb_build_object(
        'success', true,
        'subscription_id', v_subscription.id,
        'status', v_subscription.status,
        'product_id', v_subscription.revenuecat_product_id,
        'is_trial', COALESCE(v_subscription.is_trial, false),
        'is_pro', v_subscription.status IN ('active', 'trial', 'grace_period'),
        'auto_renew', COALESCE(v_subscription.auto_renew, false),
        'tokens', jsonb_build_object(
            'allocated', COALESCE(v_subscription.tokens_allocated, 0),
            'used', COALESCE(v_subscription.tokens_used, 0),
            'remaining', v_tokens_remaining
        ),
        'total_tokens_used', COALESCE(v_subscription.total_tokens_used, 0),
        'period_start', v_subscription.period_start,
        'period_end', v_subscription.period_end,
        'expires_at', v_subscription.expires_at,
        'last_token_reset', v_subscription.last_token_reset,
        'last_sync', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Process Webhook Event (Primary Entry Point)
-- Handles all RevenueCat webhook events.
-- This is the ONLY function that can create or expire subscriptions.
-- ============================================================================
CREATE OR REPLACE FUNCTION process_webhook_event(
    p_event JSONB
) RETURNS JSONB AS $$
DECLARE
    v_event_data JSONB;
    v_event_type TEXT;
    v_app_user_id TEXT;
    v_original_app_user_id TEXT;
    v_product_id TEXT;
    v_original_transaction_id TEXT;
    v_expiration_at TIMESTAMPTZ;
    v_purchased_at TIMESTAMPTZ;
    v_is_trial BOOLEAN;
    v_status TEXT;
    v_store TEXT;
    v_aliases TEXT[];
    v_subscription subscriptions;
    v_tokens INTEGER;
    v_should_reset_tokens BOOLEAN := FALSE;
BEGIN
    -- Extract event data (handle nested RevenueCat structure)
    v_event_data := COALESCE(p_event->'event', p_event);
    
    -- Extract fields
    v_event_type := COALESCE(v_event_data->>'type', p_event->>'type');
    v_app_user_id := COALESCE(v_event_data->>'app_user_id', p_event->>'app_user_id');
    v_original_app_user_id := COALESCE(v_event_data->>'original_app_user_id', p_event->>'original_app_user_id', v_app_user_id);
    v_product_id := COALESCE(v_event_data->>'new_product_id', v_event_data->>'product_id', p_event->>'product_id');
    v_original_transaction_id := COALESCE(v_event_data->>'original_transaction_id', p_event->>'original_transaction_id');
    v_store := COALESCE(v_event_data->>'store', p_event->>'store');
    
    -- Parse timestamps
    BEGIN
        IF (v_event_data->>'expiration_at_ms') IS NOT NULL THEN
            v_expiration_at := TO_TIMESTAMP((v_event_data->>'expiration_at_ms')::BIGINT / 1000.0);
        ELSIF (p_event->>'expiration_at_ms') IS NOT NULL THEN
            v_expiration_at := TO_TIMESTAMP((p_event->>'expiration_at_ms')::BIGINT / 1000.0);
        END IF;
        
        IF (v_event_data->>'purchased_at_ms') IS NOT NULL THEN
            v_purchased_at := TO_TIMESTAMP((v_event_data->>'purchased_at_ms')::BIGINT / 1000.0);
        END IF;
    EXCEPTION WHEN OTHERS THEN
        -- Continue with NULL timestamps
        NULL;
    END;
    
    -- Parse aliases
    IF v_event_data->'aliases' IS NOT NULL THEN
        SELECT ARRAY_AGG(elem::TEXT) INTO v_aliases
        FROM jsonb_array_elements_text(v_event_data->'aliases') AS elem;
    END IF;
    
    -- Determine trial status
    v_is_trial := UPPER(COALESCE(v_event_data->>'period_type', p_event->>'period_type', '')) = 'TRIAL';
    
    -- Determine status based on event type
    v_status := CASE 
        WHEN v_event_type IN ('INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'TRANSFER') THEN 
            CASE WHEN v_is_trial THEN 'trial' ELSE 'active' END
        WHEN v_event_type = 'CANCELLATION' THEN 'active'  -- Keep active until expiration
        WHEN v_event_type = 'EXPIRATION' THEN 'expired'
        WHEN v_event_type = 'BILLING_ISSUE' THEN 'grace_period'
        WHEN v_event_type = 'SUBSCRIPTION_PAUSED' THEN 'paused'
        ELSE 'active'
    END;
    
    -- Should we reset tokens?
    v_should_reset_tokens := v_event_type IN ('INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE');
    
    RAISE NOTICE 'Webhook: type=%, user=%, product=%, expires=%', v_event_type, v_app_user_id, v_product_id, v_expiration_at;
    
    -- =========================================================================
    -- EXPIRATION: Set status to expired and zero tokens
    -- =========================================================================
    IF v_event_type = 'EXPIRATION' THEN
        UPDATE subscriptions 
        SET 
            status = 'expired',
            auto_renew = false,
            tokens_used = tokens_allocated,  -- Zero remaining tokens
            last_event_type = v_event_type,
            last_event_timestamp = NOW(),
            updated_at = NOW()
        WHERE revenuecat_customer_id = v_app_user_id
           OR original_app_user_id = v_original_app_user_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', 'expired',
            'app_user_id', v_app_user_id,
            'tokens_remaining', 0
        );
    END IF;
    
    -- =========================================================================
    -- CANCELLATION: Set auto_renew to false, keep active until expiration
    -- =========================================================================
    IF v_event_type = 'CANCELLATION' THEN
        UPDATE subscriptions 
        SET 
            auto_renew = false,
            last_event_type = v_event_type,
            last_event_timestamp = NOW(),
            updated_at = NOW()
        WHERE revenuecat_customer_id = v_app_user_id
           OR original_app_user_id = v_original_app_user_id;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', 'cancelled',
            'app_user_id', v_app_user_id,
            'message', 'Auto-renew disabled, active until expiration'
        );
    END IF;
    
    -- =========================================================================
    -- ACTIVE EVENTS: Create or update subscription
    -- =========================================================================
    IF v_event_type IN ('INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'TRANSFER') THEN
        -- Get token allocation from products table
        SELECT tokens_per_period INTO v_tokens
        FROM products WHERE product_id = v_product_id LIMIT 1;
        
        -- Fallback token calculation
        IF v_tokens IS NULL THEN
            v_tokens := CASE 
                WHEN v_product_id LIKE '%9.99_weekly%' THEN 10
                WHEN v_product_id LIKE '%39.99_weekly%' THEN 50
                WHEN v_product_id LIKE '%29.99_monthly%' THEN 50
                WHEN v_product_id LIKE '%119.99_monthly%' THEN 200
                WHEN v_product_id LIKE '%249.99_annually%' THEN 60
                WHEN v_product_id LIKE '%999.99_annually%' THEN 220
                ELSE 100
            END;
        END IF;
        
        -- Find existing subscription
        v_subscription := find_subscription(NULL, v_app_user_id, v_original_transaction_id);
        
        IF v_subscription.id IS NOT NULL THEN
            -- Update existing subscription
            UPDATE subscriptions SET
                revenuecat_customer_id = v_app_user_id,
                original_app_user_id = COALESCE(original_app_user_id, v_original_app_user_id),
                original_transaction_id = COALESCE(v_original_transaction_id, original_transaction_id),
                revenuecat_product_id = v_product_id,
                status = v_status,
                is_trial = v_is_trial,
                auto_renew = true,
                store = COALESCE(v_store, store),
                all_aliases = COALESCE(v_aliases, all_aliases),
                tokens_allocated = v_tokens,
                tokens_used = CASE WHEN v_should_reset_tokens THEN 0 ELSE tokens_used END,
                period_start = CASE WHEN v_should_reset_tokens THEN COALESCE(v_purchased_at, NOW()) ELSE period_start END,
                period_end = v_expiration_at,
                expires_at = v_expiration_at,
                last_token_reset = CASE WHEN v_should_reset_tokens THEN NOW() ELSE last_token_reset END,
                last_event_type = v_event_type,
                last_event_timestamp = NOW(),
                revenuecat_data = p_event,
                last_sync = NOW(),
                updated_at = NOW()
            WHERE id = v_subscription.id
            RETURNING * INTO v_subscription;
        ELSE
            -- Create new subscription
            INSERT INTO subscriptions (
                device_id, revenuecat_customer_id, original_app_user_id,
                original_transaction_id, revenuecat_product_id, status, is_trial,
                auto_renew, store, all_aliases,
                tokens_allocated, tokens_used, total_tokens_used,
                period_start, period_end, expires_at, last_token_reset,
                last_event_type, last_event_timestamp,
                revenuecat_data, last_sync, created_at, updated_at
            ) VALUES (
                'webhook_' || gen_random_uuid()::TEXT,
                v_app_user_id,
                v_original_app_user_id,
                v_original_transaction_id,
                v_product_id,
                v_status,
                v_is_trial,
                true,
                v_store,
                v_aliases,
                v_tokens,
                0,  -- tokens_used starts at 0
                0,  -- total_tokens_used starts at 0
                COALESCE(v_purchased_at, NOW()),
                v_expiration_at,
                v_expiration_at,
                NOW(),
                v_event_type,
                NOW(),
                p_event,
                NOW(),
                NOW(),
                NOW()
            ) RETURNING * INTO v_subscription;
        END IF;
        
        RETURN jsonb_build_object(
            'success', true,
            'action', v_event_type,
            'subscription_id', v_subscription.id,
            'app_user_id', v_app_user_id,
            'product_id', v_product_id,
            'status', v_status,
            'tokens_reset', v_should_reset_tokens,
            'tokens', jsonb_build_object(
                'allocated', v_subscription.tokens_allocated,
                'used', v_subscription.tokens_used,
                'remaining', v_subscription.tokens_allocated - v_subscription.tokens_used
            ),
            'expires_at', v_expiration_at
        );
    END IF;
    
    -- Handle other events
    IF v_event_type = 'BILLING_ISSUE' THEN
        UPDATE subscriptions 
        SET status = 'grace_period', last_event_type = v_event_type, last_event_timestamp = NOW(), updated_at = NOW()
        WHERE revenuecat_customer_id = v_app_user_id OR original_app_user_id = v_original_app_user_id;
        
        RETURN jsonb_build_object('success', true, 'action', 'grace_period');
    END IF;
    
    RETURN jsonb_build_object('success', true, 'action', 'ignored', 'event_type', v_event_type);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Check Token Availability
-- ============================================================================
CREATE OR REPLACE FUNCTION check_token_availability(
    p_device_id TEXT,
    p_feature_id TEXT,
    p_app_user_id TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions;
    v_tokens_remaining INTEGER;
    v_token_cost INTEGER;
BEGIN
    -- Get feature cost
    SELECT token_cost INTO v_token_cost FROM feature_costs WHERE feature_id = p_feature_id AND is_active = TRUE;
    v_token_cost := COALESCE(v_token_cost, 1);
    
    -- Find subscription
    v_subscription := find_subscription(p_device_id, p_app_user_id, NULL);
    
    IF v_subscription.id IS NULL THEN
        RETURN jsonb_build_object(
            'available', false,
            'can_use', false,
            'reason', 'No subscription found',
            'error_code', 'NO_SUBSCRIPTION',
            'tokens_required', v_token_cost
        );
    END IF;
    
    -- Check status
    IF v_subscription.status NOT IN ('active', 'trial', 'grace_period') THEN
        RETURN jsonb_build_object(
            'available', false,
            'can_use', false,
            'reason', 'Subscription not active: ' || v_subscription.status,
            'error_code', 'SUBSCRIPTION_INACTIVE',
            'status', v_subscription.status
        );
    END IF;
    
    -- Check tokens
    v_tokens_remaining := GREATEST(0, v_subscription.tokens_allocated - v_subscription.tokens_used);
    
    IF v_tokens_remaining < v_token_cost THEN
        RETURN jsonb_build_object(
            'available', false,
            'can_use', false,
            'reason', 'Insufficient tokens',
            'error_code', 'INSUFFICIENT_TOKENS',
            'tokens_remaining', v_tokens_remaining,
            'tokens_required', v_token_cost
        );
    END IF;
    
    RETURN jsonb_build_object(
        'available', true,
        'can_use', true,
        'reason', 'Has ' || v_tokens_remaining || ' tokens remaining',
        'tokens_remaining', v_tokens_remaining,
        'tokens_required', v_token_cost,
        'subscription_id', v_subscription.id,
        'status', v_subscription.status
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Consume Tokens
-- ============================================================================
CREATE OR REPLACE FUNCTION consume_tokens(
    p_device_id TEXT,
    p_feature_id TEXT,
    p_transaction_id TEXT,
    p_metadata JSONB DEFAULT '{}',
    p_app_user_id TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_subscription subscriptions;
    v_token_cost INTEGER;
    v_tokens_before INTEGER;
    v_tokens_after INTEGER;
    v_new_total_used INTEGER;
    v_usage_id UUID;
BEGIN
    -- Check for duplicate transaction (idempotency)
    IF EXISTS (SELECT 1 FROM token_usage WHERE transaction_id = p_transaction_id) THEN
        SELECT s.* INTO v_subscription
        FROM token_usage tu
        JOIN subscriptions s ON s.id = tu.subscription_id
        WHERE tu.transaction_id = p_transaction_id;
        
        IF v_subscription.id IS NOT NULL THEN
            RETURN jsonb_build_object(
                'success', true,
                'idempotent', true,
                'message', 'Transaction already processed',
                'transaction_id', p_transaction_id,
                'tokens', jsonb_build_object(
                    'remaining', GREATEST(0, v_subscription.tokens_allocated - v_subscription.tokens_used),
                    'allocated', v_subscription.tokens_allocated,
                    'used', v_subscription.tokens_used
                ),
                'total_tokens_used', COALESCE(v_subscription.total_tokens_used, 0)
            );
        END IF;
    END IF;
    
    -- Get feature cost
    SELECT token_cost INTO v_token_cost FROM feature_costs WHERE feature_id = p_feature_id AND is_active = TRUE;
    v_token_cost := COALESCE(v_token_cost, 1);
    
    -- Find subscription
    v_subscription := find_subscription(p_device_id, p_app_user_id, NULL);
    
    IF v_subscription.id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'No subscription found',
            'error_code', 'NO_SUBSCRIPTION'
        );
    END IF;
    
    -- Check status
    IF v_subscription.status NOT IN ('active', 'trial', 'grace_period') THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Subscription not active: ' || v_subscription.status,
            'error_code', 'SUBSCRIPTION_INACTIVE',
            'status', v_subscription.status
        );
    END IF;
    
    -- Check tokens
    v_tokens_before := GREATEST(0, v_subscription.tokens_allocated - v_subscription.tokens_used);
    
    IF v_tokens_before < v_token_cost THEN
        RETURN jsonb_build_object(
            'success', false,
            'error', 'Insufficient tokens',
            'error_code', 'INSUFFICIENT_TOKENS',
            'tokens_required', v_token_cost,
            'tokens_available', v_tokens_before,
            'tokens', jsonb_build_object(
                'remaining', v_tokens_before,
                'allocated', v_subscription.tokens_allocated,
                'used', v_subscription.tokens_used
            )
        );
    END IF;
    
    -- Calculate new totals
    v_new_total_used := COALESCE(v_subscription.total_tokens_used, 0) + v_token_cost;
    
    -- Update subscription
    UPDATE subscriptions SET
        tokens_used = tokens_used + v_token_cost,
        total_tokens_used = v_new_total_used,
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    v_tokens_after := v_tokens_before - v_token_cost;
    
    -- Log usage
    INSERT INTO token_usage (subscription_id, device_id, feature_id, tokens_consumed, transaction_id, metadata, created_at)
    VALUES (v_subscription.id, p_device_id, p_feature_id, v_token_cost, p_transaction_id, p_metadata, NOW())
    RETURNING id INTO v_usage_id;
    
    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', p_transaction_id,
        'subscription_id', v_subscription.id,
        'usage_id', v_usage_id,
        'tokens_consumed', v_token_cost,
        'tokens', jsonb_build_object(
            'remaining', v_tokens_after,
            'allocated', v_subscription.tokens_allocated,
            'used', v_subscription.tokens_used + v_token_cost
        ),
        'total_tokens_used', v_new_total_used
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Refund Tokens
-- ============================================================================
CREATE OR REPLACE FUNCTION refund_tokens(
    p_transaction_id TEXT
) RETURNS JSONB AS $$
DECLARE
    v_usage token_usage;
    v_subscription subscriptions;
BEGIN
    -- Find the usage record
    SELECT * INTO v_usage FROM token_usage WHERE transaction_id = p_transaction_id;
    
    IF v_usage.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Transaction not found');
    END IF;
    
    -- Get subscription
    SELECT * INTO v_subscription FROM subscriptions WHERE id = v_usage.subscription_id;
    
    IF v_subscription.id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Subscription not found');
    END IF;
    
    -- Refund tokens
    UPDATE subscriptions SET
        tokens_used = GREATEST(0, tokens_used - v_usage.tokens_consumed),
        total_tokens_used = GREATEST(0, total_tokens_used - v_usage.tokens_consumed),
        updated_at = NOW()
    WHERE id = v_subscription.id;
    
    -- Delete usage record
    DELETE FROM token_usage WHERE id = v_usage.id;
    
    RETURN jsonb_build_object(
        'success', true,
        'refunded', v_usage.tokens_consumed,
        'subscription_id', v_subscription.id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- FUNCTION: Get Products (Catalog)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_products()
RETURNS TABLE(product_id TEXT, name TEXT, description TEXT, price_cents INTEGER, currency TEXT, billing_period TEXT, tokens_per_period INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT p.product_id, p.name, p.description, p.price_cents, p.currency, p.billing_period, p.tokens_per_period
    FROM products p WHERE p.is_active = TRUE ORDER BY p.price_cents;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Get Feature Costs
-- ============================================================================
CREATE OR REPLACE FUNCTION get_feature_costs()
RETURNS TABLE(feature_id TEXT, feature_name TEXT, token_cost INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT f.feature_id, f.feature_name, f.token_cost FROM feature_costs f WHERE f.is_active = TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- FUNCTION: Get Product Catalog (combined)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_product_catalog()
RETURNS JSONB AS $$
BEGIN
    RETURN jsonb_build_object(
        'products', (SELECT jsonb_agg(row_to_json(p)) FROM (SELECT * FROM get_products()) p),
        'features', (SELECT jsonb_agg(row_to_json(f)) FROM (SELECT * FROM get_feature_costs()) f)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- GRANTS
-- ============================================================================
GRANT EXECUTE ON FUNCTION find_subscription(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_subscription_status(TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION sync_subscription_from_revenuecat(TEXT, TEXT, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ, JSONB) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION process_webhook_event(JSONB) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION check_token_availability(TEXT, TEXT, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION consume_tokens(TEXT, TEXT, TEXT, JSONB, TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION refund_tokens(TEXT) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_products() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_feature_costs() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_product_catalog() TO anon, authenticated, service_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 002: Functions created';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Functions:';
    RAISE NOTICE '  - find_subscription (helper)';
    RAISE NOTICE '  - get_subscription_status (READ-ONLY)';
    RAISE NOTICE '  - sync_subscription_from_revenuecat';
    RAISE NOTICE '  - process_webhook_event';
    RAISE NOTICE '  - check_token_availability';
    RAISE NOTICE '  - consume_tokens';
    RAISE NOTICE '  - refund_tokens';
    RAISE NOTICE '  - get_products / get_feature_costs / get_product_catalog';
    RAISE NOTICE '========================================';
END $$;
