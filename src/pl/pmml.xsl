<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" omit-xml-declaration="yes"/>


<xsl:param name="tree" select="1"/> 
<xsl:param name="cpp" select="2"/> 
<xsl:param name="cpphead" select="0"/> 
<xsl:param name="cpptail" select="0"/> 
<xsl:param name="withstats" select="0"/> 
<xsl:param name="maxdepth" select="1000000"/> 

<xsl:template match="/PMML">
  <xsl:apply-templates select="Header"/>
  <xsl:apply-templates select="DataDictionary"/>
  <xsl:apply-templates select="MiningModel"/>

  <xsl:if test="$tree &gt; 0">
  <xsl:call-template name="ifcpp">
    <xsl:with-param name="ifcpp"><xsl:text> // </xsl:text></xsl:with-param>
    <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
  </xsl:call-template>
  <xsl:call-template name="getNodeScores">
    <xsl:with-param name="treeid" select="$tree"/>
  </xsl:call-template>
  </xsl:if>

  <xsl:text>&#xa;</xsl:text>
  
  <!--xsl:if test="$tree = count(MiningModel/DecisionTree)"-->
  <xsl:if test="$cpptail">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp">
        <xsl:text>&#xa;double treenet()&#xa;{&#xa;    return </xsl:text>
        <xsl:value-of select="/PMML/MiningModel/Output/OutputField[@name='RESPONSE']/@targetField"/>
        <xsl:text> = </xsl:text>
        <xsl:if test="$cpp = 1 and MiningModel/@distribution='bernoulli'"><xsl:text>1.0/(1.0 + exp(-(</xsl:text></xsl:if>
        <xsl:if test="$cpp = 2 and MiningModel/@distribution='bernoulli'"><xsl:text>1.0/(1.0 + Math.exp(-(</xsl:text></xsl:if>
        <xsl:value-of select="MiningModel/Output/OutputField[@name='initF']/@value"/><xsl:text> + </xsl:text>
        <xsl:text>&#xa;       </xsl:text>
        <xsl:for-each select="MiningModel/DecisionTree">
          <xsl:if test="position() &lt;= $tree">
          <xsl:if test="position() != 1"><xsl:text> + </xsl:text></xsl:if>
          <xsl:if test="(position() mod 5) = 0"><xsl:text>&#xa;       </xsl:text></xsl:if>
          <xsl:value-of select="@modelName"/><xsl:text>()</xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:if test="MiningModel/@distribution='bernoulli'"><xsl:text>)))</xsl:text></xsl:if>
        <xsl:text>;&#xa;}&#xa;&#xa;};&#xa;</xsl:text>
        <xsl:if test="$withstats">
        <xsl:text>&#xa;void printallnodes()&#xa;{</xsl:text>
        <xsl:for-each select="MiningModel/DecisionTree">
        <xsl:text>&#xa;       printnodes(</xsl:text><xsl:value-of select="position()"/><xsl:text>);</xsl:text>
        </xsl:for-each>
        <xsl:text>&#xa;}&#xa;</xsl:text>
        </xsl:if>
      </xsl:with-param>
      <xsl:with-param name="else"></xsl:with-param>
    </xsl:call-template>
  </xsl:if>

</xsl:template>

<xsl:template match="Header">
</xsl:template>

<xsl:template match="DataDictionary">
  <!--xsl:value-of select="@numberOfFields"/>
  <xsl:for-each select="DataField">
    <xsl:value-of select="@dataType"/><xsl:text> </xsl:text><xsl:value-of select="@name"/><xsl:text>,&#xa;</xsl:text>
  </xsl:for-each-->
</xsl:template>

<xsl:template match="MiningModel">
  <!--xsl:if test="$tree = 1"-->
  <xsl:if test="$cpphead">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text>//</xsl:text></xsl:with-param>
      <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
    </xsl:call-template>
    <xsl:text>Total </xsl:text>
    <xsl:value-of select="count(DecisionTree)"/>
    <xsl:text> tree(s)</xsl:text>
    <xsl:if test="$cpp = 1">
    <xsl:text>&#xa;&#xa;#include &lt;stdio.h&gt;&#xa;#include &lt;math.h&gt;&#xa;#include &lt;string.h&gt;&#xa;&#xa;struct Model_</xsl:text>
    </xsl:if>
    <xsl:if test="$cpp = 2">
    <xsl:text>&#xa;package com.vipshop.hadoop.platform.hive;&#xa;&#xa;public class Model_</xsl:text>
    </xsl:if>
    <xsl:value-of select="/PMML/MiningModel/Output/OutputField[@name='RESPONSE']/@targetField"/>
    <xsl:text> {&#xa;</xsl:text>
  
    <xsl:call-template name="getMiningFields"></xsl:call-template>
  </xsl:if>

  <xsl:for-each select="DecisionTree[position()=$tree]">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp">
        <xsl:if test="$withstats">
          <xsl:text>#define TREE</xsl:text><xsl:value-of select="$tree"/><xsl:text>NODES  </xsl:text>
          <xsl:value-of 
            select="count(/PMML/MiningModel/DecisionTree[$tree]//Node/@score)+1"/>
          <xsl:text>&#xa;</xsl:text>
          <xsl:text>#define TREE</xsl:text><xsl:value-of select="$tree"/><xsl:text>NODEIDSHIFT  </xsl:text>
          <xsl:value-of 
            select="count(/PMML/MiningModel/DecisionTree[$tree]//Node[substring(@id,1,1)='T']/@score)"/>
          <xsl:text>&#xa;</xsl:text>
          <xsl:text>unsigned int node</xsl:text><xsl:value-of select="$tree"/>
          <xsl:text>[TREE</xsl:text><xsl:value-of select="$tree"/><xsl:text>NODES] = {0};</xsl:text>
          <xsl:text>&#xa;</xsl:text>
          <xsl:text>unsigned int positivenode</xsl:text><xsl:value-of select="$tree"/>
          <xsl:text>[TREE</xsl:text><xsl:value-of select="$tree"/><xsl:text>NODES] = {0};</xsl:text>
          <xsl:text>&#xa;&#xa;</xsl:text>
        </xsl:if>
        <xsl:text>double </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
    </xsl:call-template>

    <xsl:value-of select="@modelName"/>

    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text>()</xsl:text></xsl:with-param>
      <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
    </xsl:call-template>

    <xsl:text>&#xa;</xsl:text>
    <xsl:for-each select="Node">
      <xsl:call-template name="RenderNode">
        <xsl:with-param name="node" select="."/>
        <xsl:with-param name="level" select="0"/>
        <xsl:with-param name="indent"/>
        <xsl:with-param name="totalcount" select="@recordCount"/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:for-each>
  
</xsl:template>

<xsl:template name="RenderNode">
<xsl:param name="node" />
<xsl:param name="level" />
<xsl:param name="indent" />
<xsl:param name="totalcount" />
  <xsl:call-template name="indent"><xsl:with-param name="depth" select="$level"/></xsl:call-template>
  <xsl:variable name="pred">
    <xsl:choose>
    <xsl:when test="CompoundPredicate/SimpleSetPredicate">
    <xsl:apply-templates select="CompoundPredicate/SimpleSetPredicate"/>
    </xsl:when>
    <xsl:otherwise>
    <xsl:apply-templates select="CompoundPredicate/SimplePredicate"/>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
  <xsl:when test="'' = $pred and $level = 0">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text></xsl:text></xsl:with-param>
      <xsl:with-param name="else"><xsl:text>|</xsl:text></xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="'' = $pred and $level &gt; 0">
  <xsl:text>else</xsl:text>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$pred"/>
    <xsl:choose>
    <xsl:when test="CompoundPredicate/SimpleSetPredicate">
      <xsl:call-template name="getVariableImportance"><xsl:with-param name="field" select="CompoundPredicate/SimpleSetPredicate/@field"/></xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="getVariableImportance"><xsl:with-param name="field" select="CompoundPredicate/SimplePredicate/@field"/></xsl:call-template>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:otherwise>
  </xsl:choose>

  <xsl:choose>
  <xsl:when test="substring(@id,1,1)='T' and CompoundPredicate/SimplePredicate/@operator = 'isMissing'">
  </xsl:when>
  <xsl:otherwise>
  <xsl:call-template name="getTrainingSamplePopulation"><xsl:with-param name="totalcount" select="$totalcount"/><xsl:with-param name="nodecount" select="@recordCount"/></xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>

  <xsl:variable name="cnodeids">
    <xsl:if test="count($node/Node) &gt; 0">
    <xsl:text> //c(</xsl:text>
    <xsl:for-each select="$node/Node">
      <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
      <xsl:value-of select="translate(@id,'T','-')"/>
    </xsl:for-each>
    <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:variable>

  <xsl:call-template name="ifcpp">
    <xsl:with-param name="ifcpp">
  <xsl:if test="$level != 0"><xsl:text>&#xa;</xsl:text></xsl:if>
  <xsl:call-template name="indent"><xsl:with-param name="depth" select="$level"/></xsl:call-template>
  <xsl:text>{</xsl:text>
  <xsl:if test="$withstats">
    <xsl:text>&#xa;</xsl:text>
    <xsl:call-template name="indent"><xsl:with-param name="depth" select="$level+1"/></xsl:call-template>
    <xsl:text>node(</xsl:text><xsl:value-of select="$tree"/><xsl:text>, </xsl:text><xsl:value-of select="translate($node/@id,'T','-')"/><xsl:text>); </xsl:text><xsl:value-of select="$cnodeids"/>
  </xsl:if>
    </xsl:with-param>
    <xsl:with-param name="else">
  <xsl:if test="$withstats">
    <xsl:text> node(</xsl:text><xsl:value-of select="$tree"/><xsl:text>, </xsl:text><xsl:value-of select="translate($node/@id,'T','-')"/><xsl:text>); </xsl:text><xsl:value-of select="$cnodeids"/>
  </xsl:if>
    </xsl:with-param>
  </xsl:call-template>

  <xsl:if test="$node/@score != 0">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp">
  <xsl:text>&#xa;</xsl:text>
  <xsl:call-template name="indent"><xsl:with-param name="depth" select="$level+1"/></xsl:call-template>
        <xsl:text>return </xsl:text><xsl:value-of select="$node/@score"/><xsl:text>; </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else"><xsl:text> : </xsl:text><xsl:value-of select="$node/@score"/></xsl:with-param>
    </xsl:call-template>
  </xsl:if>
  <xsl:text>&#xa;</xsl:text>

  <xsl:if test="$level &lt; $maxdepth">
  <xsl:for-each select="$node/Node">
    <xsl:call-template name="RenderNode">
      <xsl:with-param name="node" select="."/>
      <xsl:with-param name="level" select="$level+1"/>
      <xsl:with-param name="indent" select="$indent"/>
      <xsl:with-param name="totalcount" select="$totalcount"/>
    </xsl:call-template>
  </xsl:for-each>
  </xsl:if>

  <xsl:if test="$cpp &gt; 0">
  <xsl:call-template name="indent"><xsl:with-param name="depth" select="$level"/></xsl:call-template>
  <xsl:text>}</xsl:text>
  <xsl:if test="$level != 0"><xsl:text>&#xa;</xsl:text></xsl:if>
  </xsl:if>
</xsl:template>

<xsl:template match="CompoundPredicate/SimplePredicate">

    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text>if ( </xsl:text></xsl:with-param>
      <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
    </xsl:call-template>

<xsl:choose>
<xsl:when test="@operator = 'isMissing'">
  <xsl:variable name="fdtype">
  <xsl:call-template name="getFieldType"><xsl:with-param name="field" select="@field"/></xsl:call-template>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="'categorical' = $fdtype">
      <xsl:call-template name="ifcpp">
        <xsl:with-param name="ifcpp"><xsl:text>isNA ( </xsl:text><xsl:value-of select="@field"/><xsl:text> ) </xsl:text></xsl:with-param>
        <xsl:with-param name="else"><xsl:value-of select="@field"/><xsl:text> is missing</xsl:text></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="ifcpp">
        <xsl:with-param name="ifcpp"><xsl:text> 1 == 0 </xsl:text></xsl:with-param>
        <xsl:with-param name="else"><xsl:value-of select="@field"/><xsl:text> is missing</xsl:text></xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:when>
<xsl:otherwise>

<xsl:value-of select="@field"/>
<xsl:choose>
<xsl:when test="@operator = 'lessThan'">
<xsl:text> &lt; </xsl:text>
</xsl:when>
<xsl:when test="@operator = 'isNotMissing'">
  <xsl:variable name="notmissing">
  <xsl:call-template name="getMissingReplacementValue"><xsl:with-param name="field" select="@field"/></xsl:call-template>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="'' = $notmissing">
      <xsl:text> != 0 </xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$notmissing"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@operator"/> 
</xsl:otherwise>
</xsl:choose>
<xsl:value-of select="@value"/>

</xsl:otherwise>
</xsl:choose>
</xsl:template>

<xsl:template match="CompoundPredicate/SimpleSetPredicate">

    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp">
        <xsl:text>const static char* compoundLiteralArrayToPassCppFunctionCantInline[] = {</xsl:text><xsl:value-of select="Array"/>};
        <xsl:text>if ( </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="ifjava">
        <xsl:text>if ( </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else"><xsl:text></xsl:text></xsl:with-param>
    </xsl:call-template>

<xsl:choose>
<xsl:when test="@booleanOperator = 'isIn'">
<xsl:text>isIn ( </xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="@booleanOperator"/>  
</xsl:otherwise>
</xsl:choose>
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp">
        <xsl:value-of select="@field"/>, <xsl:value-of select="Array/@n"/>, compoundLiteralArrayToPassCppFunctionCantInline<xsl:text> ) </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="ifjava">
        <xsl:value-of select="@field"/>, <xsl:text>new String[] {</xsl:text><xsl:value-of select="Array"/><xsl:text>} ) </xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else">
        <xsl:value-of select="@field"/>, {<xsl:value-of select="Array"/><xsl:text>} ) </xsl:text>
      </xsl:with-param>
    </xsl:call-template>
</xsl:template>

<xsl:template name="getMissingReplacementValue">
<xsl:param name="field"/>
<xsl:variable name="nm"><xsl:value-of select="$field"/></xsl:variable>
  <xsl:value-of 
    select="/PMML/MiningModel/MiningSchema/MiningField[@name=$nm]/@missingValueReplacement"/>
  <!--xsl:for-each select="/PMML/MiningModel/MiningSchema/MiningField">
    <xsl:if test="@name=$field"><xsl:value-of select="@missingValueReplacement"/></xsl:if>
  </xsl:for-each-->
</xsl:template>

<xsl:template name="getFieldType">
<xsl:param name="field"/>
<xsl:variable name="nm"><xsl:value-of select="$field"/></xsl:variable>
  <xsl:value-of
    select="/PMML/MiningModel/MiningSchema/MiningField[@name=$nm]/@variableType"/>
</xsl:template>

<xsl:template name="getVariableImportance">
<xsl:param name="field"/>
  <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text> ) </xsl:text></xsl:with-param>
      <xsl:with-param name="else">
    <xsl:text> [ </xsl:text>
  <xsl:value-of 
    select="/PMML/MiningModel/MiningSchema/MiningField[@name=$field]/@importance"/>
    <xsl:text>% ] </xsl:text>
      </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="getTrainingSamplePopulation">
<xsl:param name="totalcount"/>
<xsl:param name="nodecount"/>
<xsl:if test="$totalcount &gt; 0">
  <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"></xsl:with-param>
      <xsl:with-param name="else">
    <xsl:text> ( </xsl:text>
  <xsl:value-of 
    select="format-number($nodecount div $totalcount, '###.##%')"/>
    <xsl:text> records ) </xsl:text>
      </xsl:with-param>
  </xsl:call-template>
</xsl:if>
</xsl:template>

<xsl:template name="getMiningFields">
  <xsl:variable name="vlist">
  <xsl:for-each select="/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted']">
    <xsl:sort select="@name" data-type="text" order="ascending"/>
    <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
    <xsl:if test="(position() mod 5) = 0"><xsl:text>&#xa;       </xsl:text></xsl:if>
    <xsl:value-of select="@name"/>
  </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="cvlist">
  <xsl:for-each select="/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted' and @variableType = 'categorical']">
    <xsl:sort select="@name" data-type="text" order="ascending"/>
    <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
    <xsl:if test="(position() mod 1) = 0"><xsl:text>&#xa;       </xsl:text></xsl:if>
    <xsl:value-of select="@name"/><xsl:text>[categoricalValueBufferSize]</xsl:text>
  </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="cvlistjava">
  <xsl:for-each select="/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted' and @variableType = 'categorical']">
    <xsl:sort select="@name" data-type="text" order="ascending"/>
    <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
    <xsl:if test="(position() mod 1) = 0"><xsl:text>&#xa;       </xsl:text></xsl:if>
    <xsl:value-of select="@name"/>
  </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="dvlist">
  <xsl:for-each select="/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted' and @variableType != 'categorical']">
    <xsl:sort select="@name" data-type="text" order="ascending"/>
    <xsl:if test="position() != 1"><xsl:text>, </xsl:text></xsl:if>
    <xsl:if test="(position() mod 5) = 0"><xsl:text>&#xa;       </xsl:text></xsl:if>
    <xsl:value-of select="@name"/>
  </xsl:for-each>
  </xsl:variable>

  <xsl:call-template name="ifcpp">
<!-- c++ code -->
      <xsl:with-param name="ifcpp">
    <xsl:if test="$withstats">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>#define node(treeid,nodeid)  { node##treeid[nodeid+TREE##treeid##NODEIDSHIFT]++; positivenode##treeid[nodeid+TREE##treeid##NODEIDSHIFT]+=COMPLETEDSUCCESSFULLY; }&#xa;</xsl:text>
    <xsl:text>#define printnodes(treeid)  { unsigned int i=0; for(i=0; i&lt;TREE##treeid##NODES; i++) { fprintf(stderr, "(%d, %d) = %d/%d\n", treeid, i-TREE##treeid##NODEIDSHIFT, node##treeid[i], positivenode##treeid[i]); } }&#xa;</xsl:text>
    <xsl:text>&#xa;&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;// Total </xsl:text>
    <xsl:value-of select="count(/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted'])"/>
    <xsl:text> factors&#xa;/************&#xa; * PREDICTORS&#xa; ************/&#xa;&#xa;const static int categoricalValueBufferSize = 512; &#xa;&#xa;</xsl:text>
    <xsl:if test="'' != $dvlist">
      <xsl:text>double &#xa;       </xsl:text> <xsl:value-of select="$dvlist"/> <xsl:text>; &#xa;</xsl:text>
    </xsl:if>
    <xsl:if test="'' != $cvlist">
      <xsl:text>&#xa;char   </xsl:text> <xsl:value-of select="$cvlist"/> <xsl:text>; &#xa;</xsl:text>
<![CDATA[
static inline int isIn(const char* var, int svc, const char* sva[])
{
  if(!var) return 0;
  if(svc < 1 || !sva) { fprintf(stderr, "Code gen error, passing in empty categorical values\n"); return 0; }
  for(int i = 0; i < svc; i++) {
    if(strlen(var) == strlen(sva[i]) && 0 == strncmp(var, sva[i], strlen(var)))
      return 1;
  }
  return 0;
}

static inline int isNA(const char* var)
{
  return !var || strlen(var) < 1 || (strlen(var) == 2 && 0 == strncmp(var, "NA", 2));
}
]]>
    </xsl:if>
    <xsl:text>&#xa;/************&#xa; * Here come the treenets in the grove.  A shell for calling them&#xa; * appears at the end of this source file.&#xa; ************/&#xa;&#xa;</xsl:text>
    <xsl:text>double </xsl:text>
    <xsl:value-of select="/PMML/MiningModel/Output/OutputField[@name='RESPONSE']/@targetField"/>
    <xsl:text>; &#xa;&#xa;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else">
    <xsl:text>&#xa;Total </xsl:text>
    <xsl:value-of select="count(/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted'])"/>
    <xsl:text> factors&#xa;       </xsl:text>
    <xsl:value-of select="$vlist"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
      </xsl:with-param>

<!-- java code -->
      <xsl:with-param name="ifjava">
    <xsl:if test="$withstats">
    <xsl:text>&#xa;</xsl:text>
    <xsl:text>#define node(treeid,nodeid)  { node##treeid[nodeid+TREE##treeid##NODEIDSHIFT]++; positivenode##treeid[nodeid+TREE##treeid##NODEIDSHIFT]+=COMPLETEDSUCCESSFULLY; }&#xa;</xsl:text>
    <xsl:text>#define printnodes(treeid)  { unsigned int i=0; for(i=0; i&lt;TREE##treeid##NODES; i++) { fprintf(stderr, "(%d, %d) = %d/%d\n", treeid, i-TREE##treeid##NODEIDSHIFT, node##treeid[i], positivenode##treeid[i]); } }&#xa;</xsl:text>
    <xsl:text>&#xa;&#xa;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;// Total </xsl:text>
    <xsl:value-of select="count(/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted'])"/>
    <xsl:text> factors&#xa;/************&#xa; * PREDICTORS&#xa; ************/ &#xa;&#xa;</xsl:text>
    <xsl:text>&#xa;// model input: continous variables &#xa;</xsl:text>
    <xsl:if test="'' != $dvlist">
      <xsl:text>&#xa;double &#xa;       </xsl:text> <xsl:value-of select="$dvlist"/> <xsl:text>; &#xa;</xsl:text>
    </xsl:if>
    <xsl:text>&#xa;// model input: categorical variables &#xa;</xsl:text>
    <xsl:if test="'' != $cvlistjava">
      <xsl:text>&#xa;String   </xsl:text> <xsl:value-of select="$cvlistjava"/> <xsl:text>; &#xa;</xsl:text>
    <xsl:text>&#xa;// model input: end variable declaration &#xa;</xsl:text>
<![CDATA[
private final static boolean isIn(String var, String sva[])
{
  if(null == var || var.length() < 1) return false;
  if(null == sva || sva.length < 1) { System.err.println("Code gen error, passing in empty categorical values"); return false; }
  for(int i = 0; i < sva.length; i++) {
    if(var.equals(sva[i]))
      return true;
  }
  return false;
}

private final static boolean isNA(String var)
{
  return null == var || var.length() < 1 || var.equals("NA");
}
]]>
    </xsl:if>
    <xsl:text>&#xa;/************&#xa; * Here come the treenets in the grove.  A shell for calling them&#xa; * appears at the end of this source file.&#xa; ************/&#xa;&#xa;</xsl:text>
    <xsl:text>private double </xsl:text>
    <xsl:value-of select="/PMML/MiningModel/Output/OutputField[@name='RESPONSE']/@targetField"/>
    <xsl:text>; &#xa;&#xa;</xsl:text>
      </xsl:with-param>
      <xsl:with-param name="else">
    <xsl:text>&#xa;Total </xsl:text>
    <xsl:value-of select="count(/PMML/MiningModel/MiningSchema/MiningField[@usageType != 'predicted'])"/>
    <xsl:text> factors&#xa;       </xsl:text>
    <xsl:value-of select="$vlist"/>
    <xsl:text>&#xa;&#xa;</xsl:text>
      </xsl:with-param>

  </xsl:call-template>
</xsl:template>

<xsl:template name="getNodeScores">
<xsl:param name="treeid"/>

  <xsl:if test="$treeid &lt;= count(/PMML/MiningModel/DecisionTree)">
  <xsl:value-of select="/PMML/MiningModel/DecisionTree[$treeid]/@modelName"/>
  <xsl:text>, #nodes: </xsl:text>
  <xsl:value-of 
    select="count(/PMML/MiningModel/DecisionTree[$treeid]//Node/@score)"/>
  <xsl:text> (terminals: </xsl:text>
  <xsl:value-of 
    select="count(/PMML/MiningModel/DecisionTree[$treeid]//Node[substring(@id,1,1)='T']/@score)"/>
  <xsl:text>)</xsl:text>

  <xsl:text>, terminal node scores (min, max): </xsl:text>
  <xsl:variable name="the_max">
    <xsl:for-each select="/PMML/MiningModel/DecisionTree[$treeid]//Node[substring(@id,1,1)='T']">
      <xsl:sort select="@score" data-type="number" order="descending"/>
      <xsl:if test="position()=1"><xsl:value-of select="@score"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="the_min">
    <xsl:for-each select="/PMML/MiningModel/DecisionTree[$treeid]//Node[substring(@id,1,1)='T']">
      <xsl:sort select="@score" data-type="number" order="descending"/>
      <xsl:if test="position()=last()"><xsl:value-of select="@score"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:text>(</xsl:text>
  <xsl:value-of select="$the_min"/>
  <xsl:text>, </xsl:text>
  <xsl:value-of select="$the_max"/>
  <xsl:text>)</xsl:text>

  <!--xsl:for-each select="/PMML/MiningModel/DecisionTree[$treeid]//Node[substring(@id,1,1)='T']">
  </xsl:for-each-->

  <xsl:text>, response coefficient: </xsl:text>
  <xsl:value-of select="/PMML/MiningModel/Regression/RegressionTable/NumericPredictor[@name=concat('Response',$treeid)]/@coefficient"/>
  <xsl:text>&#xa;</xsl:text>

  </xsl:if>
</xsl:template>

<xsl:template name="indent">
  <xsl:param name="depth"/>

  <xsl:if test="$depth &gt; 0">
    <xsl:call-template name="ifcpp">
      <xsl:with-param name="ifcpp"><xsl:text>    </xsl:text></xsl:with-param>
      <xsl:with-param name="else"><xsl:text>|   </xsl:text></xsl:with-param>
    </xsl:call-template>
    
     <xsl:call-template name="indent">
        <xsl:with-param name="depth" select="$depth - 1"/>
     </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="ifcpp">
  <xsl:param name="ifcpp"/>
  <xsl:param name="ifjava"/>
  <xsl:param name="else"/>

    <xsl:choose>
    <xsl:when test="$cpp = 1">
     <xsl:value-of select="$ifcpp"/>
    </xsl:when>
    <xsl:when test="$cpp = 2">
     <xsl:choose><xsl:when test="'' = $ifjava"><xsl:value-of select="$ifcpp"/></xsl:when><xsl:otherwise><xsl:value-of select="$ifjava"/></xsl:otherwise></xsl:choose>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="$else"/>
    </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>

