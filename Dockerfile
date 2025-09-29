FROM tomcat:9-jdk17

# Remove default ROOT application
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Download and deploy WAR file
ADD https://github.com/Prani2018/dockerbuilds/raw/main/simple-web-app.war /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
