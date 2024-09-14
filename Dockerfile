FROM python:3.9 as main
WORKDIR /lac
COPY . /lac//
ENTRYPOINT ["python", "main.py"]