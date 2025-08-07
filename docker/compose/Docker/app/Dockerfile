# Multistage Dockerfile for vProfile application
# This Dockerfile builds the vProfile application using Maven and deploys it on Tomcat.
# The build stage compiles the application, and the final stage runs it in a Tomcat server.

FROM maven:3.9.9-eclipse-temurin-21-jammy as BUILD_IMAGE

RUN git clone https://github.com/hkhcoder/vprofile-project.git && cd vprofile-project && git checkout containers && mvn install -DskipTests

FROM tomcat:10-jdk21
RUN rm -rf /usr/local/tomcat/webapps/* 
COPY --from=BUILD_IMAGE vprofile-project/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]