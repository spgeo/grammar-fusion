#!/usr/bin/perl

##-------------------------------------------------------------------##
## Report evaluation results in a tabular form:                      ##
##                                                                   ##
## Takes as input the file name of results (usually a .csv file)     ##
## and creates a .tex file, which is compiled into a .pdf file       ##
## using "pdflatex".                                                 ##
## Author: Elias Iosif						     ##
##-------------------------------------------------------------------##

## Input args
##-----------
$results_file = $ARGV[0]; chomp($results_file); ## File of evaluation results

## Consts
##-------
$amb = '&';
$nln = '\\\\';
$hln = '\hline';

## Output file
##--------------
$tex_file = $results_file.".tex"; ## Output: .tex file

open (I,"$results_file") || die "Can not open $results_file\n";
open (O,">$tex_file") || die "Can not write $tex_file\n";

print O <<'P1';
\documentclass[a4paper,10pt]{article}
\begin{document}
\scriptsize
\begin{center}
\begin{tabular}{|c||c|c|c||c|c|}
\hline
 &Exact&Under&Over& & \\
Rule&Induction&Induction&Induction&Precision&Recall\\
 &Ratio&Ratio&Ratio& & \\
\hline
\hline
P1

$r = <I>;
$r = <I>;
while ($r ne "")
 {
  chomp($r);
  ($f1,$f2,$f3,$f4,$f5,$f6) = split(/,/,$r);
  $f1 =~ s/</\$<\$/g;
  $f1 =~ s/>/\$>\$/g;
  $f1 =~ s/_/\-/g;
  print  ($f1,$amb,$f2,$amb,$f3,$amb,$f4,$amb,$f5,$amb,$f6," ",$nln,"\n");
  print  ($hln,"\n");
  if (($f1 =~ /ALL/) && ($f1 =~ /RULES/))
   {
    print O ($hln,"\n");
    print O ($f1,$amb,$f2,$amb,$f3,$amb,$f4,$amb,$f5,$amb,$f6," ",$nln,"\n");
    print O ($hln,"\n");
   }
  else
   {
    print O ($f1,$amb,$f2,$amb,$f3,$amb,$f4,$amb,$f5,$amb,$f6," ",$nln,"\n");
    print O ($hln,"\n");
   }
  $r = <I>;
 }
close (I);


print O <<'PFINAL';
\end{tabular}
\end{center}
\end{document}
PFINAL
close (O);


system ("pdflatex $tex_file"); ## Output: compile a .pdf file based on the .tex file

