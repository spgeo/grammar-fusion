#!/usr/bin/perl

use Text::Levenshtein qw(distance); ## Module from CPAN for Levenshtein distance

##-------------------------------------------------------------------------------##
## Functionality                                                                 ##
##--------------                                                                 ##
## Mapping of rules that are contained in two files.                             ##
## *** The mapping is NOT performed according to the rule labels. ***            ##    
## *** The right part of rules is used for finding the best mapping. ***         ##      
## For this purpose, the normalised Levenshtein or LCS distance is used.         ##
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

# Directories
my $root_dir = "";
my $data_dir = $root_dir;

## Input
##------
$srcf = $ARGV[0]; chomp ($srcf); ## Source file
$trgf = $ARGV[1]; chomp ($trgf); ## Target file
$sch = $ARGV[2]; chomp ($sch); ## Mapping scheme
$mtrc = $ARGV[3]; chomp ($mtrc); ## Metric option 

## Output file
##------------
$outf = $srcf."_".$trgf.".".$sch;
$mostf = $srcf."_".$trgf.".".$sch.".most";
open (OUT,">".$root_dir.$outf) || die "Can not open output file $outf for writing mapping.\n";
open (MOST,">".$root_dir.$mostf) || die "Can not open output file $mostf for writing mapping.\n";

## Load source file
##-----------------
%source = ();
$s_c = 0;
open (S,$data_dir.$srcf) || die "Can not read source file $srcf \n";
$r = <S>;
while ($r ne "") {
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
open (T,$data_dir.$trgf) || die "Can not read target file $trgf \n";
$r = <T>;
while ($r ne "") {
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
foreach $sr (keys(%source)) { ## For each source rule: start
   ## Initialization
   ##---------------
   $MIN_AVG_DIST = 100; ## Min dist. for current source rule
   $MAPPED_TARGET_RULE = ""; ## Target rule that corresponds to min. dist.

   @src_frags = ();
   @src_frags = split(/,/,$source{$sr});
   $src_frag_str_mod = "";
   @src_frags_mod = ();
   foreach $srfrag (@src_frags) { ## For each source rule; fragment: start
      if ($sch eq "lexsem") {
         $src_frag_str_mod = $srfrag;
      }
      if ($sch eq "sem") {
         @tmp = ();
         @tmp = split(/\-/,$srfrag);
         $tmp_str = "";
         foreach (@tmp) { if ($_ =~ /\</) { $tmp_str .= $_."-"; } }
         chop($tmp_str);
         $src_frag_str_mod = $tmp_str;
      }
      if ($sch eq "lex") {
         @tmp = ();
         @tmp = split(/\-/,$srfrag);
         $tmp_str = "";
         foreach (@tmp) { if (!($_ =~ /\</)) { $tmp_str .= $_."-"; } }
         chop($tmp_str);
         $src_frag_str_mod = $tmp_str;
       }
	if ($src_frag_str_mod ne "") {
		push (@src_frags_mod,$src_frag_str_mod);
	}
    } ## For each source rule; fragment: end

    ## Iterate over the rules of target file
    ##--------------------------------------
    foreach $tr (keys(%target)) { ## For each target rule: start
       @trg_frags = ();
       @trg_frags = split(/,/,$target{$tr});
       $trg_frag_str_mod = "";
       @trg_frags_mod = ();
       foreach $trfrag (@trg_frags) { ## For each target rule; fragment: start
          if ($sch eq "lexsem") {
             $trg_frag_str_mod = $trfrag;
          }
          if ($sch eq "sem") {
             @tmp = ();
             @tmp = split(/\-/,$trfrag);
             $tmp_str = "";
             foreach (@tmp) { if ($_ =~ /\</) { $tmp_str .= $_."-"; } }
             chop($tmp_str);
             $trg_frag_str_mod = $tmp_str;
          }
          if ($sch eq "lex") {
             @tmp = ();
             @tmp = split(/\-/,$trfrag);
             $tmp_str = "";
             foreach (@tmp) { if (!($_ =~ /\</)) { $tmp_str .= $_."-"; } }
             chop($tmp_str);
             $trg_frag_str_mod = $tmp_str;
          }
	  if ($trg_frag_str_mod ne "") {
		push (@trg_frags_mod,$trg_frag_str_mod);
	  } 
        
        } ## For each target rule; fragment: end

        ##-------------------------------------------------------##
        ## Compute Lev. dist between source rule and target rule ##
        ##-------------------------------------------------------##
        $sum_dist = 0;
        $avg_dist = 0;
        $num_dist = 0;
	$cc = 0;
        foreach $cur_s (@src_frags_mod) {
           $len_s = length($cur_s);
           foreach $cur_t (@trg_frags_mod) {
              $num_dist ++;
              $len_t = length($cur_t);
              ## Find max length
              ##----------------
              $max_len = -1;
              if ($len_s >= $len_t) { $max_len = $len_s; }
              else { $max_len = $len_t; }
		if ($mtrc == 0) {
	              ## Compute Lev. distance
	              ##----------------------
	              $Dist = 0; ## Init. dist.
	              $DistNorm = 0; ## Init. normalized dist. (between 0-1)
	              $Dist = distance($cur_s,$cur_t);
		      $DistNorm = $Dist / $max_len;
		} elsif ($mtrc == 1) {
		      ## Compute LCS distance
		      ##----------------------
			my @s1 = split /\s+/ => $cur_s; # seperate words of sentences
			my @s2 = split /\s+/ => $cur_t; # seperate words of sentences
			my $size1 = $#s1 + 1;
			my $size2 = $#s2 + 1;
			my $words = 0;

			$seq = lcss($cur_s,$cur_t);
			$seq =~ s/^\s+|\s+$//g; # trim
			$size1 = length $cur_s;
			$size2 = length $cur_t;
			$words = length $seq;

			#---compute scores---
			$dist_norm = 0; ## Normalized LCS distance
			$DistNorm = 1 - ($words/(($size1+$size2)/2)); ## Normalized similarity
		}
	      $sum_dist += $DistNorm;
            }
           }
	  if ($num_dist > 0) {
            $avg_dist = $sum_dist / $num_dist;
          } else { $avg_dist = 1; }
  
#	  $mappings{"$tr;$sr"} = $avg_dist;

          ## Update min. dist and corresponding rule
          ##----------------------------------------
	  #if ($cc<=10) {
		print MOST ($sr," ",$tr," ",$avg_dist,"\n");
	#	$cc++;
	  #}
          if ($avg_dist < $MIN_AVG_DIST) {
            $MIN_AVG_DIST = $avg_dist;
            $MAPPED_TARGET_RULE = $tr;
           }
     } ## For each target rule: end
   print ($sr," ",$MAPPED_TARGET_RULE," ",$MIN_AVG_DIST,"\n");
   print OUT ($sr," ",$MAPPED_TARGET_RULE," ",$MIN_AVG_DIST,"\n");
} ## For each source rule: end

close (MOST);
close (OUT);

## Subroutines
sub lcss {
	my ($a, $b) = @_;
	if ($a ne ""){
		$a =~ s/[\*!\+,\.;\(\)\[\]:=?]+/ /g;
	}
	if ($b ne ""){
		$b =~ s/[\*!\+,\.;\(\)\[\]:=?]+/ /g;
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
