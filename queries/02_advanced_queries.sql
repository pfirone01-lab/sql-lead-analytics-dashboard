-- =========================================================
-- SQL Lead Analytics Dashboard: Advanced Queries
-- File: queries/02_advanced_queries.sql
-- =========================================================

-- 1. CTE: lead conversion rate by source
-- Conversion = percentage of leads per source that reached "Closed Won"
WITH source_summary AS (
    SELECT
        lead_source,
        COUNT(*) AS total_leads,
        COUNT(*) FILTER (WHERE status = 'Closed Won') AS won_leads
    FROM leads
    GROUP BY lead_source
)
SELECT
    lead_source,
    total_leads,
    won_leads,
    ROUND(100.0 * won_leads / total_leads, 1) AS conversion_rate_pct
FROM source_summary
ORDER BY conversion_rate_pct DESC;


-- 2. Window function: rank leads by score within each company
SELECT
    name,
    company,
    score,
    status,
    RANK() OVER (PARTITION BY company ORDER BY score DESC) AS rank_in_company
FROM leads
ORDER BY company, rank_in_company;


-- 3. Window function: running total of leads created over time
-- Useful for a "cumulative leads growth" chart on the dashboard
SELECT
    created_at::date AS lead_date,
    COUNT(*) AS leads_that_day,
    SUM(COUNT(*)) OVER (ORDER BY created_at::date) AS cumulative_leads
FROM leads
GROUP BY created_at::date
ORDER BY lead_date;


-- 4. CTE + window function combined: top scoring lead per industry
WITH ranked_leads AS (
    SELECT
        l.name,
        l.company,
        c.industry,
        l.score,
        RANK() OVER (PARTITION BY c.industry ORDER BY l.score DESC) AS industry_rank
    FROM leads l
    JOIN companies c ON l.company = c.name
)
SELECT name, company, industry, score
FROM ranked_leads
WHERE industry_rank = 1
ORDER BY score DESC;
