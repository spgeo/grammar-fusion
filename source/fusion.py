#This file creates a fusion of to sets of grammar fragments and returns a combination of it to a given file
import subprocess
import simple_union
def fusion(input1,input2):
#    More advanced fusion have to be add here
    f_in1 = open(input1,"r")
    f_in2 = open(input2,"r")
    fusion_string = ""
    
    for line in f_in2:
        fusion_string += line
    
    
    
    f_in1.close()
    f_in2.close()
    
    return fusion_string


    
def start_fusion(input1, input2, output, argument):
#Chose here the fusion strategy!
#first input is augmented - do not change input here, but in the start.py
    if argument == "1":
        print "Simple Union..."
        simple_union.fuse(input1,input2,output)
    elif argument == "2":
        print "Augment fusion (top-down)..."
        cmd = ["perl", "augment_fusion.pl", input1, input2,output]
        pipe = subprocess.Popen(cmd,stdout=subprocess.PIPE)
        pipe.wait()
    elif argument == "3":
        print "Augment fusion (bottom-up)..."
        cmd = ["perl", "augment_fusion.pl", input2, input1,output]
        pipe = subprocess.Popen(cmd,stdout=subprocess.PIPE)
        pipe.wait()
    
    
    
    
