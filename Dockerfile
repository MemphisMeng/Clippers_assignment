FROM python:3.9 as main
WORKDIR /lac
COPY . /lac//
RUN pip install -r requirements.txt
ENTRYPOINT ["python", "database.py"]