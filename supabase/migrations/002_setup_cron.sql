-- =============================================
-- Scheduled Job Setup for Exchange Rate Updates
-- =============================================
-- This migration sets up pg_cron to automatically
-- trigger the Edge Function every 6 hours (4x/day).
--
-- NOTE: pg_cron is available on Supabase Pro plan.
-- For free tier, use an external scheduler (e.g., GitHub Actions).

-- =============================================
-- OPTION 1: Using pg_cron (Pro Plan)
-- =============================================

-- Enable pg_cron extension (requires Pro plan)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule the Edge Function to run every 6 hours
-- This calls the update-rates function at 00:00, 06:00, 12:00, 18:00 UTC

/*
SELECT cron.schedule(
    'update-exchange-rates',           -- Job name
    '0 */6 * * *',                     -- Cron expression: every 6 hours
    $$
    SELECT net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/update-rates',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
        ),
        body := '{}'::jsonb
    );
    $$
);
*/

-- To list scheduled jobs:
-- SELECT * FROM cron.job;

-- To unschedule:
-- SELECT cron.unschedule('update-exchange-rates');

-- =============================================
-- OPTION 2: Using pg_net for HTTP calls (Free Tier)
-- =============================================

-- Enable pg_net extension
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create a function to trigger the Edge Function
CREATE OR REPLACE FUNCTION trigger_rate_update()
RETURNS void AS $$
BEGIN
    PERFORM net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/update-rates',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
        ),
        body := '{}'::jsonb
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- OPTION 3: GitHub Actions (Recommended for Free Tier)
-- =============================================

-- For free tier users, create a GitHub Action that runs on a schedule.
-- See: .github/workflows/update-rates.yml in the repository.

-- Example GitHub Action workflow:
/*
name: Update Exchange Rates

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:        # Allow manual trigger

jobs:
  update-rates:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Supabase Edge Function
        run: |
          curl -X POST \
            'https://YOUR_PROJECT_REF.supabase.co/functions/v1/update-rates' \
            -H 'Authorization: Bearer ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}' \
            -H 'Content-Type: application/json'
*/

-- =============================================
-- MONITORING QUERIES
-- =============================================

-- Check last 10 updates
-- SELECT * FROM rate_update_logs ORDER BY started_at DESC LIMIT 10;

-- Check if rates are stale (older than 7 hours)
-- SELECT 
--     CASE 
--         WHEN MAX(updated_at) < NOW() - INTERVAL '7 hours' THEN 'STALE'
--         ELSE 'FRESH'
--     END as status,
--     MAX(updated_at) as last_update,
--     COUNT(*) as total_rates
-- FROM exchange_rates;

-- Get update frequency stats
-- SELECT 
--     DATE_TRUNC('day', started_at) as day,
--     COUNT(*) as updates,
--     SUM(crypto_count) as total_crypto_updated,
--     SUM(fiat_count) as total_fiat_updated
-- FROM rate_update_logs
-- WHERE status = 'completed'
-- GROUP BY DATE_TRUNC('day', started_at)
-- ORDER BY day DESC
-- LIMIT 7;
