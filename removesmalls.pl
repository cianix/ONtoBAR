#!/usr/bin/perl

# script by Vivek Krishnakumar downloaded @
# https://www.biostars.org/p/79202/#79467

use strict;
use warnings;

my $minlen = shift or die "Error: `minlen` parameter not provided\n";
{
    local $/ = ">";
    while (<>)
    {
        chomp;
        next unless /\w/;
        s/>$//gs;
        my @chunk  = split /\n/;
        my $header = shift @chunk;
        my $seqlen = length join "", @chunk;
        print ">$_" if ( $seqlen >= $minlen );
    }
    local $/ = "\n";
}
