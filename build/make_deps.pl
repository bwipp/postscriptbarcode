#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

# $Id$

use strict;
use warnings;
use lib 'build';
use BWIPP qw(read_upr parse_source);

my $srcfile = shift @ARGV || '';

open(my $fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
my $src = join('', <$fh>);
close($fh);

my ($upr_entries, $upr_lookup) = read_upr();

my $parsed = parse_source($src);
my $resource = $parsed->{name};
$resource = 'uk.co.terryburton.bwipp' if $resource eq 'preamble';
my $reqs = $parsed->{requires};

my $provfile = $upr_lookup->{$resource};

while (my $targetdir = shift @ARGV) {
    my @reqs_list = split /\s+/, $reqs;
    next unless @reqs_list;  # Skip if no dependencies
    my $reqfiles = "$targetdir/$provfile : |";
    foreach my $req (@reqs_list) {
        $req = 'uk.co.terryburton.bwipp' if $req eq 'preamble';
        $reqfiles .= " $targetdir/$upr_lookup->{$req}";
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
            $reqfiles .= " $resdir/$upr_lookup->{$req}";
        }
        # Include the encoder itself as a dependency
        $reqfiles .= " $resdir/$provfile";
        print "$reqfiles\n";
    }
}

exit 0;
