#!/usr/bin/perl -w

use strict;
use File::Temp;
use File::Basename;

if ($#ARGV < 1) {
    die <<EOF
Usage: $0 <infile> <outfile> [<encoder>...]

If encoders are not specified explicitly, the single encoder name is deduced
from the name of the output file.
EOF
}

my $infile=shift;
my $outfile=shift;

my @encoders = @ARGV;
if (!@encoders) {
    my $encoder=basename($outfile);
    $encoder=~s/\.ps$//;
    push @encoders, $encoder;
}

open(VER,'CHANGES') || die 'Unable to open CHANGES';
my $version=<VER>;
close VER;
chomp $version;

open(HEAD,'src/ps.head') || die 'Unable to open ps.head';
my $head=join('',<HEAD>);
close HEAD;
$head=~s/XXXX-XX-XX/$version/;

open(PS,$infile) || die "File not found: $infile";
my $template=join('',<PS>);
close(PS);

open(PS,">$outfile") || die "Failed to write $outfile";
print PS $head;

my %seen;
for my $encoder (@encoders) {
    ($_,$_,my $meta,$_)=$template=~/
        ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ($encoder)--$
        (.*?)
        (^[^%].*?)
        ^%\ --END\ \1\ \2--$
    /msgx or die 'Encoder unknown';
    (my $reqs)=$meta=~/^% --REQUIRES (.*)--$/mg;
    $reqs='' unless defined $reqs;
    my %reqs=($encoder=>1);
    $reqs{$_}=1 foreach split ' ', $reqs;

    while ($template=~/
        ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$
        (.*?)
        (^%%.*?)
        (^[^%].*?)
        ^%\ --END\ \1\ \2--$
    /msgx) {
      my $resource=$2;
      my $meta=$3;
      my $dsc=$4;
      my $body=$5;
      next unless $reqs{$resource};
      next if $seen{$resource}++;
      print PS "$dsc$body\n";
    }
}

close(PS);

