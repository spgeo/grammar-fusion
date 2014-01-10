# This script maps automatically rules derived from a top-down algorithm with rules 
# derived from a bottom-up algorithm and then performs a fusion between them.
# Firstly, all top-down rules are mapped to individual bottom-up rules(many-to-one).
# Then, the fusion rules are constructed by using the three different fusion strategies (union, top-down
# augmentation, bottom-up augmentation)
#
# The extracted fusion grammar is evaluated by mapping its rules to individual
# ground truth rules (many-to-one). That means that many fusion grammar rules can be
# mapped to the same ground truth rule.
# For the purposes of evaluation, all rules mapped to the same ground truth rule are combined 
# into an evaluation-formatted file (eval_*, using eval_export.pl).

from fusion import start_fusion as fusion 
from extractFragments import extractFromFile as extract
import sys, subprocess

argument1 = str(1)
argument2 = str(1)
#0 uses exact match
#1 uses metric
ignore = str(0)
version = str(2)
metric = str(0)	# 0 uses Levenhstein, 1 uses Longest Common Substring

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print "python start.py input_BU input_TD groundtruth threshold metric fusion_strategy mapping"
        exit(1)
    else:
        input_BU_orig = sys.argv[1]
        input_TD_orig = sys.argv[2]
	groundtruth = sys.argv[3]
	strategy = sys.argv[4] 		# 1 for simple union, 2 for top-down augmentation, 3 for bottom-up augmentation
	#mapping = sys.argv[5] 		# 0 for none, 1 for mapping top-down to bottom-up, 2 for reverse
	#threshold = sys.argv[6] 	# 1 (no threshold), 0.8 or 0.6

	# Copy the top down and bottom up grammars for possible processing (to keep the originals unaffected)
	cmd = ["cp", input_TD_orig, "../extracted_TD"]
        pipe = subprocess.Popen(cmd,stdout=subprocess.PIPE)
        pipe.wait()
	input_TD = "extracted_TD"
	cmd = ["cp", input_BU_orig, "../extracted_BU"]
        pipe = subprocess.Popen(cmd,stdout=subprocess.PIPE)
        pipe.wait()
	input_BU = "extracted_BU"

        fusion("../"+input_TD,"../"+input_BU,"fusion_result."+strategy,strategy)
        print "Fusion of "+str(input_BU_orig)+" and "+str(input_TD_orig)+" is done"
	exit(1);


        #cmd = ["perl", "results2texV2.pl", "../evaluation_results/v_"+version+"/metric_"+metric+"/mapping_"+mapping+"/strategy_"+strategy+"/thresh_"+threshold+"/eval_fusion_result.L1_"+argument1+"L2_"+argument2+".results.csv"]
        #pipe = subprocess.Popen(cmd,stdout=subprocess.PIPE)
        #print "\t\tEvaluation of the fusion fragments is done"
        


        
        
        
    
