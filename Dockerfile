FROM python:3.8.20 as main
WORKDIR /app
COPY . /app//
# Install sqlite3
RUN apt-get update && apt-get install -y sqlite3

# dependecy
RUN pip install poetry
RUN poetry install
ENTRYPOINT ["sh", "-c", "poetry run python database.py && sqlite3 lac_fullstack_dev.db < queries/4.b.sql && sqlite3 lac_fullstack_dev.db '.tables' && poetry run streamlit run dashboard.py"]