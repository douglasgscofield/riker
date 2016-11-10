Riker: Replacements for Picard tools
====================================

**Riker** aims to provide reasonable replacements for some of the Picard tools.

[Picard tools][] are a very useful set of Java-based tools for performing
bioinformatics tasks involving BAM, FASTA, FastQ files, etc.  However, like
many bioinformatics tools Picard suffers from the "all the world's a human
genome" problem, in that its usability declines rapidly for any genome project
that is not human or at least mammalian.  I was part of the the [Norway spruce
genome project][spruce] and our genome assemblies are &gt;10 gigabases and for
now have &gt;10M scaffolds.  These are statistics that send the Picard tools
that I am most interested in using into hysterics, and send me to the Java VM
documentation looking for ways to tune [memory usage][] and the garbage
collector to allow Picard to run on our genome on the 24GB nodes that are most
available to us.  This often fails, so I end up moving the problem to larger
nodes or off-site machines with even more resources.  Although some of this
arises simply because Picard inherits the problems (and benefits) of Java code,
given what Picard is doing I fail to see why it requires so many resources and
why so much tuning of the JVM and/or Picard itself is necessary.

[Picard tools]: http://picard.sourceforge.net
[spruce]:       http://www.congenie.org
[memory usage]: http://seqanswers.com/forums/showthread.php?t=15693

There are few alternatives to Picard.  Hence **Riker**.  Picard is
well-maintained and consistent, and this project can only be a partial
replacement, much like [Number One][] is quite competent but has his own
weaknesses and is definitely no [Picard][] (arguably, even [Kirk][] was no
Picard.)

[Number One]: http://en.wikipedia.org/wiki/William_Riker
[Picard]:     http://en.wikipedia.org/wiki/Jean-Luc_Picard
[Kirk]:       http://en.wikipedia.org/wiki/James_T_Kirk

**Riker** is a currently small hodgepodge of tools created as quickly and
easily as possible.  For the Perl scripts, you'll need [BioPerl][] installed.
For the compiled tools, you'll need a standard \*nix C++ compilation
environment, though note the only compiled tool so far is [yoruba][] and this
is not yet in production shape.  [Contact me][Contact] if you would like to
use [yoruba][] and I'll help get you started.

[BioPerl]:  http://www.bioperl.org
[yoruba]:   https://github.com/douglasgscofield/yoruba
[Contact]:  mailto:douglasgscofield@gmail.com

Picard tool                              |  Riker alternative
-----------------------------------------|---------------------
[AddOrReplaceReadGroups][Picard_AORRG]   |  [**yoruba readgroup**](#addorreplacereadgroups)
[CreateSequenceDictionary][Picard_CSD]   |  [**createSequenceDictionary.pl**](#createsequencedictionary)


[Picard_AORRG]: http://picard.sourceforge.net/command-line-overview.shtml#AddOrReplaceReadGroups
[Picard_CSD]:   http://picard.sourceforge.net/command-line-overview.shtml#CreateSequenceDictionary

Performance comparisons presented below were done on a 16-core 64-bit Ubuntu
machine with 192 GB RAM, with default options for the Java Virtual Machine for
Picard runs unless otherwise specified.  Timing and memory statistics were
collected using one run of the tool prefixed with `/usr/bin/time --verbose`,
with user time used for time and maximum resident set size used for memory
size.

To run a few unit tests after download, run the `test.sh` script while in the
`tests/` directory.


AddOrReplaceReadGroups
----------------------

Read groups in BAM files can be manipulated using the [Yoruba][yoruba] command
[readgroup][].  It is faster and more flexible than Picard's
[AddOrReplaceReadGroups][Picard_AORRG].  See that page for more information.

[readgroup]:  https://github.com/douglasgscofield/yoruba#readgroup



CreateSequenceDictionary
------------------------

A Picard sequence dictionary created from a FASTA file is a plaintext
[SAM-format][SAM] header containing one reference sequence line `@SQ` per FASTA
sequence.  Each `@SQ` line contains the sequence name, its length, its URL
location (local files have `file:` plus the file's absolute pathname), and a
32-character hexadecimal [MD5-format][MD5] hash of the sequence in uppercase
after all gaps and spaces are removed.  An additional `@HD` line begins the
dictionary with some simple descriptive tags.  

[SAM]:       http://samtools.sourceforge.net/SAM1.pdf
[MD5]:       http://en.wikipedia.org/wiki/MD5

The Riker script `createSequenceDictionary.pl` ([link][Riker_CSD]) uses
[BioPerl][] and standard release Perl packages.  Output from Riker and Picard
version 1.77 is identical for two examples (see below), but certainly Riker
could be more thoroughly tested.  Currently Riker can only read local files.

[Riker_CSD]: https://github.com/douglasgscofield/riker/blob/master/createSequenceDictionary.pl

### Usage

```
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
```

### Performance

For the human genome, Picard's CreateSequenceDictionary is fast, completing in
35 sec compared to 79 sec for the Riker script; Picard requires somewhat more
memory but the difference is not great.  For the spruce genome draft, which
contains many, many shorter sequences, Picard fails to run while consuming a
lot of memory with considerable time until failure.  Once the JVM is tuned so
that it completes, it is both slow and a memory hog.


FASTA Input   | Picard performance | Riker performance
--------------|--------------------|--------------------
[Human reference genome GRCh37.p9][NCBI_Human], 3.2Mbp in 245 seqs | 35 sec, 18 GB memory | 79 sec, 10 GB memory
[Spruce draft genome][spruce] July 2012 master, 12.4Gbp in 10.4M seqs | **failed**, exception with default JVM options, `java.lang.OutOfMemoryError: PermGen space` after 2613 sec, 126 GB memory | 959 sec, 69 MB memory
     | **failed**, exception with `-XX:MaxPermSize=2g`, `java.lang.OutOfMemoryError: GC overhead limit exceeded` after 15094 sec, 119 GB memory | 
     | **failed**, exception with `-XX:MaxPermSize=2g -XX:+UseParallelGC`, `java.lang.OutOfMemoryError: GC overhead limit exceeded` after 15246 sec, 119 GB memory | 
     | **failed**, exception with `-XX:MaxPermSize=2g -XX:+UseConcMarkSweepGC`, `java.lang.OutOfMemoryError: Java heap space` after 19 sec, 3 GB memory... strange | 
     | **completed** with `-XX:MaxPermSize=2g -XX:+UseConcMarkSweepGC -Xmx128g` after 39854 sec, 188 GB memory | 

[NCBI_Human]:  ftp://ftp.ncbi.nlm.nih.gov/genomes/H_sapiens/Assembled_chromosomes/seq/

