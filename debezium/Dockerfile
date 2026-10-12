# Debezium Kafka Connect + driver JDBC de Oracle.
# El driver de Oracle no viene incluido por licencia: lo bajamos de Maven Central.
FROM quay.io/debezium/connect:3.0

ARG OJDBC_VERSION=23.9.0.25.07
RUN curl -fsSL -o /kafka/connect/debezium-connector-oracle/ojdbc11-${OJDBC_VERSION}.jar \
    https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc11/${OJDBC_VERSION}/ojdbc11-${OJDBC_VERSION}.jar
