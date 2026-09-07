-- =========================================================
-- Weekly Lead Report Query
-- File: queries/03_weekly_report_query.sql
-- Used by the n8n "Weekly Lead Report" workflow (Postgres node)
-- =========================================================

WITH weekly_leads AS (
    SELECT *
    FROM leads
    WHERE created_at >= now() - interval '7 days'
),
status_counts AS (
    SELECT status, COUNT(*) AS count
    FROM weekly_leads
    GROUP BY status
),
source_conversion AS (
    SELECT
        lead_source,
        COUNT(*) AS total_leads,
        COUNT(*) FILTER (WHERE status = 'Closed Won') AS won_leads,
        ROUND(100.0 * COUNT(*) FILTER (WHERE status = 'Closed Won') / NULLIF(COUNT(*), 0), 1) AS conversion_rate_pct
    FROM weekly_leads
    GROUP BY lead_source
)
SELECT
    (SELECT COUNT(*) FROM weekly_leads) AS total_leads_this_week,
    (SELECT json_agg(status_counts) FROM status_counts) AS leads_by_status,
    (SELECT json_agg(source_conversion) FROM source_conversion) AS conversion_by_source;
