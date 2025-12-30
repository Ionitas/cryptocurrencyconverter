-- =============================================
-- Cryptocurrency Converter - Database Schema
-- =============================================
-- This migration creates the exchange_rates table
-- and supporting infrastructure for caching currency data.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- EXCHANGE RATES TABLE
-- =============================================
-- Stores all currency exchange rates (crypto and fiat)
-- Updated periodically by the Edge Function

CREATE TABLE IF NOT EXISTS public.exchange_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20),
    price_usd DECIMAL(30, 15) NOT NULL,
    change_percent_24h DECIMAL(10, 4) DEFAULT 0,
    is_crypto BOOLEAN NOT NULL DEFAULT false,
    market_cap DECIMAL(30, 2),
    volume_24h DECIMAL(30, 2),
    rank INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT unique_currency_code UNIQUE(code)
);

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_exchange_rates_code ON public.exchange_rates(code);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_is_crypto ON public.exchange_rates(is_crypto);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_updated_at ON public.exchange_rates(updated_at);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_rank ON public.exchange_rates(rank) WHERE rank IS NOT NULL;

-- =============================================
-- UPDATE LOGS TABLE
-- =============================================
-- Tracks history of rate updates for monitoring

CREATE TABLE IF NOT EXISTS public.rate_update_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    status VARCHAR(20) NOT NULL DEFAULT 'started',
    crypto_count INTEGER DEFAULT 0,
    fiat_count INTEGER DEFAULT 0,
    error_message TEXT,
    source VARCHAR(50)
);

CREATE INDEX IF NOT EXISTS idx_rate_update_logs_started_at ON public.rate_update_logs(started_at DESC);

-- =============================================
-- METADATA TABLE
-- =============================================
-- Stores metadata like last successful update time

CREATE TABLE IF NOT EXISTS public.app_metadata (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert initial metadata
INSERT INTO public.app_metadata (key, value) 
VALUES ('last_rate_update', '{"timestamp": null, "success": false}'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================
-- Enable RLS for security

ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_update_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_metadata ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read exchange rates (public data)
CREATE POLICY "Allow public read access on exchange_rates" 
ON public.exchange_rates FOR SELECT 
USING (true);

-- Policy: Only service role can insert/update/delete rates
CREATE POLICY "Allow service role full access on exchange_rates" 
ON public.exchange_rates FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Policy: Anyone can read update logs
CREATE POLICY "Allow public read access on rate_update_logs" 
ON public.rate_update_logs FOR SELECT 
USING (true);

-- Policy: Only service role can modify logs
CREATE POLICY "Allow service role full access on rate_update_logs" 
ON public.rate_update_logs FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- Policy: Anyone can read metadata
CREATE POLICY "Allow public read access on app_metadata" 
ON public.app_metadata FOR SELECT 
USING (true);

-- Policy: Only service role can modify metadata
CREATE POLICY "Allow service role full access on app_metadata" 
ON public.app_metadata FOR ALL 
USING (auth.role() = 'service_role')
WITH CHECK (auth.role() = 'service_role');

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on exchange_rates
DROP TRIGGER IF EXISTS update_exchange_rates_updated_at ON public.exchange_rates;
CREATE TRIGGER update_exchange_rates_updated_at
    BEFORE UPDATE ON public.exchange_rates
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- VIEWS
-- =============================================

-- View: All cryptocurrencies ordered by rank
CREATE OR REPLACE VIEW public.crypto_rates AS
SELECT 
    code,
    name,
    symbol,
    price_usd,
    change_percent_24h,
    market_cap,
    volume_24h,
    rank,
    updated_at
FROM public.exchange_rates
WHERE is_crypto = true
ORDER BY COALESCE(rank, 999999), code;

-- View: All fiat currencies ordered by code
CREATE OR REPLACE VIEW public.fiat_rates AS
SELECT 
    code,
    name,
    symbol,
    price_usd,
    updated_at
FROM public.exchange_rates
WHERE is_crypto = false
ORDER BY code;

-- View: Last update status
CREATE OR REPLACE VIEW public.last_update_status AS
SELECT 
    started_at,
    completed_at,
    status,
    crypto_count,
    fiat_count,
    error_message,
    source,
    EXTRACT(EPOCH FROM (completed_at - started_at)) as duration_seconds
FROM public.rate_update_logs
ORDER BY started_at DESC
LIMIT 1;

-- =============================================
-- SAMPLE DATA (Optional - for testing)
-- =============================================

-- Uncomment to insert sample data for testing:
/*
INSERT INTO public.exchange_rates (code, name, symbol, price_usd, change_percent_24h, is_crypto, rank) VALUES
('BTC', 'Bitcoin', 'BTC', 42000.00, 2.5, true, 1),
('ETH', 'Ethereum', 'ETH', 2200.00, 1.8, true, 2),
('USDT', 'Tether', 'USDT', 1.00, 0.01, true, 3),
('USD', 'US Dollar', '$', 1.00, 0, false, NULL),
('EUR', 'Euro', '€', 1.08, 0, false, NULL),
('GBP', 'British Pound', '£', 1.27, 0, false, NULL)
ON CONFLICT (code) DO UPDATE SET
    price_usd = EXCLUDED.price_usd,
    change_percent_24h = EXCLUDED.change_percent_24h;
*/

-- =============================================
-- GRANTS
-- =============================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant select on all tables and views
GRANT SELECT ON public.exchange_rates TO anon, authenticated;
GRANT SELECT ON public.rate_update_logs TO anon, authenticated;
GRANT SELECT ON public.app_metadata TO anon, authenticated;
GRANT SELECT ON public.crypto_rates TO anon, authenticated;
GRANT SELECT ON public.fiat_rates TO anon, authenticated;
GRANT SELECT ON public.last_update_status TO anon, authenticated;
