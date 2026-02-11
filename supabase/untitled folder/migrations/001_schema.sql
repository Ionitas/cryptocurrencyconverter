-- ============================================================================
-- MIGRATION 001: Database Schema
-- ============================================================================
-- Creates all tables and indexes for the subscription and token system.
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PRODUCTS TABLE: Product Catalog
-- ============================================================================
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price_cents INTEGER NOT NULL,
    currency TEXT DEFAULT 'USD',
    billing_period TEXT CHECK (billing_period IN ('week', 'month', 'year', 'lifetime')),
    tokens_per_period INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- FEATURE COSTS TABLE: Cost per feature
-- ============================================================================
CREATE TABLE IF NOT EXISTS feature_costs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_id TEXT UNIQUE NOT NULL,
    feature_name TEXT NOT NULL,
    token_cost INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SUBSCRIPTIONS TABLE: User Subscription State
-- ============================================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User identifiers (multiple ways to find a subscription)
    device_id TEXT,                              -- Device that made the purchase
    revenuecat_customer_id TEXT,                 -- RevenueCat anonymous ID ($RCAnonymousID:xxx)
    original_app_user_id TEXT,                   -- Original app user ID (for cross-device)
    original_transaction_id TEXT,                -- Apple/Google original transaction ID
    
    -- Subscription details
    revenuecat_product_id TEXT,                  -- Product ID (e.g., attentionmap_9.99_weekly_unlimited)
    status TEXT DEFAULT 'free',                  -- free, active, trial, cancelled, expired, grace_period, paused
    is_trial BOOLEAN DEFAULT FALSE,
    auto_renew BOOLEAN DEFAULT TRUE,
    store TEXT,                                  -- APP_STORE, PLAY_STORE
    entitlement_ids TEXT[],                      -- Active entitlement IDs
    all_aliases TEXT[] DEFAULT '{}',             -- All RevenueCat aliases
    
    -- Token tracking
    tokens_allocated INTEGER NOT NULL DEFAULT 0,  -- Tokens given for this period
    tokens_used INTEGER NOT NULL DEFAULT 0,       -- Tokens used this period
    total_tokens_used INTEGER NOT NULL DEFAULT 0, -- Lifetime tokens used (never resets)
    last_token_reset TIMESTAMPTZ,                 -- When tokens were last reset
    
    -- Period tracking
    period_start TIMESTAMPTZ,                    -- Current billing period start
    period_end TIMESTAMPTZ,                      -- Current billing period end
    expires_at TIMESTAMPTZ,                      -- When subscription expires
    
    -- Webhook tracking
    last_event_type TEXT,                        -- Last webhook event type
    last_event_timestamp TIMESTAMPTZ,            -- When last webhook was received
    
    -- Metadata
    revenuecat_data JSONB DEFAULT '{}',          -- Raw RevenueCat data
    last_sync TIMESTAMPTZ,                       -- Last sync with server
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR SUBSCRIPTIONS
-- ============================================================================

-- Primary lookup indexes
CREATE INDEX IF NOT EXISTS idx_subscriptions_device_id ON subscriptions(device_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_revenuecat_id ON subscriptions(revenuecat_customer_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_original_transaction ON subscriptions(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);

-- Unique constraint on original_app_user_id for cross-device lookup
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_original_user 
ON subscriptions(original_app_user_id) WHERE original_app_user_id IS NOT NULL;

-- GIN index for aliases array
CREATE INDEX IF NOT EXISTS idx_subscriptions_aliases ON subscriptions USING GIN(all_aliases);

-- ============================================================================
-- TOKEN USAGE TABLE: Usage Log
-- ============================================================================
CREATE TABLE IF NOT EXISTS token_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    feature_id TEXT,
    tokens_consumed INTEGER NOT NULL,
    transaction_id TEXT UNIQUE NOT NULL,         -- For idempotency
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_token_usage_subscription ON token_usage(subscription_id);
CREATE INDEX IF NOT EXISTS idx_token_usage_transaction ON token_usage(transaction_id);
CREATE INDEX IF NOT EXISTS idx_token_usage_created ON token_usage(created_at DESC);

-- ============================================================================
-- ANALYSES TABLE: Analysis Cache
-- ============================================================================
CREATE TABLE IF NOT EXISTS analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_hash TEXT NOT NULL,
    device_id TEXT,
    result JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analyses_hash ON analyses(content_hash);
CREATE INDEX IF NOT EXISTS idx_analyses_created ON analyses(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE analyses ENABLE ROW LEVEL SECURITY;

-- Policies (allow all - functions use SECURITY DEFINER)
DROP POLICY IF EXISTS "subscriptions_all" ON subscriptions;
CREATE POLICY "subscriptions_all" ON subscriptions FOR ALL USING (true);

DROP POLICY IF EXISTS "token_usage_all" ON token_usage;
CREATE POLICY "token_usage_all" ON token_usage FOR ALL USING (true);

DROP POLICY IF EXISTS "analyses_all" ON analyses;
CREATE POLICY "analyses_all" ON analyses FOR ALL USING (true);

-- ============================================================================
-- GRANTS
-- ============================================================================
GRANT SELECT ON products TO anon, authenticated;
GRANT SELECT ON feature_costs TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON subscriptions TO anon, authenticated, service_role;
GRANT SELECT, INSERT ON token_usage TO anon, authenticated, service_role;
GRANT SELECT, INSERT ON analyses TO anon, authenticated, service_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 001: Schema created';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Tables: products, feature_costs, subscriptions, token_usage, analyses';
    RAISE NOTICE '========================================';
END $$;
