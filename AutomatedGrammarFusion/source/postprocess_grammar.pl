#!/usr/bin/perl

# Combines the rules by unifying all rules containing common fragments and clearing them from "noisy" fragments (with no concepts). Duplicated fragments are ignored, as well as empty statements.
# How to use: 	perl postprocess_grammar.pl <arg1> <arg2>
# Output:	<arg2>
# Dependencies:	None
#

use strict;
use warnings;

# Files
my $input_file = $ARGV[0]; chomp($input_file);
my $output_file = $input_file;

my %td_statements = (); # key: top-down statement label => value: statement fragments
my %mapsto = (); # each key(fragment) maps to a value(statement)
my %combine = (); # each key(statement) should be combined to a value(comma-seperated statements)
my %combinations = (); # contains the different combinations
open(TD,$input_file) || die "Cannot read $input_file\n";
print "Finding combinations and clearing fragments\n---------------------------\n";
while(<TD>) {
	chomp $_;
	my @fragments = split(",",$_);
	$td_statements{$fragments[0]} = "";
	for(my $i=1;$i<$#fragments+1;$i++) {
		if ($fragments[$i] =~ /<|>/) { # Clear from noisy fragments
			$td_statements{$fragments[0]} .= $fragments[$i].",";
			if (not defined $mapsto{$fragments[$i]}) {
				$mapsto{$fragments[$i]} = $fragments[0];
			} else {
				# The fragment was earlier defined, meaning that is also 
				# belongs to another statement. The statements will have to be
				# combined
				my $mappedStatement = $mapsto{$fragments[$i]};
				# check if mapped statement is mapped somewhere itself
				if (defined $combine{$mappedStatement}) {
					print "We have a higher level! $mappedStatement maps to $combine{$mappedStatement}, so $fragments[0] should too. \n";
					$mappedStatement = $combine{$mappedStatement};
				}
				$combine{$fragments[0]} = $mappedStatement;
				$combinations{$fragments[0]}{$mappedStatement} = 1;
				print "$fragments[0] should be combined with $mappedStatement (common: $fragments[$i])\n";
			}
		}
	}
	chop($td_statements{$fragments[0]});
}
close(TD);

print "\nApplying combinations\n---------------------------\n";
my %grammar_rules = (); # yeeeeeeeah
my %defined = (); # to check if fragment is defined again in a rule
open(OUT,">$output_file") || die "Cannot write to $output_file\n";
foreach my $statement (keys %td_statements) {
	if ($td_statements{$statement} ne "") {
		my $fragments = "";
		my $isCombined = 0;
		# Is there something to combine from?
		foreach my $combo (keys %combine) {
			if ($combine{$combo} eq $statement) {
				print "$combo combined to $statement\n";
				my @frags = split(",",$td_statements{$combo});
				foreach my $frag (@frags) {
					# check if already in rule
					if (not defined $defined{$frag}{$statement}) {
						$defined{$frag}{$statement} = 1;
						$fragments .= ",".$frag;
					}
				}
			}
			if ($combo eq $statement) { 
				print "$combo is ignored as it is combined\n";
				$isCombined = 1;
			}
		}
		next if ($isCombined == 1);
		# Append its own fragments now to complete its awesomeness
		my @frags = split(",",$td_statements{$statement});
		foreach my $frag (@frags) {
			# check if already in rule
			if (not defined $defined{$frag}{$statement}) {
				$defined{$frag}{$statement} = 1;
				$fragments .= ",".$frag;
			}
		}
		$grammar_rules{$statement} = $fragments;
		# Print them out
		print OUT "$statement$fragments\n";
	}
}
close(OUT);
