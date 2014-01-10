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
my @folders = ("1_InputGrammars","2_SimpleUnion_NoConceptMap","3_Fusions_WithConceptMap","4_Fusions_WithRuleMap");
foreach my $folder (@folders) {
	my $path = $dirname.$folder;
	if ((-d $path)&&($folder ne "..")&&($folder ne ".")) {
		opendir my($dh), $path or die "Couldn't open dir '$path': $!";
		my @files_to = readdir $dh; ## Files of evaluation results in this folder
		closedir $dh;
		foreach my $file (@files_to) {
			if ($file =~ /csv$/) {
				push(@files,$path."/".$file);
			}
		}
	}
}

## Output file
##--------------
$tex_file = "Report.tex"; ## Output: .tex file

### Consts
###-------
#$amb = '&';
#$nln = '\\\\';
#$hln = '\hline';
#my @thresholds = ("1","0.8","0.6");
#my @directions = ("0","1");

# Load the reports
my %report = ();
foreach my $file (@files) {
	my $step = "";
	my $evalType = "";
	my $fusionType = "";
	my $mapType = "";
	#print $file."\n";
	# Get file info
	my ($stepname, $filename) = split("\/",$file);
	if ($stepname =~ m/^([1-4])/) {
		$step = $1;
	}
	if ($filename =~ m/^eval/) { 
		$evalType = "fusion";
		my @blocks = split('\.',$filename);
		my @parts = split("_",$blocks[0]);
		if ($step > 1) { $fusionType = $blocks[1]; $mapType = $blocks[2]; } else { $fusionType = $parts[2]; }
	} else {
		if ($filename =~ m/^concepts/) { $evalType = "concepts"; }
		elsif ($filename =~ m/^rules/) { $evalType = "rules"; }
		my @blocks = split("_",$filename);
		my @parts = split('\.',$blocks[5]);
		$mapType = $parts[0];
		print $mapType."\n";
	}

	# Load file data
	open (I,"$file") || die "Can not open $file\n";
	my $r;
	if ($evalType eq "fusion") {
		$r = <I>;
		chomp $r;
		($l1,$l2,$l3,$l4) = split(/,/,$r);
		while ($r = <I>) {
			chomp($r);
			($p1,$p2,$p3,$p4) = split(/,/,$r);
			$reportFusion{$step}{$fusionType}{$mapType}{$p1}{$l2} = $p2;
			$reportFusion{$step}{$fusionType}{$mapType}{$p1}{$l3} = $p3;
			$reportFusion{$step}{$fusionType}{$mapType}{$p1}{$l4} = $p4;
#print "$step $fusionType $mapType  $p1  $l2 \n";
		}
	} else {
		$r = <I>;
		chomp $r;
		($l1,$l2,$l3,$l4) = split(/,/,$r);
		while ($r = <I>) {
			chomp($r);
			$r =~ s/\%//g;
			($p1,$p2,$p3,$p4) = split(/,/,$r);
			$reportMap{$step}{$mapType}{$evalType}{$p1}{$l2} = $p2;
			$reportMap{$step}{$mapType}{$evalType}{$p1}{$l3} = $p3;
			$reportMap{$step}{$mapType}{$evalType}{$p1}{$l4} = $p4;
print "{$step}{$mapType}{$evalType}\n";
		}
	}
	close (I);
}

open (O,">$tex_file") || die "Can not write $tex_file\n";

print O <<'P1';
\documentclass[a4paper,10pt]{article}
\usepackage[margin=0.5in]{geometry}
\usepackage{tabularx,ragged2e,booktabs,caption}
\begin{document}
\scriptsize
\section{Automatic Grammar Fusion}
\subsection{Evaluations}
\begin{center}
\captionof{table}{Overall Grammar Evaluation} \label{tab:title} 
\begin{tabular}{|c||c|c|c|}
\hline
Grammar&Precision&Recall&FMeasure\\
\hline
\hline
P1

print O "Bottom Up&".$reportFusion{"1"}{"BU"}{""}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"1"}{"BU"}{""}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"1"}{"BU"}{""}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Top Down&".$reportFusion{"1"}{"TD"}{""}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"1"}{"TD"}{""}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"1"}{"TD"}{""}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Simple Union (Base)&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Simple Union (Concept map / TD-to-BU)&".$reportFusion{"3"}{"1"}{"bu"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"1"}{"bu"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"1"}{"bu"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Simple Union (Concept map / BU-to-TD)&".$reportFusion{"3"}{"1"}{"td"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"1"}{"td"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"1"}{"td"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented BU (Concept map / TD-to-BU)&".$reportFusion{"3"}{"3"}{"bu"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"3"}{"bu"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"3"}{"bu"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented BU (Concept map / BU-to-TD)&".$reportFusion{"3"}{"3"}{"td"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"3"}{"td"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"3"}{"td"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented TD (Concept map / TD-to-BU)&".$reportFusion{"3"}{"2"}{"bu"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"2"}{"bu"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"2"}{"bu"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented TD (Concept map / BU-to-TD)&".$reportFusion{"3"}{"2"}{"td"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"3"}{"2"}{"td"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"3"}{"2"}{"td"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented BU (Rule map / TD-to-BU)&".$reportFusion{"4"}{"3"}{"bu"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"4"}{"3"}{"bu"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"4"}{"3"}{"bu"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline
Augmented TD (Rule map / BU-to-TD)&".$reportFusion{"4"}{"2"}{"td"}{"ALL_RULES"}{"Precision"}."&".$reportFusion{"4"}{"2"}{"td"}{"ALL_RULES"}{"Recall"}."&".$reportFusion{"4"}{"2"}{"td"}{"ALL_RULES"}{"FMeasure"}." \\\\
\\hline";


print O <<'P1';
\end{tabular}
\end{center}

\subsubsection{Evaluation of Mappings}
The evaluation of the mappings was implemented under the following concept:\\\\
The distance between the mapping scores of the mapped rule (best score) and the worst mapped rule (worst score) was calculated to provide the score margin. The distance between the mapping scores of the mapped rule (best score) and the golden rule was also calculated(the golden mapping score should ideally be equal to the best score). Then, the accuracy of the mapping was computed as \textbf{the ratio of the mapping score distance from the golden rule score and from the worst mapped rule mapping score}. We also calculated the absolute matches to the groundtruth.\\\\
\underline{E.g. for the concept $<$STATE$>$:}\\
Worst mapping score: 0.971\\
Best mapping score($<$OBJECTTYPE\_6$>$): 0.838 \\
Golden mapping score($<$INDIVIDUAL\_5$>$): 0.850\\
\\
We measure the distance between the best and worst score:\\
Mapping margin: Worst mapping score - Best mapping score = \textbf{0.133}\\\\
and between the best and golden score:\\
Distance from gold: Golden mapping score - Best mapping score = \textbf{0.012}\\\\
We calculate the relative distance from the golden rule as:\\
Relative distance from gold = (Distance from gold)/(Mapping margin) = \textbf{0.09}\\\\
which is then normalised to represent accuracy:\\
Accuracy = (1 - (Relative distance from gold))*100 = \textbf{91\%}\\\\
P1

print O "\\begin{center}
\\captionof{table}{Evaluation of Mappings} \\label{tab:title} 
\\begin{tabular}{|c||c|c|c|}
\\hline
Mapping&Accuracy (\\%)&Correct (\\%)\\\\
\\hline
\\hline
Concept map / TD-to-BU&".$reportMap{"3"}{"BU"}{"concepts"}{"ALL_RULES"}{"Accuracy"}."&".$reportMap{"3"}{"BU"}{"concepts"}{"ALL_RULES"}{"Correct"}." \\\\
\\hline
Concept map / BU-to-TD&".$reportMap{"3"}{"TD"}{"concepts"}{"ALL_RULES"}{"Accuracy"}."&".$reportMap{"3"}{"TD"}{"concepts"}{"ALL_RULES"}{"Correct"}." \\\\
\\hline
Rule map / TD-to-BU&".$reportMap{"4"}{"BU"}{"rules"}{"ALL_RULES"}{"Accuracy"}."&".$reportMap{"4"}{"BU"}{"rules"}{"ALL_RULES"}{"Correct"}." \\\\
\\hline
Rule map / BU-to-TD&".$reportMap{"4"}{"TD"}{"rules"}{"ALL_RULES"}{"Accuracy"}."&".$reportMap{"4"}{"TD"}{"rules"}{"ALL_RULES"}{"Correct"}." \\\\
\\hline
\\end{tabular}
\\end{center}";


# STEP 1
print O <<'P1';
Accuracy measures how "close" was the mapping to the golden map rule, and Correct measures the percentage of the rules that were correctly mapped, according to the golden mapping rules.
\pagebreak
\subsection{Step 1: Input Grammars}
This step was made in order to create the base evaluations of the two grammars for comparison with the fusion.

\captionof{table}{Bottom-Up Grammar Evaluation} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"1"}{"BU"}{""}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"1"}{"BU"}{""}{$rule}{"Precision"}."\&".$reportFusion{"1"}{"BU"}{""}{$rule}{"Recall"}."\&".$reportFusion{"1"}{"BU"}{""}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"1"}{"BU"}{""}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"1"}{"BU"}{""}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"1"}{"BU"}{""}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
\captionof{table}{Top-Down Grammar Evaluation} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"1"}{"TD"}{""}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"1"}{"TD"}{""}{$rule}{"Precision"}."\&".$reportFusion{"1"}{"TD"}{""}{$rule}{"Recall"}."\&".$reportFusion{"1"}{"BU"}{""}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"1"}{"TD"}{""}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"1"}{"TD"}{""}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"1"}{"TD"}{""}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

# STEP 2
print O <<'P1';
\pagebreak
\subsection{Step 2: Simple Union}
Simple Union of the grammar without rule or concept mappings

\captionof{table}{Simple Union Evaluation (Base)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"2"}{"1"}{"L1_1L2_1"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{$rule}{"Precision"}."\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{$rule}{"Recall"}."\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"2"}{"1"}{"L1_1L2_1"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

# STEP 3
print O <<'P1';
\pagebreak
\subsection{Step 3: Concept Mapping}
Grammar Fusion after concept mapping

\captionof{table}{Simple Union Evaluation (Concept mapping TD to BU)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"1"}{"bu"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"1"}{"bu"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"1"}{"bu"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"1"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"1"}{"bu"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"1"}{"bu"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"1"}{"bu"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\pagebreak
\captionof{table}{Simple Union Evaluation (Concept mapping BU to TD)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"1"}{"td"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"1"}{"td"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"1"}{"td"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"1"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"1"}{"td"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"1"}{"td"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"1"}{"td"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

# Augmented bottom-up
print O <<'P1';
\pagebreak
\captionof{table}{Augmented Bottom Up (Concept mapping TD to BU)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"3"}{"bu"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"3"}{"bu"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"3"}{"bu"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"3"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"3"}{"bu"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"3"}{"bu"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"3"}{"bu"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\pagebreak
\captionof{table}{Augmented Bottom Up (Concept mapping BU to TD)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"3"}{"td"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"3"}{"td"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"3"}{"td"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"3"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"3"}{"td"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"3"}{"td"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"3"}{"td"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

# Augmented top-down
print O <<'P1';
\pagebreak
\captionof{table}{Augmented Top Down (Concept mapping TD to BU)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"2"}{"bu"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"2"}{"bu"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"2"}{"bu"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"2"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"2"}{"bu"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"2"}{"bu"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"2"}{"bu"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\pagebreak
\captionof{table}{Augmented Top Down (Concept mapping BU to TD)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"3"}{"2"}{"td"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"3"}{"2"}{"td"}{$rule}{"Precision"}."\&".$reportFusion{"3"}{"2"}{"td"}{$rule}{"Recall"}."\&".$reportFusion{"3"}{"2"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"3"}{"2"}{"td"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"3"}{"2"}{"td"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"3"}{"2"}{"td"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

# Step 4
print O <<'P1';
\pagebreak
\subsection{Step 4: Rule Mapping}
Grammar Fusion after rule matching

\captionof{table}{Augmented Top Down (Concept mapping BU to TD)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"4"}{"2"}{"td"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"4"}{"2"}{"td"}{$rule}{"Precision"}."\&".$reportFusion{"4"}{"2"}{"td"}{$rule}{"Recall"}."\&".$reportFusion{"4"}{"2"}{"td"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"4"}{"2"}{"td"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"4"}{"2"}{"td"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"4"}{"2"}{"td"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\pagebreak
\captionof{table}{Augmented Bottom Up (Concept mapping TD to BU)} \label{tab:title} 
\begin{center}
\begin{tabular}{|c||c|c|c|}
\hline
Rule&Precision&Recall&FMeasure\\
\hline
\hline
P1

foreach my $rule (keys %{$reportFusion{"4"}{"3"}{"bu"}}) {
	if ($rule ne "ALL_RULES") {
		my $rulename = $rule;
		$rulename =~ s/\_/\\_/g;
		$rulename =~ s/</\$<\$/g;
		$rulename =~ s/>/\$>\$/g;
		print O "$rulename\&".$reportFusion{"4"}{"3"}{"bu"}{$rule}{"Precision"}."\&".$reportFusion{"4"}{"3"}{"bu"}{$rule}{"Recall"}."\&".$reportFusion{"4"}{"3"}{"bu"}{$rule}{"FMeasure"}." \\\\\n\\hline";
	}	
}
print O "\n\\hline\n\$<\$ALL\\_RULES\$>\$\&".$reportFusion{"4"}{"3"}{"bu"}{"ALL\_RULES"}{"Precision"}."\&".$reportFusion{"4"}{"3"}{"bu"}{"ALL\_RULES"}{"Recall"}."\&".$reportFusion{"4"}{"3"}{"bu"}{"ALL\_RULES"}{"FMeasure"}." \\\\\n";

print O <<'P1';
\hline
\end{tabular}
\end{center}
P1

print O <<'P1';
\end{document}
P1
close (O);

system ("pdflatex $tex_file"); ## Output: compile a .pdf file based on the .tex file
