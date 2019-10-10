#!/usr/bin/env python3

#
# Copyright 2014 Luca Venturini. All rights reserved.
# Luca Venturini <luca.venturini@univr.it>
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

import sys,re
from scipy import mean, median

nucls = ['A','C','G','T']

print(*"bp ref cov tot_cov".split()+nucls +"del ins inserted ambiguous refFreq totRefFreq".split(), sep="\t")

differences = dict(
    [("coverage", []),
     ("matches", []),
     ("matches_excl", []),
     ("mismatches", []),
     ("deletions", []),
     ("insertions", []),
     ("ambiguous", [])
        ])


for line in open(sys.argv[1]):
#gi|18446393|gb|AY014381.1|      10      C       15      .G...,t.+3TGCA+1G.,..^~,^~,     ~~~~~~~~~~~~~~~

    nucl_counts=dict(zip(nucls,[0]*len(nucls)))

    chrom, pos, ref, cov, mapping, qualities = line.rstrip().split()
    mapping = re.sub("(\^.|\$)","", mapping) #Remove this useless marker
    ref_count = len(re.findall(r"(\.|,)", mapping)) #Count reference
    nucl_counts[ref] = ref_count
    mapping = re.sub("(\.|,)","", mapping) #Remove reference bases
    ambiguous = len(re.findall("\*", mapping))
    mapping =re.sub("\*", "", mapping)
    ins_counts = 0
    del_counts = 0
    cov = int(cov)

    i=0
    inserted_bases=[]

    while i<len(mapping):
        if i>=len(mapping): break #stop iteration
        map_token = mapping[i]
        if map_token in ("+","-"):
            if map_token=="+":
                insertion=True
            else:
                insertion=False

            indel_len = ""
            while True:
                i+=1
                map_token = mapping[i]
                if str.isdigit(map_token): indel_len+=map_token
                else: break
            indel = map_token
            indel_len=int(indel_len)
            while len(indel)<indel_len:
                i+=1
                map_token = mapping[i]
                indel+=map_token
            if insertion:
                inserted_bases.append(indel)
                ins_counts+=1
            else:
                del_counts+=1
                
        else:
            nucl_counts[map_token.upper()] += 1

        i+=1

    tot_cov = cov + ins_counts + del_counts

    line = [pos, ref, cov, tot_cov]
    for nuc in nucls:
        line.append(nucl_counts[nuc])
    line.append(del_counts)
    line.append(ins_counts)
    if inserted_bases!=[]:
        line.append(",".join(inserted_bases))
    else:
        line.append(".")

    line.append(ambiguous) #Gotta implement this

    mismatches = sum([nucl_counts[n] for n in filter(lambda n: n!=ref, nucls) ])

    differences["matches"].append(nucl_counts[ref]/tot_cov)
    differences["matches_excl"].append(nucl_counts[ref]/cov)
    differences["mismatches"].append(mismatches/tot_cov)
    differences["coverage"].append(tot_cov)
    differences["deletions"].append(del_counts/tot_cov)
    differences["insertions"].append(ins_counts/tot_cov)
    differences["ambiguous"].append(ambiguous/tot_cov)


    refFreq = nucl_counts[ref]/cov if cov>0 else "NA"
    totRefFreq = nucl_counts[ref]/tot_cov if cov>0 else "NA"

    line+=[refFreq, totRefFreq]
    
    max_nucl = ",".join(list(filter( lambda x: nucl_counts[x]==max(nucl_counts.values()), nucl_counts)))
    line+=[max_nucl]

    print(*line, sep="\t")

print("##################")

print("", "Coverage", "Matches",  "Matches (excluding INDELs)", "Mismatches", "Mismatches (excluding INDELs)", "Deletions", "Insertions", "Ambiguous", sep="\t")

print("Mean",
      mean(differences["coverage"]),
      mean(differences['matches']),
      mean(differences["matches_excl"]),
      mean(differences["mismatches"]),
      1-mean(differences["matches_excl"]),
      mean(differences['deletions']),
      mean(differences['insertions']),
      mean(differences['ambiguous']),
      sep="\t")

print("Median",
      median(differences["coverage"]),
      median(differences['matches']),
      median(differences["matches_excl"]),
      median(differences["mismatches"]),
      1-median(differences["matches_excl"]),
      median(differences['deletions']),
      median(differences['insertions']),
      median(differences['ambiguous']),
      sep="\t")
