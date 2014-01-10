#!/usr/bin/perl

use Text::Levenshtein qw(distance); ## Module from CPAN for Levenshtein distance

##----------------------------------------------------------------------------------------##
## Functionality:                                                                         ##
## -------------                                                                          ##
## Computes the evaluation metrics:                                                       ##
##  (i) precision                                                                         ##
##  (ii) recall                                                                           ##
##  (iii) F-measure                                                                       ##
## The above measurements are computed for each grammar rule in groundtruth,              ##
## as well as, for all rules.                                                             ##
##                                                                                        ##
## Input arguments:                                                                       ##
## ----------------                                                                       ##
## 1. The path of the file that correspond to groundtruth grammar.                        ##         
## 2. The path of the file that correspond to system output, i.e., induced grammar        ##
## 3. Value of lambda1 (weight of under-induction): 0 or 1                                ##
## 4. Value of lambda2 (weight of over-induction): 0 or 1                                 ##
## 4. Similarity metric: 0 (for Levenshtein) or 1 (for Longest Common Substring)          ##
##                                                                                        ##
## Notes:                                                                                 ##
## - Both of the obove files given by 1st and 2nd argument should be in .csv format.      ##
## ("csv" stands for comma separated values)                                              ##
##                                                                                        ##
## Output:                                                                                ##
## -------                                                                                ##
## A directory is created named "evaluation_results/",                                    ##
## including a .csv file named according to the name of                                   ##
## file that correspond to system output (2nd input argument)                             ##
## extended by the values of L1 and L2 and                                                ##
## ending in ".results.csv".                                                              ##
## This file includes the scores for the aforementioned evaluation metrics.               ##
##                                                                                        ##
## How to run examples                                                                    ##
## -------------------                                                                    ##
## perl script_name.pl file_groundtruth file_induced 0 0 1                                ##
## perl script_name.pl file_groundtruth file_induced 1 1 0                                ##
## perl script_name.pl file_groundtruth file_induced 1 1 1                                ##
##                                                                                        ##
## Previous (outdated) versions                                                           ##
## ----------------------------                                                           ##
## V1: Feb '13                                                                            ##
## V2: May '13 (Sebastian visit at TSI-TUC)                                               ##
## (V1 and V2 are referred only for "historical purposes")                                ##
##                                                                                        ##  
##                                                                                        ##
##                                                                                        ##
## *** Latest/current version ***                                                         ##
## ------------------------------   
## V3.1: 17 October '13:
## - Added parameter for similarity metric option between Levenshtein distance and	  ##                      
## Longest Common Substring distance                                                      ##                      
## 						                                          ##                      
## V3: 21 July '13:                                                                       ## 
## *** Major changes after the Year1 review and 3rd technical meeting ***                 ##
## (following the suggestions of P. Cimiano):                                             ##
## - When considering partial matches between the groundtruth and induced                 ##
##   fragments, consider the Levenshtein distance in order to find the best               ##
##   matches.                                                                             ##
##   That is, when no exact match can be found, which is the best partial match.          ##
##   The best match has the smallest Levenshtein distance.                                ##
##   The best matches are used when the under- and over-induction are considered.         ##
## - Note the following:                                                                  ##
##   -- For precision computation: allow any single groundtruth fragment to               ##
##   stand as the best match (even) for MULTIPLE INDUCED fragments.                       ##
##   That is, to do NOT require one-to-one mapping.                                       ##
##   -- For recall computation: allow any single induced fragment to                      ##
##   stand as the best match (even) for MULTIPLE GROUNDTRUTH fragmants.                   ##
##   That is, to do NOT require one-to-one mapping.                                       ##
##                                                                                        ##
##                                                                                        ##
## Contact                                                                                ##
## -------                                                                                ##
## Elias Iosif iosife@telecom.tuc.gr                                                      ##
##----------------------------------------------------------------------------------------##

## Input args
##-----------
$ground_file = $ARGV[0]; chomp($ground_file);
$ground_system = $ARGV[1]; chomp($ground_system);
$lambda1 = $ARGV[2]; chomp($lambda1); ## Weight assigned to under-induction
$lambda2 = $ARGV[3]; chomp($lambda2); ## Weight assigned to over-induction
$metric = $ARGV[4]; chomp($metric); ## Metric used (0 for Levenshtein, 1 for LCS)

$ignore = 0; # Static variable for exclusion of ground truth rules not found in the induced grammars

## Create directory for evaluation results
##----------------------------------------
$root_dir = "../";
$data_dir = $root_dir."data/";
$d_res = $root_dir."evaluation_results/";

## Initalization global counters and structures
##---------------------------------------------
$TOT_FRAG_GROUND = 0;
$TOT_FRAG_INDUCE = 0;
$Tot_Exact_Ground = 0;
$Tot_Under_Ground = 0;
$Tot_Over_Ground = 0;
$Tot_Exact_Induce = 0;
$Tot_Under_Induce = 0;
$Tot_Over_Induce = 0;
%PrecPerRule = ();
%RecPerRule = ();

if (scalar(@ARGV) == 0) ## No arguments given
 {
   die ("You must give the name of the file corresponding to groundtruth and  induced rules.\n");
 }
else
 {
  $groundtruth_path = "";
  $induced_path = "";
  $groundtruth_path = $data_dir.$ground_file;
  $induced_path =  $root_dir.$ground_system;

  if ( (!(-e $groundtruth_path)) ||  (!(-e $induced_path)) ) ## Check if the file(s) of groundtruth and induced rules exist
   {
    die ("Can not find file(s) of  groundtruth and/or induced rules: $groundtruth_path or $induced_path\n");
   }
 }

## Create file for reporting evaluation results
##---------------------------------------------
$results_file = $d_res.$ground_system.".L1_".$lambda1."L2_".$lambda1.".results.csv";
open (RES,">$results_file") || die ("Can not write $results_file \n");
print RES ("Rule",",","Precision",",","Recall",",","FMeasure","\n");

## Load groundtruth
##-----------------
%groundtruth_rules2members = ();
%groundtruth_rules2members_num = ();
@members_lst = ();
$members_str = ();
@groundtruth_rules_lst_sort = ();
$rule_label = "";
$num_of_members = 0;
open (G,"$groundtruth_path") || die ("Can not open $groundtruth_path \n");
$rdln = "";
$rdln = <G>;
while ($rdln ne "")
 {
  chomp($rdln);
  $rdln =~ s/\-/ /g; ## Substitute dashes by space
  @members_lst = split(/,/,$rdln); ## Rule label + members
  $rule_label = shift(@members_lst); ## Extract 1st element that is the rule label
  $members_str = join(",",@members_lst);
  $num_of_members = $#members_lst + 1;
  if ($num_of_members < 1)
   {
      die ("Rule $rule_label appears to be empty. Check this rule. \n");
   }
  $groundtruth_rules2members{$rule_label} = $members_str;
  $groundtruth_rules2members_num{$rule_label} = $num_of_members; 
  $rdln = <G>;
 }
close (G);
@groundtruth_rules_lst_sort = sort(keys(%groundtruth_rules2members));

## Load rules induced by the system
##---------------------------------
%induced_rules2members = ();
%induced_rules2members_num = ();
@induced_rules_lst_sort = ();
@members_lst = ();
$members_str = ();
$rule_label = "";
$num_of_members = 0;
open (I,"$induced_path") || die ("Can not open $induced_path \n");
$rdln = "";
$rdln = <I>;
while ($rdln ne "")
 {
   $rdln =~ s/\-/ /g; ## Substitute dashes by space
   chomp($rdln);
   @members_lst = split(/,/,$rdln); ## Rule label + members
   $rule_label = shift(@members_lst); ## Extract 1st element that is the rule label
   $members_str = join(",",@members_lst);
   $num_of_members = $#members_lst + 1;   
   $induced_rules2members{$rule_label} = $members_str;
   $induced_rules2members_num{$rule_label} = $num_of_members;
   $rdln = <I>;
 }
close (I);
@induced_rules_lst_sort = sort(keys(%induced_rules2members));


foreach $grule (@groundtruth_rules_lst_sort) ## For each groundtruth rule: start
 {
   ## Initializations
   $g_members_str = ""; ## Fragments of groundtruth rule as string
   @g_members_lst = (); ## Fragments of groundtruth rule in array
   %g_members_hsh = (); ## Fragments of groundtruth rule in hash
   %g_checked = (); ## Hash storing fragments of groundtruth rule that were checked
   %g_exact_checked = (); ## Hash storing fragments of groundtruth rule that were checked for exact induction
   %g_under_checked = (); ## Hash storing fragments of groundtruth rule that were checked for under induction
   %g_over_checked = ();  ## Hash storing fragments of groundtruth rule that were checked for over induction
   $i_members_str = ""; ## Fragments of respective induced rule as string
   @i_members_lst = (); ## Fragments of respective induced rule in array
   %i_members_hsh = (); ## Fragments of respective induced rule in hash

   ## Current groundtruth rule
   ##-------------------------  
   $g_members_str = $groundtruth_rules2members{$grule};
   @g_members_lst = split(/,/,$g_members_str);
   if ($ignore == 0) { 
      $TOT_FRAG_GROUND += $#g_members_lst + 1; ## Update (global) counter of ground fragments 
   }
   foreach (@g_members_lst) { $g_members_hsh{$_} = 1; }
   
   ## Respective induced rule
   ##-------------------------
   $respective_i_rule_exists = 0;
   if (defined($induced_rules2members{$grule})) { 
      if ($ignore == 1) { 
          $TOT_FRAG_GROUND += $#g_members_lst + 1; ## Update (global) counter of ground fragments
      }
      $respective_i_rule_exists = 1; 
   }

   if ($respective_i_rule_exists == 1)
   {
   $i_members_str = $induced_rules2members{$grule};
   @i_members_lst = split(/,/,$i_members_str);
   foreach (@i_members_lst) { $i_members_hsh{$_} = 1; }

   foreach $cur_g_member (@g_members_lst) ## For each fragment of groundtruth rule: start
    {

      $length_g_member = 0; ## Initialization
      @g_lst = split(/\s+/,$cur_g_member); ## Tokens of groundtruth fragment into array
      $length_g_member = $#g_lst + 1; ## Length of current groundtruth fragment (number of  tokens)
      $lchar_g_member = 0;
      $lchar_g_member = length($cur_g_member); ## Length of current groundtruth fragment (number of  chars)      
 
      ## Compare with members of respective induced rule
      ##------------------------------------------------
      if (defined($i_members_hsh{$cur_g_member})) ## Exact match
       {
         if ( (!(defined($g_exact_checked{$cur_g_member}))) && (!(defined($g_checked{$cur_g_member}))) )
          {
           $g_checked{$cur_g_member} = 1;
           $g_exact_checked{$cur_g_member} = 1;
           $Tot_Exact_Ground += 1;
          }
       }
      elsif (!(defined($i_members_hsh{$cur_g_member}))) ## No exact match. So, check for under-induction or over-induction
       {
          ## Find best matching induced fragment
          ##------------------------------------
          $best_induced_frag = ""; ## Best matching frag.: initialization
          $best_induced_frag_score = -100; ## Score for best matching frag: initialization
          foreach $cur_i_member (@i_members_lst) ## For each fragment of induced  rule: start
           {
		$length_i_member = 0; ## Initialization
		@i_lst = split(/\s+/,$cur_i_member); ## Tokens of induced fragment into array
		$length_i_member = $#i_lst + 1; ## Length of current induced fragment (number of  tokens) 
		$lchar_i_member = 0;
		$lchar_i_member = length($cur_i_member); ## Length of current induced fragment (number of  chars) 
		$max_lchar = 0; ## Find longest fragment
		if ($lchar_g_member >= $lchar_i_member) { $max_lchar = $lchar_g_member; }
		else { $max_lchar = $lchar_i_member; }
		$dist = 0; ## distance
		if ($metric == 0) {
			## Using Levenshtein distance
			$dist = distance($cur_g_member,$cur_i_member);
			$dist_norm = 0; ## Normalized Levenshtein distance
			$dist_norm = $dist / $max_lchar;
			$sim_norm = 0; ## Normalized similarity
			$sim_norm = 1 - $dist_norm;
		} elsif ($metric == 1) {
			## Using Longest Common Substring distance
			my @s1 = split /\s+/ => $cur_g_member; # seperate words of sentences
			my @s2 = split /\s+/ => $cur_i_member; # seperate words of sentences
			my $size1 = $#s1 + 1;
			my $size2 = $#s2 + 1;
			my $words = 0;

			$seq = lcss($cur_g_member,$cur_i_member);
			$seq =~ s/^\s+|\s+$//g; # trim
			$size1 = length $cur_g_member;
			$size2 = length $cur_i_member;
			$words = length $seq;

			#---compute scores---
			$dist_norm = 0; ## Normalized LCS distance
			$dist_norm = $words/(($size1+$size2)/2);
			$sim_norm = 0; ## Normalized similarity
			$sim_norm = $dist_norm;
		}
		if ($sim_norm > $best_induced_frag_score) {
			$best_induced_frag_score = $sim_norm;
	        	$best_induced_frag = $cur_i_member;
		}
           } ## For each member of induced  rule: end
           $length_best_i = 0; ## Initialization
           @best_i_lst = split(/\s+/,$best_induced_frag); ## Tokens of best induced fragment into array
           $length_best_i = $#best_i_lst + 1; ## Length of best induced fragment (number of  tokens)

              if ( ($length_best_i<=$length_g_member) && (!(defined($g_checked{$cur_g_member}))) ) ## Under-induction
               {
                   $g_checked{$cur_g_member} = 1;
                   $g_under_checked{$cur_g_member} = $best_induced_frag_score;
                   $Tot_Under_Ground += $best_induced_frag_score;  
               }
              if ( ($length_best_i>$length_g_member) && (!(defined($g_checked{$cur_g_member}))) )## Over-induction
               {
                   $g_checked{$cur_g_member} = 1;
                   $g_over_checked{$cur_g_member} = $best_induced_frag_score;
                   $Tot_Over_Ground += $best_induced_frag_score;
               }

       } ## Not exact match
    }  ## For each member of groundtruth rule: end
   } ## If respective induced rule exists


   ## Evaluation metrics for current rule
   ##------------------------------------
   $num_frags_ground = 0;
   $num_frags_exact_ground = 0;
   $num_frags_under_ground = 0;
   $num_frags_over_ground = 0;
   $cur_recall = 0;

   $num_frags_ground = $#g_members_lst + 1; ## Num of frags in current groundtruth rule
   foreach (keys(%g_exact_checked)) { $num_frags_exact_ground += $g_exact_checked{$_}; }
   foreach (keys(%g_under_checked)) { $num_frags_under_ground += $g_under_checked{$_}; }
   foreach (keys(%g_over_checked)) { $num_frags_over_ground += $g_over_checked{$_}; }


   $cur_recall = ($num_frags_exact_ground+($lambda1*$num_frags_under_ground)+($lambda2*$num_frags_over_ground)) / ($num_frags_ground);
   $cur_recall = sprintf("%.3f", $cur_recall);
   $RecPerRule{$grule} = $cur_recall;

 } ## For each groundtruth rule: end


foreach $irule (@induced_rules_lst_sort) ## For each induced rule: start
 {
   ## Initializations
   $i_members_str = ""; ## Fragments of induced rule as string
   @i_members_lst = (); ## Fragments of induced rule in array
   %i_members_hsh = (); ## Fragments of induced rule in hash
   %i_checked = (); ## Hash storing fragments of induced rule that were checked
   %i_exact_checked = (); ## Hash storing fragments of induced rule that were checked for exact induction
   %i_under_checked = (); ## Hash storing fragments of induced rule that were checked for under induction
   %i_over_checked = ();  ## Hash storing fragments of induced rule that were checked for over induction
   $g_members_str = ""; ## Fragments of respective groundtruth rule as string
   @g_members_lst = (); ## Fragments of respective groundtruth rule in array
   %g_members_hsh = (); ## Fragments of respective groundtruth rule in hash

   ## Current induced rule
   ##--------------------- 
print $irule." - ".$induced_rules2members{$irule}."\n";
   $i_members_str = $induced_rules2members{$irule};
   @i_members_lst = split(/,/,$i_members_str);
   if ($ignore == 0) {  
      $TOT_FRAG_INDUCE += $#i_members_lst + 1; ## Update (global) counter of induce fragments
   }
   foreach (@i_members_lst) { $i_members_hsh{$_} = 1; }

   ## Respective groundtruth rule
   ##----------------------------
   $respective_g_rule_exists = 0;
   if (defined($groundtruth_rules2members{$irule})) { 
	$respective_g_rule_exists = 1;
        if ($ignore == 1) {  
          $TOT_FRAG_INDUCE += $#i_members_lst + 1; ## Update (global) counter of induce fragments
        }
   }

   if ($respective_g_rule_exists == 1)
   {

      $g_members_str = $groundtruth_rules2members{$irule};
      @g_members_lst = split(/,/,$g_members_str);
      foreach (@g_members_lst) { $g_members_hsh{$_} = 1; }

      foreach $cur_i_member (@i_members_lst) ## For each fragment of induced rule: start
       {
         $length_i_member = 0; ## Initialization
         @i_lst = split(/\s+/,$cur_i_member); ## Tokens of induced fragment into array
         $length_i_member = $#i_lst + 1; ## Length of current induced fragment (number of  tokens)
         $lchar_i_member = 0;
         $lchar_i_member = length($cur_i_member); ## Length of current induced fragment (number of  chars) 

          ## Compare with members of respective groundtruth rule
          ##----------------------------------------------------
          if (defined($g_members_hsh{$cur_i_member})) ## Exact match
           {
             if ( (!(defined($i_exact_checked{$cur_i_member}))) && (!(defined($i_checked{$cur_i_member}))) )
              {
               $i_checked{$cur_i_member} = 1;
               $i_exact_checked{$cur_i_member} = 1;
               $Tot_Exact_Induce += 1;
              }
           }
         elsif (!(defined($g_members_hsh{$cur_i_member}))) ## No exact match. So, check for under-induction or over-induction
           {
             ## Find best matching induced fragment
             ##------------------------------------
             $best_gr_frag = ""; ## Best matching frag.: initialization
             $best_gr_frag_score = -100; ## Score for best matching frag: initialization
             foreach $cur_g_member (@g_members_lst) ## For each fragment of groundtruth  rule: start
              {
               $length_g_member = 0; ## Initialization
               @g_lst = split(/\s+/,$cur_g_member); ## Tokens of groundtruth fragment into array
               $length_g_member = $#g_lst + 1; ## Length of current groundtruth fragment (number of  tokens) 
               $lchar_g_member = 0;
               $lchar_g_member = length($cur_g_member); ## Length of current induced fragment (number of  chars) 
               $max_lchar = 0; ## Find longest fragment
               if ($lchar_g_member >= $lchar_i_member) { $max_lchar = $lchar_g_member; }
               else { $max_lchar = $lchar_i_member; }
		$dist = 0; ## distance

		if ($metric == 0) {
			## Using Levenshtein distance
			$dist = distance($cur_g_member,$cur_i_member);
			$dist_norm = 0; ## Normalized Levenshtein distance
			$dist_norm = $dist / $max_lchar;
			$sim_norm = 0; ## Normalized similarity
			$sim_norm = 1 - $dist_norm;
		} elsif ($metric == 1) {
			## Using Longest Common Substring distance
			my @s1 = split /\s+/ => $cur_g_member; # seperate words of sentences
			my @s2 = split /\s+/ => $cur_i_member; # seperate words of sentences
			my $size1 = $#s1 + 1;
			my $size2 = $#s2 + 1;
			my $words = 0;

			$seq = lcss($cur_g_member,$cur_i_member);
			$seq =~ s/^\s+|\s+$//g; # trim
			$size1 = length $cur_g_member;
			$size2 = length $cur_i_member;
			$words = length $seq;

			#---compute scores---
			$dist_norm = 0; ## Normalized LCS distance
			$dist_norm = $words/(($size1+$size2)/2);
			$sim_norm = 0; ## Normalized similarity
			$sim_norm = $dist_norm;
		}
               if ($sim_norm > $best_gr_frag_score) {
			$best_gr_frag_score = $sim_norm;
                 	$best_gr_frag = $cur_g_member;
		}

               } ## For each member of induced  rule: end
              $length_best_g = 0; ## Initialization
              @best_g_lst = split(/\s+/,$best_gr_frag); ## Tokens of best groundtruth fragment into array
              $length_best_g = $#best_g_lst + 1; ## Length of best groundtruth fragment (number of tokens)
 
              if ( ($length_best_g>$length_i_member) && (!(defined($i_checked{$cur_i_member}))) ) ## Under-induction
               {
                   $i_checked{$cur_i_member} = 1;
                   $i_under_checked{$cur_i_member} = $best_gr_frag_score;
                   $Tot_Under_Induce += $best_gr_frag_score;
               }
              if ( ($length_best_g<=$length_i_member) && (!(defined($i_checked{$cur_i_member}))) )## Over-induction
               {
                   $i_checked{$cur_i_member} = 1;
                   $i_over_checked{$cur_i_member} = $best_gr_frag_score;
                   $Tot_Over_Induce += $best_gr_frag_score;
               }

           } ## Not exact match
       } ## For each fragment of induced rule: end
   } ## If respective groundtruth rule exists


   ## Evaluation metrics for current rule
   ##------------------------------------
   $num_frags_induced = 0;
   $num_frags_exact_induced = 0;
   $num_frags_under_induced = 0;
   $num_frags_over_induced = 0;
   $cur_precision = 0;

   $num_frags_induced = $#i_members_lst + 1; ## Num of frags in current induced rule
   foreach (keys(%i_exact_checked)) { $num_frags_exact_induced += $i_exact_checked{$_}; }
   foreach (keys(%i_under_checked)) { $num_frags_under_induced += $i_under_checked{$_}; }
   foreach (keys(%i_over_checked)) { $num_frags_over_induced += $i_over_checked{$_}; }

   $cur_precision = ($num_frags_exact_induced+($lambda1*$num_frags_under_induced)+($lambda2*$num_frags_over_induced)) / ($num_frags_induced);

   $cur_precision = sprintf("%.3f", $cur_precision);
   $PrecPerRule{$irule} = $cur_precision;

 } ## For each induced rule: end




## Report eval metrics for each individual rule
##---------------------------------------------
print ("\n");
print ("RULE PRECISION RECALL FMEASURE\n");
foreach $k (keys(%RecPerRule))
 {
   if ( (defined($RecPerRule{$k})) && (defined($PrecPerRule{$k})) ) ## If exists
    {
      ## Initialize
      $current_rule_prec = 0;
      $current_rule_rec = 0;
      $current_rule_fm = 0;
      $current_rule_prec = $PrecPerRule{$k};
      $current_rule_rec = $RecPerRule{$k};
      if ( ($current_rule_prec>0) && ($current_rule_rec>0) ) ## Avoid div by zero
       {
         $current_rule_fm = (2*$current_rule_prec*$current_rule_rec) / ($current_rule_prec+$current_rule_rec);
       }
      else
       {
         $current_rule_fm = 0;
       }
    }
   else
    {
      $current_rule_prec = 0;
      $current_rule_rec = 0;
      $current_rule_fm = 0;
    }
  $current_rule_prec = sprintf("%.3f",$current_rule_prec);
  $current_rule_rec = sprintf("%.3f",$current_rule_rec);
  $current_rule_fm = sprintf("%.3f",$current_rule_fm);
  print ($k," ",$current_rule_prec," ",$current_rule_rec," ", $current_rule_fm,"\n");
  print RES ($k,",",$current_rule_prec,",",$current_rule_rec,",", $current_rule_fm,"\n");
 }


## Compute and report eval metrics for all rules
##----------------------------------------------
$TOT_PREC = 0;
$TOT_REC = 0;
$TOT_FM = 0;
if ($TOT_FRAG_INDUCE == 0) {
	$TOT_PREC = 0.000;
} else {
	$TOT_PREC = ($Tot_Exact_Induce+($lambda1*$Tot_Under_Induce)+($lambda2*$Tot_Over_Induce)) / ($TOT_FRAG_INDUCE);
}
$TOT_REC = ($Tot_Exact_Ground+($lambda1*$Tot_Under_Ground)+($lambda2*$Tot_Over_Ground)) / ($TOT_FRAG_GROUND);
if ($TOT_PREC+$TOT_REC == 0) {
	$TOT_FM = 0.000;
} else {
	$TOT_FM = (2*$TOT_PREC*$TOT_REC) / ($TOT_PREC+$TOT_REC);
}
$TOT_PREC = sprintf("%.3f", $TOT_PREC);
$TOT_REC = sprintf("%.3f", $TOT_REC);
$TOT_FM = sprintf("%.3f", $TOT_FM);
print ("ALL_RULES ",$TOT_PREC," ",$TOT_REC," ",$TOT_FM,"\n");
print RES ("ALL_RULES,",$TOT_PREC,",",$TOT_REC,",",$TOT_FM,"\n");

print ("\n");
close (RES);


## Subroutines
sub lcss{
	my ($a, $b) = @_;
	if ($a ne ""){
		$a=~s/[\*!\+,\.;\(\)\[\]:=?]+/ /g;
	}
	if ($b ne ""){
		$b=~s/[\*!\+,\.;\(\)\[\]:=?]+/ /g;
	}
		
	($a, $b) = ($b, $a) if length $a > length $b;
	my ($longest_c, $longest) = 0;
	for my $start (0..length $a) {
		for my $len ( reverse $start+1 .. length $a) {
			my $substr = substr($a, $start, $len);
			length $1 > $longest_c and ($longest_c, $longest) = (length $1, $1)
				while $b =~ m[($substr)]g;
		}
	}
	return $longest;
}
#---------end of longest common substring---------
