#!/usr/bin/perl -w

use strict;
use postscriptbarcode;

my $bwipp1 = postscriptbarcode::BWIPP->new("../../../build/monolithic_package/barcode.ps") || die 'Failed to load resource\n';
my $bwipp2 = postscriptbarcode::BWIPP->new("../../../build/monolithic/barcode.ps") || die 'Failed to load resource\n';

my $ver = $bwipp1->get_version() || die 'Failed to get version\n';
print "Packaged version: $ver\n";

$ver = $bwipp2->get_version() || die 'Failed to get version\n';
print "Unpackaged version: $ver\n";

my $ps = $bwipp1->emit_all_resources();
my $lines = $ps=~tr/\n//;
print "Packaged lines: $lines\n";

$ps = $bwipp2->emit_all_resources();
$lines = $ps=~tr/\n//;
print "Unpackaged lines: $lines\n";

$ps = $bwipp2->emit_required_resources("qrcode");
$lines = $ps=~tr/\n//;
print "qrcode resource lines: $lines\n";

$ps = $bwipp2->emit_exec("qrcode", "Hello World", "eclevel=M");
$lines = $ps=~tr/\n//;
print "emit_exec lines: $lines\n";

my $encoders = $bwipp2->list_encoders();
print "Encoders: " . scalar(@$encoders) . "\n";

my $families = $bwipp2->list_families();
print "Families: " . scalar(@$families) . "\n";
for my $family (@$families) {
    my $members = $bwipp2->list_family_members($family);
    print "  $family: " . scalar(@$members) . " members\n";
}

my $props = $bwipp2->list_properties("qrcode");
print "qrcode properties: " . scalar(@$props) . "\n";
for my $prop (@$props) {
    print "  $prop: " . $bwipp2->get_property("qrcode", $prop) . "\n";
}

1;
