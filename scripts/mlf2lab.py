#!/usr/bin/python
import sys
import re

filename = sys.argv[1]
mlf = sys.stdin
label = sys.stdout
reg = re.compile(r"([^.*\"]+)\..*\"")

start_printing = False
for ln in mlf:
    ln = ln.rstrip('\r\n')
    m = reg.search(ln)
    if m:
        id = m.group(1)
        if id in filename:
            start_printing = True
        else:
            start_printing = False
    elif re.match(r"\.", ln):
        if start_printing:
            break
        else:
            continue
    else:
        if start_printing:
            print >> label, ln



