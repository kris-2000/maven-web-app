FROM tomcat:9-jre17-temurin-noble
LABEL maintainer="KRISHNA PRASAD S"
RUN rm -rf /usr/local/tomcat/webapps/*
COPY target/maven-web-app.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
