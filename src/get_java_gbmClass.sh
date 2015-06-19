#!/bin/bash

Rscript getGBMoutput.R $1;

if [[ ! -f gbm_output.txt ]]; then
	echo 'not get gbm from R';
	exit;
fi

./gbm_code_transfer.py -i gbm_output.txt -n dm_gbm -t 1 > dm_gbm.java
./gbm_code_transfer.py -i gbm_output.txt -n dm_gbm -t 2 > dm_gbm_UDF.java

mv gbm_output.txt ../model
mv dm_gbm*.java ../udf/src/com/vipshop/hadoop/platform/hive/

pushd ../udf
./build.sh
popd

echo 'finish work!';
