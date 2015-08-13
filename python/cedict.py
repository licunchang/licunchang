#!/usr/bin/env python
# -*- encoding: utf-8 -*-

import os

dirname, filename = os.path.split(os.path.abspath(__file__))

dict_cedict_path = os.path.join(dirname, "cedict.txt")

dest_result_path = os.path.join(dirname, "result.txt")

dest_result = open(dest_result_path, 'w')

with open(dict_cedict_path) as dict_cedict:
    for line in dict_cedict:
        # print line.decode('utf-8')
        print type(line)
        print line
        exit()
        if line.startswith("#"):
            continue
        else:
            array_1 = line.split("]", 2)
            array_2 = array_1[0].split("[", 2)
            array_3 = array_2[0].split(" ", 2)
            array_4 = array_2[1].split(" ")
            fr = 0
            ok = False
            if len(array_4) < 2 or len(array_4) >= 5:
                continue
            else:
                if unicode(array_3[1]) in var_dict:
                    fr = getattr(var_dict, array_3[1])
                    dest_result.write(unicode(array_3[1] + ' ' + array_2[1] + ' ' + fr + '\n' ).encode('utf-8'))

dest_result.close()