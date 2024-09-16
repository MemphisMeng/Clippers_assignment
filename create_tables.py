import io, json, sqlite3, os, re, logging, argparse, sys

def build_sql_create_statement(table_name: str, columns: str, primary_key:list=None) -> str:
    """Configure a create table query in SQL, which is the format of 
    "CREATE TABLE IF NOT EXISTS {table_name} ({columns});"

    Args:
        table_name (str): the table name to be created.
        columns (str): the column names to be included in the upcoming new table. No data types are required, column names have to be seperated by ", ".
        primary_key (list, optional): column name of the primary key(s). Defaults to None.

    Returns:
        str: complete query
    """    
    __location__ = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
    sql_raw_statement = open(
        os.path.join(__location__, "queries/create.sql")
    ).read()
    if primary_key:
        columns += f", PRIMARY KEY ({','.join(primary_key)})"
    create_statement = sql_raw_statement.format(table_name=table_name, columns=columns)
    return create_statement

if __name__ == '__main__':
    primaryKeyMap = {
        'game_schedule.json': ['home_id', 'away_id', 'game_date'],
        'lineup.json': ['team_id', 'player_id', 'lineup_num', 'game_id'],
        'player.json': ['player_id'],
        'roster.json': ['team_id', 'player_id'],
        'team_affiliate.json': ['nba_teamId', 'glg_teamId'],
        'team.json': ['teamId']
    }