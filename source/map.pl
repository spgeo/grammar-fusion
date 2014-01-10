#!/bin/perl

use Text::Levenshtein qw(distance); ## Module from CPAN for Levenshtein distance

##-------------------------------------------------------------------------------##
## Functionality                                                                 ##
##--------------                                                                 ##
## Mapping of rules that are contained in two files.                             ##
## *** The mapping is NOT performed according to the rule labels. ***            ##    
## *** The right part of rules is used for finding the best mapping. ***         ##      
## For this purpose, the normalised Levenshtein distance is used.                ##
## The best mapping is given along with a mapping score.                         ##
## The rules (and corresponding files) are distinguished into two types:         ##
## "source" and "target".                                                        ##
## Each source rule is mapped to one target rule.                                ##
## Note that a target rule is allowed to be mapped to multiple source rules.     ## 
##                                                                               ##
## Input arguments                                                               ## 
##----------------                                                               ##
## 1. File of source rules: Each rule of this file is mapped                     ##
##    to one of the rules contained in the file of target rules.                 ##
## 2. File of target rules.                                                      ##
## 3. Mapping scheme: What type of information to use for computing mapping.     ##
##    Consider the example "FROM-TO-<CITYNAME>".                                 ##
##    Three options are available:                                               ##                                     
##    - "lexsem": use Lexical and Semantic info, e.g., "FROM-TO-<CITYNAME>"      ##
##    - "lex": use Lexical info only, e.g., "FROM-TO"                            ##
##    - "sem": use Semantic info only, e.g., "<CITYNAME>"                        ##
##                                                                               ##
## Output                                                                        ##
##-------                                                                        ##
## A file named according to all 3 input arguments as:                           ##
## src_trg.sch                                                                   ##
## where "src" is the name of the file of source rules (1st input arg.)          ##                         
##       "trg" is the name of the file of target rules (2nd input arg.)          ##
##       "sch" is the mapping scheme (3rd input arg.)                            ##   
## Each line of the output file has 3 entries:                                   ##
## 1st entry: the label of source rule                                           ##       
## 2nd entry: the label of target rule                                           ##
## 3rd entry: A matching score ranging between 0-1.                              ##
##      Lower scores correspond to better matching.                              ##
##                                                                               ##
## How to run examples                                                           ##
##--------------------                                                           ##
## perl map.pl td bu lexsem                                                      ##
## perl map.pl td bu lex                                                         ##
## perl map.pl td bu sem                                                         ##
##                                                                               ##
## Iosif Elias                                                                   ##
## 31 July 2013                                                                  ##
##-------------------------------------------------------------------------------##


## Input
##------
$srcf = $ARGV[0]; chomp ($srcf); ## Source file
$trgf = $ARGV[1]; chomp ($trgf); ## Target file
$sch = $ARGV[2]; chomp ($sch); ## Mapping scheme

## Output file
##------------
$outf = $srcf."_".$trgf.".".$sch;
open (OUT,">$outf") || die "Can not open output file $outf for writing mapping.\n";

## Load source file
##-----------------
%source = ();
$s_c = 0;
open (S,"$srcf") || die "Can not read source file $srcf \n";
$r = <S>;
while ($r ne "")
 {
  $s_c ++;
  chomp($r);
  @fields = ();
  @fields = split(/,/,$r);
  $lab = "";
  $lab = shift(@fields);
  $frags_str = "";
  $frags_str = join(",",@fields);
  $source{$lab} = $frags_str; ## Store label (even not used) in association with fragments (as string)
  $r = <S>;
 }
close (S);
print ("- ",$s_c," rules loaded from source file.\n");

## Load target file
##-----------------
%target = ();
$t_c = 0;
open (T,"$trgf") || die "Can not read target file $trgf \n";
$r = <T>;
while ($r ne "")
 {
  $t_c ++;
  chomp($r);
  @fields = ();
  @fields = split(/,/,$r);
  $lab = "";
  $lab = shift(@fields);
  $frags_str = "";
  $frags_str = join(",",@fields);
  $target{$lab} = $frags_str; ## Store label (even not used) in association with fragments (as string)
  $r = <T>;
 }
close (T);
print ("- ",$t_c," rules loaded from target file.\n");

## Iterate over the rules of source file
##--------------------------------------
foreach $sr (keys(%source)) ## For each source rule: start
 {
   ## Initialization
   ##---------------
   $MIN_AVG_DIST = 100; ## Min dist. for current source rule
   $MAPPED_TARGET_RULE = ""; ## Target rule that corresponds to min. dist.

   @src_frags = ();
   @src_frags = split(/,/,$source{$sr});
   $src_frag_str_mod = "";
   @src_frags_mod = ();
   foreach $srfrag (@src_frags) ## For each source rule; fragment: start
    {
      if ($sch eq "lexsem")
       {
         $src_frag_str_mod = $srfrag;
       }
      if ($sch eq "sem")
       {
         @tmp = ();
         @tmp = split(/\-/,$srfrag);
         $tmp_str = "";
         foreach (@tmp) { if ($_ =~ /\</) { $tmp_str .= $_."-"; } }
         chop($tmp_str);
         $src_frag_str_mod = $tmp_str;
       }
      if ($sch eq "lex")
       {
         @tmp = ();
         @tmp = split(/\-/,$srfrag);
         $tmp_str = "";
         foreach (@tmp) { if (!($_ =~ /\</)) { $tmp_str .= $_."-"; } }
         chop($tmp_str);
         $src_frag_str_mod = $tmp_str;
       }
      push (@src_frags_mod,$src_frag_str_mod);  
    } ## For each source rule; fragment: end

    ## Iterate over the rules of target file
    ##--------------------------------------
    foreach $tr (keys(%target)) ## For each target rule: start
     {
       @trg_frags = ();
       @trg_frags = split(/,/,$target{$tr});
       $trg_frag_str_mod = "";
       @trg_frags_mod = ();
       foreach $trfrag (@trg_frags) ## For each target rule; fragment: start
        {
          if ($sch eq "lexsem")
           {
             $trg_frag_str_mod = $trfrag;
           }
          if ($sch eq "sem")
           {
             @tmp = ();
             @tmp = split(/\-/,$trfrag);
             $tmp_str = "";
             foreach (@tmp) { if ($_ =~ /\</) { $tmp_str .= $_."-"; } }
             chop($tmp_str);
             $trg_frag_str_mod = $tmp_str;
           }
          if ($sch eq "lex")
           {
             @tmp = ();
             @tmp = split(/\-/,$trfrag);
             $tmp_str = "";
             foreach (@tmp) { if (!($_ =~ /\</)) { $tmp_str .= $_."-"; } }
             chop($tmp_str);
             $trg_frag_str_mod = $tmp_str;
           }
          push (@trg_frags_mod,$trg_frag_str_mod);
        } ## For each target rule; fragment: end

        ##-------------------------------------------------------##
        ## Compute Lev. dist between source rule and target rule ##
        ##-------------------------------------------------------##
        $sum_dist = 0;
        $avg_dist = 0;
        $num_dist = 0;
        foreach $cur_s (@src_frags_mod)
         {
           $len_s = length($cur_s);

           foreach $cur_t (@trg_frags_mod)
            {
              $num_dist ++;
              $len_t = length($cur_t);
              ## Find max length
              ##----------------
              $max_len = -1;
              if ($len_s >= $len_t) { $max_len = $len_s; }
              else { $max_len = $len_t; }
              ## Compute Lev. distance
              ##----------------------
              $LevDist = 0; ## Init. dist.
              $LevDistNorm = 0; ## Init. normalized dist. (between 0-1)
              $LevDist = distance($cur_s,$cur_t);
              $LevDistNorm = $LevDist / $max_len;
              $sum_dist += $LevDistNorm;
            }
           }
          $avg_dist = $sum_dist / $num_dist;
  
          ## Update min. dist and corresponding rule
          ##----------------------------------------
          if ($avg_dist < $MIN_AVG_DIST)
           {
            $MIN_AVG_DIST = $avg_dist;
            $MAPPED_TARGET_RULE = $tr;
           }
     } ## For each target rule: end
   print ($sr," ",$MAPPED_TARGET_RULE," ",$MIN_AVG_DIST,"\n");
   print OUT ($sr," ",$MAPPED_TARGET_RULE," ",$MIN_AVG_DIST,"\n");
 } ## For each source rule: end

 close (OUT);
