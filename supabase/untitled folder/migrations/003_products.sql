-- ============================================================================
-- MIGRATION 003: Product Catalog Data
-- ============================================================================
-- Inserts all products and feature costs.
-- ============================================================================

-- ============================================================================
-- PRODUCTS
-- ============================================================================
INSERT INTO products (product_id, name, price_cents, billing_period, tokens_per_period, description) VALUES
    -- Weekly Plans
    ('attentionmap_9.99_weekly_unlimited', 'Creator Weekly', 999, 'week', 10, '10 analyses per week'),
    ('attentionmap_39.99_weekly_unlimited', 'Ultimate Weekly', 3999, 'week', 50, '50 analyses per week'),
    
    -- Monthly Plans
    ('attentionmap_29.99_monthly_unlimited', 'Creator Monthly', 2999, 'month', 50, '50 analyses per month'),
    ('attentionmap_119.99_monthly_unlimited', 'Ultimate Monthly', 11999, 'month', 200, '200 analyses per month'),
    
    -- Annual Plans (tokens per month, reset monthly)
    ('attentionmap_249.99_annually_unlimited', 'Premium Annual', 24999, 'year', 60, '60 analyses per month'),
    ('attentionmap_999.99_annually_unlimited', 'Ultimate Annual', 99999, 'year', 220, '220 analyses per month')
ON CONFLICT (product_id) DO UPDATE SET
    name = EXCLUDED.name,
    price_cents = EXCLUDED.price_cents,
    billing_period = EXCLUDED.billing_period,
    tokens_per_period = EXCLUDED.tokens_per_period,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ============================================================================
-- FEATURE COSTS
-- ============================================================================
INSERT INTO feature_costs (feature_id, feature_name, token_cost) VALUES
    ('image_analysis', 'Image Analysis', 1),
    ('heatmap_generation', 'Heatmap Generation', 1),
    ('export_pdf', 'Export PDF', 1),
    ('export_csv', 'Export CSV', 0),
    ('advanced_analytics', 'Advanced Analytics', 2)
ON CONFLICT (feature_id) DO UPDATE SET
    feature_name = EXCLUDED.feature_name,
    token_cost = EXCLUDED.token_cost;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
    product_count INTEGER;
    feature_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO product_count FROM products WHERE is_active = TRUE;
    SELECT COUNT(*) INTO feature_count FROM feature_costs WHERE is_active = TRUE;
    
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Migration 003: Products populated';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Products: %', product_count;
    RAISE NOTICE 'Features: %', feature_count;
    RAISE NOTICE '========================================';
END $$;
