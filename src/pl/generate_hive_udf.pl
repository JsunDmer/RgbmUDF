#!/usr/bin/perl -w

use strict;

# $infile is the treenet generated c file
# perl parsetreenetc.pl mtrain_01052010.c > delme.c
# gcc delme.c -o delme
my ($infile, $classname, $pkg) = @ARGV;
if(!$classname) {
  printf("please provide GBM class name\n");
  exit -1;
}
if(!$pkg) {
  $pkg = "package com.vipshop.hadoop.platform.hive";
}

################## first read in the file and clean up
my $c = read_file($infile);

################## then parse out the input predictor variables

# numerical value variables
my $vars = getsection($c, '// model input: continous', '// model input: categorical', 1, 0);

$vars =~ s/^double //g;
$vars =~ s/[ \n;]//g;

# categorical value variables
my $varsc = getsection($c, '// model input: categorical', '// model input: end variable', 1, 0);

$varsc =~ s/^String //g;
$varsc =~ s/[ \n;]//g;


################## @vars contain all used variables in the model
my @varsarray = sort split /,/, $vars;
my $dvlist = 'Double ' . join(', Double ', @varsarray);
$dvlist =~ s/,/,\n    /g;
my $varassign = "";
foreach my $var (@varsarray) {
  $varassign .= "      gbm.$var = (null == $var ?  -1 : $var.doubleValue());\n";
}

my @varsarrayc = sort split /,/, $varsc;
my $cvlist = 'String ' . join(',String ', @varsarrayc);
$cvlist =~ s/,/,\n    /g;
my $cvarassign = "";
foreach my $var (@varsarrayc) {
  $cvarassign .= "      gbm.$var = (null == $var ? \"\" : $var);\n";
}


################## generate main function
my $cm = generatemain();

#print "$cm\n";
save_file("${classname}_UDF.java", $cm);

sub generatemain {
  my $mainc = <<MAIN;
$pkg;

import org.apache.hadoop.hive.ql.exec.UDF;
import org.apache.hadoop.hive.ql.exec.Description;


/**
 * ${classname}_UDF
 *
 */
public class ${classname}_UDF extends UDF {

  private static $classname gbm = new $classname();

  public double evaluate(
    // doubles 
    $dvlist,
    // Strings
    $cvlist 
    ) {
$varassign
$cvarassign  
    
    return gbm.treenet();
  }
}
MAIN
}

sub getsection {
  my ($txt, $startline, $endline, $padnewline, $includestartendlines) = @_;
  my $tree = "";
  my $foundmarker = 0;
  foreach my $line (split /\n/, $txt) {
    if($line =~ /^$startline/) {
      $foundmarker = 1;
      next if 0 == $includestartendlines;
    }
    if($line =~ /^$endline/) {
      $foundmarker = 0;
      $tree .= $line.($padnewline? "\n" : "") if 0 != $includestartendlines;
      last;
    }
    my $skip = length($line) < 1;
    $tree .= $line.($padnewline? "\n" : "") if $foundmarker && !$skip;
  }
  return $tree;
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

sub save_file {
  my ($fn, $content) = @_;
  open _SFTF,">$fn";
    print _SFTF $content;
  close _SFTF;
}
