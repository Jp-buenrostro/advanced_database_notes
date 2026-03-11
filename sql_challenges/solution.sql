-- try it 1
select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median ( weight ) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- try it 2
select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- try it 3
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and current row
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order  by weight;

-- try it 4
with totals as (
  select b.*,
         sum ( weight ) over (
           partition by shape
         ) weight_per_shape,
         sum ( weight ) over (
           order by brick_id
         ) running_weight_by_id
  from   bricks b
)
select * from totals
where  weight_per_shape > 4
and    running_weight_by_id > 4
order  by brick_id;













-- Salaries, profe en este ejercicio, no supe porque 
-- solo salían 2 en la ultima categoria en lugar de 3
-- pero si lo cambiaba, luego salian 4 de todas las 
-- categarias pero funciona al 99% jaja
SELECT department_name, name, salary
FROM (
    SELECT 
        e.name,
        e.salary,
        d.department_name,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employee e
    JOIN department d
        ON e.department_id = d.department_id
) ranked
WHERE salary_rank <= 2
ORDER BY department_name ASC, salary DESC, name ASC;

