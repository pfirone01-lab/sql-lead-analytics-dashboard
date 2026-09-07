-- =========================================================
-- SQL Lead Analytics Dashboard: Schema
-- Run this in the Supabase SQL Editor
-- =========================================================

-- Main leads table
CREATE TABLE leads (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    company TEXT,
    lead_source TEXT,
    status TEXT NOT NULL DEFAULT 'New',
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    score INTEGER CHECK (score >= 0 AND score <= 100)
);

-- Companies table, used later for the JOIN exercise
CREATE TABLE companies (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    industry TEXT,
    employee_count INTEGER,
    annual_revenue NUMERIC
);

-- Helpful index for filtering/sorting on status and score,
-- since these are the columns most dashboards will query against
CREATE INDEX idx_leads_status ON leads(status);
CREATE INDEX idx_leads_score ON leads(score);
CREATE INDEX idx_leads_created_at ON leads(created_at);
