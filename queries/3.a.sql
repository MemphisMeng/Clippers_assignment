-- 3.a.
-- home back-to-back games
WITH home_games AS (
    SELECT t1.teamName AS team_name, game_date
    FROM game_schedule gs
    JOIN team t1
    ON gs.home_id = t1.teamId
), home_b2b AS (
    SELECT g1.team_name, g1.game_date AS first_game_date, g2.game_date AS second_game_date
    FROM home_games g1
    JOIN home_games g2 ON g1.team_name = g2.team_name
    WHERE julianday(date(g2.game_date)) - julianday(date(g1.game_date)) = 1
), ranked_home_b2b AS (
    -- more than one team had the most b2b home games (2)
    SELECT team_name, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank, COUNT(*) AS b2b_games
    FROM home_b2b
    GROUP BY team_name
)
SELECT team_name, b2b_games
FROM ranked_home_b2b
WHERE rank = 1;

-- away back-to-back games
WITH away_games AS (
    SELECT t1.teamName AS team_name, game_date
    FROM game_schedule gs
    JOIN team t1
    ON gs.away_id = t1.teamId
), away_b2b AS (
    SELECT g1.team_name, g1.game_date AS first_game_date, g2.game_date AS second_game_date
    FROM away_games g1
    JOIN away_games g2 ON g1.team_name = g2.team_name
    WHERE julianday(date(g2.game_date)) - julianday(date(g1.game_date)) = 1
), ranked_away_b2b AS (
    -- more than one team had the most b2b home games (2)
    SELECT team_name, DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank, COUNT(*) AS b2b_games
    FROM away_b2b
    GROUP BY team_name
)
SELECT team_name, b2b_games
FROM ranked_away_b2b
WHERE rank = 1;