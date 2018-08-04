#!/bin/bash
#
# ben boerschinger, 21/08/12

curdir=`pwd`
#get childes-files
wget -c http://childes.psy.cmu.edu/data-xml/Eng-USA/Providence.zip
unzip Providence.zip
mkdir -p Data
cd Data
#transcribe utterances
~mjohnson/local/bin/python2.7 ${curdir}/scripts/transcribeCumulative.py -c ${curdir}/Providence -n "Naima Alex Violet Lily William Ethan" -f ${curdir}/dictionary/filterWords.txt -d ${curdir}/dictionary/words.txt -a 11 -A 22
~mjohnson/local/bin/python2.7 ${curdir}/scripts/transcribeIndividual.py -c ${curdir}/Providence -n "Naima Alex Violet Lily William Ethan" -f ${curdir}/dictionary/filterWords.txt -d ${curdir}/dictionary/words.txt -a 11 -A 22
#create testset
#this is random, you may want to use our original test-files
#${curdir}/scripts/selectSubset.py 200 \*22to22m.phon > test1.phon
#sed 's/\t/ /g' test1.phon > test1.in
#sed 's/ //g;s/\t/ /g' test1.phon >test1.gold
#${curdir}/scripts/selectSubset.py 200 \*22to22m.phon > test2.phon
#sed 's/\t/ /g' test2.phon > test2.in
#sed 's/ //g;s/\t/ /g' test2.phon >test2.gold

#transform into one-character format
${curdir}/scripts/transcribeToSingleCharacter.py ${curdir}/dictionary/phoneSet
