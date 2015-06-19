#use the following code to save a gbm model (ma) to local file (outputFn)
gbm_savemodel <- function(ma, outputFn) {
  write.table("*****Varible Names", file=outputFn,append=F,sep="\t",quote=F,col.names=F)
#  write.table(ma$var.names, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
#  lvls = unlist(lapply(ma$var.levels, function(x) toString(unlist(x))))
  lvls = unlist(lapply(ma$var.levels, function(x) gsub("\n","\\\\n",gsub("\t","\\\\t",toString(x)))))
  data.frame(ma$var.names, ma$var.type, lvls) -> mavars
  write.table(mavars, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Response Name", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(ma$response.name, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Variable Importance", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(summary(ma, plotit=FALSE), file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Fitting Status", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(as.matrix(summary(ma$fit)), file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Train error by trees", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(ma$train.error, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Validation error by trees", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(ma$valid.error, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Improvement by trees", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(ma$oobag.improve, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Model parameters", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  data.frame(ma$distribution, ma$train.fraction, ma$bag.fraction, ma$shrinkage, ma$nTrain, ma$n.trees) -> masum
  masum$ma.nTreeTrain <- ma$nTrain*ma$bag.fraction
  suppressWarnings(write.table(masum, file=outputFn,append=T,sep="\t",quote=F,col.names=T))
  write.table("*****Model output", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table(data.frame(ma$initF), file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Model csplits", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  csplits = unlist(lapply(ma$c.splits, function(x) toString(x)))
  write.table(csplits, file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  write.table("*****Decision trees", file=outputFn,append=T,sep="\t",quote=F,col.names=F)
  for(i in 1:ma$n.trees) {suppressWarnings(write.table(pretty.gbm.tree(ma, i.tree=i), file=outputFn,append=T,sep="\t",quote=F,col.names=T))}
}

