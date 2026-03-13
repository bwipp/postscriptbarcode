#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

use strict;
use warnings;
use File::Basename;
use lib 'build';
use BWIPP qw(read_version read_upr read_head parse_source extract_resource_body);

if ($#ARGV < 1) {
    die <<EOF
Usage: $0 <resourcedir> <outfile> [<encoder>...]

If encoders are not specified explicitly, the single encoder name is deduced
from the name of the output file.
EOF
}

my $resourcedir = shift;
my $outfile = shift;

($outfile) = $outfile =~ /(.*)/;   # Untaint

my @encoders = @ARGV;
if (!@encoders) {
    my $encoder = basename($outfile);
    $encoder =~ s/\.ps$//;
    push @encoders, $encoder;
}

my $version = read_version();
my ($upr_entries, $upr_lookup) = read_upr();

open(my $fh, '>', $outfile) || die "Failed to write $outfile";
print $fh read_head($version);

my %seen;
for my $encoder (@encoders) {
    my $srcfile = "src/$encoder.ps.src";
    open(my $src_fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
    my $src = join('', <$src_fh>);
    close($src_fh);

    my $parsed = parse_source($src);
    die "Encoder unknown: $encoder" unless $parsed->{name} eq $encoder;

    # Build set of resources to include: dependencies + encoder itself
    my %reqs_set;
    $reqs_set{$_} = 1 foreach split(' ', $parsed->{requires});
    $reqs_set{$encoder} = 1;

    # Output resources in UPR order (matching monolithic behavior)
    my @resources;
    for my $entry (@$upr_entries) {
        my $name = $entry->[0];
        $name = 'preamble' if $name eq 'uk.co.terryburton.bwipp';
        push @resources, $name if $reqs_set{$name};
    }

    for my $resource (@resources) {
        next if $seen{$resource}++;

        # Map resource name to file path via UPR
        my $lookup = $resource eq 'preamble' ? 'uk.co.terryburton.bwipp' : $resource;
        my $relpath = $upr_lookup->{$lookup};
        die "Resource not found in UPR: $resource" unless $relpath;

        my $respath = "$resourcedir/$relpath";
        ($respath) = $respath =~ /(.*)/;  # Untaint

        open(my $res_fh, '<', $respath) || die "Unable to open resource file: $respath";
        my $res = join('', <$res_fh>);
        close($res_fh);

        my $body = extract_resource_body($res);

        print $fh "$body\n";
    }
}

close($fh);

exit 0;
