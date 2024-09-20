-- 3.b.
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
), ordered_games AS (
    SELECT *, RANK() OVER(PARTITION BY team_name ORDER BY game_date) AS rank
    FROM team_games
), rest_periods AS (
    SELECT g1.team_name, g1.game_date AS first_game_date, g2.game_date AS second_game_date,
    julianday(date(g2.game_date)) - julianday(date(g1.game_date)) AS rest_days
    FROM ordered_games g1
    JOIN ordered_games g2
    ON g1.team_name = g2.team_name
    WHERE g2.rank - g1.rank = 1
), longest_rest AS (
    SELECT *, RANK() OVER(ORDER BY rest_days DESC) AS rank
    FROM rest_periods
) SELECT team_name, first_game_date, second_game_date, CAST(rest_days AS BIGINT) AS rest_days
FROM longest_rest
WHERE rank = 1;