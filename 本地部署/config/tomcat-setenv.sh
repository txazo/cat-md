export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_351.jdk/Contents/Home
export CAT_HOME=/data/appdatas/cat
CATALINA_OPTS="$CATALINA_OPTS -server -DCAT_HOME=$CAT_HOME -Xms1G -Xmx1G -XX:PermSize=128m -XX:MaxPermSize=128m"
