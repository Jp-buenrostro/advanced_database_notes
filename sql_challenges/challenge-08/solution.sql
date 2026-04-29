-- ============================================================
-- Exercise 1 — Find the slow query
-- ============================================================

-- Questions:
-- a) What scan type do you see? Why?
    --Full table scan: Oracle revisa toda la tabla porque no hay un índice útil y es más rápido así.

-- b) site_id has values 1–5. Is this high or low cardinality?
    --Low cardinality.
    --Hay muy pocos valores diferentes, entonces muchos registros son iguales.

-- c) Would adding an index on site_id help? Why or why not?
    --No mucho.
    --Como hay muchos registros con el mismo valor, el índice no ayuda a filtrar bien.

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
-- ============================================================

-- Step 1: CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

-- Questions:
-- a) Does Oracle use the index for this range?
    --Sí, cuando el rango es pequeño.

-- b) Change the range to the last 7 days. Does the plan change?
    --Sí, usa el índice porque son pocos datos.

-- c) Change to the last 700 days. What happens?
    --Ya no usa el índice y hace full scan.

-- d) Why does the range size affect whether Oracle uses the index?
    --Porque el índice solo sirve cuando reduce la cantidad de datos que se consultan.

-- ============================================================
-- Exercise 3 — Composite index
-- ============================================================

-- Questions:
-- a) Does the plan use the composite index?
    --Sí, cuando se usan las dos columnas.

-- b) Now try querying ONLY on visit_date (no patient_id). Does the composite index get used? Why not?
    --No.
    --Porque falta la primera columna del índice.

-- c) What's the rule about column order in composite indexes?
    --El orden importa.
    --Primero se usa la columna inicial del índice.

-- ============================================================
-- Exercise 4 — Function that breaks an index
-- ============================================================

-- Questions:
-- a) What scan type did the second query use?
    --Full table scan.

-- b) Why does wrapping a column in a function break index use?
    --Porque el índice está hecho sobre la columna original, no sobre la función.

-- c) How would you rewrite the second query to allow index use?
    --SELECT * FROM patient_visits WHERE patient_id = 5432;

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
-- ============================================================

-- Scenario A
-- a) Yes
-- b) Index on visit_date
-- c) No hay mucho problema porque los datos se cargan pocas veces.

-- Scenario B
-- a) Yes
-- b) Index on customer_id
-- c) Muchos inserts pueden hacerlo más lento.

-- Scenario C
-- a) Yes
-- b) Index on email
-- c) No hay problema, es un buen caso para índice.