from mapping import mapping
import sys, re


def importENabnf():
    hm = {}
    f_in = open("../data/en.abnf","r")
    for line in f_in:
        line = line.replace("\n","")
        line = line.replace("\"","")
        if line == ",":
            pass
        else:
            if "=" in line:
                tmp = line.split("=")
                name = tmp[0].replace("$","")
    #            I only want terminal to non-terminal relations and not rules, which point to another non-terminal.
                if "$" in tmp[1]:
                    pass
                else:
                    tmp_terminal = tmp[1].split("|")
                    for x in tmp_terminal:
                        hm[x.lower()] = name
                    
                
#    print hm
    f_in.close()
    return hm

#First simple approach for extracting pattern from an input file and additionoly substitution of words, e.g. Los Angeles to <CITYNAME>




def extractFromFile(input_file):  
    #hm_terminal_enABNF = importENabnf()
    f = open(input_file,"r")
    f_out_overall = open("../extracted_TD","w")
    
    counter_line = 0
    original_sentence = []
    statement_hm = {}
    statement_overall = {}

    
    for line in f:
        line = line.replace("\n","")
        flag = False
        if line.startswith("<"):
            tmp = line.split(" -> ")
            #if hm_terminal_enABNF.has_key(tmp[1].lower()):
            #    replacement = hm_terminal_enABNF[tmp[1].lower()]
            #    statement_hm[tmp[0]] = replacement
            #else:
            statement_hm[tmp[0]] = tmp[1]
        if line == "":
            for key,value in statement_hm.iteritems():
                if "Statement" in key:
                    while "Unknown" in value or "Statement" in value:
                        value = value.replace(" ","-")
                        value = value.replace("-<SGM>","")
                        tmp_terminals =  re.findall(r'(<[A-Za-z\_0-9]*>)', value)
                        for y in tmp_terminals:
                            try:
                                if "Unknown" not in statement_hm[y] and "Individual" not in statement_hm[y] and "Statement" not in statement_hm[y]:
                                    value = value.replace(y,"<"+statement_hm[y].upper().replace(" ","")+">")
                                else:
                                    value = value.replace(y,statement_hm[y])
                            except:
                                pass
                if statement_overall.has_key(key):
                    t_s = statement_overall[key]
                    if value in t_s:
                        pass
                    else:
                        t_s.append(value)
                        statement_overall[key] = t_s
                else:
                    statement_overall[key] = [value]
                    
            statement_hm = {}

#Idee: Alle regeln fuer einen Block raussuchen, die mit < beginnen.
#Dann an " -> " trennen (speichern in tmp) und dann hm erzeugen, key= tmp[0] value = tmp[1]
#im letzten schritt dann laengste staetment regeln nehmen, die "unknowns" in der Liste nachschauen, und dann direkt matchen zu en.abnf.
#Danach dann normal weiter zum mapping, allerdings schauen, ob ich mir nicht einmal abspeichern sparen kann und direkt der function mapping ein array mit allen statement+
#fragment rules uebergebe.
#Hm, dran denken, dass ich mehrmals die variable Unknown haben kann, mit unterschiedlichen staedte Namen..
#Ich koennte natuerlich auch direkt in diesem Schritt, das mappen nach den eabnf regeln machen!!!
#und dann den Namen des Stadt erst garnicht abspeichern zu muessen.
#Beim Mapping so lange iterieren, bis kein Key mehr gefunden wird in der hm und das muesste dann die letzte moeglichkeit sein


    for key in statement_overall:
        write_string=""
        if len(statement_overall[key]) > 0 and "statement" in key.lower():
            write_string += key+","
            for x in statement_overall[key]:
                write_string += x+","
            write_string = write_string[:-1]
            write_string = write_string.replace(" ","")
            if write_string.endswith(":  \""):
                pass
            else:
                write_string += "\n"
                f_out_overall.write(write_string)
            
    f_out_overall.close()
    

    
#def extractFromFile_Old(input_file, output_file, groundtruthFile):
##    if len(sys.argv) < 3:
##        print "python extractFragments.py input.txt output.txt"
##        exit(1)
##        
#    hm_terminal = importENabnf()
##    input_file = sys.argv[1]
##    output_file = sys.argv[2]
#        
#    f = open(input_file,"r")
#    f_out_overall = open("extracted_tmp","w")
#    
#    counter_line = 0
#    original_sentence = []
#    statement_hm = {}
#    statement_overall = {}
#
#    
#    for line in f:
#        line = line.replace("\n","")
#        flag = False
#        if line == "":
#            counter_line = 0
#            pass
#            
#        else:
#            if counter_line == 0:
#                sentence = line.replace("0.000000","")
#                sentence = sentence.replace("  "," ")
#                counter_line += 1
#                original_sentence = sentence.split(" ")
#            tmp = line.split(" ")
#            
#            first_pos = 0
#            last_pos = 0
#            if "<SGM>" in tmp:
#                counter = 0
#                for x in tmp:
#                    if "<SGM>" == x and first_pos == 0:
#                        first_pos = counter
#                    elif "<SGM>" == x:
#                        last_pos = counter + 2
#                    counter += 1
#                    if "Statement" in x:
#                        flag = True
#            if flag == True:
#                statement = tmp[first_pos - 2]
#                if statement_overall.has_key(statement):
#                    tmp = statement_overall[statement]
#                    write_string =""
#                    old_string = ""
#                    for x in original_sentence[(first_pos - 2)/2:last_pos/2]:
#                        blub = old_string + " "+ x
#                        if hm_terminal.has_key(blub.lower()):
#                            write_string += "<"+hm_terminal[blub.lower()].replace(" ","").upper()+">"+ "-"
#                            write_string = write_string.replace("-"+old_string+"-", "-")
# 
#                        elif hm_terminal.has_key(x.lower()):
#                            write_string += "<"+hm_terminal[x.lower()].replace(" ","").upper()+">"+ "-"
#                        else:
#                            write_string += x+ "-"
#                    old_string = x
#                    write_string = write_string[:-1]
#                    write_string += ""
#                    if write_string not in tmp:
#                        tmp.append(write_string)
#                    statement_overall[statement] = tmp
#                    
#                else:
#                    write_string =""
#                    old_string = ""
#                    for x in original_sentence[(first_pos - 2)/2:last_pos/2]:
#                        blub = old_string + " "+ x
#                        old_string = x
#                        if hm_terminal.has_key(blub.lower()):
#                            write_string += "<"+hm_terminal[blub.lower()].replace(" ","").upper()+">"+ "-"
# 
#                        elif hm_terminal.has_key(x.lower()):
#                            write_string += "<"+hm_terminal[x.lower()].replace(" ","").upper()+">"+ "-"
#                        else:
#                            write_string += x+ "-"
#                    write_string = write_string[:-1]
#                    write_string += ""
#                    statement_overall[statement] = [write_string]
#            
#                
#    #f_out.close()
#    
##    First only accept statements
#    for key in statement_overall:
#        write_string=""
#        if len(statement_overall[key]) > 0 and "statement" in key.lower():
#            write_string += key+","
#            for x in statement_overall[key]:
#                write_string += x+","
#            write_string = write_string[:-1]
#            while ", \"," in write_string:
#                write_string = write_string.replace(", \",",",")
#            write_string = write_string.replace("\", \",","\",")
#            write_string = write_string.replace(":  \",", ": ")
#            write_string = write_string.replace(">: ,<",">: <")
#            write_string = write_string.replace(">: ,",">: ")
#            write_string = write_string.replace(",,",",")
#
#
#            
#            if write_string.endswith(":  \""):
#                pass
#            else:
#                write_string += "\n\n\n"
#                f_out_overall.write(write_string)
#            
#    f_out_overall.close()
##    print "Done"
#
#    mapping("extracted_tmp",output_file,groundtruthFile)    
