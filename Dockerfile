FROM docker.io/library/maven:3.8.1-openjdk-8-slim AS MAVEN_TOOL_CHAIN
ARG RELEASE="0.0.1-SNAPSHOT"
ARG SPRINGBOOT_APP_JAR="consumer-0.0.1-SNAPSHOT.jar"
COPY pom.xml /usr/src/app/pom.xml
COPY src /usr/src/app/src
WORKDIR /usr/src/app
RUN mvn clean install -Dmaven.test.skip=true


FROM docker.io/adoptopenjdk/openjdk11:jdk-11.0.11_9-alpine-slim

# set configurable user group
ARG UNAME=appuser
ARG UID=860
ARG GID=860
ARG APP_HOME=/usr/local/appuser

# set environment properties for springboot configuration
ENV JAVA_OPTS='-Xms1g -Xmx1g' \
    SERVER_PORT=8080 \
    APP_HOME=${APP_HOME} \
    SPRINGBOOT_APP_JAR="consumer-0.0.1-SNAPSHOT.jar"

# create user group and user
RUN addgroup --gid "$GID" "$UNAME" \
    && adduser \
    --disabled-password \
    --gecos "" \
    --home "$APP_HOME" \
    --ingroup "$UNAME" \
    --uid "$UID" \
    --shell /bin/sh "$UNAME"

# Update system packages
RUN apk upgrade --no-cache && \
    apk add --no-cache bash

# setting workdir
WORKDIR $APP_HOME

# copy app contents
COPY --from=MAVEN_TOOL_CHAIN /usr/src/app/target/${SPRINGBOOT_APP_JAR} ${APP_HOME}

# switch user and set environment
USER $UNAME

# Springboot App port
EXPOSE 8080

ENTRYPOINT exec java $JAVA_OPTS -jar ${SPRINGBOOT_APP_JAR}
