#!/usr/bin/python
# Convert the prompts file of voxforge to a .mlf file
import sys
import re

prompts_file = sys.stdin
mlf_file = sys.stdout
path = sys.argv[1]

print >> mlf_file, '#!MLF!#'
for ln in prompts_file:
    ln = ln.rstrip('\r\n')
    ln_info = re.split('\s+', ln )

    print >> mlf_file, '\"{0}/{1}.lab\"'.format(path, ln_info[0])

    for word in ln_info[1:]:
        print >> mlf_file, word.lower()

    print >> mlf_file, '.'

