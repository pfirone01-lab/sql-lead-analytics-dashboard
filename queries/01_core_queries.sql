-- =========================================================
-- SQL Lead Analytics Dashboard: Core Queries
-- File: queries/01_core_queries.sql
-- =========================================================

-- 1. SELECT + WHERE: all leads with a high score
SELECT name, company, score, status
FROM leads
WHERE score >= 70
ORDER BY score DESC;

-- 2. SELECT + WHERE: leads still open (not closed won/lost)
SELECT name, email, status, created_at
FROM leads
WHERE status NOT IN ('Closed Won', 'Closed Lost')
ORDER BY created_at DESC;

-- 3. WHERE with date filtering: leads created in the last 30 days
SELECT name, company, created_at
FROM leads
WHERE created_at >= now() - interval '30 days'
ORDER BY created_at DESC;

-- 4. GROUP BY: count of leads per status
SELECT status, COUNT(*) AS lead_count
FROM leads
GROUP BY status
ORDER BY lead_count DESC;

-- 5. GROUP BY + aggregate: average score per lead source
SELECT lead_source, ROUND(AVG(score), 1) AS avg_score, COUNT(*) AS total_leads
FROM leads
GROUP BY lead_source
ORDER BY avg_score DESC;

-- 6. GROUP BY + HAVING: sources generating more than 5 leads
SELECT lead_source, COUNT(*) AS total_leads
FROM leads
GROUP BY lead_source
HAVING COUNT(*) > 5
ORDER BY total_leads DESC;

-- 7. JOIN: leads with their company's industry and size
SELECT
    l.name,
    l.company,
    c.industry,
    c.employee_count,
    l.score,
    l.status
FROM leads l
JOIN companies c ON l.company = c.name
ORDER BY l.score DESC;

-- 8. JOIN + GROUP BY: average lead score by industry
SELECT
    c.industry,
    ROUND(AVG(l.score), 1) AS avg_lead_score,
    COUNT(l.id) AS total_leads
FROM leads l
JOIN companies c ON l.company = c.name
GROUP BY c.industry
ORDER BY avg_lead_score DESC;

-- 9. LEFT JOIN: leads whose company isn't in the companies table
-- (useful data-quality check: finds mismatched or missing company names)
SELECT l.name, l.company
FROM leads l
LEFT JOIN companies c ON l.company = c.name
WHERE c.id IS NULL;

-- 10. Multi-condition filter + JOIN: hot leads at large companies
SELECT
    l.name,
    l.company,
    c.employee_count,
    l.score,
    l.status
FROM leads l
JOIN companies c ON l.company = c.name
WHERE l.score >= 70
    AND c.employee_count >= 1000
ORDER BY l.score DESC;
