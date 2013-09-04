#!/usr/bin/python
import sys

dictionary = sys.argv[1]
pronunciations = sys.stdout
word_list = sys.stdin

words = []
for ln in word_list:
    ln = ln.rstrip('\r\n')
    words.append(ln)

dico = open(dictionary, 'r')
for ln in dico:
    ln = ln.rstrip('\r\n')
    ln_info = ln.split(' ')
    word = ln_info[0]
    if (word in words):
        print >> pronunciations, ln

dico.close()
