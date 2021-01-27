FROM maven:3-openjdk-8 AS build-env
ADD . /build
WORKDIR /build
RUN mvn clean package

FROM tomcat:8-alpine
LABEL maintainer=”olivier.sgoifo@publicissapient.com”

RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=build-env /build/target/clickCount.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]