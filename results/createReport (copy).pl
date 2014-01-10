#!/usr/bin/perl
use Cwd 'abs_path';
##-------------------------------------------------------------------##
## Report evaluation results in a tabular form:                      ##
##                                                                   ##
## Takes as input the file name of results (usually a .csv file)     ##
## and creates a .tex file, which is compiled into a .pdf file       ##
## using "pdflatex".                                                 ##
##                                                                   ##
##                                                                   ##
## V2 - 20 July '13                                                  ##
## Updated according to new eval scheme discussed with UNIBI         ##
## after the Y1 Review & 3rd technical meeting.                      ##
## Major changes:                                                    ##
## - Report FMeasure                                                 ##
## - Do not report ratios of exact, under-, over-induction           ##
##   (such ratios do not apply any more due to the new eval scheme)  ##
##-------------------------------------------------------------------##

## Input files
##-----------
my @files = ();
my $dirname = "./";
opendir my($dh), $dirname or die "Couldn't open dir '$dirname': $!";
my @files_to = readdir $dh; ## Files of evaluation results in this folder
closedir $dh;
foreach my $file (@files_to) {
	my $path = $dirname.$file;
	if ((-d $path)&&($file ne "..")&&($file ne ".")) {
		opendir my($dh2), $path or die "Couldn't open dir '$path': $!";
		my @files_to2 = readdir $dh2; ## Files of evaluation results in this folder
		closedir $dh2;
		foreach my $file2 (@files_to2) {
			my $path2 = $path."/".$file2;
			if ((-d $path2)&&($file2 ne "..")&&($file2 ne ".")) {
				opendir my($dh3), $path2 or die "Couldn't open dir '$path2': $!";
				my @files_to3 = readdir $dh3; ## Files of evaluation results in this folder
				closedir $dh3;
				foreach my $file3 (@files_to3) {
					my $path3 = $path2."/".$file3;
					if ((-d $path3)&&($file3 ne "..")&&($file3 ne ".")) {
						opendir my($dh4), $path3 or die "Couldn't open dir '$path3': $!";
						my @files_to4 = readdir $dh4; ## Files of evaluation results in this folder
						closedir $dh4;
						foreach my $file4 (@files_to4) {
							$path4 = $path3."/".$file4;
							if ((-d $path4)&&($file4 ne "..")&&($file4 ne ".")) {
								opendir my($dh5), $path4 or die "Couldn't open dir '$path4': $!";
								my @files_to5 = readdir $dh5; ## Files of evaluation results in this folder
								closedir $dh5;
								foreach my $file5 (@files_to5) {
									$path5 = $path4."/".$file5;
									if ((-d $path5)&&($file5 ne "..")&&($file5 ne ".")) {
										opendir my($dh6), $path5 or die "Couldn't open dir '$path5': $!";
										my @files_to6 = readdir $dh6; ## Files of evaluation results in this folder
										closedir $dh6;
										foreach my $file6 (@files_to6) {
											if ($file6 =~ /csv$/) {
												push(@files,$path5."/".$file6);
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

#foreach (@files) {
#	print $_."\n";
#}

# Load groundrules
$groundtruth = "../qa_corpus_groundtruth";
my @groundrules = ();
open(GT,$groundtruth) || die "Cannot open $groundtruth\n";
while(<GT>) {
	chomp $_;
	@frags = split(",",$_);
	$frags[0] =~ s/</\$<\$/g;
	$frags[0] =~ s/>/\$>\$/g;
	$frags[0] =~ s/_/\\_/g;
	push(@groundrules, $frags[0]);
}
## Consts
##-------
$amb = '&';
$nln = '\\\\';
$hln = '\hline';
my @thresholds = ("1","0.8","0.6");
my @directions = ("0","1");

## Output file
##--------------
$tex_file = "Report.tex"; ## Output: .tex file


# First load the report
my %report = ();
foreach my $file (@files) {
	$path = abs_path($file);
	my @args = split("/",$path);
	@args = reverse(@args);
	my $version = $args[5];
	my $metric = $args[4];
	my $mapping = $args[3];
	my $strategy = $args[2];
	my $threshold = $args[1];
	my $grammar = "";
	if ($file =~ /csv$/) {
		if ($file =~ /TD/) {
			$grammar = "td";
		} elsif ($file =~ /BU/) {
			$grammar = "bu";
		} elsif ($file =~ /fusion/) {
			$grammar = "fusion";
		}
		open (I,"$file") || die "Can not open $file\n";
		$r = <I>;
		while ($r = <I>) {
		  chomp($r);
		  ($f1,$f2,$f3,$f4) = split(/,/,$r);
		  if (($f1 =~ /ALL/) && ($f1 =~ /RULES/)) {
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{"general"}{"precision"} = $f2;
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{"general"}{"recall"} = $f3;
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{"general"}{"fmeasure"} = $f4;
		  } else {
			$f1 =~ s/</\$<\$/g;
			$f1 =~ s/>/\$>\$/g;
			$f1 =~ s/_/\\_/g;
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{$f1}{"precision"} = $f2;
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{$f1}{"recall"} = $f3;
			$report{$version}{$metric}{$mapping}{$strategy}{$threshold}{$grammar}{$f1}{"fmeasure"} = $f4;
		  }
		}
		close (I);
	}
}

open (O,">$tex_file") || die "Can not write $tex_file\n";

print O <<'P1';
\documentclass[a4paper,10pt]{article}
\begin{document}
\scriptsize
\section{Automatic Grammar Fusion}
\subsection{Results}
\subsubsection{Cummulative evaluations (All rules)}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Bottom Up Augmentation} \\
\hline
\hline
Levenshtein&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\hline
LCS&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Top Down Augmentation} \\
\hline
\hline
Levenshtein&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\hline
LCS&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Simple Union} \\
\hline
\hline
Levenshtein&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\hline
LCS&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

print O "Precision&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"precision"}." \\\\ ";
print O "Recall&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"recall"}." \\\\ ";
print O "Fmeasure&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
\pagebreak
\subsubsection{Fusion evaluation}
\textbf{Simple union evaluation}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Levenshtein} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_1"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_1"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Longest Common Substring} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_1"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_1"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_1"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_1"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\textbf{Augmentation (bottom-up enrichment) evaluation}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Levenshtein} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_3"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_3"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Longest Common Substring} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_3"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_3"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_3"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_3"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\textbf{Augmentation (top-down enrichment) evaluation}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Levenshtein} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Longest Common Substring} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"fusion"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"fusion"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\pagebreak
\subsubsection{Bottom-up evaluation}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Levenshtein} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"bu"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"bu"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"bu"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Longest Common Substring} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"bu"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"bu"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"bu"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"bu"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\subsubsection{Top-down evaluation}
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Levenshtein} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"td"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_0"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"td"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_0"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_0"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"td"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\begin{center}
\begin{tabular}{|c||c|c|c|c|c|c|c|}
\hline
\multicolumn{8}{|c|}{Longest Common Substring} \\
\hline
\hline
Rule&v.1&\multicolumn{2}{|c|}{v.2(1.0)}&\multicolumn{2}{|c|}{v.2(0.8)}&\multicolumn{2}{|c|}{v.2(0.6)} \\
\hline
&&TD-BU&BU-TD&TD-BU&BU-TD&TD-BU&BU-TD \\
\hline
P1

foreach my $rule (@groundrules) {
	my $count = 0;
	my $outputText = "";
	$outputText = $rule."&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{$rule}{"fmeasure"};
	$count += $report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{$rule}{"fmeasure"};
	foreach my $thresh (@thresholds) {
		foreach my $dir (@directions) {
			$outputText .= "&".$report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"td"}{$rule}{"fmeasure"};
			$count += $report{"v_2"}{"metric_1"}{"mapping_$dir"}{"strategy_2"}{"thresh_$thresh"}{"td"}{$rule}{"fmeasure"};
		}
	}
	$outputText .= " \\\\ \\hline ";
	if ($count > 0) {
		print O $outputText;
	}
}

print O "ALL\\_RULES&".$report{"v_1"}{"metric_1"}{"mapping_9"}{"strategy_2"}{"thresh_9"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_1"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_1"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.8"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.8"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_0"}{"strategy_2"}{"thresh_0.6"}{"td"}{"general"}{"fmeasure"}."&".$report{"v_2"}{"metric_1"}{"mapping_1"}{"strategy_2"}{"thresh_0.6"}{"td"}{"general"}{"fmeasure"}." \\\\ ";

print O <<'P1';
\hline
\end{tabular}
\end{center}
\end{document}
P1
close (O);



system ("pdflatex $tex_file"); ## Output: compile a .pdf file based on the .tex file

