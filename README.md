# ONtoBAR

ONtoBAR, a two-step pipeline for MinION-based DNA barcoding that

1. retrieves from the NCBI nt database the reference sequence that is most similar to the consensus sequence obtained by the de novo assembly of MinION reads
2. calls variants by aligning the MinION reads against the reference sequence.

## INSTALL

Decompress the **ONtoBAR** archive and install all the required softwares:

 - the blastN software and a local copy of the NT database
 - poretools from http://poretools.readthedocs.org/en/latest/
 - nanocorrect from https://github.com/jts/nanocorrect/
 - samtools from http://www.htslib.org/
 - the Whole-Genome Shotgun Assembler from http://sourceforge.net/projects/wgs-assembler/files/wgs-assembler/wgs-8.1/
 - the python scipy library
 - the LAST aligner from http://last.cbrc.jp/

## Run ONtoBAR

To run the software the user must prepare a directory for the project (ie. _test_)
and a sub-directory _FAST5_ containing the 2D PASS raw reads in FAST5 format.
The program works also if the fasta file _/.../test/assembly/raw.reads.unsorted_
is available.

To run correctly the script the user have to use the absolute path of the **ONtoBAR.pl**
program and the absolute path of the _test_ directory.

Example:

	/home/luciano/ONtoBAR/ONtoBAR.pl /home/luciano/test
