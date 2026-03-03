FROM tomcat:10.1
COPY /target/*.war /usr/local/tomcat/webapps/wwp-1.0.0.war
