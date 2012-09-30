Riker: Replacements for Picard
==============================

**Riker** aims to provide reasonable replacements for some of the Picard tools.

[Picard tools][] are a very useful set of Java-based tools for performing
bioinformatics tasks involving BAM, FASTA, FastQ files, etc.  However, like
many bioinformatics tools Picard suffers from the "all the world's a human
genome" problem, in that its usability declines rapidly for any genome project
that is not human or at least mammalian.  I am part of the the [Norway spruce
genome project][spruce] and our genome assemblies are &gt;10 gigabases and for now
have &gt;10M scaffolds.  These are statistics that send the Picard tools that I
am most interested in using into hysterics, and send me to the Java VM
documentation looking for ways to tune [memory usage][] and the garbage
collector to allow Picard to run on our genome on the 24GB nodes that are most
available to us, or moving the problem to larger nodes or off-site machines
with even more resources.  Although some of this arises simply because Picard
inherits the problems (and benefits) of Java code, given what Picard is doing I
fail to see why it requires so many resources and why so much tuning of the JVM
and/or Picard itself is necessary.

[Picard tools]: http://picard.sourceforge.net
[spruce]:       http://www.congenie.org
[memory usage]: http://seqanswers.com/forums/showthread.php?t=15693

There are few alternatives to Picard.  Hence **Riker**.  Picard is
well-maintained and consistent, and this project can only be a partial
replacement, much like [Number One][] is quite competent but has his own
considerable weaknesses and is definitely no [Picard][] (arguably, even
[Kirk][] was no Picard.)

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
[Contact]:  mailto:douglasgscofield@gmail.com

Picard tool                              |  Riker alternative
-----------------------------------------|---------------------
[AddOrReplaceReadGroups][Picard_AORRG]   |  [**yoruba readgroup**][yoruba]
[CreateSequenceDictionary][Picard_CSD]   |  [**createSequenceDictionary.pl**](#Riker_CSD)


[Picard_AORRG]: http://picard.sourceforge.net/command-line-overview.shtml#AddOrReplaceReadGroups
[yoruba]:       https://github.com/douglasgscofield/yoruba
[Picard_CSD]:   http://picard.sourceforge.net/command-line-overview.shtml#CreateSequenceDictionary

Any performance comparisons presented below were done on a 16-core 64-but
Ubuntu machine with 192 GB RAM, with default options for the Java Virtual
Machine for the Picard runs.  Timing and memory statistics were collected using
one run of the tool prefixed with `/usr/bin/time --verbose`, with user time
used for time and maximum resident set size used for memory size.


CreateSequenceDictionary<a id="Riker_CSD"></a>
------------------------

A Picard sequence dictionary as created from a FASTA file contains one
[SAM-format][SAM] reference sequence line `@SQ` per FASTA sequence, with each
line containing the sequence name, its length, its URL location (if read from a
local file, then `file:` plus the file's absolute pathgname), and a
32-character hexadecimal [MD5-format][MD5] hash of the sequence in uppercase
after all gaps and spaces are removed.  An additional `@HD` line begins the
dictionary with some simple descriptive tags.  

The Riker script `createSequenceDictionary.pl` uses BioPerl to read FASTA
sequences and standard packages to create MD5 hashes.  Output from Riker and
Picard version 1.77 is identical for two examples (see below), but certainly
Riker could be more thoroughly tested.

[SAM]:  http://samtools.sourceforge.net/SAM1.pdf
[MD5]:  http://en.wikipedia.org/wiki/MD5

For the human genome, Picard's CreateSequenceDictionary is fast.  For the
spruce genome draft, which contains many, many shorter sequences, it is both
slow and a memory hog.

FASTA Input   | Picard performance | Riker performance
--------------|--------------------|--------------------
[Human reference genome GRCh37.p9][NCBI_Human], 3.2Mbp in 245 seqs | 35 s, 18 GB RAM | 79 s, 10 GB RAM
[Spruce draft genome][spruce] July 2012 master, 12.4Mbp in 10.4M seqs     | **failed to complete**, `java.lang.OutOfMemoryError: PermGen space` exception after 2613 s, 126 GB RAM | 959 s, 69 MB RAM
                                                                          | `-XX:MaxPermSize=2g` option to JVM; 2613 s, 126 GB RAM | 

[NCBI_Human]:  ftp://ftp.ncbi.nlm.nih.gov/genomes/H_sapiens/Assembled_chromosomes/seq/
