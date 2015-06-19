library(data.table)
testdata = fread("/home/bigdata/gbm_test_file//results//sj_gbm_test.log",header=T)
results = read.table("/home/bigdata/gbm_test_file//results//sj_gbm_test_results.log",header=T)

colnames(testdata) = gsub("[^.]*\\.(.*)","\\1",colnames(testdata))
colnames(results) = gsub("[^.]*\\.(.*)","\\1",colnames(results))

load("/home/jian02sun/personal_order_20140717.Rdata")

testdata$bs_flash_purchase = as.factor(as.character(testdata$bs_flash_purchase))
testdata$bs_sale_style = as.factor(as.character(testdata$bs_sale_style))
testdata$bs_warehouse = as.factor(as.character(testdata$bs_warehouse))
testdata$bs_gift_between = as.numeric(as.character(testdata$bs_gift_between))
testdata$bs_purchase_num = as.numeric(as.character(testdata$bs_purchase_num))
testdata$bs_median_price = as.numeric(as.character(testdata$bs_median_price))

testdata$bs_active_type_name = as.factor(testdata$bs_active_type_name)
testdata$bs_sex = as.factor(testdata$bs_sex)
testdata$pb_level = as.factor(testdata$pb_level)
testdata$is_same_sex = as.factor(testdata$is_same_sex)


# testdata2 = testdata[,personal_order_20140717$var.names]

library(gbm)

testdata$test_prd = predict(personal_order_20140717,newdata = testdata,type="response",n.trees = 100)

combine = merge(testdata[,c("user_id","brand_id","test_prd")],results)
combine$diff = abs(combine$test_prd - combine$score)
