-- ============================================================
-- Lesson 07: KPI Dashboards
-- File: 01_enrich_schema.sql
-- Purpose: Enrich the tasks table with analytics columns
--
-- Run this in your FreeSQL worksheet after Lesson 06 schema.
-- ============================================================

-- Add columns needed for KPI analysis
ALTER TABLE tasks ADD (
    priority      VARCHAR2(10)  DEFAULT 'medium',
    due_date      DATE,
    completed_at  TIMESTAMP,
    tags          VARCHAR2(200)
);

-- Add check constraint for valid priorities
ALTER TABLE tasks ADD CONSTRAINT chk_task_priority
    CHECK (priority IN ('low', 'medium', 'high', 'critical'));

-- Add check constraint for valid statuses (expanded)
ALTER TABLE tasks DROP CONSTRAINT chk_task_status;
ALTER TABLE tasks ADD CONSTRAINT chk_task_status
    CHECK (status IN ('open', 'in_progress', 'blocked', 'completed', 'cancelled'));

COMMIT;

-- Verify
SELECT column_name, data_type, nullable
FROM   user_tab_columns
WHERE  table_name = 'TASKS'
ORDER  BY column_id;

 

 

 

-- ============================================================
-- Lesson 07: KPI Dashboards
-- File: 02_seed_dashboard_data.sql
-- Purpose: Generate 36 realistic tasks across 2 weeks
--
-- Run this in your FreeSQL worksheet.
-- ============================================================

-- First, clear existing tasks (keep teams and users from Lesson 06)
DELETE FROM tasks;
COMMIT;

-- ============================================================
-- 36 REALISTIC TASKS
-- ============================================================
-- Spread across 14 days with varied statuses, priorities, assignees
-- Includes cancelled tasks and overdue tasks for exercise coverage

INSERT INTO tasks (title, description, status, priority, assigned_to, created_at, due_date, completed_at, tags) VALUES
('Fix login bug', 'Users cannot log in with SSO after password reset', 'completed', 'high', 1, TIMESTAMP '2026-05-01 09:00:00', DATE '2026-05-03', TIMESTAMP '2026-05-02 14:30:00', 'bug,sso,auth'),
('Design new dashboard', 'Create mockups for analytics page with KPI cards', 'in_progress', 'medium', 3, TIMESTAMP '2026-05-01 10:00:00', DATE '2026-05-10', NULL, 'design,ui,dashboard'),
('Update dependencies', 'Upgrade numpy and pandas to latest stable', 'completed', 'low', 2, TIMESTAMP '2026-05-01 11:00:00', DATE '2026-05-05', TIMESTAMP '2026-05-04 16:00:00', 'maintenance,deps'),
('API rate limiting', 'Implement rate limiting on public endpoints', 'open', 'high', 1, TIMESTAMP '2026-05-02 09:00:00', DATE '2026-05-08', NULL, 'api,security,backend'),
('Write unit tests for auth', 'Cover login, logout, token refresh flows', 'in_progress', 'medium', 2, TIMESTAMP '2026-05-02 10:00:00', DATE '2026-05-09', NULL, 'testing,auth,qa'),
('Database backup script', 'Automate daily backup to S3 with retention', 'completed', 'medium', 1, TIMESTAMP '2026-05-02 11:00:00', DATE '2026-05-04', TIMESTAMP '2026-05-03 10:00:00', 'devops,backup,s3'),
('Mobile responsive nav', 'Menu does not collapse on screens < 768px', 'blocked', 'high', 3, TIMESTAMP '2026-05-03 09:00:00', DATE '2026-05-07', NULL, 'bug,mobile,ui,css'),
('User profile page', 'Allow users to edit avatar and bio', 'open', 'low', 3, TIMESTAMP '2026-05-03 10:00:00', DATE '2026-05-15', NULL, 'feature,profile,frontend'),
('Optimize slow query', 'Report generation takes 45 seconds', 'completed', 'critical', 1, TIMESTAMP '2026-05-03 11:00:00', DATE '2026-05-04', TIMESTAMP '2026-05-03 18:00:00', 'performance,sql,optimization'),
('Set up CI/CD pipeline', 'GitHub Actions for test + deploy', 'in_progress', 'medium', 2, TIMESTAMP '2026-05-04 09:00:00', DATE '2026-05-12', NULL, 'devops,cicd,github'),
('Error tracking integration', 'Connect Sentry for production error alerts', 'open', 'medium', 1, TIMESTAMP '2026-05-04 10:00:00', DATE '2026-05-11', NULL, 'monitoring,sentry,ops'),
('Dark mode toggle', 'Add theme switcher with CSS variables', 'completed', 'low', 3, TIMESTAMP '2026-05-04 11:00:00', DATE '2026-05-06', TIMESTAMP '2026-05-05 15:00:00', 'feature,ui,theming'),
('Password strength meter', 'Visual indicator for password complexity', 'open', 'low', 2, TIMESTAMP '2026-05-05 09:00:00', DATE '2026-05-14', NULL, 'feature,auth,frontend'),
('Export to CSV', 'Allow users to download report as CSV', 'in_progress', 'medium', 3, TIMESTAMP '2026-05-05 10:00:00', DATE '2026-05-13', NULL, 'feature,export,reporting'),
('Redis caching layer', 'Cache frequent queries to reduce DB load', 'open', 'high', 1, TIMESTAMP '2026-05-05 11:00:00', DATE '2026-05-10', NULL, 'backend,redis,performance'),
('Email notification service', 'Send task assignment emails via SendGrid', 'completed', 'medium', 2, TIMESTAMP '2026-05-06 09:00:00', DATE '2026-05-08', TIMESTAMP '2026-05-07 12:00:00', 'feature,email,notifications'),
('Audit log table', 'Track all changes to tasks with timestamps', 'in_progress', 'medium', 1, TIMESTAMP '2026-05-06 10:00:00', DATE '2026-05-15', NULL, 'feature,audit,logging'),
('Two-factor auth', 'Add TOTP support for admin accounts', 'open', 'critical', 2, TIMESTAMP '2026-05-06 11:00:00', DATE '2026-05-09', NULL, 'feature,security,auth'),
('Load testing script', 'Simulate 1000 concurrent users with k6', 'completed', 'medium', 1, TIMESTAMP '2026-05-07 09:00:00', DATE '2026-05-08', TIMESTAMP '2026-05-07 17:00:00', 'testing,performance,k6'),
('Documentation site', 'Set up MkDocs for API documentation', 'open', 'low', 3, TIMESTAMP '2026-05-07 10:00:00', DATE '2026-05-20', NULL, 'docs,mkdocs,technical-writing'),
('Fix memory leak', 'Node process grows to 2GB after 24 hours', 'blocked', 'critical', 1, TIMESTAMP '2026-05-07 11:00:00', DATE '2026-05-09', NULL, 'bug,performance,memory'),
('Webhook integrations', 'Allow third-party services to subscribe to events', 'open', 'medium', 2, TIMESTAMP '2026-05-08 09:00:00', DATE '2026-05-16', NULL, 'feature,api,integrations'),
('Search autocomplete', 'Typeahead search with debounced API calls', 'in_progress', 'low', 3, TIMESTAMP '2026-05-08 10:00:00', DATE '2026-05-14', NULL, 'feature,search,frontend'),
('GDPR data export', 'Allow users to download all their data', 'open', 'high', 1, TIMESTAMP '2026-05-08 11:00:00', DATE '2026-05-12', NULL, 'compliance,gdpr,privacy'),
('Slack bot integration', 'Post task updates to team Slack channel', 'completed', 'low', 2, TIMESTAMP '2026-05-09 09:00:00', DATE '2026-05-11', TIMESTAMP '2026-05-10 11:00:00', 'feature,slack,bot'),
('Database migration tool', 'Evaluate Flyway vs Liquibase for schema changes', 'open', 'medium', 1, TIMESTAMP '2026-05-09 10:00:00', DATE '2026-05-17', NULL, 'research,db,migrations'),
('Image upload resizing', 'Resize avatars to 256x256 on upload', 'in_progress', 'low', 3, TIMESTAMP '2026-05-09 11:00:00', DATE '2026-05-13', NULL, 'feature,images,processing'),
('Session timeout bug', 'Users stay logged in after 30 days', 'open', 'high', 2, TIMESTAMP '2026-05-10 09:00:00', DATE '2026-05-11', NULL, 'bug,auth,sessions'),
('Analytics event tracking', 'Track page views and clicks with Mixpanel', 'completed', 'medium', 3, TIMESTAMP '2026-05-10 10:00:00', DATE '2026-05-12', TIMESTAMP '2026-05-11 09:00:00', 'feature,analytics,tracking'),
('Kubernetes deployment', 'Migrate from EC2 to EKS with Helm charts', 'open', 'critical', 1, TIMESTAMP '2026-05-10 11:00:00', DATE '2026-05-15', NULL, 'devops,k8s,infrastructure'),

-- ============================================================
-- ADDITIONAL TASKS FOR EXERCISE COVERAGE
-- ============================================================
-- Cancelled tasks (for completion_rate calculation in EXERCISE 3)
('Legacy API deprecation', 'Sunset the v1 API endpoints', 'cancelled', 'low', 2, TIMESTAMP '2026-05-01 08:00:00', DATE '2026-05-20', NULL, 'api,deprecation,legacy'),
('Manual data migration', 'One-time script to migrate old records', 'cancelled', 'medium', 1, TIMESTAMP '2026-05-02 08:00:00', DATE '2026-05-10', NULL, 'migration,data,one-time'),
('Third-party auth provider', 'Integrate with Okta for enterprise SSO', 'cancelled', 'high', 3, TIMESTAMP '2026-05-03 08:00:00', DATE '2026-05-18', NULL, 'auth,sso,enterprise'),

-- Overdue tasks (for EXERCISE 5 — overdue report with severity)
('Security audit remediation', 'Fix findings from Q1 penetration test', 'open', 'critical', 1, TIMESTAMP '2026-05-01 09:00:00', DATE '2026-05-05', NULL, 'security,audit,compliance'),
('Customer data retention policy', 'Implement automatic data purging', 'in_progress', 'high', 2, TIMESTAMP '2026-05-02 09:00:00', DATE '2026-05-06', NULL, 'compliance,gdpr,data'),
('Payment gateway integration', 'Add Stripe support for subscriptions', 'blocked', 'medium', 3, TIMESTAMP '2026-05-03 09:00:00', DATE '2026-05-07', NULL, 'payments,stripe,billing'),
('Performance regression fix', 'Query latency spike after last deploy', 'open', 'critical', 1, TIMESTAMP '2026-05-04 09:00:00', DATE '2026-05-08', NULL, 'performance,regression,sql');

COMMIT;

-- Verify counts
SELECT status, COUNT(*) AS task_count
FROM   tasks
GROUP  BY status
ORDER  BY task_count DESC;

-- ============================================================
-- Lesson 07: KPI Dashboards — Class Exercises
-- File: 06_exercises.sql
-- Purpose: Practice defining KPIs, writing queries, and handling edge cases
--
-- Instructions: Open this file in your FreeSQL worksheet.
-- For each exercise, write your query below the prompt, then run it.
-- There is no "autograder" — correctness is determined by whether
-- the query matches the KPI contract YOU defined.
-- ============================================================

-- ============================================================
-- PART A: The KPI Contract (Conceptual)
-- ============================================================
-- Before writing any query, answer these for EACH exercise:
--
-- 1. What is the business question?
-- 2. What is the exact definition? (Include every filter, every join)
-- 3. What are the edge cases? (NULLs, cancelled tasks, unassigned tasks, etc.)
-- 4. What is the unit? (Count, percentage, hours, dollars?)
-- 5. What would make this metric misleading?
--
-- Write your answers as SQL comments above each query.
-- A query without a contract is just a number. A query WITH a contract
-- is a metric the business can trust.
--
-- Tom Kyte's rule: "If you cannot explain the metric to a non-technical
-- person in one sentence, your query is wrong."


-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================
--
-- Business context: Management wants to compare how fast each team
-- completes work. They ask for "team velocity."
--
-- YOUR TASK:
-- 1. Define the KPI contract in comments. What EXACTLY does "velocity" mean?
--    Is it tasks completed per day? Per person? Per story point?
--    (We do not have story points — how does that change the definition?)
-- 2. Write a query that shows each team's velocity with your chosen definition.
-- 3. Add a column that flags teams with velocity below the overall average.
--
-- Edge case to consider: The Product team has fewer people than Engineering.
-- Should velocity be normalized per team member? What are the pros and cons?

-- [Write your contract here as a SQL comment]
-- [Write your query below]


-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================
--
-- Business context: The product manager wants to know: "Do we meet
-- our deadlines?" They ask for an "on-time delivery rate."
--
-- YOUR TASK:
-- 1. Define the KPI contract in comments. What does "on-time" mean?
--    Is it completed before due_date? Before end-of-day on due_date?
--    What about tasks with no due_date?
-- 2. Write a query that calculates the on-time delivery rate.
-- 3. Break it down by priority (critical, high, medium, low).
-- 4. Add a column showing the average "lateness" in hours for overdue tasks.
--
-- Edge case to consider: A task completed at 23:59 on the due date
-- vs. 00:01 the next day. Should both be "late"? Neither? Only one?
-- How does your choice affect the metric?

-- [Write your contract here as a SQL comment]
-- [Write your query below]


-- ============================================================
-- PART B: Improve the Class KPIs
-- ============================================================
-- The KPIs from 03_kpi_queries.sql work, but they can be better.
-- For each exercise, identify the flaw and rewrite the query.


-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team" (KPI 2 from class)
-- ============================================================
--
-- FLAW: The original query counts ALL tasks assigned to users in a team,
-- including completed and cancelled tasks. A team with 50 completed tasks
-- and 0 open tasks looks "busy" but has no current workload.
--
-- YOUR TASK:
-- 1. Rewrite the query to show THREE columns per team:
--    - total_tasks (all time)
--    - active_tasks (open + in_progress + blocked)
--    - completion_rate (completed / total, excluding cancelled)
-- 2. Add a "health score" column: a CASE expression that labels each team
--    as 'Overloaded' (active_tasks > 10), 'Healthy' (5-10), or 'Underutilized' (< 5).
-- 3. Order by active_tasks DESC so the busiest teams appear first.

-- Original (from 03_kpi_queries.sql — KPI 2):
-- SELECT t.name AS team_name,
--        COUNT(ts.id) AS task_count
-- FROM   teams t
-- LEFT   JOIN users u ON u.team_id = t.id
-- LEFT   JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP  BY t.id, t.name
-- ORDER  BY task_count DESC;
--
-- Technique: LEFT JOIN chain. We start from teams (the dimension table)
-- and LEFT JOIN through users to tasks. This ensures teams with zero
-- tasks still appear (count = 0), which an INNER JOIN would hide.

-- [Write your improved query below]


-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time" (KPI 5 from class)
-- ============================================================
--
-- FLAW: The original query averages ALL completed tasks together.
-- A critical bug fixed in 2 hours and a documentation update fixed in
-- 40 hours are averaged together. The metric hides priority differences.
--
-- YOUR TASK:
-- 1. Rewrite the query to show average resolution time BY PRIORITY.
-- 2. Add a column showing the MEDIAN resolution time per priority.
--    (Hint: Oracle 23ai supports PERCENTILE_CONT. Research it.)
-- 3. Add a column showing the FASTEST and SLOWEST resolution time per priority.
--    (Hint: MIN and MAX, but only if you want simple extremes.)
-- 4. Add a "target met" column: For each priority, define a target SLA
--    (critical = 24h, high = 72h, medium = 168h, low = 336h) and flag
--    whether the average meets the target.
--
-- Edge case: What if a priority has only 1 completed task? Is the average meaningful?
-- How should you communicate that in the result?

-- Original (from 03_kpi_queries.sql — KPI 5):
-- SELECT ROUND(AVG(
--            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
--            EXTRACT(HOUR FROM (completed_at - created_at)) +
--            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
--        ), 1) AS avg_resolution_hours,
--        COUNT(*) AS completed_task_count
-- FROM   tasks
-- WHERE  status = 'completed'
--   AND  completed_at IS NOT NULL;
--
-- Technique: EXTRACT from INTERVAL. Oracle timestamp subtraction
-- returns a DAY TO SECOND interval. We break it into components.
-- We also report the count — an average of 2 tasks is not meaningful.

-- [Write your improved query below]


-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks" (KPI 7 from class)
-- ============================================================
--
-- FLAW: The original query is a simple COUNT. It tells you HOW MANY
-- tasks are overdue, but not HOW OVERDUE, WHO owns them, or WHAT
-- the business impact is. A critical task 1 day late is different
-- from a low-priority task 30 days late.
--
-- YOUR TASK:
-- 1. Rewrite the query as a detailed report (not just a count).
--    Include: task title, assignee, team, priority, due_date,
--    days_overdue (calculated), and a "severity" column.
-- 2. Define severity as:
--    - 'CRITICAL': priority = 'critical' AND days_overdue > 0
--    - 'HIGH': priority = 'high' AND days_overdue > 2
--    - 'MEDIUM': priority = 'medium' AND days_overdue > 5
--    - 'LOW': everything else overdue
-- 3. Order by severity (most urgent first), then by days_overdue DESC.
-- 4. Add a summary row at the bottom (using ROLLUP or UNION) showing
--    total overdue count and average days overdue per severity level.

-- Original (from 03_kpi_queries.sql — KPI 7):
-- SELECT COUNT(*) AS overdue_count
-- FROM   tasks
-- WHERE  due_date < TRUNC(SYSDATE)
--   AND  status NOT IN ('completed', 'cancelled')
--   AND  due_date IS NOT NULL;
--
-- Technique: TRUNC(SYSDATE) gives today at midnight. We compare dates
-- without time-of-day to avoid false positives (a task due "today"
-- at 23:59 should not be flagged at 09:00).
-- NULL check is defensive — always filter out unknown due dates.

-- [Write your improved query below]


-- ============================================================
-- PART C: The "Bad KPI" Challenge
-- ============================================================
-- Below are three queries that return numbers. Each is a BAD KPI.
-- Your task: Identify WHY it is bad, then rewrite it correctly.


-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
--
-- BAD QUERY:
-- SELECT u.full_name, COUNT(ts.id) AS productivity_score
-- FROM users u
-- JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP BY u.id, u.full_name
-- ORDER BY productivity_score DESC;
--
-- PROBLEM: ____________________________________________________
-- (What is wrong with this metric? Hint: Does it distinguish between
--  creating 10 tasks and completing 10 tasks? Does it handle unassigned
--  tasks? Does it account for task complexity or priority?)
--
-- REWRITE: Write a query that measures something actually meaningful.
-- Suggestion: "Completed tasks per day, weighted by priority."

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
--
-- BAD QUERY:
-- SELECT t.name, AVG(ts.id) AS avg_task_id
-- FROM teams t
-- JOIN users u ON u.team_id = t.id
-- JOIN tasks ts ON ts.assigned_to = u.id
-- GROUP BY t.id, t.name;
--
-- PROBLEM: ____________________________________________________
-- (What is mathematically wrong here? What does "average task ID" mean?)
--
-- REWRITE: Write a query that measures actual team efficiency.
-- Suggestion: "Ratio of completed tasks to total tasks, per team."

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
--
-- BAD QUERY:
-- SELECT title, priority * 10 + DUE_DATE AS urgency_index
-- FROM tasks
-- ORDER BY urgency_index DESC;
--
-- PROBLEM: ____________________________________________________
-- (What is wrong with adding a string and a number? What is wrong with
--  multiplying a VARCHAR by 10? What should the query actually do?)
--
-- REWRITE: Write a query that creates a real urgency score.
-- Suggestion: Assign numeric weights to priority (critical=4, high=3,
-- medium=2, low=1) and add days_until_due (negative if overdue).
-- A higher score = more urgent.

-- [Write your analysis as a SQL comment]
-- [Write your rewritten query below]


-- ============================================================
-- PART D: Bonus — Build a Summary Dashboard Query
-- ============================================================
--
-- Write a SINGLE query that returns one row with ALL of the following:
-- 1. total_tasks
-- 2. completed_tasks
-- 3. active_tasks (open + in_progress + blocked)
-- 4. overdue_tasks
-- 5. completion_rate_pct
-- 6. avg_resolution_hours
-- 7. avg_days_overdue (for overdue tasks only)
-- 8. most_common_priority (the priority with the most active tasks)
-- 9. busiest_team (team with the most active tasks)
--
-- Use CTEs to build this step by step. Start with a "base" CTE that
-- enriches tasks with derived columns, then build metric CTEs from it.
--
-- This is the pattern real BI tools use: one query, many metrics.

-- [Write your mega-query below]


-- ============================================================
-- ANSWER KEY (For Instructors — Do Not Share With Students)
-- ============================================================
-- The answer key is in a separate file: 06_exercises_answers.sql
-- It contains one possible correct query per exercise, with commentary
-- on why the choices were made. There is no "single right answer" —
-- the goal is thoughtful KPI definition, not query memorization.

 

 

 

04_dashboard.ipynb
Este tema está cerrado para comentarios.