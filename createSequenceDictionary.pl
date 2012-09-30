#!/usr/bin/perl

# A replacement for the memory-expensive picard CreateSequenceDictionary.jar.
# I don't think that task of MD5'ing a set of Fasta sequences should require
# more memory than a 24G node.
#
# TODO:
# o  See how we handle chromosome-size sequences

use strict;
use warnings;
use Carp;
use Getopt::Long;
use File::Basename qw();
use Digest::MD5 qw();
use Bio::Seq;
use Bio::SeqIO;

my $infile = "";
my $outfile = "";
my $verbose = 1;

my $thisscript = File::Basename::basename($0);

sub usage {
    print "\
CreateSequenceDictionary.pl [-o outfile.dict] infile.fa\
\
    Replacement for CreateSequenceDictionary.jar \
\
   infile.fa          FASTA-format file of sequences, must be given \
   -o outfile.dict    output file, infile.dict if not provided \
";
    exit(0);
}
GetOptions (
    "o=s" => \$outfile,
) or usage();

if ($verbose) {
    print STDERR "CreateSequenceDictionary.pl: input=$infile output=$outfile\n";
}

croak("one input file required, in FASTA format") if scalar(@ARGV) == 0 or scalar(@ARGV) > 1;

my $in = Bio::SeqIO->new( -file => "<$ARGV[0]", -format => "fasta" );
#my $out = ($outfile) ? Bio::SeqIO->new( -file => ">$outfile", -format => $outformat)
#                     : Bio::SeqIO->new( -fh => \*STDOUT, -format => $outformat);

$infile = File::Spec->rel2abs($ARGV[0]);

if (! $outfile) {
    my ($fn, $dir, $sfx) = File::Basename::fileparse($infile, qr/\.[^.]*/);
    $outfile = $dir . $fn . ".dict";
}
    
open(my $out, ">$outfile");

my $i = 0;

my @line = ( "\@HD", "VN:1.0", "SO:unsorted" );
print $out join("\t", @line), "\n";

while (my $seq = $in->next_seq()) {
    ++$i;
    print STDERR "$thisscript: converting sequence $i\n" if $verbose > 0 and ! ($i % 100000);
    @line = "\@SQ";
    push @line, ("SN:" . $seq->display_id());
    push @line, ("LN:" . $seq->length());
    push @line, ("UR:file:" . $infile);
    my $char_sequence = uc($seq->seq());
    $char_sequence =~ tr/ -//d;
    push @line, ("M5:" . Digest::MD5::md5_hex($char_sequence));
    print $out join("\t", @line), "\n";
}

print STDERR "$thisscript: total of $i sequences converted\n" if $verbose;

$in->close;
$out->close;

