import io, json, sqlite3, os, warnings, re, logging

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

def build_sql_insert_statement(table_name: str, columns: str, values: str) -> str:
    """Configure an insert table query in SQL, which is the format of 
    "INSERT OR REPLACE INTO {table_name} ({columns}) VALUES {values};"
    Note that this query is defaulted to replace the existing rows in the table if any upcoming entries duplicate on the primary key(s)

    Args:
        table_name (str): the table name to be created.
        columns (str): the column names to be included in the upcoming new table. No data types are required, column names have to be seperated by ", ".
        values (str): list of tuples of to-insert values, in text.

    Returns:
        str: complete query
    """    
    __location__ = os.path.realpath(os.path.join(os.getcwd(), os.path.dirname(__file__)))
    sql_raw_statement = open(
        os.path.join(__location__, "queries/insert.sql")
    ).read()
    insert_statement = sql_raw_statement.format(table_name=table_name, columns=columns, values=values)
    return insert_statement

def execute(database:str, query:str):
    """Executor of SQL query on SQLite database

    Args:
        database (str): SQLite directory, i.e.: data.db
        query (str): SQL query

    Returns:
        class 'sqlite3.Cursor': the outcome of SQL query exeuction
    """    
    if re.search('.(sqlite|sqlite3|db|db3|s3db|sl3|sql)', database) is None:
        warnings.warn("Sqlite database filename is recommended to end with .sqlite, .sqlite3, .db, .db3, .s3db, .sl3, .sql")
    try:
        conn = sqlite3.connect(database)
    except sqlite3.Error as e:
        print(e)

    cursor = conn.cursor()
    result = cursor.execute(query)
    conn.commit()
    LOGGER.info("Successfully executed query!")
    return result

def build_column_value_text(values:list) -> tuple:
    """Reconstruct the to-insert values and the columns

    Args:
        values (list): a list of key-value pair sets on behelf of to-insert data rows

    Returns:
        1. to_insert_values (str): tuple-like string, each element split by ", " complies to SQlite JSON standard, sorted by each dict's key set
    """    
    to_insert_values = []
    for value in values:
        to_insert_values.append(
            convert_to_sql_insert_values(
                tuple(value.values())
                ))

    return ", ".join(to_insert_values)

def convert_to_sql_insert_values(data:tuple) -> str:
    """A custom method to convert tuple data to string. The final result can be used in an SQLite insert query without bringing malformed JSON errors.

    Args:
        data (tuple): an object that needs to be converted to text

    Returns:
        str: tuple-like string, can be used in an SQLite insert query without bringing malformed JSON error.
    """    
    def format_value(value:any, surrounded:bool=True):
        """An iterative way to convert all data types of Python objects to strings for SQLite upsertion.

        Args:
            value (any): to-format data value
            surrounded (bool, optional): A flag to signal if the result should be surrounded by a pair of single quotes. Defaults to True.

        Returns:
            str: JSON-formatted string
        """        
        if value is None:
            return "NULL"
        elif isinstance(value, bool):
            return str(value).lower()
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, str):
            escaped_quotes = value.replace('"', '""').replace('\'', '\'\'')
            return f'"{escaped_quotes}"'
        elif isinstance(value, list):
            converted_list = [format_value(item, surrounded=False) for item in value]
            if not surrounded:
                return "[" + ", ".join(converted_list) + "]"
            else:
                return "\'[" + ", ".join(converted_list) + "]\'"
        elif isinstance(value, dict):
            converted_dict = {
                format_value(key, surrounded=False): format_value(val, surrounded=False) for key, val in value.items()
            }
            if surrounded:
                return "\'{" + ", ".join([f"{k}: {v}" for k, v in converted_dict.items()]) + "}\'"
            else:
                return "{" + ", ".join([f"{k}: {v}" for k, v in converted_dict.items()]) + "}"
        else:
            return str(value)

    converted_data = [format_value(item) for item in data]
    return "(" + ", ".join(converted_data) + ")"

def build_table(filename:str, database:str):
    """Build a SQLite3 table using data in JSON file

    Args:
        filename: str, should include extension name (.json)
        database: str, the SQLite catalog name
    """
    with open(filename, 'r') as file:
        data = json.load(file)

    tableName = filename.split('.')[0]
    if data:
        columns = ','.join(data[0].keys())
        primaryKeys = [key for key in data[0].keys() if 'Id' in key]
        values = build_column_value_text(data)

        try:
            create_statement = build_sql_create_statement(tableName, columns, primaryKeys)
            LOGGER.info(f"{tableName} table creation query was successfully created!")
        except Exception as e:
            LOGGER.error(f"Encountered error when building {tableName} table creation query, error detail: {e}")
            sys.exit(1)

        try:
            insert_statement = build_sql_insert_statement(tableName, columns, values)
            LOGGER.info(f'{tableName} table insersion query was successfully created!')
        except Exception as e:
            LOGGER.error(f"Encountered error when building {tableName} table insersion query, error detail: {e}")
            sys.exit(1)

        try:
            execute(database, create_statement)
            print(f"{tableName} table was successfully created!")
        except Exception as e:
            print(f"Encountered error when creating {tableName} table, error detail: {e}")
            sys.exit(1)

        try:
            execute(database, insert_statement)
            print(f'Insertions into {tableName} table were successfully completed!')
        except Exception as e:
            print(f"Encountered error when inserting into {tableName} table, error detail: {e}")
            sys.exit(1)

if __name__ == '__main__':
    LOGGER = logging.getLogger(__name__)
    SCHEMA = 'lac_fullstack_dev'

    files = ['team.json', 'team_affiliate.json', 'game_schedule.json', 'player.json', 'lineup.json', 'roster.json']
    for file in files:
        build_table(file, SCHEMA)
    