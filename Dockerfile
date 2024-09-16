FROM python:3.9 as main
WORKDIR /lac
RUN pip install sqlalchemy==1.4.49
COPY . /lac//
ENTRYPOINT ["python", "main.py"]