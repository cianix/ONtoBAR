#!/bin/bash

#
# This program is from https://github.com/jts/nanopore-paper-analysis
# modified by Cesare Centomo <cesare.centomo@univr.it>
# and Luciano Xumerle <luciano.xumerle@univr.it>
#

# path to be updated
NANOCORRECT=/opt/nanocorrect;
WGS=/opt/wgs-8.1/Linux-amd64/bin;
SAMTOOLS=samtools;
PORETOOLS=poretools;

CPU=32;

# store the ONtoBAR home
ONTOBAR=$1;

#
# function filter
#
filterReads () {
	python $NANOCORRECT/lengthsort.py < raw.reads.unsorted > raw.reads.fasta;
	make -f $NANOCORRECT/nanocorrect-overlap.make INPUT=*.fasta NAME=nc;
	$SAMTOOLS faidx nc.pp.fasta;
	python $NANOCORRECT/makerange.py raw.reads.fasta | parallel -v --eta -P $CPU "python $NANOCORRECT/nanocorrect.py nc {} > nc.{}.corrected.fasta";
	cat nc.*.corrected.fasta | python $NANOCORRECT/lengthsort.py > raw.reads.corrected.fasta;
	rm nc.*.corrected.fasta;
}

#
# convert fast5 to fasta
#
if [ ! -f assembly/raw.reads.unsorted ]; then
	$PORETOOLS fasta --type 2D FAST5/ | awk '{if($1 ~ /^>/) print $1" "$3; else print $0}' > assembly/raw.reads.unsorted ;
fi;

cd assembly;

#
# first filter step
#
filterReads;

# prepare the second filter step
mkdir second_round;
cd second_round;
$ONTOBAR/removesmalls.pl 14 ../raw.reads.corrected.fasta > raw.reads.unsorted;

#
# second filter step
#
filterReads;

#
# assembly step
#
java -Xmx1024M -jar $WGS/convertFastaAndQualToFastq.jar raw.reads.corrected.fasta > assembly.input.fastq;
$WGS/fastqToCA -technology sanger -libraryname assembly -reads assembly.input.fastq > assembly.frg;
$WGS/runCA -d celera-assembly -p asm -s $ONTOBAR/revised_ovlErrorRate0.04.spec assembly.frg;

#
# copy assembly
#
cd .. ;
cp second_round/celera-assembly/9-terminator/asm.utg.fasta draft_genome.fasta ;
