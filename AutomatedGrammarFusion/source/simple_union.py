def fuse(input1,input2,output):
    hm_rules = {}
    
    for path in [input1,input2]:
        f_in = open(path,"r")
        for line in f_in:
            line = line.replace("\n","")
            tmp = line.split(",")
            key = tmp[0]
            value = tmp[1:]
            
            if hm_rules.has_key(key):
                tmp = hm_rules[key]
                for x in value:
                    if x not in tmp:
                        tmp.append(x)
                hm_rules[key] = tmp
            else:
                hm_rules[key] = value
        f_in.close()
        
    f_out = open(output,"w")
    for key, value in hm_rules.iteritems():
        string = key+","
        for x in value:
            string += x+","
        if string.endswith(","):
            string = string[:-1]
        f_out.write(string+"\n")
    f_out.close()
    