FROM python:3.8.20 as main
WORKDIR /lac
COPY . /lac//
RUN pip install poetry
RUN poetry install
ENTRYPOINT ["poetry", "run", "python", "database.py"]