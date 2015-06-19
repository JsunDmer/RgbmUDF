#!/bin/bash

# use build.xml

# use ant -verbose to see build porgress
#ant -Dhadoop.home=/Users/teyuan/tedyuan/SVN/4build/usr/lib/hadoop -Dhive.home=/Users/teyuan/tedyuan/SVN/4build/apache/hive ted-udf
ant -Dhadoop.home=build.jars/home/vipshop/platform/hadoop/share/hadoop/common -Dhive.home=build.jars/home/vipshop/platform/hive ted-udf
