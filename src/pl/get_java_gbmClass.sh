#!/bin/bash

Rscript getGBMoutput.R $1;

if [[ ! -f gbm_output.txt ]]; then
	echo 'not get gbm from R';
	exit;
fi

./parserma.pl gbm_output.txt > gbm_output.xml;

if [[ ! -f gbm_output.xml ]]; then
	echo 'not get gbm_output.xml from perl';
	exit;
fi

xsltproc -param cpphead 1 pmml.xsl gbm_output.xml > Model_target.java;
for i in `seq 2 99`; do xsltproc -param tree $i pmml.xsl gbm_output.xml >> Model_target.java; done;
xsltproc -param cpptail 1 -param tree 100 pmml.xsl gbm_output.xml >> Model_target.java;

if [[ ! -f Model_target.java ]]; then
	echo 'not get gbm from R';
	exit;
fi

./generate_hive_udf.pl Model_target.java Model_target

mv gbm_output.* ../model/
mv Model_target*.java ../udf/src/com/vipshop/hadoop/platform/hive/

pushd ../udf
./build.sh
popd

echo 'finish work!';
