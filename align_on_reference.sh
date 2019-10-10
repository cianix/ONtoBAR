#!/bin/bash

#
# Copyright 2015 Cesare Centomo. All rights reserved.
# Cesare Centomo <cesare.centomo@univr.it>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# $1 is the reference
# $2 is the '.fasta' file that contains the reads to be mapped
# $3 ONtoBAR home

# path to be set
export LAST=/home/luca/software/last;
export SAMTOOLS=samtools;

# store the ONtoBAR home
ONTOBAR=$3;

export LASTAL=$LAST/bin/lastal;
export FILTER=$LAST/bin/last-map-probs.py;
export MAF_CONVERT=$LAST/bin/maf-convert.py;
export COUNT=$ONTOBAR/detailed_counts.py;
export CONSENSUS=$ONTOBAR/consensus_from_counts.py;

# create LAST DB index
$LAST/bin/lastdb $1 $1;
$SAMTOOLS faidx $1;

# reads alignment
$LASTAL -a 1 $1 $2 > 2D.maf;

# Filter
$FILTER 2D.maf > 2D.filter.maf ;

# misalignment likelyhood, and reads splits
$MAF_CONVERT sam 2D.filter.maf | $SAMTOOLS view -T $1 -bS - | $SAMTOOLS sort -o - - | $SAMTOOLS fillmd -be - $1 > 2D.filter.bam && $SAMTOOLS index 2D.filter.bam ;

# mpileup
$SAMTOOLS mpileup -BQ 0 -d 10000000 -f $1 2D.filter.bam > 2D.filter.mpileup ;

# Counts
$COUNT 2D.filter.mpileup > 2D.filter.mpileup.detailed.txt;

# Variants
awk '{if($1 ~"[0-9]" && $2 != $15) print $0}' 2D.filter.mpileup.detailed.txt > 2D.filter.mpileup.variants.txt;

# Consensus
python $CONSENSUS 2D.filter.mpileup.detailed.txt > 2D.consensus.fasta ;
