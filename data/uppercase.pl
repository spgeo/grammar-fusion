#! usr/bin/perl

use strict;
use warnings;

my $input = $ARGV[0];
my $output = $input.".uppercase";

open(IN,$input) || die "Cannot read $input\n";
my @lines = <IN>;
close(IN);

open(OUT,">$output") || die "Cannot write to $output\n";
foreach (@lines) {
	chomp $_;
	my $newline = "";
	my @frags = split(",",$_);
	foreach my $frag (@frags) { 
		my $newfrag = "";
		my @words = split(" ",$frag);
		foreach my $word (@words) { 
			if ($word !~ /<|>/) { $word = uc($word); }
			$newfrag .= $word." ";
		}
		chop $newfrag;
		$newline .= $newfrag.",";
	}
	chop $newline;
	print OUT $newline."\n";
}
close(OUT);
