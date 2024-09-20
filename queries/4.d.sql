-- 4.d.
WITH detailed_data AS (
    SELECT s.game_id, 
    CASE WHEN t.teamId = gs.home_id THEN gs.home_score ELSE gs.away_score END AS team_score,
    CASE WHEN t.teamId = gs.home_id THEN gs.away_score ELSE gs.home_score END AS opponent_score,
    player_name, period, 
    stint_number, stint_start_time, stint_end_time
    FROM stints s
    JOIN team t 
    ON s.team = t.teamName
    JOIN team o 
    ON s.opponent = o.teamName
    JOIN game_schedule gs
    ON s.game_id = gs.game_id
), basics AS (
    SELECT game_id, 
    CASE WHEN team_score > opponent_score THEN 'win' ELSE 'loss' END AS game_result,
    player_name, stint_number, 
    (CAST(SUBSTR(stint_start_time, 1, INSTR(stint_start_time, ':') - 1) AS REAL) * 60 +
    CAST(SUBSTR(stint_start_time, INSTR(stint_start_time, ':')+1, LENGTH(stint_start_time)) AS REAL)) - 
    (CAST(SUBSTR(stint_end_time, 1, INSTR(stint_end_time, ':') - 1) AS REAL) * 60 +
    CAST(SUBSTR(stint_end_time, INSTR(stint_end_time, ':')+1, LENGTH(stint_end_time)) AS REAL)) AS stint_length
    FROM detailed_data
), calculation1 AS (
    SELECT game_id, player_name, game_result,
    COUNT(stint_number) AS stints, 
    AVG(stint_length) AS average_stint_length
    FROM basics
    GROUP BY game_id, player_name, game_result
), calculation2 AS (
    SELECT player_name, game_result, AVG(stints) AS average_stints
    FROM calculation1
    GROUP BY player_name, game_result
) SELECT game_id, calculation1.player_name, calculation1.game_result,
ROUND(average_stints, 2) AS average_stints_per_game,
ROUND(average_stint_length, 2) AS average_stint_length_this_game
FROM calculation1
JOIN calculation2 
ON calculation1.player_name = calculation2.player_name
AND calculation1.game_result = calculation2.game_result
UNION ALL
SELECT game_id, calculation1.player_name, 'all' AS game_result,
ROUND(average_stints, 2) AS average_stints_per_game,
ROUND(average_stint_length, 2) AS average_stint_length_this_game
FROM calculation1
JOIN calculation2 
ON calculation1.player_name = calculation2.player_name
ORDER BY game_result, game_id, calculation1.player_name;