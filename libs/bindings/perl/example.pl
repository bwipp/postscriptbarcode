#!/usr/bin/perl -w

use strict;
use postscriptbarcode;

my $bwipp1=new postscriptbarcode::BWIPP("../../../build/monolithic_package/barcode.ps") || die 'Failed to load resource\n';
my $bwipp2=new postscriptbarcode::BWIPP("../../../build/monolithic/barcode.ps") || die 'Failed to load resource\n';

my $ver=$bwipp1->get_version() || die 'Failed to get version\n';
print "Packaged version: $ver\n";
$ver=$bwipp2->get_version() || die 'Failed to get version\n';
print "Unpackaged version: $ver\n";

my $ps=$bwipp1->emit_all_resources();
my $lines=$ps=~tr/\n//;
print "Packaged lines: $lines\n";
$ps=$bwipp2->emit_all_resources();
$lines=$ps=~tr/\n//;
print "Unpackaged lines: $lines\n";


