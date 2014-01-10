#! /usr/bin/perl

use strict;
use warnings;

# Args
my $mapping = $ARGV[0];
my $most = $ARGV[1];
my $ground = $ARGV[2];

my $evalfile = $mapping.".results.csv";
# Open mapping file
my %mapsTo = ();
my %shouldMapTo = ();
open(MAP,$mapping) || die "Cannot read $mapping\n";
while (my $mapline = <MAP>) {
	my @blocks = split(" ",$mapline);
	my $mappedLabel = uc($blocks[0]); $mappedLabel =~ s/<|>//g;
	my $mappedToLabel = uc($blocks[1]); $mappedToLabel =~ s/<|>//g;
	$mapsTo{$mappedLabel} = $mappedToLabel;
	# Find concept/rule in groundtruth file
	open(GRD,$ground) || die "Cannot read $ground\n";
	while (my $grline = <GRD>) {
		if ($grline !~ /\{|\}/g) {
			chomp $grline;
			$grline = uc($grline);
			my ($first, $second) = split(":",$grline);
			chop $second;
			$first =~ s/\s+|\[|\]|\"//g;
			$second =~ s/\s+|\[|\]|\"//g;
			my @mappedLabelsFromGr = ();
			if ($second =~ /,/) { @mappedLabelsFromGr = split(",",$second); } else { push(@mappedLabelsFromGr,$second); }
			foreach my $mappedLabelFromGr (@mappedLabelsFromGr) {
				if ($mappedLabelFromGr eq $mappedLabel) { 
					$shouldMapTo{$mappedLabel} = $first;
				}
			}
		}
	}
	close(GRD);
}
close(MAP);

open(EVAL,">$evalfile") || die "Cannot write to $evalfile\n";
print EVAL "Concept,MappedTo,Accuracy,Correct\n";
my $accuracy_sum = 0;
my $mappedCorrectly = 0;
my $countForEval = 0;
foreach my $label (keys %shouldMapTo) {
	my $accuracy = 0;
	my $mapScore = 0;
	my $goldMapScore = 0;
	my $worstScore = 0;
	open(MOST,$most) || die "Cannot read $most:$!\n";
	while(my $line = <MOST>) {
		chomp $line;
		$line = uc($line);
		# Find mapped
		if (($line =~ /<$label>/)&&($line =~ /<$mapsTo{$label}>/)) {
			my @blocks = split(" ",$line);
			$mapScore = $blocks[2];
		}
		# Find golden
		if (($line =~ /<$label>/)&&($line =~ /<$shouldMapTo{$label}>/)) {
			my @blocks = split(" ",$line);
			$goldMapScore = $blocks[2];
		}
		# Find worst for canonicalisation
		if ($line =~ /<$label>/) {
			my @blocks = split(" ",$line);
			if ($worstScore <= $blocks[2]) { $worstScore = $blocks[2]; }
		}
	}
	close(MOST);
	if (($goldMapScore > 0)&&($mapScore > 0)) {
		# The automatic mapping mechanism has to be evaluated with the ground maps. This happens as described below:
		# We calculate the distance from the mapped score (best score) to the worst score.
		# We also calculate the distance from the mapped score to the golden score.
		# The ratio of the golden score distance and the worst score distance represents the accuracy.
		# E.g.
		# If the concept is correctly mapped, the distance from the golden concept will be 0, so the accuracy will be 100%. 
		# If the concept is wrongly mapped, we calculate how much wrong it is by normalizing the distances from the worst mapping 
		# and the gold mapping (with the worst possible case to be the worst mapped, so the distance will be 1, thus the accuracy 0%)
		# We also calculate the exact matches.
		my $distanceFromEdges = $worstScore - $mapScore;
		my $distanceFromGolden = $goldMapScore - $mapScore;
		my $accuracy = sprintf("%.4f", 1 - $distanceFromGolden/$distanceFromEdges)*100;
		$accuracy_sum += $accuracy;
		$countForEval++;
		print "Accuracy: $accuracy% ($label maps to $mapsTo{$label} - groundmap: $shouldMapTo{$label})\n";
		my $correct = 0;
		if ($distanceFromGolden == 0) { 
			$correct = 1;
			$mappedCorrectly++;
		}
		print "W: $worstScore - G: $goldMapScore - M: $mapScore\n";
		print EVAL $label.",".$mapsTo{$label}.",".$accuracy."%,".$correct."\n";
	}
}

my $accuracy_gen = 0;
my $mapped_gen = 0;
if ($accuracy_sum > 0) {
	$accuracy_gen = sprintf("%.2f", $accuracy_sum/$countForEval);
	$mapped_gen = sprintf("%.4f", $mappedCorrectly/$countForEval)*100;
	print "Overall accuracy of concept mapping: $accuracy_gen%\n";
	print "Overall exactly mapped: $mapped_gen%\n";
} else {
	print "No golden rules appear in the given grammar to evaluate with!\n";
}
print EVAL "ALL_RULES,,$accuracy_gen%,$mapped_gen%";
close(EVAL);
