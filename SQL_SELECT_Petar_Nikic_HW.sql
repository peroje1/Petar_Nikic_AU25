-- 1) The marketing team needs a list of animation movies between 2017 and 2019 to promote family-friendly content in an upcoming season in stores. 
-- Show all animation movies released during this period with rate more than 1, sorted alphabetically

-- List all Animation films released between 2017 and 2019 with rate > 1; sort A→Z.
-- - "rate" as public.film.rental_rate (> 1).
-- - Filter films by release_year between 2017 and 2019.
-- - Keep only films in category 'Animation'.
-- - Sort by title ascending.
-- Solution A — CTE/Subquery
WITH anim AS (
  SELECT fc.film_id
  FROM public.film_category fc
  INNER JOIN public.category c ON c.category_id = fc.category_id
  WHERE c.name = 'Animation'
)
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM public.film f
INNER JOIN anim a ON a.film_id = f.film_id
WHERE f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title ASC;
-- Using CTE helps to get animation films step clear and can be reusable if needed.

-- Solution B — JOIN
SELECT f.film_id, f.title, f.release_year, f.rental_rate
FROM public.film f
INNER JOIN public.film_category fc ON fc.film_id = f.film_id
INNER JOIN public.category c       ON c.category_id = fc.category_id
WHERE c.name = 'Animation'
  AND f.release_year BETWEEN 2017 AND 2019
  AND f.rental_rate > 1
ORDER BY f.title ASC;
-- This is faster to do but not reusable, useful if needed to do only once.

-- 2) The finance department requires a report on store performance to assess profitability and plan resource allocation for stores after March 2017. 
-- Calculate the revenue earned by each rental store after March 2017 (since April) (include columns: address and address2 – as one column, revenue) 

-- Sum revenue per rental store since April 2017; show store address and address2 as one column.
-- - Revenue = SUM(public.payment.amount) where payment_date >= '2017-04-01'.
-- - Map payment -> rental -> inventory -> store -> address.
select * from rental;
WITH store_rev AS (
  select i.store_id, SUM(p.amount) AS revenue
  FROM public.payment  AS p
  INNER JOIN public.rental    AS r ON r.rental_id    = p.rental_id
  INNER JOIN public.inventory AS i ON i.inventory_id = r.inventory_id
  WHERE p.payment_date >= DATE '2017-04-01'
  GROUP BY i.store_id
)
select s.store_id, a.address, sr.revenue
FROM store_rev           AS sr
INNER JOIN public.store  AS s ON s.store_id   = sr.store_id
INNER JOIN public.address AS a ON a.address_id = s.address_id
ORDER BY sr.revenue ASC, s.store_id;
-- Easy to read, reusable if results are needed.

-- Solution B — JOIN-
select s.store_id, a.address, SUM(p.amount) AS revenue
FROM public.payment   AS p
INNER JOIN public.rental    AS r ON r.rental_id    = p.rental_id
INNER JOIN public.inventory AS i ON i.inventory_id = r.inventory_id
INNER JOIN public.store     AS s ON s.store_id     = i.store_id
INNER JOIN public.address   AS a ON a.address_id   = s.address_id
WHERE p.payment_date >= DATE '2017-04-01'
GROUP BY s.store_id, a.address
ORDER BY revenue DESC, s.store_id;
-- Good for quick checking, not reusable.

-- 3) The marketing department in our stores aims to identify the most successful actors since 2015 to boost customer interest in their films. 
--Show top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

--Show top 5 actors by count of films released after 2015, include first_name, last_name, number_of_movies; sort desc.
-- - Count distinct films per actor with film.release_year > 2015.
-- - actor -> film_actor -> film
-- - Order by number_of_movies DESC, then name for tie-breaks; LIMIT 5.

-- Solution A — CTE/Subquery
WITH actor_movies AS (
  select fa.actor_id, COUNT(DISTINCT fa.film_id) AS number_of_movies
  FROM public.film_actor fa
  INNER JOIN public.film f ON f.film_id = fa.film_id
  WHERE f.release_year > 2015
  GROUP BY fa.actor_id
)
SELECT a.first_name, a.last_name, am.number_of_movies
FROM actor_movies am
INNER JOIN public.actor a ON a.actor_id = am.actor_id
ORDER BY am.number_of_movies DESC, a.last_name, a.first_name
LIMIT 5;
--  Easy to reuse.

-- Solution B — JOIN
select a.first_name, a.last_name, COUNT(DISTINCT f.film_id) AS number_of_movies
FROM public.actor a
INNER JOIN public.film_actor fa ON fa.actor_id = a.actor_id
INNER JOIN public.film       f  ON f.film_id   = fa.film_id
WHERE f.release_year > 2015
GROUP BY a.first_name, a.last_name
ORDER BY number_of_movies DESC, a.last_name, a.first_name
LIMIT 5;
-- Short and easy, not reusable.

-- 4) The marketing team needs to track the production trends of Drama, Travel, and Documentary films to inform genre-specific marketing strategies.
-- Ырщц number of Drama, Travel, Documentary per year (include columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order. Dealing with NULL values is encouraged)

-- For each release_year, count films in Drama / Travel / Documentary, show 3 count columns, sort year DESC.
-- Join film → film_category → category, aggregate per year with COUNT(*) FILTER.
-- Solution A — CTE/Subquery
WITH film_genre AS (
  select f.release_year, c.name AS category_name
  FROM public.film AS f
  INNER JOIN public.film_category AS fc
    ON fc.film_id = f.film_id
  INNER JOIN public.category AS c
    ON c.category_id = fc.category_id
  WHERE c.name IN ('Drama', 'Travel', 'Documentary')
)
SELECT
  fg.release_year,
  COUNT(*) FILTER (WHERE fg.category_name = 'Drama')       AS drama_count,
  COUNT(*) FILTER (WHERE fg.category_name = 'Travel')      AS travel_count,
  COUNT(*) FILTER (WHERE fg.category_name = 'Documentary') AS documentary_count
FROM film_genre AS fg
GROUP BY fg.release_year
ORDER BY fg.release_year DESC;
--Readable and reusable

-- Directly join film → film_category → category; aggregate per year with COUNT(*) FILTER.
-- Solution B: Join
SELECT
  f.release_year,
  COUNT(*) FILTER (WHERE c.name = 'Drama')       AS drama_count,
  COUNT(*) FILTER (WHERE c.name = 'Travel')      AS travel_count,
  COUNT(*) FILTER (WHERE c.name = 'Documentary') AS documentary_count
FROM public.film AS f
INNER JOIN public.film_category AS fc
  ON fc.film_id = f.film_id
INNER JOIN public.category AS c
  ON c.category_id = fc.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;
--For quick checking.

-- The HR department aims to reward top-performing employees in 2017 with bonuses to recognize their contribution to stores revenue. 
-- Show which three employees generated the most revenue in 2017? 
--Assumptions: 
--staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
--if staff processed the payment then he works in the same store; 
--take into account only payment_date


--   Top 3 staff by total revenue in 2017.
--   Staff name, their store_id, and revenue:
--   1. Sum payment.amount per staff_id for 2017.
--   2. Join to staff to get name and store.
--   3. Join to store just to show store_id.
-- Solution A, CTE version
WITH rev2017 AS (
  select p.staff_id, SUM(p.amount) AS revenue
  FROM public.payment AS p
  WHERE p.payment_date >= DATE '2017-01-01'
    AND p.payment_date <  DATE '2018-01-01'
  GROUP BY p.staff_id
)
SELECT
  stf.staff_id,
  stf.first_name || ' ' || stf.last_name AS staff_name,
  st.store_id,
  r.revenue
FROM rev2017 r
INNER JOIN public.staff AS stf ON stf.staff_id = r.staff_id
INNER JOIN public.store AS st ON st.store_id  = stf.store_id
ORDER BY r.revenue DESC, stf.staff_id
LIMIT 3;
--Reusable and easier to read

-- Solution B — JOIN
SELECT
  stf.staff_id,
  stf.first_name || ' ' || stf.last_name AS staff_name,
  st.store_id,
  r.revenue
FROM (
  SELECT p.staff_id, SUM(p.amount) AS revenue
  FROM public.payment AS p
  WHERE p.payment_date >= DATE '2017-01-01'
    AND p.payment_date <  DATE '2018-01-01'
  GROUP BY p.staff_id
) AS r
INNER JOIN public.staff AS stf ON stf.staff_id = r.staff_id
INNER JOIN public.store AS st   ON st.store_id  = stf.store_id
ORDER BY r.revenue DESC, stf.staff_id
LIMIT 3;
-- Good for one use, just for checking

--2. The management team wants to identify the most popular movies and their target audience age groups to optimize marketing efforts. 
--Show which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience for these movies? To determine expected age please use 'Motion Picture Association film rating system'
-- Find the 5 most rented movies.
-- Show rental_count, rating, and target audience age group.
-- rental -> inventory -> film gives which film got rented.
-- Count rentals per film.
-- Take top 5 by that count.
-- Map film.rating (G / PG / PG-13 / R / NC-17) to age description
-- Solution A — CTE/Subquery
WITH film_rentals AS (
    SELECT i.film_id, COUNT(r.rental_id) AS rental_count
    FROM public.rental AS r
    INNER JOIN public.inventory AS i
        ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
),
top5 AS (
    SELECT fr.film_id, fr.rental_count
    FROM film_rentals AS fr
    ORDER BY fr.rental_count DESC, fr.film_id
    LIMIT 5
)
SELECT f.film_id, f.title, t5.rental_count, f.rating,
    CASE
        WHEN f.rating = 'G' THEN        'All ages admitted'
        WHEN f.rating = 'PG' THEN       'Parental guidance suggested'
        WHEN f.rating = 'PG-13' THEN    'May be inappropriate under 13'
        WHEN f.rating = 'R' THEN        'Under 17 needs parent/adult'
        WHEN f.rating = 'NC-17' THEN    'Adults only (no one 17 and under)'
        ELSE                            'Unrated / Not classified'
    END AS expected_audience_age_group
FROM top5 AS t5
INNER JOIN public.film AS f
    ON f.film_id = t5.film_id
ORDER BY t5.rental_count DESC, f.film_id;
-- Reusable 

-- Inner subquery finds the top 5 most-rented films.
-- Outer SELECT gives them title, rating, and audience age group.
-- Solution B — JOIN

SELECT f.film_id, f.title, x.rental_count, f.rating,
    CASE
        WHEN f.rating = 'G' THEN        'All ages admitted'
        WHEN f.rating = 'PG' THEN       'Parental guidance suggested'
        WHEN f.rating = 'PG-13' THEN    'May be inappropriate under 13'
        WHEN f.rating = 'R' THEN        'Under 17 needs parent/adult'
        WHEN f.rating = 'NC-17' THEN    'Adults only (no one 17 and under)'
        ELSE                            'Unrated / Not classified'
    END AS expected_audience_age_group
FROM (
    SELECT i.film_id, COUNT(r.rental_id) AS rental_count
    FROM public.rental AS r
    INNER JOIN public.inventory AS i
        ON i.inventory_id = r.inventory_id
    GROUP BY i.film_id
    ORDER BY COUNT(r.rental_id) DESC, i.film_id
    LIMIT 5
) AS x
INNER JOIN public.film AS f
    ON f.film_id = x.film_id
ORDER BY x.rental_count DESC, f.film_id;
--Shorter and not reusable

--Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
--The stores’ marketing team wants to analyze actors' inactivity periods to select those with notable career breaks for targeted promotional campaigns, highlighting their comebacks or consistent appearances to engage customers with nostalgic or reliable film stars
--The task can be interpreted in various ways, and here are a few options (provide solutions for each one):
--V1: gap between the latest release_year and current year per each actor;
--V2: gaps between sequential films per each actor;


-- V1: Time since last movie
-- For each actor, find the most recent release_year they appeared in.
-- Calculate how long they've been inactive:
--  inactivity_years = current_year - last_release_year
-- Sort by inactivity_years DESC to see who has been inactive the longest.
-- actor -> film_actor -> film
-- MAX(f.release_year) = last year they were in a film
-- CURRENT_DATE gives us the current year
-- This is the only solution i have for V1 and V2 for this task

SELECT  a.actor_id, a.first_name || ' ' || a.last_name AS actor_name, last_info.last_release_year,
        EXTRACT(YEAR FROM CURRENT_DATE)::int
          - last_info.last_release_year AS inactivity_years
FROM (
    SELECT fa.actor_id, MAX(f.release_year) AS last_release_year
    FROM public.film_actor AS fa
    INNER JOIN public.film AS f
        ON f.film_id = fa.film_id
    GROUP BY fa.actor_id
) AS last_info
INNER JOIN public.actor AS a
    ON a.actor_id = last_info.actor_id
ORDER BY inactivity_years DESC, a.actor_id;

-- V2: Career break potential 
--    first_year  = earliest film year they are in
--    last_year   = latest film year they are in
--    career_gap_years = last_year - first_year
-- Sort by career_gap_years DESC.
-- actor -> film_actor -> film
-- MIN() and MAX() per actor_id

SELECT
    a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name,
    span.first_year,
    span.last_year,
    (span.last_year - span.first_year) AS career_gap_years
FROM (
    SELECT fa.actor_id, MIN(f.release_year) AS first_year, MAX(f.release_year) AS last_year
    FROM public.film_actor AS fa
    INNER JOIN public.film AS f
        ON f.film_id = fa.film_id
    GROUP BY fa.actor_id
) AS span
INNER JOIN public.actor AS a
    ON a.actor_id = span.actor_id
ORDER BY career_gap_years DESC, a.actor_id;
