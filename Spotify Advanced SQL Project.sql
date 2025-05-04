-- Advanced SQL project -- Spotify Datasets

-- create table

CREATE TABLE spotify (
    artist VARCHAR(255),
    track VARCHAR(255),
    album VARCHAR(255),
    album_type VARCHAR(50),
    danceability FLOAT,
    energy FLOAT,
    loudness FLOAT,
    speechiness FLOAT,
    acousticness FLOAT,
    instrumentalness FLOAT,
    liveness FLOAT,
    valence FLOAT,
    tempo FLOAT,
    duration_min FLOAT,
    title VARCHAR(255),
    channel VARCHAR(255),
    views FLOAT,
    likes BIGINT,
    comments BIGINT,
    licensed BOOLEAN,
    official_video BOOLEAN,
    stream BIGINT,
    energy_liveness FLOAT,
    most_played_on VARCHAR(50)
);

-----------------------------------
-- EXPLORATORY DATA ANLAYSIS -- 
------------------------------------
--  Show the complete data from the spotify table. --
select * from spotify;
-- How many total records (rows) are there in the spotify table? --
select count(*) from spotify;
-- How many unique artists are present in the dataset? --
select count(distinct artist) from spotify;
-- How many unique albums are there in the dataset? --
select count(distinct album ) from spotify;
-- What are the different types of albums in the dataset? --
select distinct album_type  from spotify;
-- What is the maximum duration (in minutes) of any track in the dataset? --
select max(duration_min) from spotify;
-- What is the minimum duration (in minutes) of any track in the dataset? --
select min(duration_min) from spotify;
--Which tracks have a duration of 0 minutes? --
select *from spotify where duration_min=0;
-- What are the different album types available in the Spotify dataset? --
select distinct album_type  from spotify;
-- Remove all tracks that have a duration of 0 minutes from the dataset. --
delete from spotify where duration_min=0;
-- What are the different channels (possibly upload sources) present in the dataset? --
select distinct channel  from spotify;
-- On which platforms or regions are tracks most frequently played? --
select distinct most_played_on  from spotify;
-- What is the highest number of streams any track has received?--
select max(stream) from spotify;
-----------------------------------
-- Data Anaysis -- Easy category
------------------------------------
--1.Retrieve the names of all tracks that have more than 1 billion streams.--

select distinct track from spotify where stream > 1000000000;

--2.List all albums along with their respective artists.--

select  distinct album , artist from spotify;
--3.Get the total number of comments for tracks where licensed = TRUE.--
select sum(comments) as total_comments
from spotify
where licensed = TRUE;

--4.Find all tracks that belong to the album type single.--

select  distinct track
from spotify
where album_type = 'single';

--5.Count the total number of tracks by each artist.--

select  artist, count(distinct track) as total_tracks
from spotify
group by artist;

-----------------------------------
-- Data Anaysis -- Medium  category
------------------------------------

--Calculate the average danceability of tracks in each album.--
select album,avg (danceability)as average_danceability 
from spotify 
group by album 
order by average_danceability desc;
--Find the top 5 tracks with the highest energy values.--
select track,energy  
from spotify 
order by energy  desc limit 5 ;

--List all tracks along with their views and likes where official_video = TRUE.--
select track,views,likes from spotify where official_video = TRUE;
--For each album, calculate the total views of all associated tracks.--
select album ,sum(views)as total_views 
from spotify 
group by  album order by total_views desc;
--Retrieve the track names that have been streamed on Spotify more than YouTube.--

SELECT track, stream, views
FROM spotify
WHERE most_played_on = 'Spotify' AND stream > views;

-----------------------------------
-- Data Anaysis -- Advanced category
------------------------------------
-- 1.Find the top 3 most-viewed tracks for each artist using window functions.--


SELECT DISTINCT track, artist
FROM (
    SELECT track, artist, views, 
           ROW_NUMBER() OVER (PARTITION BY artist ORDER BY views DESC) AS most_viewed_tracks
    FROM spotify
) AS rank
WHERE most_viewed_tracks <= 3;


-- 2.Write a query to find tracks where the liveness score is above the average.--

SELECT track,liveness
FROM (
SELECT track , liveness, AVG(liveness) OVER() AS avg_liveness_score FROM spotify
) AS average
WHERE liveness > avg_liveness_score;

-- 3.Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.--
WITH energy_bounds AS (
    SELECT 
        album,
        MAX(energy) OVER (PARTITION BY album) AS max_energy,
        MIN(energy) OVER (PARTITION BY album) AS min_energy
    FROM spotify
)
SELECT DISTINCT 
    album,
    (max_energy - min_energy) AS energy_difference
FROM energy_bounds;




-- 4.Find tracks where the energy-to-liveness ratio is greater than 1.2.--
WITH track_ratios AS (
    SELECT track, album, energy, 
           (energy/NULLIF(liveness,0)) AS ratio
    FROM spotify
)

SELECT track,ratio
FROM track_ratios
WHERE ratio > 1.2;

-- 5.Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.--
select track,likes,views,
sum(likes)over(order by views desc)as cumulative_sum  from spotify ;


--6.Find the tracks with energy greater than the average energy of their album.--
WITH track_energy AS (
    select track,energy,album,
    avg(energy)over(partition by album) as average_energy_album 
    from spotify)

select track from track_energy where energy> average_energy_album;


--7.Find the most popular track (by stream) in each album.
WITH ranked_tracks AS (
    SELECT 
        track,
        album,
        stream,
        DENSE_RANK() OVER (PARTITION BY album ORDER BY stream DESC) AS rank
    FROM spotify
    WHERE stream > 0 AND stream IS NOT NULL  -- Exclude tracks with 0 streams or NULL values
)
SELECT track, album, stream
FROM ranked_tracks
WHERE rank = 1;


--8.Calculate the difference between the highest and lowest danceability in each album.
WITH danceability_album AS (
    SELECT 
        album,
        danceability,
        MAX(danceability) OVER (PARTITION BY album) AS highest_danceability,
        MIN(danceability) OVER (PARTITION BY album) AS lowest_danceability
    FROM spotify
)
SELECT 
    distinct album,
    (highest_danceability - lowest_danceability) AS danceability_range
FROM danceability_album;
--9. Find tracks that have energy higher than the album's average energy and have more than 1 million streams.--

WITH track_energy AS (
    SELECT 
        track, 
        energy, 
        album, 
        stream, 
        AVG(energy) OVER (PARTITION BY album) AS average_energy_album
    FROM spotify
)
SELECT track
FROM track_energy
WHERE energy > average_energy_album AND stream > 1000000;


--10. Rank the tracks in each album by their loudness and find the top 3 loudest tracks for each album.--

WITH track_loudness AS (
    SELECT 
        track, 
        album, 
        loudness, 
        ROW_NUMBER() OVER (PARTITION BY album ORDER BY loudness DESC) AS rank
    FROM spotify
)
SELECT track, loudness
FROM track_loudness
WHERE rank <= 3;

--11. Find the total number of views and likes per album.--
SELECT 
    album, 
    SUM(views) AS total_views, 
    SUM(likes) AS total_likes
FROM spotify
GROUP BY album;

--12. Find tracks that have a speechiness score above the average speechiness of all tracks.--
WITH avg_speechiness AS (
    SELECT AVG(speechiness) AS avg_speechiness FROM spotify
)
SELECT 
    track, 
    album, 
    speechiness
FROM spotify
WHERE speechiness > (SELECT avg_speechiness FROM avg_speechiness);

--13. Find the tracks with the highest valence in each album.--
WITH ranked_tracks AS (
    SELECT 
        track, 
        album, 
        valence,
        DENSE_RANK() OVER (PARTITION BY album ORDER BY valence DESC) AS rank
    FROM spotify
)
SELECT track, album, valence
FROM ranked_tracks
WHERE rank = 1;

--14. Find the albums where the average acousticness is above 0.5--
SELECT album
FROM spotify
GROUP BY album
HAVING AVG(acousticness) > 0.5;

--15. Find tracks with more than 10 million streams and have an instrumentalness score greater than 0.8--
SELECT track, album, stream, instrumentalness
FROM spotify
WHERE stream > 10000000 AND instrumentalness > 0.8;

-- Query Optimization--
EXPLAIN ANALYZE -- et 7.97 ms pt 0.112ms
SELECT track, artist ,views FROM spotify WHERE artist = 'Gorillaz' AND most_played_on ='Youtube'
ORDER BY stream  DESC LIMIT 25;

CREATE INDEX artist_index on spotify(artist); -- et 0.071 ms pt 0.126 ms
