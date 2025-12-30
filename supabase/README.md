# Supabase Backend Setup

This folder contains the Supabase backend configuration for the cryptocurrency converter app.

## Overview

The Supabase backend serves as a centralized data store for exchange rates, reducing API calls to external services (CoinCap, CoinGecko, ExchangeRate API) from every user request to just 3-5 times per day.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐    Scheduled (every 6 hours)          │
│  │ pg_cron          │───────────────────────────────────────┐│
│  │ (PostgreSQL)     │                                       ││
│  └────────┬─────────┘                                       ││
│           │                                                  ││
│           ▼                                                  ││
│  ┌──────────────────┐     ┌──────────────────┐              ││
│  │ Edge Function    │────►│ External APIs    │              ││
│  │ update-rates     │◄────│ CoinCap/CoinGecko│              ││
│  └────────┬─────────┘     └──────────────────┘              ││
│           │                                                  ││
│           ▼                                                  ││
│  ┌──────────────────┐                                       ││
│  │ exchange_rates   │◄──────────────────────────────────────┘│
│  │ (PostgreSQL)     │                                        │
│  └────────┬─────────┘                                        │
│           │                                                  │
└───────────┼──────────────────────────────────────────────────┘
            │
            ▼ REST API
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP                               │
│  Fetches rates from Supabase instead of external APIs       │
└─────────────────────────────────────────────────────────────┘
```

## Setup Instructions

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key from Settings > API

### 2. Run Database Migration

1. Go to SQL Editor in Supabase Dashboard
2. Run the contents of `migrations/001_create_exchange_rates.sql`

### 3. Deploy Edge Function

```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy update-rates
```

### 4. Set Up Scheduled Updates

Run the contents of `migrations/002_setup_cron.sql` in SQL Editor.

### 5. Configure Flutter App

Update `lib/core/config/supabase_config.dart` with your project credentials:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

## Files Structure

```
supabase/
├── README.md                              # This file
├── migrations/
│   ├── 001_create_exchange_rates.sql     # Database schema
│   └── 002_setup_cron.sql                # Scheduled job setup
└── functions/
    └── update-rates/
        ├── index.ts                       # Edge Function code
        └── deno.json                      # Deno configuration
```

## API Endpoints

### Fetch All Rates
```
GET https://YOUR_PROJECT.supabase.co/rest/v1/exchange_rates
Authorization: Bearer YOUR_ANON_KEY
```

### Fetch Crypto Only
```
GET https://YOUR_PROJECT.supabase.co/rest/v1/exchange_rates?is_crypto=eq.true
```

### Fetch Fiat Only
```
GET https://YOUR_PROJECT.supabase.co/rest/v1/exchange_rates?is_crypto=eq.false
```

## Manual Rate Update

To manually trigger a rate update:

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/update-rates \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

## Monitoring

- Check `rate_update_logs` table for update history
- Edge Function logs available in Supabase Dashboard > Edge Functions > Logs
