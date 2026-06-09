-- CONTRATO KPI:
-- 1. Business question: ¿Qué tan rápido completa tareas cada equipo?
-- 2. Definición exacta: Tareas completadas / días activos del equipo.
--    "Día activo" = días desde la primera tarea creada hasta hoy.
--    Sin story points, usamos conteo de tareas como unidad de trabajo.
-- 3. Edge cases:
--    - Equipos sin tareas completadas → velocity = 0 (no NULL)
--    - Equipos recién creados con 1 día → velocidad artificialmente alta
--    - Tareas canceladas NO cuentan como completadas
-- 4. Unidad: tareas completadas / día
-- 5. ¿Qué haría esta métrica engañosa?
--    - No normalizar por miembros favorece a equipos grandes
--    - Un sprint corto intensivo puede inflar la velocidad histórica

WITH team_stats AS (
    SELECT
        t.id                                               AS team_id,
        t.name                                             AS team_name,
        COUNT(u.id)                                        AS member_count,
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END)
                                                           AS completed_tasks,
        GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.created_at)), 1)
                                                           AS active_days
    FROM   teams t
    LEFT   JOIN users u  ON u.team_id      = t.id
    LEFT   JOIN tasks ts ON ts.assigned_to = u.id
    GROUP  BY t.id, t.name
),
velocity_calc AS (
    SELECT
        team_id,
        team_name,
        member_count,
        completed_tasks,
        active_days,
        ROUND(completed_tasks / active_days, 2)            AS velocity_per_day,
        ROUND(completed_tasks / NULLIF(member_count,0) / active_days, 3)
                                                           AS velocity_per_member_day
    FROM team_stats
),
overall_avg AS (
    SELECT AVG(velocity_per_day) AS avg_velocity
    FROM   velocity_calc
)
SELECT
    v.team_name,
    v.member_count,
    v.completed_tasks,
    v.active_days,
    v.velocity_per_day,
    v.velocity_per_member_day,
    CASE
        WHEN v.velocity_per_day < o.avg_velocity THEN 'Below average'
        ELSE 'On track'
    END                                                    AS velocity_flag
FROM   velocity_calc v
CROSS  JOIN overall_avg o
ORDER  BY v.velocity_per_day DESC;

-- CONTRATO KPI:
-- 1. Business question: ¿Cumplimos nuestras fechas de entrega?
-- 2. Definición exacta:
--    On-time = completado antes del fin del día de vencimiento.
--    TRUNC(completed_at) <= TRUNC(due_date) → on-time.
--    Tareas sin due_date → EXCLUIDAS (no hay compromiso de fecha).
--    Solo tareas con status = 'completed'.
-- 3. Edge cases:
--    - Completado a las 23:59 del due_date → on-time
--    - Completado a las 00:01 del día siguiente → late
--    - Sin due_date → excluida
--    - Canceladas → excluidas
-- 4. Unidad: porcentaje (0–100%)
-- 5. ¿Qué haría esta métrica engañosa?
--    - Fechas asignadas con margen excesivo inflan el rate artificialmente
--    - Agregar todas las prioridades oculta incumplimientos críticos

WITH completed_with_due AS (
    SELECT
        priority,
        due_date,
        completed_at,
        CASE
            WHEN TRUNC(completed_at) <= TRUNC(due_date) THEN 1
            ELSE 0
        END                                                AS is_on_time,
        CASE
            WHEN TRUNC(completed_at) > TRUNC(due_date) THEN
                ROUND(
                    EXTRACT(DAY  FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 +
                    EXTRACT(HOUR FROM (completed_at - CAST(due_date AS TIMESTAMP))),
                    1
                )
            ELSE NULL
        END                                                AS hours_late
    FROM   tasks
    WHERE  status       = 'completed'
      AND  completed_at IS NOT NULL
      AND  due_date     IS NOT NULL
)
SELECT
    priority,
    COUNT(*)                                               AS total_completed,
    SUM(is_on_time)                                        AS on_time_count,
    ROUND(SUM(is_on_time) * 100.0 / COUNT(*), 1)           AS on_time_rate_pct,
    ROUND(AVG(hours_late), 1)                              AS avg_hours_late_when_late
FROM   completed_with_due
GROUP  BY priority
ORDER  BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high'     THEN 2
        WHEN 'medium'   THEN 3
        WHEN 'low'      THEN 4
    END;

    -- FLAW ORIGINAL: Contaba todas las tareas incluyendo completadas y canceladas.
-- Un equipo con 50 completadas y 0 abiertas parecía "muy ocupado" sin carga actual.

SELECT
    t.name                                                 AS team_name,
    COUNT(ts.id)                                           AS total_tasks,
    SUM(CASE
            WHEN ts.status IN ('open','in_progress','blocked') THEN 1
            ELSE 0
        END)                                               AS active_tasks,
    CASE
        WHEN COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END) = 0 THEN NULL
        ELSE ROUND(
            COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) * 100.0 /
            COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END),
            1
        )
    END                                                    AS completion_rate_pct,
    CASE
        WHEN SUM(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END) > 10
            THEN 'Overloaded'
        WHEN SUM(CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END) >= 5
            THEN 'Healthy'
        ELSE 'Underutilized'
    END                                                    AS health_score
FROM   teams t
LEFT   JOIN users u  ON u.team_id      = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY active_tasks DESC;

-- FLAW ORIGINAL: Promediaba todo junto sin distinguir prioridad.
-- Un bug critical en 2h y documentación en 40h tenían el mismo peso.

WITH resolution_times AS (
    SELECT
        priority,
        EXTRACT(DAY    FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR   FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60   AS resolution_hours
    FROM   tasks
    WHERE  status       = 'completed'
      AND  completed_at IS NOT NULL
),
sla_targets (priority, sla_hours) AS (
    SELECT 'critical', 24  FROM DUAL UNION ALL
    SELECT 'high',     72  FROM DUAL UNION ALL
    SELECT 'medium',   168 FROM DUAL UNION ALL
    SELECT 'low',      336 FROM DUAL
)
SELECT
    r.priority,
    COUNT(*)                                               AS completed_count,
    CASE WHEN COUNT(*) = 1 THEN 'Solo 1 muestra' ELSE NULL END
                                                           AS sample_warning,
    ROUND(AVG(r.resolution_hours), 1)                      AS avg_resolution_hours,
    ROUND(
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY r.resolution_hours),
        1
    )                                                      AS median_resolution_hours,
    ROUND(MIN(r.resolution_hours), 1)                      AS fastest_hours,
    ROUND(MAX(r.resolution_hours), 1)                      AS slowest_hours,
    s.sla_hours                                            AS sla_target_hours,
    CASE
        WHEN AVG(r.resolution_hours) <= s.sla_hours THEN 'Met'
        ELSE 'Missed'
    END                                                    AS sla_status
FROM   resolution_times r
JOIN   sla_targets s ON s.priority = r.priority
GROUP  BY r.priority, s.sla_hours
ORDER  BY
    CASE r.priority
        WHEN 'critical' THEN 1
        WHEN 'high'     THEN 2
        WHEN 'medium'   THEN 3
        WHEN 'low'      THEN 4
    END;

    -- FLAW ORIGINAL: Solo devolvía un COUNT. No decía cuánto tiempo llevan
-- vencidas, quién las tiene ni cuál es el impacto real.

-- Parte 1: reporte detallado
SELECT
    ts.title,
    u.full_name                                            AS assignee,
    t.name                                                 AS team,
    ts.priority,
    ts.due_date,
    TRUNC(SYSDATE) - TRUNC(ts.due_date)                    AS days_overdue,
    CASE
        WHEN ts.priority = 'critical'
            THEN 'CRITICAL'
        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2
            THEN 'HIGH'
        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5
            THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                    AS severity
FROM   tasks ts
JOIN   users u ON u.id  = ts.assigned_to
JOIN   teams t ON t.id  = u.team_id
WHERE  ts.due_date < TRUNC(SYSDATE)
  AND  ts.status NOT IN ('completed','cancelled')
  AND  ts.due_date IS NOT NULL

UNION ALL

-- Parte 2: fila de resumen por severidad
SELECT
    'SUBTOTAL — ' ||
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                    AS title,
    NULL, NULL, NULL, NULL,
    ROUND(AVG(TRUNC(SYSDATE) - TRUNC(ts.due_date)))        AS days_overdue,
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END                                                    AS severity
FROM   tasks ts
WHERE  ts.due_date < TRUNC(SYSDATE)
  AND  ts.status NOT IN ('completed','cancelled')
  AND  ts.due_date IS NOT NULL
GROUP  BY
    CASE
        WHEN ts.priority = 'critical' THEN 'CRITICAL'
        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2 THEN 'HIGH'
        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5 THEN 'MEDIUM'
        ELSE 'LOW'
    END, ts.priority

ORDER  BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        ELSE 4
    END,
    days_overdue DESC;

    -- PROBLEMA: COUNT(ts.id) cuenta todas las tareas asignadas sin importar
-- si están completadas, abiertas o canceladas. Tener 10 tareas asignadas
-- no es productividad. Tampoco distingue complejidad: un bug critical
-- completado vale igual que una tarea low. El score es inútil.

-- REESCRITURA: tareas completadas por día activo, ponderadas por prioridad

WITH priority_weights (priority, weight) AS (
    SELECT 'critical', 4 FROM DUAL UNION ALL
    SELECT 'high',     3 FROM DUAL UNION ALL
    SELECT 'medium',   2 FROM DUAL UNION ALL
    SELECT 'low',      1 FROM DUAL
),
user_activity AS (
    SELECT
        u.id                                               AS user_id,
        u.full_name,
        GREATEST(TRUNC(SYSDATE) - TRUNC(MIN(ts.completed_at)), 1)
                                                           AS active_days,
        SUM(pw.weight)                                     AS weighted_score,
        COUNT(ts.id)                                       AS completed_count
    FROM   users u
    LEFT   JOIN tasks ts ON ts.assigned_to = u.id
                         AND ts.status     = 'completed'
                         AND ts.completed_at IS NOT NULL
    LEFT   JOIN priority_weights pw ON pw.priority = ts.priority
    GROUP  BY u.id, u.full_name
)
SELECT
    full_name,
    completed_count,
    weighted_score,
    active_days,
    ROUND(weighted_score / active_days, 2)                 AS weighted_productivity_per_day
FROM   user_activity
ORDER  BY weighted_productivity_per_day DESC;

-- PROBLEMA: AVG(ts.id) promedia los IDs numéricos de las tareas.
-- El ID es una clave técnica sin significado de negocio: un ID alto
-- no implica mayor dificultad ni esfuerzo. Es como medir la eficiencia
-- de un equipo por el promedio de sus números de empleado. Absurdo.

-- REESCRITURA: ratio de tareas completadas sobre total (excluyendo canceladas)

SELECT
    t.name                                                 AS team_name,
    COUNT(ts.id)                                           AS total_tasks,
    SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END)
                                                           AS completed_tasks,
    SUM(CASE WHEN ts.status = 'cancelled' THEN 1 ELSE 0 END)
                                                           AS cancelled_tasks,
    CASE
        WHEN COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END) = 0 THEN NULL
        ELSE ROUND(
            SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) * 100.0 /
            COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END),
            1
        )
    END                                                    AS efficiency_pct
FROM   teams t
LEFT   JOIN users u  ON u.team_id      = t.id
LEFT   JOIN tasks ts ON ts.assigned_to = u.id
GROUP  BY t.id, t.name
ORDER  BY efficiency_pct DESC NULLS LAST;

-- PROBLEMA:
-- 1. priority es VARCHAR2 — multiplicar un string por 10 lanza ORA-01722.
-- 2. Sumar priority * 10 + DUE_DATE mezcla tipos incompatibles.
-- 3. En Oracle, sumar un número a un DATE agrega días, no produce un índice.
-- 4. No hay semántica: ¿qué significa "urgency = 30 + fecha"?

-- REESCRITURA: urgency_score = (peso de prioridad × 10) + días vencidos
-- Tareas vencidas tienen días positivos → score más alto de urgencia

WITH priority_weights (priority, weight) AS (
    SELECT 'critical', 4 FROM DUAL UNION ALL
    SELECT 'high',     3 FROM DUAL UNION ALL
    SELECT 'medium',   2 FROM DUAL UNION ALL
    SELECT 'low',      1 FROM DUAL
)
SELECT
    ts.title,
    ts.priority,
    ts.due_date,
    TRUNC(ts.due_date) - TRUNC(SYSDATE)                    AS days_until_due,
    pw.weight                                              AS priority_weight,
    pw.weight * 10 + (TRUNC(SYSDATE) - TRUNC(ts.due_date))
                                                           AS urgency_score
FROM   tasks ts
JOIN   priority_weights pw ON pw.priority = ts.priority
WHERE  ts.status NOT IN ('completed','cancelled')
  AND  ts.due_date IS NOT NULL
ORDER  BY urgency_score DESC;

-- Ejemplo:
-- Bug critical vencido 3 días = (4×10) + 3 = 43  → muy urgente
-- Tarea low con 2 días de margen = (1×10) - 2 = 8 → poco urgente

-- Un solo SELECT que devuelve una fila con todos los KPIs del sistema.
-- Patrón real de BI: CTEs apiladas, cada una calcula una dimensión.

WITH

base AS (
    SELECT
        ts.*,
        CASE WHEN ts.status IN ('open','in_progress','blocked') THEN 1 ELSE 0 END
                                                           AS is_active,
        CASE
            WHEN ts.due_date < TRUNC(SYSDATE)
             AND ts.status NOT IN ('completed','cancelled')
             AND ts.due_date IS NOT NULL
            THEN 1 ELSE 0
        END                                                AS is_overdue,
        CASE
            WHEN ts.due_date < TRUNC(SYSDATE)
             AND ts.status NOT IN ('completed','cancelled')
             AND ts.due_date IS NOT NULL
            THEN TRUNC(SYSDATE) - TRUNC(ts.due_date)
            ELSE NULL
        END                                                AS days_overdue,
        CASE
            WHEN ts.status = 'completed' AND ts.completed_at IS NOT NULL
            THEN EXTRACT(DAY    FROM (ts.completed_at - ts.created_at)) * 24 +
                 EXTRACT(HOUR   FROM (ts.completed_at - ts.created_at)) +
                 EXTRACT(MINUTE FROM (ts.completed_at - ts.created_at)) / 60
            ELSE NULL
        END                                                AS resolution_hours
    FROM tasks ts
),

general AS (
    SELECT
        COUNT(*)                                           AS total_tasks,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END)
                                                           AS completed_tasks,
        SUM(is_active)                                     AS active_tasks,
        SUM(is_overdue)                                    AS overdue_tasks,
        ROUND(
            SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) * 100.0 /
            NULLIF(COUNT(*), 0), 1
        )                                                  AS completion_rate_pct,
        ROUND(AVG(resolution_hours), 1)                    AS avg_resolution_hours,
        ROUND(AVG(days_overdue), 1)                        AS avg_days_overdue
    FROM base
),

busiest_priority AS (
    SELECT priority AS most_common_priority
    FROM   base
    WHERE  is_active = 1
    GROUP  BY priority
    ORDER  BY COUNT(*) DESC
    FETCH  FIRST 1 ROW ONLY
),

busiest_team AS (
    SELECT t.name AS busiest_team
    FROM   base b
    JOIN   users u ON u.id  = b.assigned_to
    JOIN   teams t ON t.id  = u.team_id
    WHERE  b.is_active = 1
    GROUP  BY t.id, t.name
    ORDER  BY COUNT(*) DESC
    FETCH  FIRST 1 ROW ONLY
)

SELECT
    g.total_tasks,
    g.completed_tasks,
    g.active_tasks,
    g.overdue_tasks,
    g.completion_rate_pct,
    g.avg_resolution_hours,
    g.avg_days_overdue,
    p.most_common_priority,
    t.busiest_team
FROM   general g
CROSS  JOIN busiest_priority p
CROSS  JOIN busiest_team     t;