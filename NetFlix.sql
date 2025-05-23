--Count Movies vs TV Shows
SELECT 
    type, 
    COUNT(*) AS count
FROM netflix_titles
GROUP BY type;


--Top 5 Most Common Ratings
SELECT 
    rating, 
    COUNT(*) AS count
FROM netflix_titles
GROUP BY rating
ORDER BY count DESC
LIMIT 5;

--recent additions (last three years)
SELECT 
    title, 
    type, 
    date_added
FROM netflix_titles
WHERE date_added >= date('now', '-3 years')
ORDER BY date_added DESC;

--Movies over 2 hours long
SELECT 
    title, 
    duration
FROM netflix_titles
WHERE type = 'Movie' 
AND duration LIKE '%min'
AND CAST(SUBSTR(duration, 1, INSTR(duration, ' ')-1) AS INTEGER) > 120;

--TV shows with many seasons
SELECT 
    title, 
    duration
FROM netflix_titles
WHERE type = 'TV Show'
AND CAST(SUBSTR(duration, 1, INSTR(duration, ' ')-1) AS INTEGER) >= 5;

--Counted by country
SELECT 
    country, 
    COUNT(*) AS count
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY count DESC
LIMIT 25;

--directors with most Content
SELECT 
    director, 
    COUNT(*) AS count
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
ORDER BY count DESC
LIMIT 100;

--polular genres
SELECT 
    listed_in AS genre, 
    COUNT(*) AS count
FROM netflix_titles
GROUP BY genre
ORDER BY count DESC
LIMIT 20;


--content add by month for trend analysis
SELECT 
    strftime('%Y', date_added) AS year,
    strftime('%m', date_added) AS month,
    COUNT(*) AS content_added
FROM netflix_titles
WHERE date_added IS NOT NULL
GROUP BY year, month
ORDER BY year, month;


--yearly genre popularity
WITH genre_yearly AS (
    SELECT 
        release_year,
        TRIM(value) AS genre,
        COUNT(*) AS count
    FROM netflix_titles, 
    json_each('["' || REPLACE(listed_in, ', ', '","') || '"]')
    GROUP BY release_year, genre
),
ranked_genres AS (
    SELECT 
        release_year,
        genre,
        count,
        RANK() OVER (PARTITION BY release_year ORDER BY count DESC) AS rank
    FROM genre_yearly
)
SELECT 
    release_year,
    genre,
    count
FROM ranked_genres
WHERE rank <= 3
ORDER BY release_year DESC, rank;

--this is for seasonal content patterns
SELECT 
    strftime('%m', date_added) AS month,
    TRIM(value) AS genre,
    COUNT(*) AS count
FROM netflix_titles, 
json_each('["' || REPLACE(listed_in, ', ', '","') || '"]')
WHERE date_added IS NOT NULL
GROUP BY month, genre
ORDER BY month, count DESC;

--rating distribution by country
WITH top_countries AS (
    SELECT 
        TRIM(value) AS country
    FROM netflix_titles, 
    json_each('["' || REPLACE(country, ', ', '","') || '"]')
    GROUP BY country
    ORDER BY COUNT(*) DESC
    LIMIT 5
)
SELECT 
    t.country,
    n.rating,
    COUNT(*) AS count
FROM netflix_titles n, 
json_each('["' || REPLACE(n.country, ', ', '","') || '"]') c
JOIN top_countries t ON TRIM(c.value) = t.country
WHERE n.rating IS NOT NULL
GROUP BY t.country, n.rating
ORDER BY t.country, count DESC;


--movies by duration buckets
SELECT 
    CASE 
        WHEN duration LIKE '%min' AND CAST(substr(duration, 1, 3) AS INT) <= 90 THEN 'Short (<90min)'
        WHEN duration LIKE '%min' AND CAST(substr(duration, 1, 3) AS INT) <= 120 THEN 'Medium (90-120min)'
        WHEN duration LIKE '%min' THEN 'Long (>120min)'
    END AS duration_category,
    COUNT(*) AS movie_count
FROM netflix_titles
WHERE type = 'Movie'
GROUP BY duration_category;

--recent added by type
SELECT 
    type,
    COUNT(*) AS added_last_year
FROM netflix_titles
WHERE date_added >= date('now', '-1 year')
GROUP BY type;

--directors with multiple titles
SELECT 
    director,
    COUNT(*) AS title_count
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
HAVING COUNT(*) > 1
ORDER BY title_count DESC
LIMIT 10;

--country production analysis
SELECT 
    substr(country, 1, instr(country, ',')-1) AS primary_country,
    COUNT(*) AS productions
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY primary_country
ORDER BY productions DESC
LIMIT 10;


--TV shows Seasons analysis
SELECT 
    CASE 
        WHEN CAST(substr(duration, 1, 2) AS INT) = 1 THEN '1 Season'
        WHEN CAST(substr(duration, 1, 2) AS INT) <= 3 THEN '2-3 Seasons'
        ELSE '4+ Seasons'
    END AS season_group,
    COUNT(*) AS show_count
FROM netflix_titles
WHERE type = 'TV Show'
GROUP BY season_group;

--title word analysis
SELECT 
    substr(title, 1, instr(title, ' ')) AS first_word,
    COUNT(*) AS frequency
FROM netflix_titles
GROUP BY first_word
ORDER BY frequency DESC
LIMIT 10;

--yearly release trends
SELECT 
    release_year,
    COUNT(*) AS titles_released
FROM netflix_titles
GROUP BY release_year
ORDER BY release_year DESC
LIMIT 10;
