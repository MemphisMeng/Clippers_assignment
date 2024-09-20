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