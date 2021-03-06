#!/usr/bin/env perl

# Copyright (c) 2012-2015 Douglas G. Scofield
# Evolutionary Biology Centre, Uppsala University
# douglas.scofield@ebc.uu.se
# douglasgscofield@gmail.com
#
# No warranty is implied or assumed by this code.  Please send bugs, suggestions etc.
#
# Part of Riker (https://github.com/douglasgscofield/riker), this script is a
# partial replacement for Picard tools' CreateSequenceDictionary.jar.  See
# https://github.com/douglasgscofield/riker#createsequencedictionary.
#
# CHANGELOG:
# - 2015-06-01 /usr/bin/env perl
# - 2013-04-18 Die gracefully if input file is missing
#
# TODO:
# --- See what if any Picard subtleties might be missing...
# xxx Handle gzipped input 

use strict;
use warnings;
use Getopt::Long;
use File::Basename qw();
use Digest::MD5 qw();
use Bio::Seq;
use Bio::SeqIO;

my $in_file = "";
my $out_file = "";
my $opt_verbose = 0;
my $progress = 10000;
my $help = 0;

use constant VERSION => "0.0.4";
my $script = File::Basename::basename($0);

sub usage ($){
    my $exitcode = shift;
    print "
createSequenceDictionary.pl [-o outfile] infile.fa

   Create a sequence dictionary for the input FASTA file.  The input file
   may be compressed with gzip.

   A sequence dictionary contains a SAM-format header line for each FASTA
   sequence with the sequence name, the full URL of the referene sequence
   (currently only local files are supported), and the 32-character MD5
   hashkey for the sequence after all gaps (as indicated by ' ' or '-') are
   removed.

   This is a partial replacement for Picard's CreateSequenceDictionary and is
   the only reasonable option when the infile has many sequences.  Equivalent
   command lines:

     java -jar picard.jar CreateSequenceDictionary R=reference.fasta O=reference.dict

     createSequenceDictionary.pl -o reference.dict reference.fasta

   Unlike Picard, this script does not support remote files available via URLs.

OPTIONS

   infile.fa             FASTA-format file of sequences, must be given
   -o FILE, --out FILE   Output dictionary to FILE; if not provided, the name
                         used is that of the input file with the final suffix
                         replaced by '.dict', so infile.fa has infile.dict
                         and infile.fa.gz has infile.fa.dict

   -v, --verbose         Show absolute paths of input and output files and
                         progress of dictionary creation
   -h, --help, -?        This message

";
    exit($exitcode);
}

GetOptions (
    'out=s' => \$out_file,
    'verbose' => \$opt_verbose,
    'help|?' => \$help,
) or usage(1);

usage(0) if $help;

die("one input file required, in FASTA format") if scalar(@ARGV) == 0 or scalar(@ARGV) > 1;

die("input file $ARGV[0] cannot be read") if ! -r $ARGV[0];

$in_file = File::Spec->rel2abs($ARGV[0]);
if (! $out_file) {
    my ($fn, $dir, $sfx) = File::Basename::fileparse($in_file, qr/\.[^.]*/);
    # this will remove .gz if the input is gzipped, so the dict file will
    # instead be namemd infile.fa.dict.
    $out_file = $dir . $fn . ".dict";
}

print STDERR "$script: input=$in_file output=$out_file\n" if $opt_verbose;

my $in = Bio::SeqIO->new( -file => "<$in_file", 
                          -format => "fasta" );
    
open(my $out, ">$out_file") or die("could not open output dictionary $out_file: $!");;

my $i = 0;

my @line = ( "\@HD", "VN:1.0", "SO:unsorted" );
print $out join("\t", @line), "\n";

while (my $seq = $in->next_seq()) {
    ++$i;
    print STDERR "$script: creating dictionary entry for sequence $i\n" if $opt_verbose and ! ($i % $progress);
    @line = "\@SQ";
    push @line, ("SN:" . $seq->display_id());
    push @line, ("LN:" . $seq->length());
    push @line, ("UR:file:" . $in_file);
    my $char_sequence = uc($seq->seq());
    $char_sequence =~ tr/ -//d;
    push @line, ("M5:" . Digest::MD5::md5_hex($char_sequence));
    print $out join("\t", @line), "\n";
}

print STDERR "$script: created a dictionary for $i sequences\n" if $opt_verbose;

$in->close;
$out->close;

