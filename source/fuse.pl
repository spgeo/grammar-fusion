#!/usr/bin/perl

# Combines the bottop up rules with the top down rules using a simple union (omitting any reoccuring fragments).
# How to use: 	perl top_down bottom_up mapping
# Output:	fusion_result
# Dependencies:	None
#
# Notes:
# 1. There is a thin point that must be taken under consideration. 
# If we choose to enhance the bu rules, some td rules may be omitted and vice versa.
# This problem is solved by appending at the end of the fusion file the unmapped
# rules (in this case any bu rules that were not mapped to td rules). 
#
# 2. Another problem is that a bu rule can be mapped to more than one td rule. This 
# was overcome by augmenting the bottom up rules with their mapped top-down rules.
#
# 3. This script assumes that the top-down rules are more than the bottom-up. In a different 
# case, just a switch on the topdown and bottomup input arguments would suffice, but it would 
# produce a fusion labeled with the top-down labels. In that case a minor configuration might be 
# needed in case we always require the fusion rules to be named according to the bottom-up.

use strict;
use warnings;

# Arguments
my $input_td = $ARGV[0]; chomp $input_td;	# top-down grammar
my $input_bu = $ARGV[1]; chomp $input_bu;	# bottom-up grammar
my $mapping = $ARGV[2]; chomp $mapping;		# mapping of top-down to bottom-up
my $SCORE_LIM = 1; #$ARGV[3]; chomp $SCORE_LIM;	# mapping score threshold

# Files
my $output = "fusion_result";

# Variable instantiation
my %maps_to = (); # key: top-down rule label => value: bottom-up rule label
my %map_score = (); # key: top-down rule label, bottom-up rule label => value: mapping score
open(MAP,$mapping) || die "Cannot read $mapping\n";
while(<MAP>) {
	chomp $_;
	my ($td_label, $bu_label, $score) = split(" ",$_);
	$maps_to{$td_label} = $bu_label;
	$map_score{$td_label}{$bu_label} = $score;
}
my %td_rules = (); # key: top-down rule label => value: rule fragments
open(TD,$input_td) || die "Cannot read $input_td\n";
while(<TD>) {
	chomp $_;
	my @fragments = split(",",$_);
	$td_rules{$fragments[0]} = "";
	for(my $i=1;$i<$#fragments+1;$i++) {
		$td_rules{$fragments[0]} .= $fragments[$i].",";
	}
	chop($td_rules{$fragments[0]});
}
close(TD);
my %bu_rules = (); # key: bottom-up rule label => value: rule fragments
open(BU,$input_bu) || die "Cannot read $input_bu\n";
while(<BU>) {
	chomp $_;
	my @fragments = split(",",$_);
	$bu_rules{$fragments[0]} = "";
	for(my $i=1;$i<$#fragments+1;$i++) {
		$bu_rules{$fragments[0]} .= $fragments[$i].",";
	}
}
close(BU);

# Create the fusion
# The fusion grammar is labeled according to the bottom up labels.
# If the corresponding bottom-up-labeled fusion grammar is not defined, it
# is instantiated with its bottom-up rule.
# If it is defined (thus instantiated), it is augmented with its top down
# rules.
my %fusion = ();
my %fusion_grams = ();
my %mapped = ();
foreach my $td_label (keys %td_rules) {
	my $bu_label = $maps_to{$td_label};
	# prints corresponding BU label and union of grammars
	if (not defined $fusion{$bu_label}) {
		$fusion{$bu_label} = "";
		my @rules = split(",",$bu_rules{$bu_label});
		foreach my $rule (@rules) {
			if (not defined $fusion_grams{$bu_label}{$rule}) {
				$fusion{$bu_label} .= $rule.",";
				$fusion_grams{$bu_label}{$rule} = 1;
			}
		}
	}
	if ($map_score{$td_label}{$bu_label} < $SCORE_LIM) {
		$mapped{$td_label} = 1;
		my @rules = split(",",$td_rules{$td_label});
		foreach my $rule (@rules) {
			if (not defined $fusion_grams{$bu_label}{$rule}) {
				$fusion{$bu_label} .= $rule.",";
				$fusion_grams{$bu_label}{$rule} = 1;
			}
		}
	}
}

# Save any unmapped rules as their own.
foreach my $bu_label (keys %bu_rules) {
	if (not defined $fusion{$bu_label}) {
		$fusion{$bu_label} = $bu_rules{$bu_label};
	}
}
foreach my $td_label (keys %td_rules) {
	if (not defined $mapped{$td_label}) {
		$fusion{$td_label} = $td_rules{$td_label};
	}
}

open(OUT,">$output") || die "Cannot write to $output\n";
foreach my $label (keys %fusion) {
	print OUT "$label,$fusion{$label}\n";
}
close(OUT);
