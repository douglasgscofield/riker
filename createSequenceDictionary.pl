#!/usr/bin/perl

# Copyright (c) 2012 Douglas G. Scofield, Umeå Plant Sciences Centre, Umeå, Sweden
# douglas.scofield@plantphys.umu.se
# douglasgscofield@gmail.com
#
# No warranty is implied or assumed by this code.  Please send bugs, suggestions etc.
#
# Part of Riker (https://github.com/douglasgscofield/riker), this script is a
# partial replacement for Picard tools' CreateSequenceDictionary.jar.  See
# https://github.com/douglasgscofield/riker#createsequencedictionary.
#
# TODO:
# --- See what if any Picard subtleties might be missing...
# xxx Handle gzipped input 

use strict;
use warnings;
use Carp;
use Getopt::Long;
use File::Basename qw();
use Digest::MD5 qw();
use Bio::Seq;
use Bio::SeqIO;

my $in_file = "";
my $out_file = "";
my $opt_nogzip = 0;
my $gunzip = "gzip -d -c -f"; # command to unpack potentially gzipped file and send to stdout
my $opt_verbose = 0;
my $progress = 10000;
my $help = 0;

use constant VERSION => "0.0.2";
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

   This is a partial replacement for Picardtools' CreateSequenceDictionary.jar.

OPTIONS

   infile.fa             FASTA-format file of sequences, must be given
   -o FILE, --out FILE   output dictionary to FILE; if not provided, the name
                         used is infile.dict
   --no-gzip             open file directly, do not assume it might be gzipped

   -v, --verbose         show absolute paths of input and output files and
                         progress of dictionary creation
   -?, --help            this message
";
    exit($exitcode);
}

GetOptions (
    'out=s' => \$out_file,
    'verbose' => \$opt_verbose,
    'no-gzip' => \$opt_nogzip,
    'help|?' => \$help,
) or usage(1);

usage(0) if $help;

croak("one input file required, in FASTA format") if scalar(@ARGV) == 0 or scalar(@ARGV) > 1;

$in_file = File::Spec->rel2abs($ARGV[0]);
if (! $out_file) {
    my ($fn, $dir, $sfx) = File::Basename::fileparse($in_file, qr/\.[^.]*/);
    # this will remove .gz if the input is gzipped, so the dict file will
    # instead be namemd infile.fa.dict.
    $out_file = $dir . $fn . ".dict";
}

print STDERR "$script: input=$in_file output=$out_file\n" if $opt_verbose;

my $in = Bio::SeqIO->new( -file => ($opt_nogzip ? "<$in_file" : "$gunzip $in_file |"), 
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

