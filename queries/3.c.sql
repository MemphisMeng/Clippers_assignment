-- 3.c.
WITH named_games AS (
    SELECT t1.teamName AS home_name, t2.teamName AS away_name, game_date
    FROM game_schedule gs
    JOIN team t1
    ON gs.home_id = t1.teamId
    JOIN team t2
    ON gs.away_id = t2.teamId
), team_games AS (
    SELECT home_name AS team_name, game_date
    FROM named_games
    UNION ALL
    SELECT away_name AS team_name, game_date
    FROM named_games
), game_windows AS (
    SELECT g1.team_name, g1.game_date AS first_game_date, g2.game_date AS second_game_date, g3.game_date AS third_game_date,
           julianday(date(g3.game_date)) - julianday(date(g1.game_date)) AS day_difference
    FROM team_games g1
    JOIN team_games g2 ON g1.team_name = g2.team_name AND g2.game_date > g1.game_date
    JOIN team_games g3 ON g2.team_name = g3.team_name AND g3.game_date > g2.game_date
    -- conditions:
    -- 1. the third game was 3 days behind the first game
    -- 2. the second game was 1 day behind the first game, or 1 day before the third game
    WHERE julianday(date(g3.game_date)) - julianday(date(g1.game_date)) = 3
    AND (julianday(date(g2.game_date)) - julianday(date(g1.game_date)) = 1
    OR julianday(date(g3.game_date)) - julianday(date(g2.game_date)) = 1)
), rank_tbl AS(SELECT team_name, COUNT(*) AS three_in_four_count, RANK() OVER(ORDER BY COUNT(*) DESC) AS three_in_four_count_rank
FROM game_windows
GROUP BY team_name
ORDER BY COUNT(*) DESC)
SELECT team_name, three_in_four_count
FROM rank_tbl WHERE three_in_four_count_rank = 1;