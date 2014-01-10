import re

def mapping(extracted_file,mapped_output_file,groundtruthFile):
#    f_out = open(mapped_output_file,"w")
    f_out = open(mapped_output_file,"w")
    f_out.write(optimiseSimpleMapping(extracted_file,groundtruthFile))
    f_out.close()




def simulation():
    write_string = ""
    f_in = open("extracted-manualMapping1","r")
    for line in f_in:
        write_string += line
    f_in.close()
    return write_string
#    return "<FROMCITY>,<ATTRIBUTE_FLIGHT>-<DATESPEC_RELATIVE>-<CITYNAME>-TO-<CITYNAME>"


def optimiseSimpleMapping(extracted_file,groundtruthFile):
    f_ground =  open(groundtruthFile,"r")
#    create hm with inverse index, so each rule is a key and the attribute is the value
    inverse_hm = {}
#    here key is the attribute and the value is a list of rules => Precision should be always 1 with this approach
    hm = {}
    returnstring = ""
    for line in f_ground:
        line = line.replace("\n","")
        tmp = line.split(",")
        value = tmp[0]
#        print ("line1",line)
        for x in tmp[1:]:
            inverse_hm[x] = value # inverse_hm(groundtruth) : keys are fragments, value is where they belong (grammar rule)
    f_ground.close()
    
    f_in = open(extracted_file,"r")
    
    for line in f_in:
        line = line.replace("\n","")
        tmp = line.split(",")
#        print ("line2",line)

        value = tmp[0] # e.g. <statement_5>
        for x in tmp[1:]:
#            Take out two attributes out of x and check, in which values from inverse_hm this occurs
#            then the rule will be set to the attributes with the most occurrences
            tmp =  re.findall(r'-(<[A-Z]*>)-', x)
            number_hm = {}

            if len(tmp)>1: # two or more concepts in fragment
                for key, value in inverse_hm.iteritems():
                    if tmp[0] in key and tmp[1]:
                        if number_hm.has_key(value):
                            tmp_int = number_hm[value]
                            number_hm[value] = tmp_int + 1
                        else:
                            number_hm[value] = 1
            elif len(tmp) == 1: # one concept in fragment
                for key, value in inverse_hm.iteritems():
                    if tmp[0] in key:
                        if number_hm.has_key(value):
                            tmp_int = number_hm[value]
                            number_hm[value] = tmp_int + 1
                        else:
                            number_hm[value] = 1

#            now chose attribute with the highest number for the given x
                highest_atribute = ""
                highest_number = 0
                for key, value in number_hm.iteritems():
                    if value > highest_number:
                        highest_number = value
                        highest_atribute = key
                if hm.has_key(highest_atribute):
                   t_h = hm[highest_atribute]
                   if x not in t_h:
                       t_h.append(x)
                       hm[highest_atribute] = t_h
                else:
                    hm[highest_atribute] = [x]
                        
    for key in hm:
        if key == "":
            pass
        else:
           # print ("key in mapping",key)
            returnstring+=key+"," 
            for x in hm[key]:
                returnstring+=x+"," 
            returnstring = returnstring[:-1]
            returnstring += "\n"    
    
    
    f_in.close()
#    print ("returnstring",returnstring)   
    return returnstring

    
    
    
    
