#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Created on Wed Aug 27 22:49:58 2014

@author: sunjian
"""

#############################################################

import pandas as pd
import numpy as np
import sys
import getopt

#############################################
### CREATE JAVA GBM TREE CODE FOR HIVE UDF  
#############################################

class GBMTreeNodeParse:
    
    def __init__(self,filepath):
        # 获取文件
        f = open(filepath)
        self.content = [ line.rstrip() for line in f]
        f.close()
               
    def GBMModelbaseInfo(self):
        self.indexNameList = [ ind for ind in range(len(self.content)) if '*****' in self.content[ind] ]
        # 得到变量名 和 factor levels
        p = self.getContentIndex('Varible Names')
        varibleNames = [self.content[i].split('\t') for i in range(p[0]+1,p[1])]
        self.featuresName = [ v[1]  for v in varibleNames]
        checkIsFactor = [ i for i in range(len(varibleNames)) if int(varibleNames[i][2]) > 0]
        # 用dict得到
        self.factorDict = dict([(self.featuresName[i],varibleNames[i][3].split(', ')) for i in checkIsFactor])
        
        # 得到树的信息
        p = self.getContentIndex('Decision trees')
        self.treenode_index = [ ind for ind in range(p[0],p[1]) if 'SplitVar' in self.content[ind] ]
        self.treenodeName = ('id\t' + self.content[self.treenode_index[0]]).split('\t') 

        # 得到分裂levels        
        p = self.getContentIndex('Model csplits')
        self.factorSplit = [self.content[i].split('\t')[1] for i in range(p[0]+1,p[1])] 
        
        p = self.getContentIndex('Response Name')
        self.targetName = self.content[p[0] + 1].split('\t')[1]

        # 初始值
        p = self.getContentIndex('Model output') 
        self.initF = float( self.content[p[0]+1].split('\t')[1] )

        # p = self.getContentIndex('Variable Importance')       
        # p = s.getContentIndex('Model parameters') 
        return

    def getContentIndex(self,matchname):   
        begin = [ i for i in self.indexNameList if matchname in self.content[i] ][0]
        place = self.indexNameList.index(begin)
        if len(self.indexNameList) == place + 1:
            end = len(self.content)
        else:
            end = self.indexNameList[place + 1]
        return (begin,end)

    # 得到树的node 以 pd形式存储
    def createTreeNode(self,index):
        if index < len(self.treenode_index) -1:
            treeContent = [ self.content[i].split('\t') for i in range(self.treenode_index[index]+1, self.treenode_index[index+1]) ]
        else:
            treeContent = [ self.content[i].split('\t') for i in range(self.treenode_index[index]+1, len(self.content)) ]            
        treeContent = pd.DataFrame(treeContent,columns=self.treenodeName)
        p =[]
        for i in treeContent['SplitVar']:
            if int(i)==-1:
                p.append("")
            else:
                p.append(self.featuresName[int(i)])    
        treeContent['SplitVar'] = p
        return treeContent

    def GetTree(self, treeContent, id):
        tr = treenode(treeContent,self.factorDict,self.factorSplit,id)   
        if treeContent['SplitVar'][id] =='': 
            return treenode(treeContent,self.factorDict,self.factorSplit,id,-1)
        tr.leftnode  = self.GetTree(treeContent, int(treeContent['LeftNode'][id]))
        tr.rightnode  = self.GetTree(treeContent, int(treeContent['RightNode'][id]))
        tr.missingnode = self.GetTree(treeContent, int(treeContent['MissingNode'][id]))
        return tr

    def SingleTreeNodeToJava(self,trr,span):
        if trr.status == -1:  
            print '\t' * (span-1) + "    return %s;" %trr.splitCodePred
            return         
        for typ in range(3):
            if typ == 0:
                if trr.splitVarType == None:
                    print '\t' * span + "if ( %s < %s )" %(trr.splitVar,trr.splitCodePred)
                else:
                   include = [ trr.splitVarType[i] for i in range(len(trr.splitCodePred)) if trr.splitCodePred[i] == '-1' ] 
                   r = ",".join(['"%s"' %rr for rr in include ])
                   print '\t' * span + "if ( isIn ( %s, new String[] { %s } ) )" %(trr.splitVar, r)
                print '\t' * span + "{"
                self.SingleTreeNodeToJava(trr.leftnode, span + 1)
                print '\t' * span + "}"            
            if typ == 1:
                if trr.splitVarType == None:
                    print '\t' * span + "else if ( %s >= %s )" %(trr.splitVar,trr.splitCodePred)
                else:
                   include = [ trr.splitVarType[i] for i in range(len(trr.splitCodePred)) if trr.splitCodePred[i] == '1' ] 
                   r = ",".join(['"%s"' %rr for rr in include ])
                   print '\t' * span + "else if ( isIn ( %s, new String[] { %s } ) )" %(trr.splitVar, r)
                print '\t' * span + "{"
                self.SingleTreeNodeToJava(trr.rightnode, span + 1)
                print '\t' * span + "}" 
            if typ == 2:   
                print '\t' * span + "else "
                print '\t' * span + "{"
                self.SingleTreeNodeToJava(trr.missingnode, span + 1)  
                #print '\t' * span + "    return %s" %trr.missingnode.splitCodePred
                print '\t' * span + "}"                                      
        return

    ## 打印 tree using java code
    ## TreeCount 树个数
    def PrintTreeToJava(self):      
        for treeid in range(len(self.treenode_index)):
            print "double Tree%s()\n{" %(treeid + 1)
            treeContent = self.createTreeNode(treeid)
            trr = self.GetTree(treeContent, 0)
            self.SingleTreeNodeToJava(trr,1)
            print "}\n\n"
        return

    def PrintTailToJava(self):     
        treeStr = "+".join([" Tree%s() " %i for i in range(1,len(self.treenode_index)+1) ])    
        print "double treenet()\n{"
        print "\n   return %s = 1.0/(1.0 + Math.exp(-(%s + %s)));\n}\n\n\n};" %(self.targetName,self.initF,treeStr)
        return

    def PrintHeadToJava(self,ModelName):
        print "//Total %s tree(s)\
        \npackage com.vipshop.hadoop.platform.hive;\
        \n\npublic class %s {\
        \n\n // Total %s factors\n \
        \n/************  \
         \n* PREDICTORS  \
         \n************/\
        \n\n//model input: continous variables\n"  %(len(self.treenode_index),ModelName,len(self.featuresName))    
        
        # 申明 continous variables 
        var = ", ".join(['%s' %rr for rr in [ f for f in self.featuresName if f not in self.factorDict.keys()] ])
        
        # 申明 categorical variables 
        print "double\n       %s;\n\n// model input: categorical variables\n"  %var      
        var = ", ".join(['%s' %rr for rr in self.factorDict.keys()])
        
        print "String\n       %s;\n\n"  %var
        
        print "// model input: end variable declaration\n"

        ## isIn function        
        print 'private final static boolean isIn( String var, String sva[] )\n{ \
              \n  if(null == var || var.length() < 1) return false;\
              \n  if(null == sva || sva.length < 1) { System.err.println("Code gen error, passing in empty categorical values"); return false; }\
              \n  for(int i = 0; i < sva.length; i++) {\
              \n       if(var.equals(sva[i]))\n         return true;\n       }\n  return false;\n}\n'

        ## String isNA function
        print "private final static boolean isNA( String var )\n{"
        print '   return null == var || var.length() < 1 || var.equals("NA");\n}\n'
        
        ## Double isNA function
        print "private final static boolean isNA( Double var )\n{"
        print '   return null == var;\n}\n'
        
        # commit
        print "/************\n * Here come the treenets in the grove.  A shell for calling them\n * appears at the end of this source file.\n ************/"
        # target
        print "private double %s;\n"  %self.targetName       
        return

    ### print all java code    
    def PrintTotalToJava(self,ModelName):
        self.PrintHeadToJava(ModelName)
        self.PrintTreeToJava()
        self.PrintTailToJava()
        return

    def CreateGBMUDF(self,gbmName): 
        print "package com.vipshop.hadoop.platform.hive;\n\nimport org.apache.hadoop.hive.ql.exec.UDF;\nimport org.apache.hadoop.hive.ql.exec.Description;\n\n"
        print "  /**\n   * Model_target_UDF\n   *\n   **/"
        print "public class %s_UDF extends UDF {\n" %gbmName
        print "private static %s gbm = new %s();\n" %(gbmName,gbmName)
        print "public double evaluate(\n\t// doubles"
    
        # 申明 continous variables 
        print ",\n".join(['\tDouble %s' %rr for rr in [ f for f in self.featuresName if f not in self.factorDict.keys()] ]) + ',\n// Strings'   
        # 申明 categorical variables       
        print ",\n".join(['\tString %s' %rr for rr in self.factorDict.keys()]) + '\n) {\n'
    
        print "\n".join(['\t%s.%s = %s.doubleValue();' %('gbm',rr,rr) for rr in [ f for f in self.featuresName if f not in self.factorDict.keys()] ]) 
    
        print "\n".join(['\t%s.%s = ( null == %s ? " " : %s );' %('gbm',rr,rr,rr) for rr in self.factorDict.keys()]) 
        
        print "\n\treturn gbm.treenet();\n\t}\n}"
        return
        
    def classify_single(self, newX, treeNode, step):   
        if treeNode.status == -1:
            print "<-----terminalNodeId = {},finalprd={}----->".format(step, treeNode.id, round(float(treeNode.Prediction),4))
            return
        if treeNode.splitVar in self.factorDict.keys():
            if newX[treeNode.splitVar] in list(['','NULL']):
                print "\t" * step + "==>step={}: go_missingNode={} -->split={},prd={}".format(step,treeNode.missingnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.missingnode, step + 1)                
            elif newX[treeNode.splitVar] in treeNode.splitCodePred:
                print "\t" * step + "==>step={}: go_left={} -->split={},prd={}".format(step,treeNode.leftnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.leftnode, step + 1)
            else:
                print "\t" * step + "==>step={}: go_right={} -->split={},prd={}".format(step,treeNode.rightnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.rightnode, step + 1)                
        else:
            val = float(newX[treeNode.splitVar])
            if np.isnan(val):
                print "\t" * step + "==>step={}: go_missingNode={} -->split={},prd={}".format(step,treeNode.missingnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.missingnode, step + 1)                
            elif val < treeNode.splitCodePred:
                print "\t" * step + "==>step={}: go_left={} -->split={},prd={}".format(step,treeNode.leftnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.leftnode, step + 1)
            else:
                print "\t" * step + "==>step={}: go_right={} -->split={},prd={}".format(step,treeNode.rightnode.id,treeNode.splitVar,round(float(treeNode.Prediction),4))
                self.classify_single(newX, treeNode.rightnode, step + 1)                 
        return

    def prd_single_user(self, data, treeNode, user_id, brand_id):
        try:
            newX = data[(data.user_id == user_id) & (data.brand_id == brand_id)]   
        except:
            print "wrong"
            return
        l = len(newX)            
        if l == 0:
            print "can not match data, sorry, you should check!"
            return
        if l > 1:
            print "can not handle more then one input data!"
            return 
        newX = newX.iloc[0]                
        self.classify_single(newX, treeNode, 0)             
        return

def load_prd_data(testfile):
    data = []
    with open(testfile) as f:
        header = f.readline().rstrip().split(',')
        for line in f:
            data.append(line.rstrip().split(','))     
    data = pd.DataFrame(data,columns=header)
    return data


#############################################
### CREATE TREE NODE CLASS
#############################################

class treenode:
    def __init__(self,treeContent,factorDict,factorSplit,id,status=0):
        
        self.id = id
        self.splitVar = treeContent['SplitVar'][id]
        self.Prediction = treeContent['Prediction'][id]
        self.ErrorReduction = treeContent['ErrorReduction'][id]
           
        if self.splitVar in factorDict.keys():
            self.splitVarType = factorDict[self.splitVar]
            self.splitCodePred = factorSplit[int(treeContent['SplitCodePred'][id])].split(',')
            self.splitCodePred = [ int(h.strip()) for h in self.splitCodePred ]
            self.splitCodePred = [ self.splitVarType[i] for i in xrange(len(self.splitVarType)) if self.splitCodePred[i] == -1 ]
        else:
            self.splitCodePred = treeContent['SplitCodePred'][id]
            self.splitVarType = None
            
        self.leftnode    = None
        self.rightnode   = None
        self.missingnode = None      
        self.status = status

def inred(s,color):
    return"%s[%s;2m%s%s[0m"%(chr(27), color, s, chr(27))

### PRINT SINGLE TREE
def printTree(trr,span,typ):
    if trr.status<>-1: 
        if trr.splitVarType == None:
            print '\t' * span + '├── %s=%s,splitName=%s,splitvalue=%f,prd=%s\n' %(typ,trr.id,inred(trr.splitVar,42),round(float(trr.splitCodePred),4),inred(round(float(trr.Prediction),5),44))    
        else:
            print '\t' * span + '├── %s=%s,splitName=%s,value=%s\n' %(typ,trr.id,inred(trr.splitVar,42),','.join(trr.splitCodePred))             
        printTree(trr.leftnode, span + 1, "leftNode")
        printTree(trr.rightnode, span + 1, "rightNode")
        printTree(trr.missingnode, span + 1, "missingNode")
    else:
        print '\t' * span + '├── predValue=%s\n' %(inred(round(float(trr.splitCodePred),4),44))
        return     

def usage():
    print '''Help Information:
    -h | --help: Show help information
    -i | --input: R gbm output
    -n | --name: java classname and udf classname
    -t | --type: t=1 output java code t=2 udf code 
    
    -p | --newdata: 输入数据，CSV文件，带有字段
    -c | --cond: 输入形式："user_i,brand_id"    
    -d | --nodeid: 打印第几个树    
    
    '''

if __name__ == "__main__":
    try:  
        opts,args = getopt.getopt(sys.argv[1:], "hi:n:t:p:c:d:", ["help", "input=","name=","type=","newdata=","cond=","nodeid"])
        for o,v in opts:  
            if o in ("-h", "--help"):
                usage()
                sys.exit(1);
            if o in ("-i", "--input"):
                filePath = v
            if o in ("-n", "--name"):
                modelName = v
            if o in ("-t", "--type"):
                typ = int(v)
            if o in ("-p", "--newdata"):
                testfile = v
            if o in ("-c", "--cond"):
                cond = v.split(',')
            if o in ("-d", "--nodeid"):
                nid = int(v)

    except getopt.GetoptError:  
        print("getopt error!");  
        usage();  
        sys.exit(1);
    # load file
    s = GBMTreeNodeParse(filePath)
    # init info
    s.GBMModelbaseInfo()  
    # 运行
    if typ == 1:
        s.PrintTotalToJava(modelName)
    elif typ == 2:
        s.CreateGBMUDF(modelName)
    else:
        if nid == None:
            nid = 0      
        treeContent = s.createTreeNode(nid) 
        treeNode = s.GetTree(treeContent,0)
        print "============  打印树  =============="
        printTree(treeNode,1,"rootNode")
       
        if testfile != None and cond != None:
            dd = load_prd_data(testfile)
            print "\n预测用户id={}，专场id={}\n".format(cond[0],cond[1])
            s.prd_single_user(dd, treeNode, cond[0],cond[1])

