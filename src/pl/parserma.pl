#!/usr/bin/perl -w
# this depends on R with gbm package and a set of commands 
#

#use lib (exists($ENV{'MY_PERL_SCRIPT_HOME'}) ? "$ENV{'MY_PERL_SCRIPT_HOME'}" : "$ENV{'HOME'}/perl");

use strict;

my $now = localtime();

my ($rgbmoutput) = @ARGV;

if(!defined($rgbmoutput) || length($rgbmoutput) < 1) {
  $rgbmoutput = "mtrain_gbm.log";
}

my $txt = read_file($rgbmoutput);

my $varlist = getsection1($txt, 'Varible Names', 'Response Name', 1, 0);
my $targetsect = getsection1($txt, 'Response Name', 'Variable Importance', 1, 0);
my $targetname;
foreach (getlines($targetsect)) {
  chomp;
  my ($ln, $var) = split /\t/;
  if(defined($var) && length($var) > 0) {
    $targetname = $var;
  }
}

# first collect variable importance
my %varimp = ();
my $implist = getsection1($txt, 'Variable Importance', 'Fitting Status', 1, 0);
my $maximp = 0;
foreach (getlines($implist)) {
  chomp;
  my ($ln, $var, $w) = split /\t/;
  if(defined($w) && length($w) > 0) {
    $varimp{$var} = $w;
    $maximp = $maximp >= $w ? $maximp : $w;
  }
}
# scale importance to 100%
foreach (keys %varimp) {
  my $w = $varimp{$_};
  $w = $w / $maximp;
  $varimp{$_} = sprintf("%.3f",$w * 100);
}

# collect all input vars stored in the gbm object (some of them may not be used by the model)
my @vars = ();
my @vartypes = ();
my @varvalues = ();
my $varfields = "";
my $varmfields = "";
#foreach (split /\n/, $varlist) {
foreach (getlines($varlist)) {
  chomp;
  my ($ln, $var, $ty, $vals) = split /\t/;
  if(defined($var) && length($var) > 0) {
    chomp $var;
    push @vars, $var;
    push @vartypes, $ty;
    push @varvalues, $vals;
    if($ty > 0) {
      my @vlvls = split /, /, $vals;
      my $nlvls = scalar(@vlvls); #ty is model learnt (used levels?)
      $varfields .= "  <DataField name='$var' optype='categorical' dataType='char' levels='$nlvls'>\n";
      foreach my $v (@vlvls) {
        $varfields .= "    <Value value='$v' />\n";
      }
      $varfields .= "  </DataField>\n";
    } else {
      $varfields .= "  <DataField name='$var' optype='continuous' dataType='double' />\n";
#      $varmfields .= "  <MiningField name='$var' usageType='active' importance='$varimp{$var}' missingValueReplacement='' />\n";
    }
  }
}
my $nvars = scalar(@vars);

# get model distribution
my $modelps = getsection1($txt, 'Model parameters', 'Model output', 1, 0);
my $dist;
foreach (getlines($modelps)) {
  chomp;
  my ($ln, $distv, $etc) = split /\t/;
  if(defined($distv) && length($distv) > 0) {
    $dist = $distv;
  }
}

# get intercept
my $initF = getsection1($txt, 'Model output', 'Model csplits', 1, 0);
my $intercept;
foreach (getlines($initF)) {
  chomp;
  my ($ln, $initfv) = split /\t/;
  if(defined($initfv) && length($initfv) > 0) {
    $intercept = $initfv;
  }
}

# get categorical splits
my $csplitlist = getsection1($txt, 'Model csplits', 'Decision trees', 1, 0);
my @csplits;
foreach (getlines($csplitlist)) {
  chomp;
  my ($ln, $splts) = split /\t/;
  if(defined($splts) && length($splts) > 0) {
    push @csplits, $splts;
  }
}

# get all the trees
my $trees = getsection1($txt, 'Decision trees', 'end of file', 1, 0);

#print $trees;

my @trees = getTrees($trees);
my $ntrees = scalar(@trees);

# generate each decision tree one by one
my $dtrees = "";
my %usedvars = ();
foreach my $it (0..$#trees) {
  $dtrees .= parseTree($it+1, $trees[$it]);
}
#print STDERR scalar(keys %usedvars)." used vars:".join(",", sort keys %usedvars)."\n";

# try to output only the used vars
foreach my $var (sort keys %usedvars) {
#  $varfields .= "  <DataField name='$var' optype='continuous' dataType='float' />\n";
  my$ vty = ($usedvars{$var} > 0 ? "categorical" : "continuous"); 
  $varmfields .= "  <MiningField name='$var' usageType='active' variableType='$vty' importance='$varimp{$var}' missingValueReplacement='' />\n";
}

my $coefs = "";
foreach my $it (1..$ntrees) {
  $coefs .= "    <NumericPredictor name='Response$it' coefficient='1.0' />\n";
}

my $header = <<HEADER;
<?xml version='1.0'?>
 
<PMML version='3.1'
      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
 
<Header copyright='' description='R_gbm Model'>
  <Application name='GBM' version='0.1'/>
  <Timestamp>$now</Timestamp>
  </Header>
 
<DataDictionary numberOfFields='$nvars'>
$varfields
  </DataDictionary>
 
<MiningModel modelName='R_gbm'
             functionName='regression'
             algorithmName='MART' distribution='$dist'>
 
<MiningSchema>
  <MiningField name='$targetname' usageType='predicted' />
$varmfields
  </MiningSchema>
 
<Output>
  <OutputField name='RESPONSE' optype='continuous' dataType='float'
               targetField='$targetname' feature='predictedValue' />
  <OutputField name='RESIDUAL' optype='continuous' dataType='float'
               targetField='$targetname' feature='residual' />
  <OutputField name='initF' value='$intercept' />
</Output>
 
HEADER


my $footer = <<FOOTER;

<Regression functionName='regression'>
  <RegressionTable intercept='0.0' targetCategory=''>
$coefs
    </RegressionTable>
  </Regression>
 
</MiningModel>
 
</PMML>
FOOTER

# output final pmml
print $header;
print $dtrees;
print $footer;

# get all the trees, all in text lines
sub getTrees {
  my ($txt) = @_;
  my @trees;
  open MEMORY, '<', \$txt;
  local $/ = "SplitVar\tSplitCodePred\tLeftNode\tRightNode\tMissingNode\tErrorReduction\tWeight\tPrediction";
  my $c = 0;
  while(<MEMORY>) {
    chomp;
    push @trees, $_ if length($_) > 1;
  }
  close MEMORY;
  return @trees
}

# parse tree and return pmml segment for a decision tree
sub parseTree {
  my ($tid, $txt) = @_;
  my @lines = getlines($txt); #split /\n/, $txt;
  my @treelines = ();
  foreach my $line (@lines) {
    chomp $line;
    next if length($line) < 1;
    push @treelines, $line;
    my ($ln, $var, $pred, $left, $right, $miss, $err, $weight, $score) = split /\t/, $line;
    #print "$ln, $var, ".($var < 0 ? "LEAF" : $vars[$var]).", $pred, $left, $right, $miss, $err, $weight, $score\n";
  }

  my $buf = <<TREEHEAD;  
<DecisionTree modelName='Tree$tid'
              functionName='regression'
              splitCharacteristic='binarySplit'>
 
<ResultField name='Response$tid'
             optype='continuous'
             dataType='float'
             feature='predictedValue' />

TREEHEAD
  $buf .= printnode(0, \@treelines, \@vars, \@vartypes, \@varvalues, $treelines[0], undef, undef, undef, undef, undef);
  
  $buf .= "\n</DecisionTree>\n";
  return $buf;
}

# recursive call
sub printnode {
  my ($level, $treelinesref, $varsref, $vartysref, $varvalsref, $nodeline, $condvar, $condvarty, $condvarvals, $cond, $value) = @_;
  # $weight contains number of records went through the node
  my ($ln, $var, $predvalue, $left, $right, $miss, $err, $weight, $score) = split /\t/, $nodeline;
  my $pad = '  ' x $level;
  my $padn = '  ' x ($level+1);
  my $padnn = '  ' x ($level+2);
  my $buf = "";
  if($var >= 0) {
    my $nid = $ln;
    $buf = "$pad<Node id='$nid' score='0' recordCount='$weight'>\n";
    if(defined($condvar)) {
      if("isMissing" eq $cond) {
        $buf .= "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
                "$padnn<SimplePredicate field='$condvar' operator='$cond' />\n".
                "$padnn<False />\n$padn</CompoundPredicate>\n";
      } elsif($condvarty > 0) { # categorical
        #$buf .= "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
        #        "$padnn<SimpleSetPredicate field='$condvar' booleanOperator='isIn'>\n$value</SimpleSetPredicate>\n".
        #        "$padnn<False />\n$padn</CompoundPredicate>\n";
        $buf .= categoricalnode($csplits[$value], $condvarvals, $condvar, $nid, $score, $weight, $pad, $padn, $padnn);
      } else {
        $buf .= "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
                "$padnn<SimplePredicate field='$condvar' operator='$cond' value='$value' />\n".
                "$padnn<False />\n$padn</CompoundPredicate>\n";
      }
    } else {
      $buf .= "$padn<True />\n";
    }
    my @treelines = @$treelinesref;
    my @vars = @$varsref;
    my @vartypes = @$vartysref;
    my @varvalues = @$varvalsref;
    $usedvars{$vars[$var]} = $vartypes[$var];
    $buf .= printnode($level+1, $treelinesref, $varsref, $vartysref, $varvalsref, $treelines[$miss],
                      $vars[$var], $vartypes[$var], $varvalues[$var], "isMissing", $predvalue);
                      #$condvar, $condvarty, $condvarvals, "isMissing", $value);
    $buf .= printnode($level+1, $treelinesref, $varsref, $vartysref, $varvalsref, $treelines[$left], 
                      $vars[$var], $vartypes[$var], $varvalues[$var], "lessThan", $predvalue);
    $buf .= printnode($level+1, $treelinesref, $varsref, $vartysref, $varvalsref, $treelines[$right], undef, undef, undef, undef, undef);
    $buf .= "$pad</Node>\n";
  } else {
    $buf = printleaf($level, $nodeline, $condvar, $condvarty, $condvarvals, $cond, $value);
  }
  return $buf;
}

# print leaf node of a tree
sub printleaf {
  my ($level, $leafnode, $condvar, $condvarty, $condvarvals, $cond, $value) = @_;
  my ($ln, $var, $pred, $left, $right, $miss, $err, $weight, $score) = split /\t/, $leafnode;
  my $pad = '  ' x $level;
  my $padn = '  ' x ($level+1);
  my $padnn = '  ' x ($level+2);
  if($var < 0) {
    my $nid = $ln;
    my $buf = "$pad<Node id='T$nid' score='$score' recordCount='$weight'>\n".
              "$padn<True />\n".
              "$pad</Node>\n";
    if(defined($condvar)) {
      if("isMissing" eq $cond) {
        $buf = "$pad<Node id='T$nid' score='$score' recordCount='$weight'>\n".
                "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
                "$padnn<SimplePredicate field='$condvar' operator='$cond' />\n".
                "$padnn<False />\n$padn</CompoundPredicate>\n".
                "$padn<True />\n$pad</Node>\n";
      } elsif($condvarty > 0) { # categorical
        $buf = "$pad<Node id='T$nid' score='$score' recordCount='$weight'>\n".
               categoricalnode($csplits[$value], $condvarvals, $condvar, $nid, $score, $weight, $pad, $padn, $padnn).
               "$padn<True />\n$pad</Node>\n";
      } else {
        $buf = "$pad<Node id='T$nid' score='$score' recordCount='$weight'>\n".
             "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
             "$padnn<SimplePredicate field='$condvar' operator='$cond' value='$value' />\n".
             "$padnn<False />\n$padn</CompoundPredicate>\n$padn<True />\n$pad</Node>\n";
      }
    }
    return $buf;
  }
}

sub categoricalnode {
  my ($csplitsarray, $condvarvals, $condvar, $nid, $score, $weight, $pad, $padn, $padnn) = @_;
  my @csv = split /, /, $csplitsarray;
  my @lvl = split /, /, $condvarvals;
  #if(scalar(@csv) != scalar(@lvl)) { # theer are cases scalar(@lvl) > scalar(@csv)
  #  print STDERR "Error: categorical var $condvar splits not the same as levels at leafnode, $#csv != $#lvl\n";
  #}
  my $csvals = "";
  my $nn = 0;
  foreach my $cpi (0..$#lvl) {
    if($cpi < scalar(@csv) && $csv[$cpi] == -1) { # -1 on the left, 1 on the right
      $csvals .= ($nn < 1 ? "" : ", ")."\"".$lvl[$cpi]."\"";
      $nn++;
    }
  }
  my $buf = "$padn<CompoundPredicate booleanOperator='surrogate'>\n".
             "$padnn<SimpleSetPredicate field='$condvar' booleanOperator='isIn'>\n".
             "$padnn<Array n='$nn' type='string'>$csvals</Array>\n".
             "$padnn</SimpleSetPredicate>\n".
             "$padnn<False />\n$padn</CompoundPredicate>\n";
  return $buf;
}

# deal with \r\n on pc
sub getlines {
  my ($txt) = @_;
  my @lines;
  open MEMORY, '<', \$txt;
#  local $/ = "\r\n"; # this worked for pc cygwin only
  local $/ = "\n";    # works for mac and pc
  while(<MEMORY>) {
    chomp;
    $_ =~ s/\r//;     # works for mac and pc
    push @lines, $_ if length($_) > 1;
  }
  close MEMORY;
  return @lines;
}

sub read_file {
  my ($fn) = @_;
  local $/=undef;
  open _RFTF,"<$fn";
  binmode _RFTF;
  my $content = <_RFTF>;
  close _RFTF;
  return $content;
}

sub getsection1 {
  my ($txt, $startline, $endline, $padnewline, $includestartendlines) = @_;
  my $tree = "";
  my $foundmarker = 0;
  foreach my $line (split /\n/, $txt) {
    if($line =~ /$startline/) {
      $foundmarker = 1;
      next if 0 == $includestartendlines;
    }
    if($line =~ /$endline/) {
      $foundmarker = 0;
      $tree .= $line.($padnewline? "\n" : "") if 0 != $includestartendlines;
      last;
    }
    my $skip = length($line) < 1;
    $tree .= $line.($padnewline? "\n" : "") if $foundmarker && !$skip;
  }
  return $tree;
}

