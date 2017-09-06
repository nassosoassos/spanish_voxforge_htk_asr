#!/usr/bin/perl

# Converts an HTK SLF lattice file into an AT&T dot file.
# The dot file can then be converted into a PNG file or
# something for visualization.
#
# Copyright 2005 by Keith Vertanen
#

use strict;

if ( @ARGV < 1 )
{
    print "$0 <file>\n"; 
    exit(1);
}

my $slfFile;

($slfFile) = @ARGV;

open(IN, $slfFile);

my $line = "";
my $done = 0;

# First skip over the header
while (($done eq 0) && ($line = <IN>))
{
    if (($line =~ m/N=/) && ($line =~ m/L=/))
    {
	$done = 1;	
    }
}

$done = 0;

# Open up the dot graph object
printf "digraph G {\n";
printf "\trankdir = LR;\n";
printf "\tnode [fontname = \"Arial\"];\n";

my $id = "";
my $word = "";
my $start = "";
my $end = "";
my $acoustic = "";
my $lm = "";
my $time = "";

my $i = 0;
my @chunks;

# Create all the nodes using their HTK id and labeling them with their word.
# Also create the edges and label them with acoustic and LM scores.
while ($line = <IN>)
{
    @chunks = split(/\s{1,}/, $line);
	
    $id = "";
    $word = "";
    $start = "";
    $end = "";
    $acoustic = "";
    $lm = "";
    $time = "";

    # Find any fields in this line of text
    for ($i = 0; $i < scalar @chunks; $i++)
    {
	if ($chunks[$i] =~ m/I=/)
	{
		$id = substr($chunks[$i], 2);	
	}
	elsif ($chunks[$i] =~ m/W=/)
	{
		$word = substr($chunks[$i], 2);
	}
	elsif ($chunks[$i] =~ m/S=/)
	{
		$start = substr($chunks[$i], 2);
	}
	elsif ($chunks[$i] =~ m/E=/)
	{
		$end = substr($chunks[$i], 2);
	}
	elsif ($chunks[$i] =~ m/a=/)
	{
		$acoustic = substr($chunks[$i], 2);
	}
	elsif ($chunks[$i] =~ m/l=/)
	{
		$lm = substr($chunks[$i], 2);
	}
	elsif ($chunks[$i] =~ m/t=/)
	{
		$time = substr($chunks[$i], 2);
	}
    }

    # Now determine if we had a node line or an edge line
    if (($id eq "") && ($word eq ""))
    {
    # Discard emtpy start and end tags (otherwise graphviz throws an error)
    if(($start eq "") && ($end eq ""))
    {
    printf STDERR "Discarding an edge line, because the start AND end label is empty\n";
    }
    else
    {
	# Edge line	
	printf "\t$start -> $end [label = \"a=$acoustic l=$lm\"];\n";
    }
    }
    else
    {
	# Node line
    if($time eq "")
    {
	printf "\t$id [label = \"$word\"];\n";	
    }
    else
    {
    #replace > (greater than sign aka end node) with the html code (otherwise problems with dot
    #rendering)
    if($word eq ">")
    {
    $word="&gt;"
    }
    #replace > (smaller than sign aka start node) with the html code (otherwise problems with dot
    #rendering)
    elsif($word eq "<")
    {
    $word="&lt;"
    }
    #output the word with the time information. Print word bold and time smaller than the normal
    #font
	printf "\t$id [label = < <B>$word</B><br/><FONT POINT-SIZE='10'>t=$time</FONT> >];\n";	
    }
    }
}

close IN;

# Close the dot graph object
printf "}\n";
