-- Exercise 10
SELECT MAX(years_employed)
FROM employees;

SELECT role, AVG(years_employed)
FROM employees
GROUP BY role;

SELECT building, SUM(years_employed)
FROM employees
GROUP BY building;

-- Exercise 11

SELECT COUNT(role), role FROM employees
WHERE Role = "Artist"
GROUP BY Role

SELECT Count(name), Role FROM employees
GROUP BY Role

SELECT Sum(years_employed) FROM employees
WHERE Role = "Engineer"

--Try it 1
select count(unique shape) number_of_shapes, stddev(unique Weight) distinct_weight_stddev from   bricks;

--Try it 2
select shape, sum ( weight ) from   bricks group  by shape;

--Try it 3
select shape, sum ( weight ) from   bricks group  by shape; having sum(weight) < 4;


