#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

# $Id$

use strict;
use warnings;

my $srcfile = shift @ARGV || '';

my $fh;

open($fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
my $src = join('', <$fh>);
close($fh);

open($fh, '<', 'src/uk.co.terryburton.bwipp.upr') || die 'Unable to open UPR file';
my $upr = join('', <$fh>);
close($fh);

(my $begin, $_, my $resource, my $meta, $_, my $end) = $src =~ /
    (^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$)
    (.*?)
    (^[^%].*?)
    (^%\ --END\ \2\ \3--$)
/msgx;

$resource = 'uk.co.terryburton.bwipp' if $resource eq 'preamble';

(my $reqs) = $meta =~ /^% --REQUIRES (.*)--$/mg;
$reqs = '' unless defined $reqs;

(my $provfile) = $upr =~ /^$resource=(.*)$/m;

while (my $targetdir = shift @ARGV) {
    my @reqs_list = split /\s+/, $reqs;
    next unless @reqs_list;  # Skip if no dependencies
    my $reqfiles = "$targetdir/$provfile : |";
    foreach my $req (@reqs_list) {
        $req = 'uk.co.terryburton.bwipp' if $req eq 'preamble';
        (my $reqfile) = $upr =~ /^$req=(.*)$/m;
        $reqfiles .= " $targetdir/$reqfile";
    }
    print "$reqfiles\n";
}

# Standalone dependency rules (only for encoders, not preamble)
if ($resource ne 'uk.co.terryburton.bwipp') {
    for my $standalonedir ('build/standalone', 'build/standalone_package') {
        my $resdir = $standalonedir eq 'build/standalone'
            ? 'build/resource/Resource' : 'build/packaged_resource/Resource';
        my $reqfiles = "$standalonedir/$resource.ps :";
        foreach my $req (split /\s+/, $reqs) {
            $req = 'uk.co.terryburton.bwipp' if $req eq 'preamble';
            (my $reqfile) = $upr =~ /^$req=(.*)$/m;
            $reqfiles .= " $resdir/$reqfile";
        }
        # Include the encoder itself as a dependency
        $reqfiles .= " $resdir/$provfile";
        print "$reqfiles\n";
    }
}

exit 0;
