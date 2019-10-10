#!/usr/bin/perl

#
# Copyright 2015 Luciano Xumerle. All rights reserved.
# Luciano Xumerle <luciano.xumerle@univr.it>
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

use strict;
use warnings;

my $NTDB = '/home/db/NR_2015_02_02/nt';

my $FAST5    = '';
my $assembly = '';
my $ncbi     = '';
if ( defined $ARGV[0] && -d $ARGV[0] )
{
    $FAST5    = qq|$ARGV[0]/FAST5|;
    $assembly = qq|$ARGV[0]/assembly|;
    $ncbi     = qq|$ARGV[0]/NCBI_consensus|;
}
else
{
    print qq|Directory $FAST5 or $assembly not found!\n\n|;
    exit 0;
}

# check if exist the directory with the FAST5 files or the file raw.reads.unsorted
# in directory assembly (used when the reads were already converted to fastq)
if ( -d $FAST5 || -f qq|$assembly/raw.reads.unsorted| )
{
    mkdir($assembly) if ( !-d $assembly );
    mkdir($ncbi)     if ( !-d $ncbi );
}
else
{
    print qq|Directory $FAST5 or $assembly not found!\n\n|;
    exit 0;
}

# detect ONtoBAR home
my $path = $0;
$path =~ s/ONtoBAR.pl$//;

# assembly reads
system( qq|$path/assembly.sh|, $path )
  if ( -f qq|$path/assembly.sh| && !-f qq|$assembly/draft_genome.fasta| );

# get the best two assembly
&getFirstSecond( qq|$assembly/draft_genome.fasta|,
    qq|$assembly/draft_genome_best_2.fasta| );

# select the NCBI reference
&parseBlastn( qq|$assembly/draft_genome_best_2.fasta|, 10 );

# create a consensus using the NCBI reference
if ( -f qq|$ncbi/NCBI.fasta| && !-f qq|$ncbi/2D.consensus.fasta| )
{
    chdir($ncbi);
    system(
        qq|$path/align_on_reference.sh|,  'NCBI.fasta',
        '../assembly/raw.reads.unsorted', $path
    );

    system( 'blastn', '-db', $NTDB, '-query', '2D.consensus.fasta', '-out',
        'blast.results.out' );
}

sub parseBlastn
{
    my $file  = shift;
    my $limit = shift;

    my @old = ();

    my $gb    = '';
    my $name  = '';
    my $ident = '';
    my $score = '';

    foreach (`blastn -db $NTDB -query $file`)
    {
        chomp;
        if (m/^>/)
        {
            my @a = split /\|/;
            $gb   = $a[1];
            $name = $a[2];
            $name =~ s/^\s+//;
            $name = substr( $name, 0, 50 );
        }
        elsif (m/^\s*Score\s*=\s*(\d+)\s+bits.+$/)
        {
            $score = $1;
        }
        elsif (m/^\s*Identities\s*=\s+(.+),\s+.+$/)
        {
            $ident = $1;
            my $perc = $ident;
            $perc =~ s/^.+\(//;
            $perc =~ s/%.*//;
            push @old, [ $gb, $name, $ident, $score, $perc ];
            $gb    = '';
            $name  = '';
            $ident = '';
            $score = '';
        }
    }

    @old = sort { $b->[4] <=> $a->[4] } @old;

    $limit = $#old + 1 if ( $limit > $#old );

    for ( my $i = 0 ; $i < $limit ; $i++ )
    {
        print join( "\t", $i + 1, $old[$i]->[0], $old[$i]->[1], $old[$i]->[2] ),
          "\n";
    }

    my $num = 0;
    while ( $num < 1 || $num > 10 )
    {
        print
          qq|Please insert the number of sequence to be used as reference: |;
        my $in = <STDIN>;
        chomp $in;
        $num = $in if ( $in =~ m/^\d+$/ );
    }

    my $id = $old[ $num - 1 ]->[0];

    `blastdbcmd -db $NTDB -entry $id > $ncbi/NCBI.fasta`;
}

sub getFirstSecond
{
    my $file = shift;
    my $dest = shift;

    my $end = 2;

    my $count = 0;
    open( DEST, ">$dest" ) || die;
    open( FILE, $file )    || die;
    while (<FILE>)
    {
        chomp;
        if (m/^>/)
        {
            last if ( $count == $end );
            $count++;
        }
        print DEST $_, "\n";
    }
    close FILE;
    close DEST;
}
