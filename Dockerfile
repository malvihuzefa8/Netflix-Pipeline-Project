FROM tomcat

# Remove default Tomcat apps (ROOT, docs, examples, manager)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR from Jenkins workspace (produced by mvn package)
COPY target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8081

CMD ["catalina.sh", "run"]
