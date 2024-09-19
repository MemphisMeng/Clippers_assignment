-- 2.a.
WITH named_games AS (
    SELECT t1.teamName AS home_name, home_score, t2.teamName AS away_name, away_score
    FROM game_schedule gs
    JOIN team t1
    ON gs.home_id = t1.teamId
    JOIN team t2
    ON gs.away_id = t2.teamId
)
SELECT games_data.team,
       games_played,
       wins,
       losses,
       ROUND((CAST(wins AS REAL) / games_played) * 100, 2) AS win_percentage
FROM (
    -- Calculate games played
    SELECT team,
           COUNT(*) AS games_played
    FROM (
        SELECT home_name AS team FROM named_games
        UNION ALL
        SELECT away_name AS team FROM named_games
    ) AS all_games
    GROUP BY team
) AS games_data
LEFT JOIN (
    -- Calculate wins
    SELECT team,
           COUNT(*) AS wins
    FROM (
        SELECT home_name AS team
        FROM named_games
        WHERE home_score > away_score
        
        UNION ALL
        
        SELECT away_name AS team
        FROM named_games 
        WHERE away_score > home_score
    ) AS all_wins
    GROUP BY team
) AS win_data ON games_data.team = win_data.team
LEFT JOIN (
    -- Calculate losses
    SELECT team,
           COUNT(*) AS losses
    FROM (
        SELECT home_name AS team
        FROM named_games
        WHERE home_score < away_score
        
        UNION ALL
        
        SELECT away_name AS team
        FROM named_games
        WHERE away_score < home_score
    ) AS all_losses
    GROUP BY team
) AS loss_data ON games_data.team = loss_data.team;

-- 2.b.
WITH named_games AS (
    SELECT t1.teamName AS home_name, home_score, t2.teamName AS away_name, away_score
    FROM game_schedule gs
    JOIN team t1
    ON gs.home_id = t1.teamId
    JOIN team t2
    ON gs.away_id = t2.teamId
    WHERE strftime('%m', game_date) = '01'
)
SELECT games_data.team,
       games_played,
       RANK() OVER(ORDER BY games_played DESC) AS games_played_rank,
       home_games_played,
       RANK() OVER(ORDER BY home_games_played DESC) AS home_games_played_rank,
       away_games_played,
       RANK() OVER(ORDER BY away_games_played DESC) AS away_games_played_rank,
       wins,
       losses,
       ROUND((CAST(wins AS REAL) / games_played) * 100, 2) AS win_percentage
FROM (
    -- Calculate games played
    SELECT A.team, home_games_played + away_games_played AS games_played, home_games_played, away_games_played
    FROM (
    SELECT home_name AS team, COUNT(*) AS home_games_played FROM named_games GROUP BY home_name
    ) A
    LEFT JOIN (SELECT away_name AS team, COUNT(*) AS away_games_played FROM named_games GROUP BY away_name) B
    ON A.team = B.team
) AS games_data
LEFT JOIN (
    -- Calculate wins
    SELECT team,
           COUNT(*) AS wins
    FROM (
        SELECT home_name AS team
        FROM named_games
        WHERE home_score > away_score
        
        UNION ALL
        
        SELECT away_name AS team
        FROM named_games 
        WHERE away_score > home_score
    ) AS all_wins
    GROUP BY team
) AS win_data ON games_data.team = win_data.team
LEFT JOIN (
    -- Calculate losses
    SELECT team,
           COUNT(*) AS losses
    FROM (
        SELECT home_name AS team
        FROM named_games
        WHERE home_score < away_score
        UNION ALL
        SELECT away_name AS team
        FROM named_games
        WHERE away_score < home_score
    ) AS all_losses
    GROUP BY team
) AS loss_data ON games_data.team = loss_data.team;

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

-- 4.a.
WITH ordered_players AS (
    SELECT *, RANK() OVER(PARTITION BY game_id, team_id, lineup_num ORDER BY player_id) AS player_order
    FROM lineup
)
SELECT team_id, lineup_num, period, time_in, time_out, game_id, 
MAX(CASE WHEN player_order = 1 THEN player_id END) AS player1_id,
MAX(CASE WHEN player_order = 2 THEN player_id END) AS player2_id,
MAX(CASE WHEN player_order = 3 THEN player_id END) AS player3_id,
MAX(CASE WHEN player_order = 4 THEN player_id END) AS player4_id,
MAX(CASE WHEN player_order = 5 THEN player_id END) AS player5_id
FROM ordered_players
GROUP BY team_id, lineup_num, period, time_in, time_out, game_id
ORDER BY game_id, team_id, lineup_num;

-- 4.b.
CREATE TABLE IF NOT EXISTS stints AS -- for answering the next question more easily
SELECT s.game_id, 
CASE WHEN s.team_id = g.home_id THEN h.teamName ELSE a.teamName END AS team,
CASE WHEN s.team_id = g.home_id THEN a.teamName ELSE h.teamName END AS opponent,
p.first_name || ' ' || p.last_name AS player_name,
s.period, 
RANK() OVER(PARTITION BY s.game_id, s.team_id, s.player_id ORDER BY stint_label) AS stint_number,
printf('%02d:%02d', time_in / 60, time_in % 60) AS stint_start_time,
printf('%02d:%02d', time_out / 60, time_out % 60) AS stint_end_time
FROM (
    SELECT game_id, team_id, player_id,
    lineup_num - player_lineup_order AS stint_label, period, 
    MAX(time_in) AS time_in, MIN(time_out) AS time_out
    FROM (
        SELECT game_id, team_id, player_id, period, time_in, time_out, lineup_num, 
    RANK() OVER(PARTITION BY game_id, player_id ORDER BY lineup_num) AS player_lineup_order
    FROM lineup
    ) AS ordered_player_lineup
    GROUP BY game_id, team_id, player_id, stint_label, period
    ORDER BY game_id, team_id, player_id, stint_label, period
) AS s
JOIN game_schedule g
ON s.game_id = g.game_id
JOIN team h
ON h.teamId = g.home_id
JOIN team a
ON a.teamId = g.away_id
JOIN player p
ON p.player_id = s.player_id;

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