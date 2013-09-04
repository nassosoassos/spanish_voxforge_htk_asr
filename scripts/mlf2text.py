#!/usr/bin/python
import sys
import re

mlf_filename = sys.argv[1]
file_list = sys.stdin
text = sys.stdout

mlf = open(mlf_filename, 'r')
reg = re.compile(r"([^.*\"]+)\..*\"")

id_list = []
for ln in file_list:
    ln = ln.rstrip('\r\n')
    ln_info = ln.split('.')
    id_list.append(ln_info[0])

start_printing = False
for ln in mlf:
    ln = ln.rstrip('\r\n')
    m = reg.search(ln)
    if m:
        id = m.group(1)
        if any(id==s for s in id_list):
            start_printing = True
        else:
            start_printing = False
    elif re.match(r"\.", ln):
        if start_printing:
            print >> text, " "
        start_printing = False
        continue
    else:
        if start_printing:
            print >> text, ln + " ",

mlf.close()
