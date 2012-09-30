#!/usr/bin/perl -w

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
# --- Handle gzipped input 
# --- See what if any Picard subtleties might be missing...

use strict;
use Carp;
use Getopt::Long;
use File::Basename qw();
use Digest::MD5 qw();
use Bio::Seq;
use Bio::SeqIO;

use constant VERSION => "0.0.1";
my $thisscript = File::Basename::basename($0);

my $infile = "";
my $outfile = "";
my $opt_verbose = 0;

sub usage {
    print "\
CreateSequenceDictionary.pl [-o outfile.dict] infile.fa\
\
    Replacement for CreateSequenceDictionary.jar \
\
   infile.fa                    FASTA-format file of sequences, must be given \
   -o | --output outfile.dict   output file, infile.dict if not provided \
   -v | --verbose               verbose output on STDERR
";
    exit(0);
}
GetOptions (
    "o=s" => \$outfile,
    "v" => \$opt_verbose,
    "verbose" => \$opt_verbose,
) or usage();

croak("one input file required, in FASTA format") if scalar(@ARGV) != 1;

my $in = Bio::SeqIO->new( -file => "<$ARGV[0]", -format => "fasta" );

$infile = File::Spec->rel2abs($ARGV[0]);

if (! $outfile) {
    my ($fn, $dir, $sfx) = File::Basename::fileparse($infile, qr/\.[^.]*/);
    $outfile = $dir . $fn . ".dict";
}
    
open(my $out, ">$outfile");

if ($opt_verbose) {
    print STDERR "$thisscript: input=$infile output=$outfile\n";
}

my $i = 0;

my @line = ( "\@HD", "VN:1.0", "SO:unsorted" );
print $out join("\t", @line), "\n";

while (my $seq = $in->next_seq()) {
    ++$i;
    print STDERR "$thisscript: converting sequence $i\n" if $opt_verbose and ! ($i % 100000);
    @line = "\@SQ";
    push @line, ("SN:" . $seq->display_id());
    push @line, ("LN:" . $seq->length());
    push @line, ("UR:file:" . $infile);
    my $char_sequence = uc($seq->seq());
    $char_sequence =~ tr/ -//d;
    push @line, ("M5:" . Digest::MD5::md5_hex($char_sequence));
    print $out join("\t", @line), "\n";
}

print STDERR "$thisscript: total of $i sequences converted\n" if $opt_verbose;

$in->close;
$out->close;

