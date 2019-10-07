# Automating Workflows with Airflow

![Airflow Diagram](https://www.xenonstack.com/images/insights/xenonstack-what-is-apache-airflow.png)

Apache Airflow is a like a crontab on steroids.

Its a pipeline framework that can be used for ETL processing, training model overnight, or any task that needs to be run at certain frequency. The framework allows you to run multiple jobs across different workers. I have a simple implementation of Airflow running on my local machine with the airflow server using docker containers. Therefore you run this near production example on your local machine using docker container and then migrate to Amazon Web Services or the Google Cloud Platform.

To get a near production implementation of airflow running. The following tasks need to be completed.

1) Set up an airflow meta-database in Postgres
2) Install and run the airflow scheduler and airflow websever within your virtual environment
3) Starting Running some DAGs on different schedules

### Postgres and Airflow Versions

Each version usually involved change to the airflow config file, therefore I would suggest that you start off by using airflow `1.10.3`. This is a good choice because this the version that introduces time zone support for the airflow scheduler and airflow web server.

There is not real technical reason to use Postgres 9.6.15.

- Airflow = 1.10.3
- Postgres Database =  9.6.15

### Setting up Postgres Database

First, you will need [docker](https://docs.docker.com/v17.09/engine/installation/#updates-and-patches). Please use the docker website to install the version of docker that is appropriate for you.

Start a postgres server within a docker container and creating a database called "airflow". We will use this database as our meta-database when we start running the airflow scheduler and webserver.

```bash
# Creating postgres docker container
docker run -d --name my_postgres -v my_dbdata:/var/lib/postgresql/data -p 54320:5432 postgres:11

# Connect to the postgres database
docker exec -it my_postgres psql -U postgres

# Check the current version of Postgres
SHOW server_version;

# Create a Airflow
CREATE DATABASE airflow;

# View the databases on the Postgres server/contianer
\l

# Disconnect from Postgres server
\q
```

At the very end you should get an output like the following. You see our new airflow database on the server. We will not populate it during the airflow setup and use it as a persistent data store for our scheduler.

![Postgres Database Setup](/images/postrgess_databas_setup.png)

### Virtual Environment & Airflow Installation

Next we are going to setup a virtual environment for our airflow installation.

After install the environment, we will populate our meta-database, and start running the airflow scheduler and airflow web server.

- **Airflow scheduler** - schedule that check for dag and task run a short time interval.
- **Airflow web server** - interactive user interface to view job progress

I use [conda](https://www.anaconda.com/) as my package manager and virtual environments. Therefore I suggest that you install anaconda, virenv, or pyenv and following along. This tutorial will be using conda.

1. Create a virtual environment using conda.

```bash
# Create a virtual environment
conda create -n airflow python=3.6
```

2. Activate and enter your new virtual environment

```bash
# Activate the airflow environment
source activate airflow
```

3. Install our python modules using pip. The requirements file can be found under the requirements folder within this repository

```bash
# Install the environment using pip and the requirements.txt file
pip install -r requirements.txt
```

5. Set Conda Home environment Path

```bash
# Create an AIRFLOW_HOME environment variable that points to our airflow config file.
# In my case I store this repository in the "/Users/kavi/repos/" on my Mac.
export AIRFLOW_HOME="/Users/kavi/repos/airflow"
```

5. Populate the meta database by running the `airflow initdb` command

```bash
# Populate the meta database with the tables for the schedule and webserver
airflow initdb
```

4. Start the Airflow web server.

```bash
# Start the airflow webserver
airflow webserver -p 8080
```

5. Start the Airflow scheduler

```bash
# Start the schedule scheduler
airflow scheduler -p 8080
```

6. Visit "http://localhost:8080/admin/" to view the Airflow Dashboard to run your DAGs. A user interface like the following should appear in your browser.

![Image](./Images/local_airflow.png)

### Running Airflow

When you have airflow running it will start executing the airflow DAGs found under the `dags` subdirectory. There are a variety of light weight DAGs in this repository that have designed to uses a variety of airflow feature. I would highly suggest checking the out as Airflow executes.
### Creating a Docker Airflow Container

```bash
# Navigate to airflow dircetory
cd /Users/kavi/repos/airflow

# Creating airflow docker image
docker build -t airflow_image .
```


### Creating Docker Network

```bash
# Create a docker network and add the container to the network
docker network create my_network
docker network connect my_network my_postgres
docker network connect my_network airflow_container

# View network information
docker network inspect my_network
```

### Running a Docker Container

```bash
# Creating airflow docker container
docker run -d -P --name airflow_container -it airflow_image /bin/bash


```

Start the scheduler and webserver into two seperate screens

```bash
# Start airflow scheduler and webserver in two seperate screens
source activate airflow
&& screen -d -m -S scheduler bash -c "airflow scheduler"
&& screen -d -m -S webserver bash -c "airflow webserver -p 8080"
```

```bash
# See the open incoming ports for your docker container
 docker port airflow_container
```

Look for the port mapping of port 8080 (i.e. `8080/tcp -> 0.0.0.0:32769`) Take the mapped port number and it to your airflow web server url.

http://localhost:32769/admin/

### Connecting to Postgres Container with Linux Container

```bash
# Connet to postgress database container via psql
psql -h 172.18.0.1 -p 54320 -U postgres

# Connet to postgress database container via psql on your local machine
psql -h localhost -p 54320 -U postgres
```

#### Stopping Docker

Lets say your finished playing around with airflow. You can run the following docker commands to stop and remove your docker containers.

```bash
# Stop docker containers
# (docker stop [container_name], docker_rm [container_name)
docker stop my_postgres
docker rm my_postgres
docker volume rm my_dbdata
```



### <center> More About Airflow <center>

Everything after this section is just bonus airflow content. Items that you don't necessarily need to run  this example but information that will helpful in getting out the most from airflow your needs.

### Airflow Command Line

Use this command to set a dag to be completed without running it
```bash
airflow run the_pipeline run_task 2019-07-27 -m
```

Use this command to set a backfill dags to be completed without running it
```bash
airflow backfill the_pipeline -s 2019-07-27 -e 2019-07-20 -m  --dry_run
```

There will be time when I take the airflow scheduler down for testing and updates. When I start dhe scheduler up again I don't want it to start bacfill automatically because I don't ant it pining our API all the time.

Therefore I will use backfill to start populate the database a date range of "marked success fulljob."

```bash
airflow backfill the_mark_pipeline -s 2019-07-27 -e 2019-07-30 -m --verbose
```


### General Notes

As I learn more through my experimentation. I will be adding to these notes below.

- You can modify Airflow paths and DAG locations in the Airflow config file.
- If you are running bash script using the Bash Operator place an extra space at the end of the Python script.
- If you modify or add a DAG to Airflow, it can take up to 5 minutes so show up in the web server.
- If you change the name of a DAG, unlink the DAG in Airflow before renaming it within the Python file.


### Sources

- [Airflow Documentation](https://airflow.apache.org/)
- [Postgres Docker Container Setup](https://www.saltycrane.com/blog/2019/01/how-run-postgresql-docker-mac-local-development///)
- [Postgres Connection String](https://airflow.apache.org/howto/connection/postgres.html)
