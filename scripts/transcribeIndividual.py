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

def isFilterWord(w,d,actual):
    if w is None:
        return True
    try:
        dummy = d[w.upper()]
        actual[w.upper()]=0
    except KeyError:
        return False
    return True


def transcribeWord(word,d,actual):
    try:
        actual[word.upper()]=d[word.upper()]
        return d[word.upper()]
    except KeyError:
        return "%s_UNK"%word.upper()

if __name__=="__main__":
    actualWords = {} #which words have actually been used
    actualFilter = {} #which words have actually been filtered
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
    filteredOut = 0
    untranscribed=0
    if options.filter is None:
        filterWords[None]=0
        for fiWo in FILTER.split():
            filterWords[fiWo]=0
    else:
        filterWords = readFilterWords(options.filter)
    speakers = options.speakers.split()
    for age in range(startAge,endAge+1):
        for name in names:
            utterances = []
            filtered = []
            for f in sorted([x for x in os.listdir("%s/%s/"%(corpus,name)) if x[-3:]=='xml']):
                data = xmlchat.readfile("%s/%s/%s"%(corpus,name,f))
                chiAge = int(data[0]['CHI']['months'])
                if chiAge == age:
                    utterances += [("\t".join(transcribeWord(x,dictionary,actualWords) for x in ut["words"] if not isFilterWord(x,filterWords,actualFilter)), " ".join(y for y in ut["words"] if not isFilterWord(y,filterWords,actualFilter))) for ut in data[1] if ut["who"] in speakers]
                    for ut in [x for x in data[1] if x["who"] in speakers]:
                        if len([x for x in ut["words"] if not isFilterWord(x,filterWords,actualFilter)])==0:
                            filtered += [" ".join([x for x in ut["words"] if x is not None])]
                else:
                    if chiAge>age: #there won't be any later files that meet the criterion
                        break
                    else: #too young, there could be later files that meet the criterion
                        continue
            if len(utterances)>0: #don't create files for ages without data
                outphon = codecs.open("%s_%sto%sm.phon"%(name,age,age),"w",encoding="utf-8")
                outplain = codecs.open("%s_%sto%sm.plain"%(name,age,age),"w",encoding="utf-8")
                outUnknown = codecs.open("%s_%sto%sm.unk"%(name,age,age),"w",encoding="utf-8")
                for l in utterances:
                    phon,plain = l
                    if len(phon.strip())>0: #don't write empty utterances
                        if phon.count("_UNK")==0:
                            outphon.write("%s\n"%phon.strip())
                            outplain.write("%s\n"%plain.strip())
                        else:
                            outUnknown.write("%s\n"%phon.strip())
                            untranscribed += 1
                    else:
                        filteredOut += 1
                outphon.close()
                outplain.close()
                outUnknown.close()
            if len(filtered)>0:
                outfiltered = codecs.open("%s_%sto%sm.filtered"%(name,age,age),"w",encoding="utf-8")
                for l in filtered:
                    outfiltered.write("%s\n"%l.strip())
                outfiltered.close()
    print("filtered out:\t%d"%filteredOut)
    print("untranscribed:\t%d"%untranscribed)
    outLex = codecs.open("usedWords.txt","w",encoding="utf-8")
    for (w,p) in sorted(actualWords.iteritems(),lambda x,y:cmp(x[0],y[0])):
        outLex.write("%s\t[%s]\t%s\n"%(w.strip(),w.strip(),p.strip()))
    outLex.close()
    outFilter = codecs.open("usedFilters.txt","w",encoding="utf-8")
    for w in sorted(actualFilter.keys()):
        outFilter.write("%s\n"%w)
    outFilter.close()
