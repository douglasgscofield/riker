#!/bin/bash
# #!/bin/bash -x

TempID=$$
ScriptDir=..

# Complete set of variables used in tests; reset between tests

function ClearVariables()
{
    ThisTest=
    Input=
    CompressedInput=
    Expected=
    Output=
    Temp1=
    Temp2=
    Temp3=
}
ClearVariables

function RemoveTempFiles()
{
    rm -f $Temp1 $Temp2
    if [ "$Temp3" != "" ] ; then
        rm -f $Temp3
    fi
}
RemoveTempFiles


# -------------------------------- test_01


ThisTest="test_01"
echo "$ThisTest - general test of script operation with -o output"
Input=test_01_input.fa
CompressedInput=test_01_input.fa.gz
if [ "$CompressedInput" != "" -a ! -f $Input ] ; then
    gzip -d -c < $CompressedInput > $Input
fi
Expected=test_01.expected
Temp1=$ThisTest.$TempID.1
Temp2=$ThisTest.$TempID.2
$ScriptDir/createSequenceDictionary.pl -o $Temp1 $Input
# standardize filenames in UL: tag
sed -e 's/\(UR:file:\).*\(test_01_input.fa\)/\1\2/g' < $Temp1 > $Temp2
if diff $Temp2 $Expected ; then
    echo "$ThisTest - PASSED"
    RemoveTempFiles
    if [ "$CompressedInput" != "" ] ; then
        rm -f $Input
    fi
else
    echo "$ThisTest - FAILED"
fi
ClearVariables


# -------------------------------- test_02


ThisTest="test_02"
echo "$ThisTest - general test of script operation without -o"
# reuses input and expected output of test_01
Input=test_01_input.fa
CompressedInput=test_01_input.fa.gz
if [ "$CompressedInput" != "" -a ! -f $Input ] ; then
    gzip -d -c < $CompressedInput > $Input
fi
Expected=test_01.expected
Temp1=$ThisTest.$TempID.1
$ScriptDir/createSequenceDictionary.pl $Input
# script output should be in file named from $Input with final '.fa' replaced with '.dict'
Output=${Input%.fa}.dict
# standardize filenames in UL: tag
sed -e 's/\(UR:file:\).*\(test_01_input.fa\)/\1\2/g' < $Output > $Temp1
if diff $Temp1 $Expected ; then
    echo "$ThisTest - PASSED"
    rm -f $Output
    RemoveTempFiles
    if [ "$CompressedInput" != "" ] ; then
        rm -f $Input
    fi
else
    echo "$ThisTest - FAILED"
fi
ClearVariables


# -------------------------------- test_03


ThisTest="test_03"
echo "$ThisTest - general test of script operation with gzipped input"
CompressedInput=test_01_input.fa.gz
Expected=test_03.expected
Temp1=$ThisTest.$TempID.1
Temp2=$ThisTest.$TempID.2
$ScriptDir/createSequenceDictionary.pl -o $Temp1 $CompressedInput
# standardize filenames in UL: tag
sed -e 's/\(UR:file:\).*\(test_01_input.fa.gz\)/\1\2/g' < $Temp1 > $Temp2
if diff $Temp2 $Expected ; then
    echo "$ThisTest - PASSED"
    RemoveTempFiles
else
    echo "$ThisTest - FAILED"
fi
ClearVariables


# -------------------------------- test_04


ThisTest="test_04"
echo "$ThisTest - general test of script operation with --no-gzip option"
Input=test_01_input.fa
CompressedInput=test_01_input.fa.gz
if [ "$CompressedInput" != "" -a ! -f $Input ] ; then
    gzip -d -c < $CompressedInput > $Input
fi
Expected=test_01.expected
Temp1=$ThisTest.$TempID.1
Temp2=$ThisTest.$TempID.2
$ScriptDir/createSequenceDictionary.pl --no-gzip -o $Temp1 $Input
# standardize filenames in UL: tag
sed -e 's/\(UR:file:\).*\(test_01_input.fa\)/\1\2/g' < $Temp1 > $Temp2
if diff $Temp2 $Expected ; then
    echo "$ThisTest - PASSED"
    RemoveTempFiles
    if [ "$CompressedInput" != "" ] ; then
        rm -f $Input
    fi
else
    echo "$ThisTest - FAILED"
fi
ClearVariables


# -------------------------------- test_05


ThisTest="test_05"
echo "$ThisTest - general test of script operation with --verbose option"
Input=test_01_input.fa
CompressedInput=test_01_input.fa.gz
if [ "$CompressedInput" != "" -a ! -f $Input ] ; then
    gzip -d -c < $CompressedInput > $Input
fi
Expected=test_05.expected
Temp1=$ThisTest.$TempID.1
Temp2=$ThisTest.$TempID.2
Temp3=$ThisTest.$TempID.3
$ScriptDir/createSequenceDictionary.pl --verbose -o $Temp1 $Input 2>$Temp2
sed -e 's/\(input=\).*\(test_01_input.fa\)/\1\2/g' \
    -e 's/\(output=\).*\(test_05\).*\(.1\)/\1\2\3/g' < $Temp2 > $Temp3
if diff $Temp3 $Expected ; then
    echo "$ThisTest - PASSED"
    RemoveTempFiles
    if [ "$CompressedInput" != "" ] ; then
        rm -f $Input
    fi
else
    echo "$ThisTest - FAILED"
fi
ClearVariables


