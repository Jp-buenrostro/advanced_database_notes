-- Exercise 6
SELECT title, domestic_sales, international_sales
FROM Boxoffice
INNER JOIN movies
ON movies.id = boxoffice.movie_id;

SELECT Title, Domestic_sales, International_sales
FROM Boxoffice
JOIN Movies
ON Boxoffice.Movie_id = Movies.id
WHERE Boxoffice.International_sales > Boxoffice.Domestic_sales;

SELECT Title
FROM Movies
JOIN Boxoffice
ON Movies.id = Boxoffice.Movie_id
ORDER BY Rating
desc

--Exercise 7
SELECT DISTINCT Building_name
FROM Buildings
JOIN Employees
ON Buildings.Building_name = Employees.Building

SELECT DISTINCT Building_name, Capacity
FROM Buildings

SELECT DISTINCT Building_name, Role
FROM Buildings
LEFT JOIN Employees
ON Buildings.Building_name = Employees.Building

-- Inverview Question
SELECT pages.page_id
FROM pages
LEFT JOIN page_likes
ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL
ORDER BY pages.page_id ASC;