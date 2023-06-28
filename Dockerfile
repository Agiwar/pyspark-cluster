# builder step used to download and configure spark environment
FROM openjdk:11.0.11-jre-slim-buster as builder

# Add Dependencies for PySpark
RUN apt-get update && \
    apt-get install -y --no-install-recommends cron curl vim wget software-properties-common ssh net-tools ca-certificates python3 python3-pip

# Python packages
COPY requirements.txt .

RUN pip3 install --upgrade pip setuptools && \
    python3 -m pip install -r requirements.txt

#  Spark Versions
ARG SPARK_VERSION="3.4.0"
ARG HADOOP_VERSION="3"

ENV SPARK_HOME="/opt/spark" \
    PYTHONPATH="${PYTHONPATH}:${SPARK_HOME}/apps" \
    PYTHONHASHSEED="1" \
    TZ="Asia/Taipei"

# Download Spark
RUN wget --no-verbose -O apache-spark.tgz "https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" && \
    mkdir -p ${SPARK_HOME} && \
    tar -xf apache-spark.tgz -C ${SPARK_HOME} --strip-components=1 && \
    rm -f apache-spark.tgz


# Apache spark environment
FROM builder as apache-spark

WORKDIR ${SPARK_HOME}

# JDBC connectors version
ARG MSSQL_JDBC_VERSION="12.2.0.jre11"
ARG MYSQL_JDBC_VERSION="8.0.20"
ARG CLICKHOUSE_JDBC_VERSION="0.3.2-patch11"

# Download JDBC Connectors
RUN wget --no-verbose -O mssql-jdbc.jar "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_JDBC_VERSION}/mssql-jdbc-${MSSQL_JDBC_VERSION}.jar" && \
    wget --no-verbose -O mysql-jdbc.jar "https://repo1.maven.org/maven2/mysql/mysql-connector-java/${MYSQL_JDBC_VERSION}/mysql-connector-java-${MYSQL_JDBC_VERSION}.jar" && \
    wget --no-verbose -O clickhouse-jdbc.jar "https://github.com/ClickHouse/clickhouse-java/releases/download/v${CLICKHOUSE_JDBC_VERSION}/clickhouse-jdbc-${CLICKHOUSE_JDBC_VERSION}-all.jar" && \
    mv mssql-jdbc.jar mysql-jdbc.jar clickhouse-jdbc.jar ${SPARK_HOME}/jars

# Spark-specific environment variables
ENV SPARK_MASTER_PORT=7077 \
    SPARK_WORKER_PORT=7000 \
    SPARK_MASTER_WEBUI_PORT=8080 \
    SPARK_WORKER_WEBUI_PORT=8080 \
    SPARK_MASTER="spark://spark-master:7077"

EXPOSE 8080 7077

CMD ["/bin/bash"]