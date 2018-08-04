#!/usr/bin/python

import glob, sys, random

if __name__=="__main__":
    n = int(sys.argv[1])
    data = glob.glob(sys.argv[2])
    res = []
    for f in data:
        lines = open(f,"r").readlines()
        for i in range(10):
            random.shuffle(lines)
        for l in lines[:n]:
            print l.strip()
        
