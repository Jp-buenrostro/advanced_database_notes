-- ============================================================
-- Lesson 08: ETL + Data Warehouse
-- Exercise: Assignment History
-- ============================================================

-- Clean up si re-ejecutas
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets';            EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE agents';             EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- STEP 1 — Source Tables (OLTP)
-- ============================================================

CREATE TABLE agents (
    agent_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name  VARCHAR2(100) NOT NULL,
    email       VARCHAR2(200) NOT NULL,
    team        VARCHAR2(50)  NOT NULL
);

CREATE TABLE tickets (
    ticket_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR2(200)  NOT NULL,
    status       VARCHAR2(20)   DEFAULT 'open' NOT NULL,
    priority     VARCHAR2(10)   DEFAULT 'medium' NOT NULL,
    assigned_to  NUMBER         REFERENCES agents(agent_id),
    created_by   NUMBER         REFERENCES agents(agent_id),
    created_at   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    updated_at   TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at  TIMESTAMP,
    CONSTRAINT chk_ticket_status   CHECK (status   IN ('open','in_progress','blocked','resolved','cancelled')),
    CONSTRAINT chk_ticket_priority CHECK (priority IN ('low','medium','high','critical'))
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER    NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER    NOT NULL REFERENCES agents(agent_id),
    assigned_by   NUMBER             REFERENCES agents(agent_id),
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);

CREATE INDEX idx_ticket_assign_lookup
ON ticket_assignments (ticket_id, valid_from, valid_to);

-- ============================================================
-- STEP 2 — Sample Data
-- ============================================================

-- Agentes
INSERT INTO agents (agent_name, email, team) VALUES ('JP Buenrostro', 'jp@support.com',  'Platform');
INSERT INTO agents (agent_name, email, team) VALUES ('Fer Ramírez',   'fer@support.com', 'Backend');
INSERT INTO agents (agent_name, email, team) VALUES ('Lalo Torres',   'lalo@support.com','Frontend');
INSERT INTO agents (agent_name, email, team) VALUES ('Ana Soto',      'ana@support.com', 'Data');
COMMIT;

-- Tickets
INSERT INTO tickets (title, status, priority, assigned_to, created_by, created_at, updated_at, resolved_at)
VALUES ('App crashes on startup',       'resolved',    'critical', 1, 1,
        TIMESTAMP '2026-05-01 08:00:00', TIMESTAMP '2026-05-02 11:00:00', TIMESTAMP '2026-05-02 11:00:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_by, created_at, updated_at, resolved_at)
VALUES ('Reports page loads slowly',    'in_progress', 'high',     3, 2,
        TIMESTAMP '2026-05-02 09:00:00', TIMESTAMP '2026-05-02 09:00:00', NULL);

INSERT INTO tickets (title, status, priority, assigned_to, created_by, created_at, updated_at, resolved_at)
VALUES ('Broken image on profile page', 'resolved',    'low',      2, 1,
        TIMESTAMP '2026-05-03 10:00:00', TIMESTAMP '2026-05-04 14:00:00', TIMESTAMP '2026-05-04 14:00:00');

INSERT INTO tickets (title, status, priority, assigned_to, created_by, created_at, updated_at, resolved_at)
VALUES ('Payment fails on checkout',    'blocked',     'critical', 4, 3,
        TIMESTAMP '2026-05-04 07:30:00', TIMESTAMP '2026-05-04 07:30:00', NULL);

INSERT INTO tickets (title, status, priority, assigned_to, created_by, created_at, updated_at, resolved_at)
VALUES ('Search returns no results',    'open',        'medium',   1, 4,
        TIMESTAMP '2026-05-05 11:00:00', TIMESTAMP '2026-05-05 11:00:00', NULL);

COMMIT;

-- Historial inicial de asignaciones (antes del trigger)
-- Ticket 1: siempre JP
INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (1, 1, 1, TIMESTAMP '2026-05-01 08:00:00', NULL);

-- Ticket 2: empezó con Fer, reasignado a Lalo
INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (2, 2, 1, TIMESTAMP '2026-05-02 09:00:00', TIMESTAMP '2026-05-02 15:00:00');

INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (2, 3, 2, TIMESTAMP '2026-05-02 15:00:00', NULL);

-- Ticket 3: siempre Fer
INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (3, 2, 1, TIMESTAMP '2026-05-03 10:00:00', NULL);

-- Ticket 4: siempre Ana
INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (4, 4, 3, TIMESTAMP '2026-05-04 07:30:00', NULL);

-- Ticket 5: siempre JP
INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
VALUES (5, 1, 4, TIMESTAMP '2026-05-05 11:00:00', NULL);

COMMIT;

-- ============================================================
-- STEP 3 — Trigger
-- ============================================================

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, :NEW.created_by, :NEW.created_at, NULL);

    ELSIF UPDATING THEN
        -- Cerrar la asignación anterior
        UPDATE ticket_assignments
           SET valid_to = :NEW.updated_at
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to  IS NULL;

        -- Abrir la nueva asignación
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, :OLD.assigned_to, :NEW.updated_at, NULL);
    END IF;
END;
/

-- Test: reasignar ticket 4 de Ana (4) a Fer (2)
UPDATE tickets
   SET assigned_to = 2,
       updated_at  = TIMESTAMP '2026-05-05 09:00:00'
 WHERE ticket_id   = 4;

COMMIT;

-- Verificar historial completo del ticket 4
SELECT
    ta.assignment_id,
    ta.ticket_id,
    tk.title,
    a.agent_name                                                AS assigned_to,
    ta.valid_from,
    ta.valid_to,
    CASE WHEN ta.valid_to IS NULL THEN 'current' ELSE 'historical' END AS assignment_status
FROM   ticket_assignments ta
JOIN   tickets tk ON tk.ticket_id  = ta.ticket_id
JOIN   agents  a  ON a.agent_id    = ta.assigned_to
WHERE  ta.ticket_id = 4
ORDER  BY ta.valid_from;

-- ============================================================
-- STEP 4 — Data Warehouse Tables (Star Schema)
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent';         EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE dim_agent (
    agent_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id    NUMBER        NOT NULL,
    agent_name  VARCHAR2(100) NOT NULL,
    team        VARCHAR2(50)  NOT NULL,
    CONSTRAINT uq_dim_agent UNIQUE (agent_id)
);

CREATE TABLE fact_ticket_daily (
    date_key          NUMBER       NOT NULL,
    agent_key         NUMBER       NOT NULL REFERENCES dim_agent(agent_key),
    status            VARCHAR2(20) NOT NULL,
    priority          VARCHAR2(10) NOT NULL,
    tickets_created   NUMBER       DEFAULT 0,
    tickets_resolved  NUMBER       DEFAULT 0,
    CONSTRAINT uq_fact_ticket UNIQUE (date_key, agent_key, status, priority)
);

-- ============================================================
-- STEP 5 — Populate dim_agent
-- ============================================================

INSERT INTO dim_agent (agent_id, agent_name, team)
SELECT agent_id, agent_name, team FROM agents;

COMMIT;

-- Verificar
SELECT * FROM dim_agent;

-- ============================================================
-- STEP 7 — Verify
-- ============================================================

-- Reporte general: tickets creados y resueltos por agente por día
SELECT
    TO_DATE(TO_CHAR(f.date_key), 'YYYYMMDD')          AS fecha,
    a.agent_name,
    a.team,
    f.status,
    f.priority,
    SUM(f.tickets_created)                             AS tickets_created,
    SUM(f.tickets_resolved)                            AS tickets_resolved
FROM   fact_ticket_daily f
JOIN   dim_agent a ON a.agent_key = f.agent_key
GROUP  BY
    f.date_key,
    a.agent_name,
    a.team,
    f.status,
    f.priority
ORDER  BY
    fecha,
    a.agent_name;

-- Verificación del ticket 2 (reasignado de Fer → Lalo):
-- Fer debe aparecer en tickets_created
-- Lalo debe aparecer en tickets_resolved cuando se resuelva
SELECT
    TO_DATE(TO_CHAR(f.date_key), 'YYYYMMDD')          AS fecha,
    a.agent_name,
    f.tickets_created,
    f.tickets_resolved
FROM   fact_ticket_daily f
JOIN   dim_agent a ON a.agent_key = f.agent_key
WHERE  f.status = 'in_progress'
ORDER  BY fecha, a.agent_name;

-- Conteo general para verificar carga
SELECT 'agents: '            || COUNT(*) FROM agents
UNION ALL
SELECT 'tickets: '           || COUNT(*) FROM tickets
UNION ALL
SELECT 'ticket_assignments: '|| COUNT(*) FROM ticket_assignments
UNION ALL
SELECT 'dim_agent: '         || COUNT(*) FROM dim_agent
UNION ALL
SELECT 'fact_ticket_daily: ' || COUNT(*) FROM fact_ticket_daily;

!pip install oracledb pandas -q

import pandas as pd
import oracledb

# ── EXTRACT ─────────────────────────────────────────────────
tickets_df = pd.read_sql("""
    SELECT ticket_id, status, priority, created_at, resolved_at
    FROM   tickets
""", connection)

assignments_df = pd.read_sql("""
    SELECT ticket_id, assigned_to, valid_from, valid_to
    FROM   ticket_assignments
""", connection)

# Convertir timestamps
for col in ["created_at", "resolved_at"]:
    tickets_df[col] = pd.to_datetime(tickets_df[col])

assignments_df["valid_from"] = pd.to_datetime(assignments_df["valid_from"])
assignments_df["valid_to"]   = pd.to_datetime(assignments_df["valid_to"])

# ── TRANSFORM ────────────────────────────────────────────────
def find_agent(ticket_id, point_in_time):
    if pd.isna(point_in_time):
        return None
    mask = (
        (assignments_df["ticket_id"]  == ticket_id) &
        (assignments_df["valid_from"] <= point_in_time) &
        (assignments_df["valid_to"].isna() | (assignments_df["valid_to"] > point_in_time))
    )
    result = assignments_df[mask]
    return int(result.iloc[0]["assigned_to"]) if not result.empty else None

tickets_df["creator_agent"]  = tickets_df.apply(
    lambda r: find_agent(r["ticket_id"], r["created_at"]),  axis=1)

tickets_df["resolver_agent"] = tickets_df.apply(
    lambda r: find_agent(r["ticket_id"], r["resolved_at"]), axis=1)

# Filas de creación
created = tickets_df.copy()
created["date_key"]         = created["created_at"].dt.strftime("%Y%m%d").astype(int)
created["agent_key"]        = created["creator_agent"]
created["tickets_created"]  = 1
created["tickets_resolved"] = 0

# Filas de resolución
resolved = tickets_df[tickets_df["resolved_at"].notna()].copy()
resolved["date_key"]        = resolved["resolved_at"].dt.strftime("%Y%m%d").astype(int)
resolved["agent_key"]       = resolved["resolver_agent"]
resolved["tickets_created"] = 0
resolved["tickets_resolved"]= 1

cols = ["date_key", "agent_key", "status", "priority",
        "tickets_created", "tickets_resolved"]

fact_df = (
    pd.concat([created[cols], resolved[cols]], ignore_index=True)
    .dropna(subset=["agent_key"])
    .groupby(["date_key", "agent_key", "status", "priority"], as_index=False)
    .sum()
)

fact_df["agent_key"] = fact_df["agent_key"].astype(int)

# ── LOAD ────────────────────────────────────────────────────
cursor = connection.cursor()

insert_sql = """
    INSERT INTO fact_ticket_daily
        (date_key, agent_key, status, priority, tickets_created, tickets_resolved)
    VALUES (:1, :2, :3, :4, :5, :6)
"""

for _, row in fact_df.iterrows():
    cursor.execute(insert_sql, (
        int(row["date_key"]),
        int(row["agent_key"]),
        row["status"],
        row["priority"],
        int(row["tickets_created"]),
        int(row["tickets_resolved"])
    ))

connection.commit()
cursor.close()
connection.close()

print(f"ETL completado: {len(fact_df)} filas cargadas en fact_ticket_daily")