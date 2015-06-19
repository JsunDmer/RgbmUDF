if [[ -f results/sj_gbm_test.log ]]; then
        rm results/sj_gbm_test.log
fi

if [[ -f results/sj_gbm_test_results.log ]]; then
        rm results/sj_gbm_test_results.log
fi

hive -e "set hive.cli.print.header=true;select * from temp_bigdata.sj_gbm_test" > results/sj_gbm_test.log;
hive -e "set hive.cli.print.header=true;select * from temp_bigdata.sj_gbm_test_results" > results/sj_gbm_test_results.log;
