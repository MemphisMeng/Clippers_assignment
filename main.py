import os, json, logging, sys, argparse
from datetime import datetime
from sqlalchemy.util import deprecations
from sqlalchemy import create_engine, Table, Column, String, MetaData, Integer, BigInteger, DateTime, FLOAT
from sqlalchemy.orm import sessionmaker

def convert(key, value):
    """Convert the raw data types to the expected

    Args:
        key (str): key
        value (any): value to be converted
    """    
    if 'id' in key.lower():
        if value: # do nothing if empty
            return int(value) # some id values are in float type
    elif 'date' in key:
        try:
            # Assuming the datetime format is 'YYYY-MM-DD HH:MM:SS'
            return datetime.strptime(value, '%Y-%m-%d %H:%M:%S')
        except ValueError:
            LOGGER.error('The date time string is in an unexpected format!')
            sys.exit(1)
    return value

if __name__ == '__main__':
    TableMap = {
        'game_schedule': {
            # column: [data_type, is_pk]
            'game_id': [Integer, False], 
            'home_id': [BigInteger, True], 
            'home_score': [Integer, False], 
            'away_id': [BigInteger, True], 
            'away_score': [Integer, False], 
            'game_date': [DateTime,True]
        },
        'lineup': {
            "team_id": [BigInteger, True],
            "player_id": [BigInteger, True],
            "lineup_num": [Integer, True],
            "period": [Integer, False],
            "time_in": [FLOAT, False],
            "time_out": [FLOAT, False],
            "game_id": [Integer, True]
        },
        'player': {
            "player_id": [BigInteger, True],
            "first_name": [String, False],
            "last_name": [String, False]
        },
        'roster': {
            "team_id": [BigInteger, True],
            "player_id": [BigInteger, True],
            "first_name": [String, False],
            "last_name": [String, False],
            "position": [String, False],
            "contract_type": [String, False]
        },
        'team_affiliate': {
            "nba_teamId": [BigInteger, True],
            "nba_abrv": [String, False],
            "glg_teamId": [BigInteger, False],
            "glg_abrv": [String, False]
        },
        'team': {
            "teamId":[BigInteger, True],
            "leagueLk": [String, False],
            "teamName": [String, False],
            "teamNameShort": [String, False],
            "teamNickname": [String, False]
        }
    }
    LOGGER = logging.getLogger(__name__)
    deprecations.SILENCE_UBER_WARNING = True
    DB_URL = os.getenv('DB_URL')
    FILE_DIR = os.getenv('FILE_DIR')
    engine = create_engine(DB_URL)
    metadata = MetaData(bind=engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    for file in os.listdir(FILE_DIR):
        if file.endswith('.json'):
            tableName = os.path.splitext(file)[0]
            filePath = os.path.join(FILE_DIR, file)
            LOGGER.info(f"{'=' * 100}\nTransfering the data of {tableName} file...")
            
            with open(filePath, 'r') as file:
                data = json.load(file)

                if not isinstance(data, list) or len(data) == 0:
                    LOGGER.warning(f"Skipping file {file}: No data found.")
                    continue
            
            columns = [Column(col, attributes[0], primary_key=attributes[1]) for col, attributes in TableMap[tableName].items()]
            table = Table(tableName, metadata, *columns, extend_existing=True)

            conn = engine.connect()
            # CREATE TABLE IF NOT EXISTS
            if not engine.dialect.has_table(conn, tableName):
                table.create(engine)
            LOGGER.info(f"\nSuccessfully created the table {tableName}!")

            # INSERT INTO table (col1, col2, ...) VALUES (?, ?, ...)
            batch = []
            for item in data:
                converted_item = {key: convert(key, value) for key, value in item.items()}
                batch.append(converted_item)
            LOGGER.info(f"\nSuccessfully inserted a new data batch into the table {tableName}!")
            
            conn.execute(table.insert(), batch)
            conn.close()
            LOGGER.info(f"\nFinished transferring the data of {tableName} file!\n{'=' * 100}")

    session.commit()
    session.close()