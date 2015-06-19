#!/usr/bin/env Rscript

# 从R-GBM模型提取参数
args <- commandArgs(TRUE)
library(gbm)
# load parserma.r code
source("parserma.r")
# load model
load(args[1])
# output model 
gbm_savemodel(get(sub(".*/([^/]*)\\.Rdata","\\1",args[1])),paste("gbm_output.txt",sep=""))

