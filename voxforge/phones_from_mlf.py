#!/usr/bin/python
import sys
import re
from collections import defaultdict

mlf = sys.stdin
phones_list = sys.stdout

phonemap = defaultdict(int)
for ln in mlf:
    ln = ln.rstrip('\r\n')
    if re.match('^#!MLF!#', ln) or re.match('^\"', ln) or re.match('^\.', ln):
        continue
    else:
        phonemap[ln] += 1

for key,val in phonemap.iteritems():
    print >> phones_list, key
