use strict;
use warnings;

# Directories
my $root_dir = "";
my $data_dir = $root_dir;

# Variables
my $input = $ARGV[0]; chomp $input;
my $mapping = $ARGV[1]; chomp $mapping; $mapping = $root_dir.$mapping;
my $threshold = $ARGV[2]; chomp $threshold;
my $output = $root_dir."eval_".$input;
$input = $data_dir.$input;

# Loads input result to variable
my %input_grammar = ();
open(IN,$input) || die "Cannot open $input\n";
while(<IN>) {
	chomp $_;
	my @frags = split(",",$_);
	$input_grammar{$frags[0]} = "";
	for(my $i=1;$i<$#frags+1;$i++) {
		$input_grammar{$frags[0]} .= $frags[$i].","; 
	}
	chop $input_grammar{$frags[0]};
}
close(IN);

# Loads mapping information and score
my %maps_to = ();
my %map_score = ();
open(MAP,$mapping) || die "Cannot open $mapping\n";
while(<MAP>) {
	my @frags = split(" ",$_);
	$maps_to{$frags[0]} = $frags[1];
	$map_score{$frags[0]}{$frags[1]} = $frags[2];
}
close(MAP);

# Calculates and saves exported grammar, NOT combining multiple same-groundtruth-mapped rules 
# (to combine, comment #1 and uncomment #2)
# It actually makes no difference for evaluation when using eval_metrics_v3.pl
#open(OUT,">$output") || die "Cannot write to $output\n"; #1
my %export = ();
my %defined = ();
foreach my $label (keys %input_grammar) {
#print "$label maps to ";
	my $gr_label = $maps_to{$label};
#	print "$gr_label with $map_score{$label}{$gr_label}\n";
	if ($map_score{$label}{$gr_label} <= $threshold) {
		if (not defined $export{$gr_label}) { $export{$gr_label} = ""; }
#		$export{$gr_label} = ",".$input_grammar{$label}; #1
		my @frags = split(",",$input_grammar{$label}); #2
		foreach my $frag (@frags) { #2
			if (not defined $defined{$frag}) { #2
				$export{$gr_label} .= ",".$frag; #2
				$defined{$frag} = 1; #2
			} #2
		} #2
#		print OUT "$gr_label$export{$gr_label}\n"; #1
	
	}
}
#close(OUT); #1

open(OUT,">$output") || die "Cannot write to $output\n";	#2
foreach my $label (keys %export) {				#2
	if ($export{$label} ne "") {				#2
		print OUT "$label$export{$label}\n";		#2
	}							#2
}								#2
close(OUT);							#2
