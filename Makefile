# AGWS/Makefile
#  modified by ben boerschinger, 16/08/12
#
#  (c) Mark Johnson, 20th July 2012
#
#
# Makefile for Adaptor Grammar word segmentation

# set default shell
#
SHELL=/bin/bash

NAME=Violet
SAGE=0
EAGE=21

# DIR is the base directory in which we work (all files produced are
# relative to this directory)
#
DIR:=.

# OUTPUTPREFIX is a prefix prepended to all temporary and output run
# files (change this for a new run)
#
OUTPUTPREFIX=r00

# EVALDIR is the directory in which the output is placed
#


#TEST1 and TEST2 are the two test-sets
TEST1IN=Data/test1.in
TEST2IN=Data/test2.in
TEST1GOLD=Data/test1.gold
TEST2GOLD=Data/test2.gold

# SOURCE is the gold data file
#
# SOURCE=Data/swb_icsi_transcriptions_phones
# SOURCE=Data/swb_icsi_transcriptions_allophones
#SOURCE=Data/SWITCHBOARD.jansen_icsi_utt_45phn.bnd.txt

SOURCE=Data/$(NAME)_$(SAGE)to$(EAGE)m.phon
EVALDIR:=$(DIR)/$(NAME)Eval
TMPDIR:=$(DIR)/$(NAME)Tmp

# SOURCE=Data/Ethan_0to21m.phon
# EVALDIR:=$(DIR)/EthanEval
# TMPDIR:=$(DIR)/EthanTmp

# SOURCE=Data/Naima_0to21m.phon
# EVALDIR:=$(DIR)/NaimaEval
# TMPDIR:=$(DIR)/NaimaTmp

# SOURCE=Data/Violet_0to21m.phon
# EVALDIR:=$(DIR)/VioletEval
# TMPDIR:=$(DIR)/VioletTmp

# SOURCE=Data/William_0to21m.phon
# EVALDIR:=$(DIR)/WilliamEval
# TMPDIR:=$(DIR)/WilliamTmp

# SOURCE=Data/Lily_0to21m.phon
# EVALDIR:=$(DIR)/LilyEval
# TMPDIR:=$(DIR)/LilyTmp

# GRAMMARS is a list of adaptor grammars to try
#
# GRAMMARS:=syll collocsyll colloc2syll ncolloc ncollocmorph ncollocsyll nsyll collocnsyll colloc2nsyll
# GRAMMARS:=unigram colloc invcolloc unigrammorph collocmorph syll collocsyll colloc2syll ncolloc ncollocmorph ncollocsyll nsyll collocnsyll colloc2nsyll
# GRAMMARS:=syll collocsyll colloc2syll ncolloc ncollocmorph ncollocsyll nsyll collocnsyll colloc2nsyll
# GRAMMARS:=syll collocsyll colloc2syll ncolloc ncollocmorph ncollocsyll nsyll collocnsyll colloc2nsyll unigram colloc invcolloc unigrammorph collocmorph syll collocsyll colloc2syll ncolloc ncollocmorph ncollocsyll nsyll collocnsyll colloc2nsyll
#GRAMMARS:=colloc colloc2 colloc3 #Syll collocSyll colloc2Syll colloc3Syll  SyllIF collocSyllIF colloc2SyllIF colloc3SyllIF
GRAMMARS=colloc3Syll

# BURNINSKIP is the fraction of the sample to be discarded before collecting 
#  samples for evaluation
BURNINSKIP=0.8

# PYFLAGS specify flags to be given to py-cfg, e.g., -P (predictive filter)
PYFLAGS=-d 10

# OUTS is a list of types of output files we're going to produce
OUTS=trscore

# Each fold is a different run; to do 8 runs set FOLDS=0 1 2 3 4 5 6 7
#FOLDS=00 01 02 03 04 05 06 07
FOLDS=1

# PYCFG is the py-cfg program (including its path)
#
PYCFG=~/software/py-cfg/py-cfg

PYAS=1e-4
PYES=2
PYFS=1

PYBS=1e4
PYGS=100
PYHS=0.01

PYWS=1

PYTS=1
PYMS=0

# PYNS is the number of iterations
PYNS=200

# PYRS controls how long we do table label resampling for (-1 = forever)
PYRS=-1

PYD=D_
PYE=E_

# rate at which model's output is evaluated
TRACEEVERY=5

# EXEC is the prefix used to execute the py-cfg command
EXEC=time
# EXEC=valgrind

# EVALREGEX is the regular expression given to eval.py in the evaluation script (may depend on grammar)
# EVALREGEX=Colloc\\b
EVALREGEX=^Word

# IGNORETERMINALREGEX is the regular expression given to eval.py in the evaluation script
IGNORETERMINALREGEX=^[$$]{3}$$

# WORDSPLITREGEX is the regular expression given to eval.py in the evaluation script
WORDSPLITREGEX=[\\t]+

################################################################################
#                                                                              #
#                     everything below this should be generic                  #
#                                                                              #
################################################################################

# INPUTFILE is the file that contains the adaptor grammar input
#
INPUTFILE:=$(TMPDIR)/AGinput.txt

# GOLDFILE is the file that contains word boundaries that will be used to
#  evaluate the adaptor grammar word segmentation
#
GOLDFILE:=$(TMPDIR)/AGgold.txt


#TEST2IN=$(TMPDIR)/AGinput.txt
#TEST2GOLD=$(TMPDIR)/AGgold.txt

# The list of files we will make

OUTPUTS=$(foreach GRAMMAR,$(GRAMMARS), \
	$(foreach e,$(PYES), \
	$(foreach f,$(PYFS), \
	$(foreach g,$(PYGS), \
	$(foreach h,$(PYHS), \
	$(foreach a,$(PYAS), \
	$(foreach b,$(PYBS), \
	$(foreach w,$(PYWS), \
	$(foreach t,$(PYTS), \
	$(foreach m,$(PYMS), \
	$(foreach n,$(PYNS), \
	$(foreach R,$(PYRS), \
	$(foreach out,$(OUTS), \
	$(EVALDIR)/$(OUTPUTPREFIX)_G$(GRAMMAR)_$(PYD)$(PYE)n$(n)_m$(m)_t$(t)_w$(w)_a$(a)_b$(b)_e$(e)_f$(f)_g$(g)_h$(h)_R$(R).$(out))))))))))))))

TARGETS=$(PROGRAM) $(OUTPUTS)

.PHONY: top
top: $(TARGETS)

.SECONDARY:
.DELETE_ON_ERROR:

getarg=$(patsubst $(1)%,%,$(filter $(1)%,$(subst _, ,$(2))))

keyword=$(patsubst $(1),-$(1),$(filter $(1),$(subst _, ,$(2))))

GRAMMARFILES=$(foreach g,$(GRAMMARS),$(TMPDIR)/$(g).gr)

$(EVALDIR)/$(OUTPUTPREFIX)_%.trscore: $(TMPDIR)/$(OUTPUTPREFIX)_%.travprs programs/eval.py
	mkdir -p $(EVALDIR)
	programs/eval.py --gold $(GOLDFILE) --train $< --score-cat-re="$(EVALREGEX)" --ignore-terminal-re="$(IGNORETERMINALREGEX)" --word-split-re=" " > $@	

$(TMPDIR)/$(OUTPUTPREFIX)_%.travprs: programs/mbr.py $(foreach fold,$(FOLDS),$(TMPDIR)/$(OUTPUTPREFIX)_%_$(fold).trsws)
	$^ > $@

$(EVALDIR)/$(OUTPUTPREFIX)_%.t1score: $(TMPDIR)/$(OUTPUTPREFIX)_%.t1avprs programs/eval.py
	mkdir -p $(EVALDIR)
	programs/eval.py --gold $(TEST1GOLD) --train $< --score-cat-re="$(EVALREGEX)" --ignore-terminal-re="$(IGNORETERMINALREGEX)" --word-split-re=" " > $@	

$(TMPDIR)/$(OUTPUTPREFIX)_%.t1avprs: programs/mbr.py $(foreach fold,$(FOLDS),$(TMPDIR)/$(OUTPUTPREFIX)_%_$(fold).t1sws)
	$^ > $@

$(EVALDIR)/$(OUTPUTPREFIX)_%.t2score: $(TMPDIR)/$(OUTPUTPREFIX)_%.t2avprs programs/eval.py
	mkdir -p $(EVALDIR)
	programs/eval.py --gold $(TEST2GOLD) --train $< --score-cat-re="$(EVALREGEX)" --ignore-terminal-re="$(IGNORETERMINALREGEX)" --word-split-re=" " > $@	

$(TMPDIR)/$(OUTPUTPREFIX)_%.t2avprs: programs/mbr.py $(foreach fold,$(FOLDS),$(TMPDIR)/$(OUTPUTPREFIX)_%_$(fold).t2sws)
	$^ > $@

$(TMPDIR)/$(OUTPUTPREFIX)_%.trsws: $(PYCFG) $(GRAMMARFILES) $(GOLDFILE) $(INPUTFILE)
	mkdir -p $(TMPDIR)
	echo "Starting $@"
	date
	$(EXEC) $(PYCFG) $(PYFLAGS) \
		-A $(basename $@).prs \
		-F $(basename $@).trace \
		-G $(basename $@).wlt \
		-C \
		$(call keyword,D,$(*F)) \
		$(call keyword,E,$(*F)) \
		-r $$RANDOM$$RANDOM \
		-a $(call getarg,a,$(*F)) \
		-b $(call getarg,b,$(*F)) \
		-e $(call getarg,e,$(*F)) \
		-f $(call getarg,f,$(*F)) \
		-g $(call getarg,g,$(*F)) \
		-h $(call getarg,h,$(*F)) \
		-w $(call getarg,w,$(*F)) \
		-T $(call getarg,t,$(*F)) \
		-m $(call getarg,m,$(*F)) \
		-n $(call getarg,n,$(*F)) \
		-R $(call getarg,R,$(*F)) \
		-x $(TRACEEVERY) \
		-u $(TEST1IN) \
		-v $(TEST2IN) \
		-X "programs/eval.py --gold $(GOLDFILE) --train-trees --score-cat-re=\"$(EVALREGEX)\" --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --word-split-re=\" \" > $(basename $@).trweval" \
		-U "programs/eval.py --gold $(TEST1GOLD) --train-trees --score-cat-re=\"$(EVALREGEX)\" --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --word-split-re=\" \" > $(basename $@).t1weval" \
		-V "programs/eval.py --gold $(TEST2GOLD) --train-trees --score-cat-re=\"$(EVALREGEX)\" --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --word-split-re=\" \" > $(basename $@).t2weval" \
		-X "programs/trees-words.py --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --score-cat-re=\"$(EVALREGEX)\" --nepochs $(call getarg,n,$(*F)) --rate $(TRACEEVERY) --skip $(BURNINSKIP) > $(basename $@).trsws" \
		-U "programs/trees-words.py --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --score-cat-re=\"$(EVALREGEX)\" --nepochs $(call getarg,n,$(*F)) --rate $(TRACEEVERY) --skip $(BURNINSKIP) > $(basename $@).t1sws" \
		-V "programs/trees-words.py --ignore-terminal-re=\"$(IGNORETERMINALREGEX)\" --score-cat-re=\"$(EVALREGEX)\" --nepochs $(call getarg,n,$(*F)) --rate $(TRACEEVERY) --skip $(BURNINSKIP) > $(basename $@).t2sws" \
		$(TMPDIR)/$(call getarg,G,_$(*F)).gr \
		< $(INPUTFILE)


$(TMPDIR)/$(OUTPUTPREFIX)_%.t1sws: $(TMPDIR)/$(OUTPUTPREFIX)_%.trsws

$(TMPDIR)/$(OUTPUTPREFIX)_%.t2sws:  $(TMPDIR)/$(OUTPUTPREFIX)_%.trsws

$(TMPDIR)/%.gr: programs/input2grammar.py $(INPUTFILE)
	$^ --grammar $(*F) > $@

$(INPUTFILE): programs/source2AGinput.py $(SOURCE)
	mkdir -p $(TMPDIR)
	$^ -s0 -b "\t" > $@ 

$(GOLDFILE): programs/source2AGinput.py $(SOURCE)
	mkdir -p $(TMPDIR)
	$^ -s 0 -b "\t" --gold > $@

.PHONY: clean
clean: 
	rm -fr $(TMP)

.PHONY: real-clean
real-clean: clean
	rm -fr $(OUTPUTDIR)
