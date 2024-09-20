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