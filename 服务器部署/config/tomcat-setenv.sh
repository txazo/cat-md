export JAVA_HOME=/cat/java
export CAT_HOME=/data/appdatas/cat
CATALINA_OPTS="$CATALINA_OPTS -server -DCAT_HOME=$CAT_HOME -Xms1500m -Xmx1500m -XX:PermSize=256m -XX:MaxPermSize=256m"
