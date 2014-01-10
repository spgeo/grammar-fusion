#!/usr/bin/perl

##-----------------------------------------##
## Fusion of top-down and bottom-up rules  ##
## v0.0: very basic scheme: union          ##
##-----------------------------------------##

$topdown_in  = $ARGV[0]; chomp($topdown_in); ## Top-down input file
$bottomup_in  = $ARGV[1]; chomp($bottomup_in); ## Bottom-up output file
$output = $ARGV[2]; chomp($output); ## Output: fusion

## Load top-down rules
##--------------------
%td = ();
open (T,"$topdown_in") || die "Can not open $topdown_in \n";
$r = <T>;
while ($r ne "")
 {
  chomp($r);
  #print ($r,"\n");
  @toks = ();
  @toks = split(/,/,$r);
  $label = "";
  $label = $toks[0];
  shift (@toks);
  $mems = "";
  $mems = join(",",@toks);
  #print ($label,"-->",$mems,"\n");
  $td{$label} = $mems;
  $r = <T>;
 }
close (T); 


## Load bottom-up rules
##---------------------
%bu = ();
open (B,"$bottomup_in") || die "Can not open $bottomup_in \n";
$r = <B>;
while ($r ne "")
 {
  chomp($r);
  #print ($r,"\n");
  @toks = ();
  @toks = split(/,/,$r);
  $label = "";
  $label = $toks[0];
  shift (@toks);
  $mems = "";
  $mems = join(",",@toks);
  #print ($label,"-->",$mems,"\n");
  $bu{$label} = $mems;
  $r = <B>;
 }
close (B);


## Simple fusion
##-------------
%fused = ();

foreach $td_lab (keys(%td))
 {

   if (defined($bu{$td_lab}))
    {
      %cur_fused = ();
      %cur_td = %cur_bu = ();
      $cur_td_mem_str = $cur_bu_mem_str =();
      @ar1 = @ar2 = ();
      @ar1 = split (/,/,$td{$td_lab});
      @ar2 = split (/,/,$bu{$td_lab});
      foreach (@ar1) { $cur_fused{$_} = 1; }
      foreach (@ar2) { $cur_fused{$_} = 1; }
      
      $cur_fused_str = "";
      foreach (keys(%cur_fused))
       {
         $cur_fused_str .= $_.",";
       }

      $fused{$td_lab} = $cur_fused_str;
    }
   else
    {
      $fused{$td_lab} = $td{$td_lab};
    }

 }


## Report results of fusion
##-------------------------
open (O,">$output") || die "can not write outout \n";
foreach $fus_label (keys(%fused))
 {
   $fus_mem = "";
   $fus_mem = $fused{$fus_label};
   $fus_mem =~ s/,$//g;
   print O ($fus_label,",",$fus_mem,"\n");
 }
close (O);
