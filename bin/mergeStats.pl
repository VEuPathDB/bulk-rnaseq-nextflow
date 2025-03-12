#!/usr/bin/perl

use strict;

use Getopt::Long;

use File::Basename;

use Data::Dumper;

my ($sampleId, $outputFile, %stats);

&GetOptions("sampleId=s"=> \$sampleId,
            "outputFile=s" => \$outputFile);

my @HEADERS  = ("file",
                "coverage",
                "mapped",
                "number_reads_mapped",
                "average_read_length"
    );

my $fullStats = "${sampleId}.stats.filtered";
my $fullCov = "${sampleId}.cov";

&readFile($sampleId, $fullStats, \%stats, undef);
&readFile($sampleId, $fullCov, \%stats, undef);
&addPctMappedReads($sampleId, $sampleId, \%stats);

$stats{"${sampleId}"}->{file} = "results.bam";

my $totalReads = $stats{"${sampleId}"}->{"raw total sequences"};

my @otherFiles = glob("*unique*.{cov,filtered}");

foreach my $otherFile (@otherFiles) {
    my $otherFileName = $otherFile;

    $otherFile =~ s/\.cov$//;
    $otherFile =~ s/\.stats.filtered$//;

    &readFile($otherFile, $otherFileName, \%stats, $totalReads);
    &addFileKey($otherFile, $otherFileName, \%stats);
    &addPctMappedReads($otherFile, $sampleId, \%stats);
}


my $outFh;
open($outFh, ">$outputFile") or die "Cannot open file $outputFile for writing: $!";

print $outFh join("\t", @HEADERS) . "\n";
&printStatsHash($outFh, \%stats, \@HEADERS);
close $outFh;
#====================== Subroutines =======================================================================

sub printStatsHash {
    my ($fh, $statsHash, $headers) = @_;

    foreach my $key (keys %$statsHash) {
        my @values = map { $statsHash->{$key}->{$_} } @$headers;
        print $outFh join("\t", @values) . "\n";
    }
}

sub addPctMappedReads {
    my ($key, $fullKey, $statsHash) = @_;

    my $totalReads = $statsHash->{$fullKey}->{"raw total sequences"};
    my $mappedReads = $statsHash->{$key}->{"number_reads_mapped"};

    $statsHash->{$key}->{"mapped"} = $mappedReads / $totalReads;

}

sub addFileKey {
    my ($key, $file, $statsHash) = @_;

    my $fileBase = basename $file;
    my ($align, $sample, $strand, $suffixes) = split(/\./, $fileBase);

    my $fileValue = "${align}_results.bam";
    if($strand eq 'firststrand' || $strand eq 'secondstrand') {
        $fileValue = "${align}_results.${strand}.bam";
    }

    $statsHash->{$key}->{"file"} = $fileValue;
}


sub readFile {
    my ($uniqueId, $file, $statsHash, $totalReads) = @_;

    my $fileBase = basename $file;

    open(FILE, $file) or die "Cannot open file $file for reading: $!";
    while(<FILE>) {
        chomp;
        my ($key, $value) = split(/\t/, $_);

        if($key eq 'reads mapped') {
            $statsHash->{$uniqueId}->{number_reads_mapped} = $value;
        }
        elsif($key eq 'average length') {
            $statsHash->{$uniqueId}->{average_read_length} = $value;
        }
        else {
            $statsHash->{$uniqueId}->{$key} = $value;
        }
    }

    close FILE;
}

1;
