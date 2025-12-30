/**
 * Supabase Edge Function: update-rates
 * 
 * Logic:
 * 1. Check if data exists and is fresh (within CACHE_DURATION_MINUTES)
 * 2. If fresh -> return cached data from database
 * 3. If stale or no data -> fetch from APIs concurrently, save to DB, return data
 * 
 * Tracks: when data was fetched, which API was used, duration
 */

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Configuration
const CACHE_DURATION_MINUTES = 20 // Data is considered fresh for 20 minutes

// Types
interface ExchangeRate {
  code: string
  name: string
  symbol: string
  price_usd: number
  change_percent_24h: number
  is_crypto: boolean
  market_cap?: number
  volume_24h?: number
  rank?: number
}

interface CoinCapAsset {
  id: string
  rank: string
  symbol: string
  name: string
  priceUsd: string
  changePercent24Hr: string
  marketCapUsd: string
  volumeUsd24Hr: string
}

interface CoinGeckoCoin {
  id: string
  symbol: string
  name: string
  current_price: number
  price_change_percentage_24h: number
  market_cap: number
  total_volume: number
  market_cap_rank: number
}

// Fiat currency names
const FIAT_NAMES: Record<string, { name: string; symbol: string }> = {
  'USD': { name: 'US Dollar', symbol: '$' },
  'EUR': { name: 'Euro', symbol: '€' },
  'GBP': { name: 'British Pound', symbol: '£' },
  'JPY': { name: 'Japanese Yen', symbol: '¥' },
  'CHF': { name: 'Swiss Franc', symbol: 'Fr' },
  'AUD': { name: 'Australian Dollar', symbol: 'A$' },
  'CAD': { name: 'Canadian Dollar', symbol: 'C$' },
  'CNY': { name: 'Chinese Yuan', symbol: '¥' },
  'HKD': { name: 'Hong Kong Dollar', symbol: 'HK$' },
  'NZD': { name: 'New Zealand Dollar', symbol: 'NZ$' },
  'SEK': { name: 'Swedish Krona', symbol: 'kr' },
  'KRW': { name: 'South Korean Won', symbol: '₩' },
  'SGD': { name: 'Singapore Dollar', symbol: 'S$' },
  'NOK': { name: 'Norwegian Krone', symbol: 'kr' },
  'MXN': { name: 'Mexican Peso', symbol: '$' },
  'INR': { name: 'Indian Rupee', symbol: '₹' },
  'RUB': { name: 'Russian Ruble', symbol: '₽' },
  'ZAR': { name: 'South African Rand', symbol: 'R' },
  'TRY': { name: 'Turkish Lira', symbol: '₺' },
  'BRL': { name: 'Brazilian Real', symbol: 'R$' },
  'TWD': { name: 'Taiwan Dollar', symbol: 'NT$' },
  'DKK': { name: 'Danish Krone', symbol: 'kr' },
  'PLN': { name: 'Polish Zloty', symbol: 'zł' },
  'THB': { name: 'Thai Baht', symbol: '฿' },
  'IDR': { name: 'Indonesian Rupiah', symbol: 'Rp' },
  'HUF': { name: 'Hungarian Forint', symbol: 'Ft' },
  'CZK': { name: 'Czech Koruna', symbol: 'Kč' },
  'ILS': { name: 'Israeli Shekel', symbol: '₪' },
  'CLP': { name: 'Chilean Peso', symbol: '$' },
  'PHP': { name: 'Philippine Peso', symbol: '₱' },
  'AED': { name: 'UAE Dirham', symbol: 'د.إ' },
  'COP': { name: 'Colombian Peso', symbol: '$' },
  'SAR': { name: 'Saudi Riyal', symbol: '﷼' },
  'MYR': { name: 'Malaysian Ringgit', symbol: 'RM' },
  'RON': { name: 'Romanian Leu', symbol: 'lei' },
  'ARS': { name: 'Argentine Peso', symbol: '$' },
  'BGN': { name: 'Bulgarian Lev', symbol: 'лв' },
  'HRK': { name: 'Croatian Kuna', symbol: 'kn' },
  'PEN': { name: 'Peruvian Sol', symbol: 'S/' },
  'UAH': { name: 'Ukrainian Hryvnia', symbol: '₴' },
  'EGP': { name: 'Egyptian Pound', symbol: '£' },
  'PKR': { name: 'Pakistani Rupee', symbol: '₨' },
  'VND': { name: 'Vietnamese Dong', symbol: '₫' },
  'BDT': { name: 'Bangladeshi Taka', symbol: '৳' },
  'NGN': { name: 'Nigerian Naira', symbol: '₦' },
  'KES': { name: 'Kenyan Shilling', symbol: 'KSh' },
  'QAR': { name: 'Qatari Rial', symbol: '﷼' },
  'KWD': { name: 'Kuwaiti Dinar', symbol: 'د.ك' },
  'MAD': { name: 'Moroccan Dirham', symbol: 'د.م.' },
  'OMR': { name: 'Omani Rial', symbol: '﷼' },
  'BHD': { name: 'Bahraini Dinar', symbol: '.د.ب' },
  'JOD': { name: 'Jordanian Dinar', symbol: 'د.ا' },
  'LKR': { name: 'Sri Lankan Rupee', symbol: '₨' },
  'MMK': { name: 'Myanmar Kyat', symbol: 'K' },
  'NPR': { name: 'Nepalese Rupee', symbol: '₨' },
  'GHS': { name: 'Ghanaian Cedi', symbol: '₵' },
  'TZS': { name: 'Tanzanian Shilling', symbol: 'TSh' },
  'UGX': { name: 'Ugandan Shilling', symbol: 'USh' },
  'RWF': { name: 'Rwandan Franc', symbol: 'FRw' },
  'XOF': { name: 'West African CFA', symbol: 'CFA' },
  'XAF': { name: 'Central African CFA', symbol: 'FCFA' },
}

// ============================================
// DATABASE FUNCTIONS
// ============================================

async function getLastFetchTime(supabase: SupabaseClient): Promise<Date | null> {
  try {
    const { data, error } = await supabase
      .from('fetch_logs')
      .select('fetched_at')
      .eq('success', true)
      .order('fetched_at', { ascending: false })
      .limit(1)
      .single()
    
    if (error || !data) return null
    return new Date(data.fetched_at)
  } catch {
    return null
  }
}

async function isDataFresh(supabase: SupabaseClient): Promise<boolean> {
  const lastFetch = await getLastFetchTime(supabase)
  if (!lastFetch) return false
  
  const now = new Date()
  const diffMs = now.getTime() - lastFetch.getTime()
  const diffMinutes = diffMs / (1000 * 60)
  
  console.log(`Last fetch: ${lastFetch.toISOString()}, ${diffMinutes.toFixed(1)} minutes ago`)
  return diffMinutes < CACHE_DURATION_MINUTES
}

async function getCachedRates(supabase: SupabaseClient): Promise<ExchangeRate[]> {
  const { data, error } = await supabase
    .from('exchange_rates')
    .select('*')
    .order('is_crypto', { ascending: false })
    .order('rank', { ascending: true, nullsFirst: false })
    .order('code', { ascending: true })
  
  if (error) {
    console.error('Error fetching cached rates:', error)
    return []
  }
  
  return (data || []).map(row => ({
    code: row.code,
    name: row.name,
    symbol: row.symbol,
    price_usd: parseFloat(row.price_usd) || 0,
    change_percent_24h: parseFloat(row.change_percent_24h) || 0,
    is_crypto: row.is_crypto,
    market_cap: row.market_cap ? parseFloat(row.market_cap) : undefined,
    volume_24h: row.volume_24h ? parseFloat(row.volume_24h) : undefined,
    rank: row.rank,
  }))
}

async function saveRates(supabase: SupabaseClient, rates: ExchangeRate[]): Promise<void> {
  // Deduplicate by code - keep first occurrence (crypto takes priority since it's added first)
  const seen = new Set<string>()
  const uniqueRates = rates.filter(rate => {
    if (seen.has(rate.code)) {
      console.log(`Duplicate code skipped: ${rate.code}`)
      return false
    }
    seen.add(rate.code)
    return true
  })

  console.log(`Saving ${uniqueRates.length} unique rates (removed ${rates.length - uniqueRates.length} duplicates)`)

  const upsertData = uniqueRates.map(rate => ({
    code: rate.code,
    name: rate.name,
    symbol: rate.symbol,
    price_usd: rate.price_usd,
    change_percent_24h: rate.change_percent_24h || 0,
    is_crypto: rate.is_crypto,
    market_cap: rate.market_cap || null,
    volume_24h: rate.volume_24h || null,
    rank: rate.rank || null,
    updated_at: new Date().toISOString(),
  }))

  const { error } = await supabase
    .from('exchange_rates')
    .upsert(upsertData, { onConflict: 'code' })

  if (error) {
    console.error('Error saving rates:', error)
    throw error
  }
}

async function logFetch(
  supabase: SupabaseClient, 
  cryptoSource: string,
  cryptoCount: number,
  fiatCount: number,
  durationMs: number,
  success: boolean,
  errorMessage?: string
): Promise<void> {
  await supabase.from('fetch_logs').insert({
    crypto_source: cryptoSource,
    crypto_count: cryptoCount,
    fiat_count: fiatCount,
    duration_ms: durationMs,
    success,
    error_message: errorMessage || null,
  })
}

// ============================================
// API FETCH FUNCTIONS
// ============================================

async function fetchFromCoinCap(limit = 250): Promise<ExchangeRate[]> {
  console.log('Fetching crypto from CoinCap...')
  try {
    const response = await fetch(
      `https://api.coincap.io/v2/assets?limit=${limit}`,
      { headers: { 'Accept-Encoding': 'gzip' } }
    )
    
    if (!response.ok) throw new Error(`CoinCap returned ${response.status}`)
    
    const data = await response.json()
    const assets: CoinCapAsset[] = data.data || []
    
    console.log(`CoinCap: got ${assets.length} assets`)
    
    return assets.map(asset => ({
      code: asset.symbol.toUpperCase(),
      name: asset.name,
      symbol: asset.symbol.toUpperCase(),
      price_usd: parseFloat(asset.priceUsd) || 0,
      change_percent_24h: parseFloat(asset.changePercent24Hr) || 0,
      is_crypto: true,
      market_cap: parseFloat(asset.marketCapUsd) || undefined,
      volume_24h: parseFloat(asset.volumeUsd24Hr) || undefined,
      rank: parseInt(asset.rank) || undefined,
    }))
  } catch (error) {
    console.error('CoinCap error:', error)
    return []
  }
}

async function fetchFromCoinGecko(limit = 250): Promise<ExchangeRate[]> {
  console.log('Fetching crypto from CoinGecko...')
  try {
    const response = await fetch(
      `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=${limit}&page=1&sparkline=false`
    )
    
    if (!response.ok) throw new Error(`CoinGecko returned ${response.status}`)
    
    const coins: CoinGeckoCoin[] = await response.json()
    console.log(`CoinGecko: got ${coins.length} coins`)
    
    return coins.map(coin => ({
      code: coin.symbol.toUpperCase(),
      name: coin.name,
      symbol: coin.symbol.toUpperCase(),
      price_usd: coin.current_price || 0,
      change_percent_24h: coin.price_change_percentage_24h || 0,
      is_crypto: true,
      market_cap: coin.market_cap || undefined,
      volume_24h: coin.total_volume || undefined,
      rank: coin.market_cap_rank || undefined,
    }))
  } catch (error) {
    console.error('CoinGecko error:', error)
    return []
  }
}

async function fetchFiatRates(): Promise<ExchangeRate[]> {
  console.log('Fetching fiat from ExchangeRate API...')
  try {
    const response = await fetch('https://api.exchangerate-api.com/v4/latest/USD')
    
    if (!response.ok) throw new Error(`ExchangeRate API returned ${response.status}`)
    
    const data = await response.json()
    const rates: Record<string, number> = data.rates || {}
    
    console.log(`ExchangeRate API: got ${Object.keys(rates).length} currencies`)
    
    const fiatRates: ExchangeRate[] = []
    
    for (const [code, rate] of Object.entries(rates)) {
      const info = FIAT_NAMES[code]
      fiatRates.push({
        code,
        name: info?.name || code,
        symbol: info?.symbol || code,
        price_usd: 1 / rate, // Convert to USD price
        change_percent_24h: 0,
        is_crypto: false,
      })
    }
    
    return fiatRates
  } catch (error) {
    console.error('ExchangeRate API error:', error)
    return []
  }
}

// ============================================
// MAIN HANDLER
// ============================================

Deno.serve(async (req: Request) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  const startTime = Date.now()

  try {
    // Initialize Supabase client with service role for writes
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false }
    })

    // Step 1: Check if data is fresh
    const dataIsFresh = await isDataFresh(supabase)
    
    if (dataIsFresh) {
      // Data is fresh, return from cache
      console.log('Data is fresh, returning cached rates')
      const cachedRates = await getCachedRates(supabase)
      
      if (cachedRates.length > 0) {
        const lastFetch = await getLastFetchTime(supabase)
        return new Response(
          JSON.stringify({
            success: true,
            source: 'cache',
            data: cachedRates,
            count: cachedRates.length,
            last_updated: lastFetch?.toISOString(),
            cache_duration_minutes: CACHE_DURATION_MINUTES,
            duration_ms: Date.now() - startTime,
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      // If cache is empty, continue to fetch
      console.log('Cache is empty, fetching fresh data')
    }

    // Step 2: Fetch fresh data from APIs concurrently
    console.log('Fetching fresh data from APIs...')
    
    // Fetch crypto and fiat concurrently
    const [cryptoRates, fiatRates] = await Promise.all([
      // Try CoinCap first, fallback to CoinGecko
      fetchFromCoinCap(250).then(rates => {
        if (rates.length > 0) return { rates, source: 'coincap' }
        return fetchFromCoinGecko(250).then(r => ({ rates: r, source: 'coingecko' }))
      }),
      fetchFiatRates(),
    ])

    const allCrypto = cryptoRates.rates
    const cryptoSource = cryptoRates.source
    const allFiat = fiatRates

    console.log(`Fetched ${allCrypto.length} crypto (${cryptoSource}), ${allFiat.length} fiat`)

    if (allCrypto.length === 0 && allFiat.length === 0) {
      throw new Error('No data received from any API')
    }

    // Step 3: Save to database
    const allRates = [...allCrypto, ...allFiat]
    await saveRates(supabase, allRates)

    // Step 4: Log the fetch
    const durationMs = Date.now() - startTime
    await logFetch(supabase, cryptoSource, allCrypto.length, allFiat.length, durationMs, true)

    // Step 5: Return the data
    return new Response(
      JSON.stringify({
        success: true,
        source: 'api',
        crypto_source: cryptoSource,
        data: allRates,
        count: allRates.length,
        crypto_count: allCrypto.length,
        fiat_count: allFiat.length,
        last_updated: new Date().toISOString(),
        cache_duration_minutes: CACHE_DURATION_MINUTES,
        duration_ms: durationMs,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    
    // Try to log the error
    try {
      const supabaseUrl = Deno.env.get('SUPABASE_URL')!
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
      const supabase = createClient(supabaseUrl, supabaseServiceKey)
      await logFetch(supabase, 'error', 0, 0, Date.now() - startTime, false, errorMessage)
    } catch {
      // Ignore logging errors
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        duration_ms: Date.now() - startTime,
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
