#!/usr/bin/python
# -*- coding: utf-8 -*-

usage ="""
Version of 15/08/12

extracts utterances from CHILDES xml-files and transcribes them, outputting
both plain text (plain) and dictionary transcribed utterances (phon), as well
as collecting untranscribed utterances (unk) due to unknown items

you need to specify (the path to) a corpus (e.g. /data/Providence) using -c, 
a list of names / subcorpora that matches the file-structure, e.g. 
  "Alex Ethan Lily Naima Violet William"
using -n,
a dictionary that is tab-separated and in VoxForge format, e.g.
  IDENTIFIER\t[LEMMA]\tPHONOLOGICALFORM
where the phonological form is white-space separated
using -d.
you can additionally specify a file that contains words that are going to be
ignored, e.g. interjections, wordplay, strange items etc. --- these words
will silently be omitted (empty utterances won't be output), using -f

usage: %prog [options]"""

import xmlchat,re, codecs,os, optparse

CORPUS="/home/bborschi/data/CHILDES/Providence"
NAMES="Alex Ethan Lily Naima Violet William"
ENDAGE=22
SPEAKERS="MOT FAT" #people we collect

FILTER="xx xxx" #items we filter, e.g. xx --- None is automatically included

DICT="/home/bborschi/research/Providence/dictionary/dict.txt"
prefix = re.compile(r"([^0-9]+).+\.xml")    #to grab the name

def readVoxDict(f):
    #we pick the first pronunciation
    dictionary = {}
    for l in codecs.open(f,"r",encoding="utf-8"):
        if len(l.strip())==0:
            continue
        try:
            lID,lemma,form = l.strip().split("\t")
        except ValueError:
            print l
            print l.split("\t")
        lemma = lemma[1:-1] #get rid of brackets
        if dictionary.has_key(lemma):
            continue
        else:
            dictionary[lemma] = form
    return dictionary

def readFilterWords(f):
    res = {}
    for w in codecs.open(f,"r",encoding="utf-8").readlines():
        if len(w.strip())==0:
            continue
        res[w.strip().upper()]=0
    return res

def lookUp(w,d):
    if w is None:
        return True
    try:
        dummy = d[w.upper()]
    except KeyError:
        return False
    return True


def transcribeWord(word,d):
    try:
        return d[word.upper()]
    except KeyError:
        return "%s_UNK"%word.upper()

def transcribeUtterance(utterance,d):
    result = []
    for w in utterance.split():
        result.append(transcribeWord(w.upper(),d))
    return " ".join(result)


if __name__=="__main__":
    parser = optparse.OptionParser()
    parser.add_option("-A","--endAge",dest="endAge",type="int",
                      help="collect until this age (in months)")
    parser.add_option("-a","--startAge",dest="startAge",type="int",
                      help="collect from this age (in months)",default=0)
    parser.add_option("-c","--corpus",dest="corpus",default=CORPUS,
                      help="folder where individual corpora reside, e.g. /CHILDES/Providence/")
    parser.add_option("-n","--names",dest="names",default=NAMES,
                      help="white-space separated string of names, needs to match name of individual corpora, e.g. \"Alex Naima\"")
    parser.add_option("-d","--dictionary",dest="dictionary",default=DICT,
                      help="name of VoxForge-style dictionary to be used")
    parser.add_option("-s","--speakers",dest="speakers",default=SPEAKERS,
                      help="name of participants whose utterances are collected, e.g. \"MOT FAT\"")
    parser.add_option("-f","--filter",dest="filter",default=None,
                      help="file with words that are to be filtered")
    (options,args) = parser.parse_args()
    dictionary = readVoxDict(options.dictionary)
    startAge = options.startAge
    endAge = options.endAge
    names = options.names.split()
    corpus = options.corpus
    filterWords = {}
    if options.filter is None:
        filterWords = [None] + FILTER.split()
    else:
        filterWords = readFilterWords(options.filter)
    speakers = options.speakers.split()
    for age in range(startAge,endAge+1):
        for name in names:
            utterances = []
            for f in sorted([x for x in os.listdir("%s/%s/"%(corpus,name)) if x[-3:]=='xml']):
                data = xmlchat.readfile("%s/%s/%s"%(corpus,name,f))
                chiAge = int(data[0]['CHI']['months'])
                if chiAge>=startAge and chiAge <= age:
                    utterances += [("\t".join(transcribeWord(x,dictionary) for x in ut["words"] if not lookUp(x,filterWords)), " ".join(y for y in ut["words"] if not lookUp(y,filterWords))) for ut in data[1] if ut["who"] in speakers]
                else:
                    if chiAge>age: #there won't be any later files that meet the criterion
                        break
                    else: #too young, there could be later files that meet the criterion
                        continue
            if len(utterances)>0: #don't create files for ages without data
                outphon = codecs.open("%s_%sto%sm.phon"%(name,startAge,age),"w",encoding="utf-8")
                outplain = codecs.open("%s_%sto%sm.plain"%(name,startAge,age),"w",encoding="utf-8")
                outUnknown = codecs.open("%s_%sto%sm.unk"%(name,startAge,age),"w",encoding="utf-8")
                for l in utterances:
                    phon,plain = l
                    if len(phon.strip())>0: #don't write empty utterances
                        if phon.count("_UNK")==0:
                            outphon.write("%s\n"%phon.strip())
                            outplain.write("%s\n"%plain.strip())
                        else:
                            outUnknown.write("%s\n"%phon.strip())                        
                outphon.close()
                outplain.close()
                outUnknown.close()
               
