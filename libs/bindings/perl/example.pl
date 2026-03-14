#!/usr/bin/perl -w

use strict;
use postscriptbarcode;

my $bwipp;

if (@ARGV) {
    $bwipp = postscriptbarcode::BWIPP->new($ARGV[0]) || die 'Failed to load resource\n';
    my $ver = $bwipp->get_version() || die 'Failed to get version\n';
    print "Version: $ver\n";
} else {
    my $bwipp1 = postscriptbarcode::BWIPP->new("../../../build/monolithic_package/barcode.ps") || die 'Failed to load resource\n';
    $bwipp = postscriptbarcode::BWIPP->new("../../../build/monolithic/barcode.ps") || die 'Failed to load resource\n';

    my $ver = $bwipp1->get_version() || die 'Failed to get version\n';
    print "Packaged version: $ver\n";

    $ver = $bwipp->get_version() || die 'Failed to get version\n';
    print "Unpackaged version: $ver\n";

    my $ps = $bwipp1->emit_all_resources();
    my $lines = $ps=~tr/\n//;
    print "Packaged lines: $lines\n";
}

my $ps = $bwipp->emit_all_resources();
my $lines = $ps=~tr/\n//;
print "Unpackaged lines: $lines\n";

$ps = $bwipp->emit_required_resources("qrcode");
$lines = $ps=~tr/\n//;
print "qrcode resource lines: $lines\n";

$ps = $bwipp->emit_exec("qrcode", "Hello World", "eclevel=M");
$lines = $ps=~tr/\n//;
print "emit_exec lines: $lines\n";

my $encoders = $bwipp->list_encoders();
print "Encoders: " . scalar(@$encoders) . "\n";

my $families = $bwipp->list_families();
print "Families: " . scalar(@$families) . "\n";
for my $family (@$families) {
    my $members = $bwipp->list_family_members($family);
    print "  $family: " . scalar(@$members) . " members\n";
}

my $props = $bwipp->list_properties("qrcode");
print "qrcode properties: " . scalar(@$props) . "\n";
for my $prop (@$props) {
    print "  $prop: " . $bwipp->get_property("qrcode", $prop) . "\n";
}

1;
