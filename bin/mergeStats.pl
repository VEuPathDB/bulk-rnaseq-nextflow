#!/usr/bin/perl

use strict;

use Getopt::Long;
use Data::Dumper;

my ($nuFile, $nuCoverage, $fullFile, $fullCoverage, $unFile, $unCoverage, $totalReads, $outputFile);

&GetOptions("nuFile=s"=> \$nuFile,
	    "nuCoverage=s"=> \$nuCoverage,
	    "fullFile=s"=> \$fullFile,
	    "fullCoverage=s"=> \$fullCoverage,	    
	    "unFile=s"=> \$unFile,
	    "unCoverage=s"=> \$unCoverage,
            "totalReads=i" => \$totalReads,
            "outputFile=s" => \$outputFile);

&printHeaderLine($outputFile);

# Non Unique
my $nuCov = &getCoverage($nuCoverage);
my %nuStatsHash = &getStats($nuFile);
&printStats($outputFile,'non_unique_results.bam',$nuCov,$totalReads,\%nuStatsHash);

# Full 
my $fullCov = &getCoverage($fullCoverage);
my %fullStatsHash = &getStats($fullFile);
&printStats($outputFile,'results.bam',$fullCov,$totalReads,\%fullStatsHash);

# Unique
my $unCov = &getCoverage($unCoverage);
my %unStatsHash = &getStats($unFile);
&printStats($outputFile,'unique_results.bam',$unCov,$totalReads,\%unStatsHash);

#====================== Subroutines =======================================================================

sub printHeaderLine {
    my ($output) = @_;
    open (OUT, '>', $output);
    print OUT "file\tcoverage\tmapped\tnumber_reads_mapped\taverage_read_length\n";
    close OUT;
}

sub printStats {
    my ($output,$fileName,$coverage,$totalReads,$stats) = @_;
    open (OUT, '>>', $output);
    my %statsHash = %{ $stats };
    my $number_reads_mapped = $statsHash{"reads mapped"};
    my $average_length = $statsHash{"average length"};
    my $percent_mapped = $number_reads_mapped / $totalReads;
    print OUT "$fileName\t$coverage\t$percent_mapped\t$number_reads_mapped\t$average_length\n";
    close OUT;
}

sub getCoverage {
    my ($covFile) = @_;
    open(my $data, '<', $covFile) || die "Could not open file $covFile: $!";
    my $genomeCoverage = 0;
    my $count = 0;    
    while (my $line = <$data>) {
	chomp $line;
	if ($line =~ /^genome/) {
	    my ($identifier, $depth, $freq, $size, $proportion) = split(/\t/, $line);
	    $genomeCoverage += ($depth*$freq);
            $count += $freq;
        }
    }
    close $data;
    return ($genomeCoverage/$count);
}

sub getStats {
    my ($statFile) = @_;
    open(my $data, '<', $statFile) || die "Could not open file $statFile: $!";
    my %statsHash;
    while (my $line = <$data>) {
	chomp $line;
        my ($attr, $value) = split(/\t/, $line);
        $attr =~ s/\:$//;
        if ($attr eq "raw total sequences" || $attr eq "reads mapped" || $attr eq "average length") {
            $statsHash{$attr} = $value;
        }
    }
    close $data;
    return %statsHash;
}

#====================================================================================================

1;