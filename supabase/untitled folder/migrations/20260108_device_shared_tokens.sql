-- ============================================
-- DEVICE-BASED SHARED TOKEN POOL ARCHITECTURE
-- Migration: 20260108_device_shared_tokens.sql
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PRODUCTS TABLE (Token Packages Catalog)
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  adapty_product_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  token_count INTEGER NOT NULL,
  price_usd DECIMAL(10,2) NOT NULL,
  is_subscription BOOLEAN DEFAULT FALSE,
  description TEXT,
  active BOOLEAN DEFAULT TRUE,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default products
INSERT INTO products (adapty_product_id, name, token_count, price_usd, is_subscription, description) VALUES
('5_analyses', '5 Analyses', 5, 4.99, FALSE, 'One-time purchase of 5 analysis tokens'),
('20_analyses', '20 Analyses', 20, 14.99, FALSE, 'One-time purchase of 20 analysis tokens'),
('50_analyses', '50 Analyses', 50, 29.99, FALSE, 'One-time purchase of 50 analysis tokens'),
('pro_monthly', 'Pro Monthly', 100, 19.99, TRUE, 'Monthly subscription with 100 tokens'),
('pro_yearly', 'Pro Yearly', 1200, 199.99, TRUE, 'Annual subscription with 1200 tokens')
ON CONFLICT (adapty_product_id) DO NOTHING;

-- ============================================
-- DEVICES TABLE (Shared Token Pool)
-- ============================================
CREATE TABLE IF NOT EXISTS devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT UNIQUE NOT NULL,
  adapty_customer_id TEXT, -- Shared across devices
  
  -- Token balance (shared pool)
  tokens_remaining INTEGER DEFAULT 5,
  tokens_total INTEGER DEFAULT 5,
  
  -- Free tier (per device)
  free_tier_used_this_month INTEGER DEFAULT 0,
  free_tier_limit INTEGER DEFAULT 5,
  free_tier_reset_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '1 month'),
  
  -- Subscription status (shared)
  has_active_subscription BOOLEAN DEFAULT FALSE,
  subscription_expires_at TIMESTAMP WITH TIME ZONE,
  subscription_product_id TEXT,
  
  -- Device metadata (expandable)
  app_version TEXT,
  platform TEXT, -- 'ios', 'android', 'web'
  os_version TEXT,
  device_model TEXT,
  metadata JSONB DEFAULT '{}',
  
  -- Sync tracking
  last_synced_with_adapty TIMESTAMP WITH TIME ZONE,
  
  -- Stats
  total_analyses INTEGER DEFAULT 0,
  last_analysis_at TIMESTAMP WITH TIME ZONE,
  
  -- Audit
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_devices_device_id ON devices(device_id);
CREATE INDEX IF NOT EXISTS idx_devices_adapty_id ON devices(adapty_customer_id);
CREATE INDEX IF NOT EXISTS idx_devices_subscription ON devices(has_active_subscription, subscription_expires_at);

-- ============================================
-- ANALYSES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS analyses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT NOT NULL,
  
  -- Analysis data
  image_hash TEXT NOT NULL,
  result JSONB NOT NULL,
  
  -- Image metadata (expandable)
  image_metadata JSONB DEFAULT '{}', -- {width, height, format, file_size, source}
  
  -- Processing info
  processing_time_ms INTEGER,
  cost_usd DECIMAL(10,4) DEFAULT 0.003,
  used_free_tier BOOLEAN DEFAULT FALSE,
  used_subscription BOOLEAN DEFAULT FALSE,
  
  -- MSI-Net data
  msi_net_points JSONB,
  claude_labels JSONB,
  
  -- Metadata
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_analyses_device_id ON analyses(device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_image_hash ON analyses(image_hash);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON analyses(created_at DESC);

-- ============================================
-- TOKEN TRANSACTIONS TABLE (Audit Trail)
-- ============================================
CREATE TABLE IF NOT EXISTS token_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  device_id TEXT, -- Can be NULL for account-level transactions
  adapty_customer_id TEXT, -- For shared pool tracking
  
  transaction_type TEXT NOT NULL, -- 'purchase', 'consume', 'free', 'subscription', 'refund'
  amount INTEGER NOT NULL, -- Positive for add, negative for consume
  balance_after INTEGER NOT NULL,
  
  -- References
  analysis_id UUID REFERENCES analyses(id),
  adapty_transaction_id TEXT,
  product_id TEXT,
  
  -- Metadata
  notes TEXT,
  metadata JSONB DEFAULT '{}',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_device_id ON token_transactions(device_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_adapty_id ON token_transactions(adapty_customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_analysis_id ON token_transactions(analysis_id);

-- ============================================
-- TRIGGER: Device Limit Enforcement (Max 3 devices per Adapty account)
-- ============================================
CREATE OR REPLACE FUNCTION enforce_device_limit()
RETURNS TRIGGER AS $$
DECLARE
  device_count INTEGER;
BEGIN
  -- Skip if no adapty_customer_id
  IF NEW.adapty_customer_id IS NULL THEN
    RETURN NEW;
  END IF;
  
  -- Count existing devices with this adapty_customer_id
  SELECT COUNT(*) INTO device_count
  FROM devices
  WHERE adapty_customer_id = NEW.adapty_customer_id
    AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::UUID);
  
  -- Enforce 3-device limit
  IF device_count >= 3 THEN
    RAISE EXCEPTION 'Device limit exceeded: Maximum 3 devices per account';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_device_limit
  BEFORE INSERT OR UPDATE ON devices
  FOR EACH ROW
  EXECUTE FUNCTION enforce_device_limit();

-- ============================================
-- TRIGGER: Auto-update timestamps
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_devices_updated_at
  BEFORE UPDATE ON devices
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- RPC: Get or Create Shared Device
-- ============================================
CREATE OR REPLACE FUNCTION get_or_create_shared_device(
  p_device_id TEXT,
  p_adapty_id TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT NULL
)
RETURNS TABLE (
  device_uuid UUID,
  tokens_remaining INTEGER,
  free_tier_available INTEGER,
  has_subscription BOOLEAN,
  device_count INTEGER
) AS $$
DECLARE
  v_device RECORD;
  v_free_tier INTEGER;
  v_device_count INTEGER;
BEGIN
  -- Try to find existing device by device_id or adapty_customer_id
  SELECT * INTO v_device
  FROM devices
  WHERE device_id = p_device_id
     OR (p_adapty_id IS NOT NULL AND adapty_customer_id = p_adapty_id)
  ORDER BY 
    CASE WHEN device_id = p_device_id THEN 1 ELSE 2 END
  LIMIT 1;
  
  IF FOUND THEN
    -- Update existing device
    UPDATE devices SET
      device_id = p_device_id, -- Update if switched device
      adapty_customer_id = COALESCE(p_adapty_id, adapty_customer_id),
      metadata = COALESCE(p_metadata, metadata),
      last_synced_with_adapty = CASE 
        WHEN p_adapty_id IS NOT NULL THEN NOW() 
        ELSE last_synced_with_adapty 
      END,
      updated_at = NOW()
    WHERE id = v_device.id
    RETURNING * INTO v_device;
  ELSE
    -- Create new device
    INSERT INTO devices (
      device_id,
      adapty_customer_id,
      tokens_remaining,
      tokens_total,
      metadata,
      last_synced_with_adapty
    ) VALUES (
      p_device_id,
      p_adapty_id,
      5, -- Free tier
      5,
      COALESCE(p_metadata, '{}'),
      CASE WHEN p_adapty_id IS NOT NULL THEN NOW() ELSE NULL END
    )
    RETURNING * INTO v_device;
  END IF;
  
  -- Calculate free tier available
  IF v_device.free_tier_reset_at < NOW() THEN
    -- Reset free tier
    UPDATE devices SET
      free_tier_used_this_month = 0,
      free_tier_reset_at = NOW() + INTERVAL '1 month'
    WHERE id = v_device.id;
    v_free_tier := v_device.free_tier_limit;
  ELSE
    v_free_tier := GREATEST(0, v_device.free_tier_limit - v_device.free_tier_used_this_month);
  END IF;
  
  -- Count devices with same adapty_customer_id
  IF v_device.adapty_customer_id IS NOT NULL THEN
    SELECT COUNT(*) INTO v_device_count
    FROM devices
    WHERE adapty_customer_id = v_device.adapty_customer_id;
  ELSE
    v_device_count := 1;
  END IF;
  
  -- Return device info
  RETURN QUERY SELECT 
    v_device.id,
    v_device.tokens_remaining,
    v_free_tier,
    v_device.has_active_subscription 
      AND (v_device.subscription_expires_at IS NULL OR v_device.subscription_expires_at > NOW()),
    v_device_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RPC: Consume Token (Atomic with Row Locking)
-- ============================================
CREATE OR REPLACE FUNCTION consume_token(
  p_identifier TEXT, -- device_id or adapty_customer_id
  p_analysis_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_device RECORD;
  v_used_free BOOLEAN := FALSE;
  v_used_subscription BOOLEAN := FALSE;
  v_new_balance INTEGER;
BEGIN
  -- Find device with row-level lock (prevents simultaneous consumption)
  SELECT * INTO v_device
  FROM devices
  WHERE device_id = p_identifier 
     OR adapty_customer_id = p_identifier
  ORDER BY 
    CASE WHEN device_id = p_identifier THEN 1 ELSE 2 END
  LIMIT 1
  FOR UPDATE NOWAIT; -- Fail immediately if locked
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Device not found';
  END IF;
  
  -- Check subscription first (unlimited)
  IF v_device.has_active_subscription 
     AND (v_device.subscription_expires_at IS NULL OR v_device.subscription_expires_at > NOW()) THEN
    UPDATE devices 
    SET 
      total_analyses = total_analyses + 1,
      last_analysis_at = NOW()
    WHERE id = v_device.id;
    
    -- Record transaction
    INSERT INTO token_transactions (
      device_id, adapty_customer_id, transaction_type, 
      amount, balance_after, analysis_id, notes
    ) VALUES (
      v_device.device_id, v_device.adapty_customer_id, 'subscription',
      0, v_device.tokens_remaining, p_analysis_id, 'Used subscription (unlimited)'
    );
    
    RETURN jsonb_build_object(
      'success', TRUE,
      'used_subscription', TRUE,
      'remaining_tokens', 'unlimited'
    );
  END IF;
  
  -- Check free tier (reset if needed)
  IF v_device.free_tier_reset_at < NOW() THEN
    UPDATE devices
    SET 
      free_tier_used_this_month = 0,
      free_tier_reset_at = NOW() + INTERVAL '1 month'
    WHERE id = v_device.id;
    v_device.free_tier_used_this_month := 0;
  END IF;
  
  IF v_device.free_tier_used_this_month < v_device.free_tier_limit THEN
    -- Use free tier
    UPDATE devices 
    SET 
      free_tier_used_this_month = free_tier_used_this_month + 1,
      total_analyses = total_analyses + 1,
      last_analysis_at = NOW()
    WHERE id = v_device.id;
    
    v_used_free := TRUE;
    v_new_balance := v_device.free_tier_limit - v_device.free_tier_used_this_month - 1;
    
    -- Record transaction
    INSERT INTO token_transactions (
      device_id, adapty_customer_id, transaction_type, 
      amount, balance_after, analysis_id, notes
    ) VALUES (
      v_device.device_id, v_device.adapty_customer_id, 'free',
      -1, v_new_balance, p_analysis_id, 'Used free tier'
    );
  ELSE
    -- Use paid tokens
    IF v_device.tokens_remaining <= 0 THEN
      RAISE EXCEPTION 'No tokens available';
    END IF;
    
    v_new_balance := v_device.tokens_remaining - 1;
    
    UPDATE devices
    SET 
      tokens_remaining = v_new_balance,
      total_analyses = total_analyses + 1,
      last_analysis_at = NOW()
    WHERE id = v_device.id;
    
    -- Record transaction
    INSERT INTO token_transactions (
      device_id, adapty_customer_id, transaction_type, 
      amount, balance_after, analysis_id, notes
    ) VALUES (
      v_device.device_id, v_device.adapty_customer_id, 'consume',
      -1, v_new_balance, p_analysis_id, 'Consumed paid token'
    );
  END IF;
  
  RETURN jsonb_build_object(
    'success', TRUE,
    'used_free_tier', v_used_free,
    'used_subscription', FALSE,
    'remaining_tokens', v_new_balance
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- RPC: Add Tokens (For Purchases)
-- ============================================
CREATE OR REPLACE FUNCTION add_tokens(
  p_adapty_customer_id TEXT,
  p_product_id TEXT,
  p_transaction_id TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_product RECORD;
  v_new_balance INTEGER;
  v_devices_updated INTEGER;
BEGIN
  -- Get product details
  SELECT * INTO v_product
  FROM products
  WHERE adapty_product_id = p_product_id AND active = TRUE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found: %', p_product_id;
  END IF;
  
  -- Update all devices with this adapty_customer_id (shared pool)
  IF v_product.is_subscription THEN
    -- Set subscription status
    UPDATE devices
    SET 
      has_active_subscription = TRUE,
      subscription_expires_at = NOW() + INTERVAL '1 month',
      subscription_product_id = p_product_id,
      tokens_remaining = tokens_remaining + v_product.token_count,
      tokens_total = tokens_total + v_product.token_count,
      updated_at = NOW()
    WHERE adapty_customer_id = p_adapty_customer_id
    RETURNING tokens_remaining INTO v_new_balance;
  ELSE
    -- Add one-time tokens
    UPDATE devices
    SET 
      tokens_remaining = tokens_remaining + v_product.token_count,
      tokens_total = tokens_total + v_product.token_count,
      updated_at = NOW()
    WHERE adapty_customer_id = p_adapty_customer_id
    RETURNING tokens_remaining INTO v_new_balance;
  END IF;
  
  GET DIAGNOSTICS v_devices_updated = ROW_COUNT;
  
  -- Record transaction
  INSERT INTO token_transactions (
    adapty_customer_id,
    transaction_type,
    amount,
    balance_after,
    adapty_transaction_id,
    product_id,
    notes
  ) VALUES (
    p_adapty_customer_id,
    CASE WHEN v_product.is_subscription THEN 'subscription' ELSE 'purchase' END,
    v_product.token_count,
    v_new_balance,
    p_transaction_id,
    p_product_id,
    format('Purchased %s (%s tokens)', v_product.name, v_product.token_count)
  );
  
  RETURN jsonb_build_object(
    'success', TRUE,
    'tokens_added', v_product.token_count,
    'new_balance', v_new_balance,
    'devices_updated', v_devices_updated,
    'is_subscription', v_product.is_subscription
  );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================
COMMENT ON TABLE devices IS 'Device registry with shared token pool via adapty_customer_id';
COMMENT ON TABLE analyses IS 'Analysis results with expandable metadata';
COMMENT ON TABLE token_transactions IS 'Audit trail for all token operations';
COMMENT ON TABLE products IS 'Token package catalog synced with Adapty';
COMMENT ON FUNCTION get_or_create_shared_device IS 'Finds or creates device, returns shared pool balance';
COMMENT ON FUNCTION consume_token IS 'Atomically consumes token with row locking to prevent race conditions';
COMMENT ON FUNCTION add_tokens IS 'Adds tokens to all devices with same adapty_customer_id';
