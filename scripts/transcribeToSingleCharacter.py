#!/usr/bin/python
# -*- coding: utf-8 -*-

usage ="""
Version of 21/08/12

takes a transcription key and maps files to a single-character input format that some programs require as input

usage: %prog [options]"""

import xmlchat,re, codecs,os, optparse, sys


prefix = re.compile(r"([^0-9]+).+\.phon")    #to grab the name

def readKey(f):
    #we pick the first pronunciation
    dictionary = {}
    uniq = {}
    for l in codecs.open(f,"r",encoding="utf-8"):
        if len(l.strip())==0:
            continue
        try:
            orig,trans = l.strip().split("\t")
            dictionary[orig]=trans
            if uniq.has_key(trans):
                print("Non-uniq identifier: %s"%trans)
                sys.exit(-1)
        except ValueError:
            print l
            print l.split("\t")
    return dictionary

def transcribeWord(word,d):
    result = []
    for c in word.split():
        result.append(d[c])
    return "".join(result)

def transcribeUtterance(utterance,d):
    result = []
    for w in utterance.split("\t"):
        result.append(transcribeWord(w,d))
    return " ".join(result)


if __name__=="__main__":
    dictionary = readKey(sys.argv[1])
    for f in sorted([x for x in os.listdir("./") if x[-4:]=='phon']):
        outf = codecs.open("%s.sin"%f[:-5],"w",encoding="utf-8")
        for l in codecs.open(f,"r",encoding="utf-8"):
            outf.write("%s\n"%transcribeUtterance(l.strip(),dictionary).strip())
        outf.close()
