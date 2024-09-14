# Clippers_assignment

This ingestion processor is containerized by Docker.

**Prerequisite**: [Docker Desktop](https://www.docker.com/products/docker-desktop/)

## Execution

0. Get in this working directory
```
cd directory/to/Clippers_assignment
# claim a variable for the absolute path of the current working directory
work_dir=your/absolute/path/to/Clippers_assignment
```

1. Build docker image:
```
docker build -t lac .
```

2. Run docker image:
```
docker run --name nba -v /$(pwd):$work_dir lac --schema $work_dir/lac_fullstack_dev
```

3. Expected result:
You are supposed to see a file named "lac_fullstack_dev" created in the current working directory. To verify, please run `sqlite3 $work_dir/lac_fullstack_dev` and you'll see a dialog waiting for you to type in.