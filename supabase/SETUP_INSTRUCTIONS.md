# Supabase Setup Instructions

## Your Project Info
- **Project ID**: `wvnjhqrasmtbyupipdfz`
- **Project URL**: `https://wvnjhqrasmtbyupipdfz.supabase.co`
- **Anon Key**: Already configured in the app

---

## Step 1: Create the Database Tables

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/wvnjhqrasmtbyupipdfz

2. Click on **SQL Editor** in the left sidebar

3. Click **+ New query**

4. Copy and paste the ENTIRE content below, then click **Run**:

```sql
-- =============================================
-- SIMPLE DATABASE SETUP
-- =============================================

-- 1. Create the exchange_rates table
CREATE TABLE IF NOT EXISTS public.exchange_rates (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(20),
    price_usd NUMERIC(30, 15) NOT NULL DEFAULT 0,
    change_percent_24h NUMERIC(10, 4) DEFAULT 0,
    is_crypto BOOLEAN NOT NULL DEFAULT false,
    market_cap NUMERIC(30, 2),
    volume_24h NUMERIC(30, 2),
    rank INTEGER,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the fetch_logs table (tracks API fetches)
CREATE TABLE IF NOT EXISTS public.fetch_logs (
    id SERIAL PRIMARY KEY,
    fetched_at TIMESTAMPTZ DEFAULT NOW(),
    crypto_source VARCHAR(50),
    crypto_count INTEGER DEFAULT 0,
    fiat_count INTEGER DEFAULT 0,
    duration_ms INTEGER,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_exchange_rates_code ON public.exchange_rates(code);
CREATE INDEX IF NOT EXISTS idx_exchange_rates_is_crypto ON public.exchange_rates(is_crypto);
CREATE INDEX IF NOT EXISTS idx_fetch_logs_fetched_at ON public.fetch_logs(fetched_at DESC);

-- 4. Enable Row Level Security
ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fetch_logs ENABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public read on exchange_rates" ON public.exchange_rates;
DROP POLICY IF EXISTS "Allow service write on exchange_rates" ON public.exchange_rates;
DROP POLICY IF EXISTS "Allow public read on fetch_logs" ON public.fetch_logs;
DROP POLICY IF EXISTS "Allow service write on fetch_logs" ON public.fetch_logs;

-- 6. Create RLS policies
CREATE POLICY "Allow public read on exchange_rates" 
ON public.exchange_rates FOR SELECT 
TO anon, authenticated
USING (true);

CREATE POLICY "Allow service write on exchange_rates" 
ON public.exchange_rates FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow public read on fetch_logs" 
ON public.fetch_logs FOR SELECT 
TO anon, authenticated
USING (true);

CREATE POLICY "Allow service write on fetch_logs" 
ON public.fetch_logs FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);

-- 7. Grant permissions
GRANT SELECT ON public.exchange_rates TO anon, authenticated;
GRANT ALL ON public.exchange_rates TO service_role;
GRANT SELECT ON public.fetch_logs TO anon, authenticated;
GRANT ALL ON public.fetch_logs TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.exchange_rates_id_seq TO service_role;
GRANT USAGE, SELECT ON SEQUENCE public.fetch_logs_id_seq TO service_role;
```

5. You should see "Success. No rows returned" - this means it worked!

---

## Step 2: Verify Tables Were Created

1. Click on **Table Editor** in the left sidebar
2. You should see two tables:
   - `exchange_rates` (empty for now)
   - `fetch_logs` (empty for now)

---

## Step 3: Deploy the Updated Edge Function

Run these commands in your terminal:

```bash
# Navigate to project
cd /Users/ionitaserghei/Documents/GitHub/cryptocurrencyconverter

# Login to Supabase (if not already)
supabase login

# Link to your project
supabase link --project-ref wvnjhqrasmtbyupipdfz

# Deploy the function
supabase functions deploy update-rates
```

---

## Step 4: Test the Function

Run this command to test:

```bash
curl -X POST https://wvnjhqrasmtbyupipdfz.supabase.co/functions/v1/update-rates \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2bmpocXJhc210Ynl1cGlwZGZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY1Nzg1NzUsImV4cCI6MjA4MjE1NDU3NX0.Uh0jhcz8bN-jeHGEm8GJ_bJ_ML_N0h771iu2ZPl1Nds" \
  -H "Content-Type: application/json"
```

### Expected Response (First Call - fetches from APIs):
```json
{
  "success": true,
  "source": "api",
  "crypto_source": "coincap",
  "count": 300,
  "crypto_count": 250,
  "fiat_count": 50,
  "last_updated": "2024-12-29T...",
  "cache_duration_minutes": 20,
  "duration_ms": 1500,
  "data": [...]
}
```

### Expected Response (Subsequent Calls within 20 min - from cache):
```json
{
  "success": true,
  "source": "cache",
  "count": 300,
  "last_updated": "2024-12-29T...",
  "cache_duration_minutes": 20,
  "duration_ms": 50,
  "data": [...]
}
```

---

## How the Caching Works

```
┌─────────────────────────────────────────────────────────────┐
│                    REQUEST FLOW                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  App calls function                                          │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────────┐                                       │
│  │ Check last fetch │                                       │
│  │ from fetch_logs  │                                       │
│  └────────┬─────────┘                                       │
│           │                                                  │
│     ┌─────┴─────┐                                           │
│     │           │                                            │
│  < 20 min    >= 20 min                                      │
│     │           │                                            │
│     ▼           ▼                                            │
│  ┌──────┐  ┌─────────────────────────────────┐              │
│  │CACHE │  │ Fetch APIs concurrently:        │              │
│  │Return│  │ - CoinCap → CoinGecko (crypto)  │              │
│  │data  │  │ - ExchangeRate API (fiat)       │              │
│  └──────┘  └─────────────┬───────────────────┘              │
│                          │                                   │
│                          ▼                                   │
│                   ┌──────────────┐                          │
│                   │ Save to DB   │                          │
│                   │ Log fetch    │                          │
│                   │ Return data  │                          │
│                   └──────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

---

## Troubleshooting

### Error: "relation does not exist"
→ Run the SQL in Step 1 again

### Error: "Unknown error"  
→ Check that tables exist in Table Editor

### Error: "permission denied"
→ Make sure RLS policies were created (Step 1)

### View Function Logs
1. Go to Supabase Dashboard
2. Click **Edge Functions** in sidebar
3. Click **update-rates**
4. Click **Logs** tab

---

## Files Updated

| File | Change |
|------|--------|
| `pubspec.yaml` | Updated to `supabase_flutter: ^2.12.0` |
| `lib/core/config/supabase_config.dart` | Added your project credentials |
| `supabase/functions/update-rates/index.ts` | Rewrote with caching logic |
| `supabase/migrations/001_simple_setup.sql` | Simplified SQL setup |
