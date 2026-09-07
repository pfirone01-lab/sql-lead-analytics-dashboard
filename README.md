# sql-lead-analytics-dashboard

A cloud-hosted SQL database and analytics layer for sales lead data, built on
Supabase (PostgreSQL), with two n8n workflows handling automated data
ingestion and scheduled reporting.

This project was built as part of a self-directed GTM automation engineering
roadmap, focused on demonstrating practical SQL skills (from basic filtering
through CTEs and window functions) combined with real-world automation.

---

## Problem

Sales teams generate lead data across multiple channels (web forms,
referrals, cold outreach, trade shows), but that data is often scattered
across spreadsheets with no easy way to answer basic business questions:

- Which lead sources actually convert?
- Which companies have the strongest pipeline?
- Is the team on pace this week compared to last?

This project builds a lightweight but properly structured database to answer
those questions, plus the automation to keep it fed with fresh data and to
surface insights without anyone needing to log in and run a query manually.

---

## Architecture

```
Google Sheets (lead intake)
        │
        ▼
n8n: Lead Sheet to Supabase Sync
   ├── Google Sheets Trigger (on row added)
   ├── Code node (clean, validate, default missing fields)
   └── Supabase node (insert into leads table)
        │
        ▼
Supabase (PostgreSQL)
   ├── leads table
   └── companies table
        │
        ▼
n8n: Weekly Lead Report
   ├── Schedule Trigger (weekly)
   ├── Postgres node (aggregate query: totals, status, conversion by source)
   ├── Code node (format results as HTML)
   └── Gmail node (send summary email)
```

---

## Database Schema

Two tables, designed to support both simple lookups and multi-table analysis:

**`leads`**

| Column        | Type      | Notes                              |
|---------------|-----------|-------------------------------------|
| id            | SERIAL    | Primary key, auto-generated         |
| name          | TEXT      | Lead's full name                    |
| email         | TEXT      | Lead's email                        |
| company       | TEXT      | Matches `companies.name`            |
| lead_source   | TEXT      | Where the lead came from            |
| status        | TEXT      | Pipeline stage                      |
| created_at    | TIMESTAMP | Defaults to `now()`                 |
| score         | INTEGER   | 0–100, enforced by a CHECK constraint |

**`companies`**

| Column          | Type    | Notes                     |
|-----------------|---------|---------------------------|
| id              | SERIAL  | Primary key                |
| name            | TEXT    | Unique, joined against leads |
| industry        | TEXT    |                            |
| employee_count  | INTEGER |                            |
| annual_revenue  | NUMERIC |                            |

Indexes were added on `status`, `score`, and `created_at` on the `leads`
table, since these are the columns most likely to be filtered or sorted on
in a dashboard context.

Row Level Security (RLS) is enabled on both tables. Since this project has
no authentication layer, a permissive `USING (true)` policy is applied for
now, satisfying Supabase's security baseline while keeping the project
functional. In a production system with real users, this policy would be
scoped to restrict access per authenticated user (e.g. `auth.uid() = user_id`).

Full schema: [`schema.sql`](./schema.sql)

---

## Sample Data

`data/sample_leads.csv` and `data/sample_companies.csv` contain 90 fictional
leads and 41 fictional companies, generated with realistic, loosely
correlated patterns (e.g. leads marked "Closed Won" skew toward higher
scores), so aggregate queries return meaningful, non-random results.

---

## Queries

All queries live in the `queries/` folder, organized from foundational to
advanced:

**[`01_core_queries.sql`](./queries/01_core_queries.sql)**
Ten queries covering `SELECT` + `WHERE` (including date filtering),
`GROUP BY` aggregation, `HAVING`, `JOIN`, and `LEFT JOIN` (used here as a
data-quality check, surfacing any lead whose company name doesn't match the
`companies` table).

**[`02_advanced_queries.sql`](./queries/02_advanced_queries.sql)**
- A **CTE** calculating lead conversion rate by source, using `COUNT(*) FILTER (WHERE ...)`
- A **window function** (`RANK() OVER (PARTITION BY ...)`) ranking leads by score within each company
- A cumulative running total of leads over time
- A combined CTE + window function query identifying the top-scoring lead per industry

**[`03_weekly_report_query.sql`](./queries/03_weekly_report_query.sql)**
The aggregate query powering the automated email report: total leads,
a JSON breakdown by status, and a JSON breakdown of conversion rate by
source, all in a single result row for easy downstream formatting.

---

## Automation

### 1. Lead Sheet to Supabase Sync

Simulates a live intake pipeline: new rows added to a Google Sheet (standing
in for a web form response sheet) are picked up automatically, cleaned and
validated, and inserted into the `leads` table with no manual data entry.

The Code node handles:
- Trimming and lowercasing emails for consistency
- Clamping `score` to the valid 0–100 range so it never violates the
  database's `CHECK` constraint
- Defaulting missing `lead_source` / `status` values
- Throwing a clear error on rows missing required fields (`name`, `email`),
  so bad data fails loudly in the execution log rather than silently
  entering the database

### 2. Weekly Lead Report

Runs on a schedule, queries Supabase for the week's key metrics, formats
the results into an HTML summary (a status breakdown and a source
conversion table), and emails it via Gmail, no manual reporting required.

---

## Tech Stack

- **PostgreSQL** (via Supabase) for data storage and querying
- **n8n** for workflow automation (ingestion and reporting)
- **Google Sheets** as the lead intake interface
- **Gmail** for report delivery

---

## Notes on Design Decisions

- **Direct database connection over REST API for automation:** n8n connects
  to Supabase using its native Postgres/Supabase nodes rather than routing
  through the public REST API, since the automation runs server-side and
  doesn't need the API layer's constraints.
- **Session pooler over direct connection:** Supabase's direct connection
  defaults to IPv6, which isn't reachable from all networks. The session
  pooler was used instead, since it proxies over IPv4.
- **JSON aggregation in the reporting query:** rather than returning
  multiple result sets, the weekly report query packages its breakdowns as
  JSON within a single row, simplifying the downstream formatting logic in
  n8n.

---

## What This Project Demonstrates

- Relational schema design with appropriate constraints and indexing
- SQL fluency across filtering, aggregation, joins, CTEs, and window functions
- Building resilient automation with validation and sane defaults at each
  handoff point
- Debugging real infrastructure issues (SSL certificate chains, connection
  pooling, authentication) rather than just working from a pre-solved tutorial
- End-to-end thinking: data capture, storage, analysis, and reporting as one
  connected system, not isolated exercises
