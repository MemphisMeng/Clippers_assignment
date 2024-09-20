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