-- 4.c.
WITH basics AS (
    SELECT game_id, player_name, stint_number, 
    (CAST(SUBSTR(stint_start_time, 1, INSTR(stint_start_time, ':') - 1) AS REAL) * 60 +
    CAST(SUBSTR(stint_start_time, INSTR(stint_start_time, ':')+1, LENGTH(stint_start_time)) AS REAL)) - 
    (CAST(SUBSTR(stint_end_time, 1, INSTR(stint_end_time, ':') - 1) AS REAL) * 60 +
    CAST(SUBSTR(stint_end_time, INSTR(stint_end_time, ':')+1, LENGTH(stint_end_time)) AS REAL)) AS stint_length
    FROM stints
), calculation1 AS (
    SELECT game_id, player_name, 
    COUNT(stint_number) AS stints, 
    AVG(stint_length) AS average_stint_length
    FROM basics
    GROUP BY game_id, player_name
), calculation2 AS (
    SELECT player_name, AVG(stints) AS average_stints
    FROM calculation1
    GROUP BY player_name
) SELECT game_id, calculation1.player_name,
ROUND(average_stints, 2) AS average_stints_per_game,
ROUND(average_stint_length, 2) AS average_stint_length_this_game
FROM calculation1
JOIN calculation2 
ON calculation1.player_name = calculation2.player_name;