import streamlit as st
from streamlit_calendar import calendar
import yaml, sqlite3
from yaml.loader import SafeLoader
import pandas as pd
import plotly.express as px
from datetime import timedelta, datetime

# Load credentials
with open('credentials.yaml') as file:
    credentials = yaml.load(file, Loader=SafeLoader)

def time_to_timedelta(time_str):
    minutes, seconds = map(int, time_str.split(':'))
    return timedelta(minutes=48) - timedelta(minutes=minutes, seconds=seconds)

def basketball_pythagorean(points_scored, points_allowed, power=16.5):
    return pow(points_scored, power) / (pow(points_scored, power) + pow(points_allowed, power))

st.set_page_config(layout="wide")
st.markdown('# Clippers Team Management App')

conn=sqlite3.connect('lac_fullstack_dev.db')

# Initialize session state for user
if 'user_state' not in st.session_state:
    st.session_state.user_state = {
        'full_name': '',
        'username': '',
        'password': '',
        'logged_in': False,
        'user_type': '',
        'email_address': ''
    }

# Check if user is already logged in
if not st.session_state.user_state['logged_in']:
    st.write('Please login')
    username = st.text_input('Username')
    password = st.text_input('Password', type='password')
    submit = st.button('Login')

    if submit:
        # Check credentials
        user_info = next((user for user in credentials['credentials']['usernames'] if user['username'] == username), None)
        
        if not user_info:
            st.error('User not found')
        elif user_info['password'] == password:
            st.session_state.user_state.update({
                'username': username,
                'logged_in': True,
                'user_type': user_info['user_type']
            })
            st.success('Successfully logged in!')
            st.rerun()  # Refresh the page after successful login
        else:
            st.error('Invalid username or password')

# Once logged in, replace the login screen with the new content
if st.session_state.user_state['logged_in']:
    st.markdown(f"## Welcome {st.session_state.user_state['username']}!")
    col1, col2 = st.columns(2)
    if st.session_state.user_state['user_type'] == 'coach':
        calendar_query = """
        select 
        CASE WHEN h.teamNameShort = 'LAC' THEN 'vs ' || a.teamNameShort
        ELSE '@ ' || h.teamNameShort END AS game, 
        game_date, home_score, away_score
        from game_schedule gs
        join team h
        on gs.home_id = h.teamId
        join team a
        on gs.away_id = a.teamId
        where h.teamNameShort = 'LAC' or a.teamNameShort = 'LAC'
        """

        gantt_query = """
        SELECT game_date, 
        (CASE WHEN gs.home_id = t.teamId THEN '@ ' || t.teamNameShort
        ELSE 'vs ' || t.teamNameShort END) || ' ' || date(game_date) AS game,
        r.first_name || ' ' || r.last_name AS player,
        'Q' || CAST(period AS TEXT) AS quarter,
        printf('%02d%s', 
        12 * (4 - period) + CAST(SUBSTR(stint_start_time, 1, INSTR(stint_start_time, ':') - 1) AS REAL), 
        SUBSTR(stint_start_time, INSTR(stint_start_time, ':'), LENGTH(stint_start_time))) AS stint_start_time,
        printf('%02d%s', 
        12 * (4 - period) + CAST(SUBSTR(stint_end_time, 1, INSTR(stint_end_time, ':') - 1) AS REAL),
        SUBSTR(stint_end_time, INSTR(stint_end_time, ':'), LENGTH(stint_end_time))) AS stint_end_time
        FROM stints s
        JOIN roster r
        ON player_name = r.first_name || ' ' || r.last_name
        JOIN game_schedule gs
        ON gs.game_id = s.game_id
        JOIN team t
        ON t.teamName = s.opponent
        WHERE team = 'LA Clippers'
        """

        calendar_df = pd.read_sql(calendar_query, conn)
        gantt_df = pd.read_sql(gantt_query, conn)

        with col1:
            calendar_options = {
                "editable": "true",
                "selectable": "true",
                "headerToolbar": {
                    "left": "today prev,next",
                    "center": "title",
                    "right": "timeGridDay,timeGridWeek,dayGridMonth",
                },
                "slotMinTime": "12:00:00",
                "slotMaxTime": "24:00:00",
                "initialView": "dayGridMonth",
            }
            calendar_events = [
                {
                    'title': ('W' if (
                            record['game'].startswith('vs') 
                            and record['home_score'] > record['away_score']) 
                            or (record['game'].startswith('@') 
                            and record['home_score'] < record['away_score'])
                            else 'L') + ' ' + record['game'], 
                    'start': record['game_date'],
                    'backgroundColor': '#37752B' if (
                            record['game'].startswith('vs') 
                            and record['home_score'] > record['away_score']) 
                            or (record['game'].startswith('@') 
                            and record['home_score'] < record['away_score'])
                            else '#F15F30',
                    'borderColor': '#37752B' if (
                            record['game'].startswith('vs') 
                            and record['home_score'] > record['away_score']) 
                            or (record['game'].startswith('@') 
                            and record['home_score'] < record['away_score'])
                            else '#F15F30'
                    } for record in calendar_df.to_dict('records')
            ]
            custom_css="""
                .fc-event-past {
                    opacity: 0.8;
                }
                .fc-event-time {
                    font-style: italic;
                }
                .fc-event-title {
                    font-weight: 700;
                }
                .fc-toolbar-title {
                    font-size: 2rem;
                }
            """
            calendar = calendar(events=calendar_events, options=calendar_options, custom_css=custom_css)
        with col2:
            # Apply conversion to start and end times
            option = st.selectbox(
                "Select a game",
                gantt_df.game.unique()
            )
            # st.write(gantt_df['game_date'].loc[gantt_df['game'] == option].iloc[0])
            filtered_df = gantt_df.loc[gantt_df['game'] == option]
            filtered_df['game_date'] = pd.to_datetime(filtered_df['game_date'])
            filtered_df['stint_start_time'] = filtered_df['stint_start_time'].apply(time_to_timedelta)
            filtered_df['stint_end_time'] = filtered_df['stint_end_time'].apply(time_to_timedelta)
            reference_date = filtered_df['game_date'].iloc[0]
            filtered_df['stint_start_time'] = reference_date + filtered_df['stint_start_time']
            filtered_df['stint_end_time'] = reference_date + filtered_df['stint_end_time']

            fig = px.timeline(
                filtered_df, 
                x_start='stint_start_time', 
                x_end='stint_end_time', 
                y='player',
                color='quarter',
                category_orders={'quarter': ['Q1', 'Q2', 'Q3', 'Q4']},
                )
            fig.update_layout(
                xaxis_title="Time", yaxis_title="Player",
                title="Stint in Game",
                showlegend=True,
                xaxis=dict(visible=False)
                )
    
            st.plotly_chart(fig, use_container_width=True)
        
    elif st.session_state.user_state['user_type'] == 'analyst':
        points_query = """
        SELECT date(game_date) AS game_date,
        'LAC' AS team,
        CASE WHEN h.teamNameShort = 'LAC' THEN h.teamNameShort ELSE a.teamNameShort END AS teamSpec,
        CASE WHEN h.teamNameShort = 'LAC' THEN gs.home_score ELSE gs.away_score END AS points
        FROM game_schedule gs
        JOIN team h
        ON gs.home_id = h.teamId
        JOIN team a
        ON gs.away_id = a.teamId
        WHERE h.teamNameShort = 'LAC' OR a.teamNameShort = 'LAC'
        UNION ALL
        SELECT date(game_date) AS game_date,
        'Opponent' AS team,
        CASE WHEN h.teamNameShort = 'LAC' THEN a.teamNameShort ELSE h.teamNameShort END AS teamSpec,
        CASE WHEN h.teamNameShort = 'LAC' THEN gs.away_score ELSE gs.home_score END AS points
        FROM game_schedule gs
        JOIN team h
        ON gs.home_id = h.teamId
        JOIN team a
        ON gs.away_id = a.teamId
        WHERE h.teamNameShort = 'LAC' OR a.teamNameShort = 'LAC'
        """

        pythagorean_query = """
        SELECT date(game_date) AS game_date,
        'LAC' AS team,
        CASE WHEN h.teamNameShort = 'LAC' THEN gs.home_score ELSE gs.away_score END AS points_scored,
        CASE WHEN h.teamNameShort = 'LAC' THEN gs.away_score ELSE gs.home_score END AS points_allowed
        FROM game_schedule gs
        JOIN team h
        ON gs.home_id = h.teamId
        JOIN team a
        ON gs.away_id = a.teamId
        WHERE h.teamNameShort = 'LAC' OR a.teamNameShort = 'LAC'
        """

        points_df = pd.read_sql(points_query, conn)
        pythagorean_df = pd.read_sql(pythagorean_query, conn)

        with col1:
            pythagorean_df[['total_points_scored', 'total_points_allowed']] = pythagorean_df[['points_scored', 'points_allowed']].cumsum()
            pythagorean_df['win_ratio'] = pythagorean_df.apply(lambda x: 100.0 * basketball_pythagorean(x.total_points_scored, x.total_points_allowed), axis=1)

            fig1 = px.line(
                pythagorean_df, x="game_date", y="win_ratio"
            )
            fig1.update_layout(
                xaxis_title="Game Date", yaxis_title="Winning Percentage%",
                title="Pythagorean Winning Percentage %",
                showlegend=True
                )
            st.plotly_chart(fig1, use_container_width=True)
            st.markdown("""
            Formula: *Pythagorean (Expected) Winning Percentage Formula=(Points Scored)16.5/[Points Scored)16.5 + (Points Allowed)16.5)]* ([source](https://nbastuffer.com/analytics101/pythagorean-winning-percentage/))
            """)

            fig2 = px.bar(
                points_df, x="game_date", y="points", color="team", barmode="group",
                hover_data=["game_date", "teamSpec", "points"]
            )
            fig2.update_layout(
                xaxis_title="Game Date", yaxis_title="Points Scored/Allowed",
                title="Points Scored/Allowed in January, 2024",
                showlegend=True,
                legend=dict(yanchor="top", y=0.99, xanchor="left", x=0.01)
                )
            
            st.plotly_chart(fig2, use_container_width=True)
        with col2:
            st.markdown("### Amount of time for Players Playing on Court Together")
            lac_games_query = """
            select game_id, 
            (CASE WHEN h.teamNameShort = 'LAC' THEN 'vs ' || a.teamNameShort ELSE '@ ' || h.teamNameShort END) || ' ' || date(game_date) AS game 
            from game_schedule gs
            JOIN team h
            ON gs.home_id = h.teamId
            JOIN team a
            ON gs.away_id = a.teamId
            WHERE h.teamNameShort = 'LAC' OR a.teamNameShort = 'LAC'
            """
            lac_games_df = pd.read_sql(lac_games_query, conn)
            game_option = st.selectbox(
                "Select a game",
                lac_games_df.game.unique()
            )

            roster_query = """
            select player_id, first_name || ' ' || last_name AS player_name 
            from roster r
            join team t
            on r.team_id = t.teamId
            where t.teamNameShort = 'LAC'
            """
            roster_df = pd.read_sql(roster_query, conn)
            player_options = st.multiselect(
                "Select players",
                roster_df.player_name.unique(),
                max_selections=5
            )

            game_id = lac_games_df['game_id'].loc[lac_games_df['game'] == game_option].iloc[0]
            player_ids = roster_df['player_id'].loc[roster_df['player_name'].isin(player_options)].tolist()

            on_court_query = f"""
            select sum(time_per_quarter) AS total_time_on_court
            from (
            select period, max(time_in) - min(time_out) as time_per_quarter
            from (
            select period, lineup_num, MIN(time_in) AS time_in, MAX(time_out) AS time_out
            from lineup
            where game_id = {game_id}
            and team_id = 1610612746
            and player_id in ({','.join([str(player_id) for player_id in player_ids])})
            group by period, lineup_num
            HAVING COUNT(lineup_num) = {len(player_ids)}
            ) AS cte1
            group by period) AS cte2;
            """
            total_time = pd.read_sql(on_court_query, conn)['total_time_on_court'].iloc[0]

            if total_time:
                st.metric(label=f"""
                In total, they played on court together:
                """,
                value=f"{str(int(total_time // 60)).zfill(2)}:{str(int(total_time % 60)).zfill(2)}")
            else:
                st.metric(label=f"""
                In total, they played on court together:
                """,
                value="00:00")

    
    if st.button("Logout"):
        st.session_state.user_state['logged_in'] = False
        st.rerun()  # Refresh the page after logging out