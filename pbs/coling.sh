#! /bin/bash
#PBS -l nodes=1:ppn=4,walltime=200:00:00,mem=2000mb
# 4 cores results in 2 chains using 2 cores each running in parallel
#
# specify NAME, SAGE (start age), EAGE (endage) and the GRAMMAR you want to use

#set this to the main folder where the Makefile resides
MAINFOLDER=

#set this to the a date-identifier
date=

iters=1000
cd ${MAINFOLDER}
mkdir -p ${NAME}-${SAGE}-${EAGE}-${date}
make -f Makefile -j GRAMMARS=${GRAMMAR} NAME=${NAME} FOLDS="00 01" PYNS=${iters} OUTPUTDIR=${NAME}-${SAGE}-${EAGE}-${date} EVALDIR=${NAME}-${SAGE}-${EAGE}-${date} TMPDIR=tmp${NAME}-${EAGE}-${SAGE}-${date} SAGE=${SAGE} EAGE=${EAGE} OUTPUTPREFIX=r${date} >& ${NAME}-${SAGE}-${EAGE}-${date}/r${date}-${NAME}-${GRAMMAR}-n${iters}.out

programs/mbr.py tmp${NAME}-${EAGE}-${SAGE}-${date}/*${GRAMMAR}*.t1sws > ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t1avprs
programs/mbr.py tmp${NAME}-${EAGE}-${SAGE}-${date}/*${GRAMMAR}*.t2sws > ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t2avprs

programs/eval.py -g Data/test1.gold < ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t1avprs > ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t1score

# we only reported scores on one of the test-sets as there was no noticeable difference
#programs/eval.py -g Data/test2.gold < ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t2avprs > ${NAME}-${SAGE}-${EAGE}-${date}/${GRAMMAR}.t2score
