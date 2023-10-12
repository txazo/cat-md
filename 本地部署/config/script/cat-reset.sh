#!/bin/bash

current=$(pwd)

rm -rf /data/appdatas
rm -rf /data/applogs
mkdir -p /data/appdatas/cat
mkdir -p /data/applogs/cat
chmod -R 777 /data/appdatas
chmod -R 777 /data/applogs

cd $current
cp ../client.xml /data/appdatas/cat
cp ../server.xml /data/appdatas/cat
cp ../datasources.xml /data/appdatas/cat
cp ../tomcat-setenv.sh ~/cat/tomcat/apache-tomcat-9.0.73/bin/setenv.sh
