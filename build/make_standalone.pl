#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

use strict;
use warnings;
use File::Basename;

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

my $fh;

open($fh, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <$fh>;
close $fh;
chomp $version;

open($fh, '<', 'src/ps.head') || die 'Unable to open ps.head';
my $head = join('', <$fh>);
close $fh;
$head =~ s/XXXX-XX-XX/$version/;

open($fh, '<', 'src/uk.co.terryburton.bwipp.upr') || die 'Unable to open UPR file';
my $upr = join('', <$fh>);
close $fh;

open($fh, '>', $outfile) || die "Failed to write $outfile";
print $fh $head;

my %seen;
for my $encoder (@encoders) {
    my $srcfile = "src/$encoder.ps.src";
    my $src_fh;
    open($src_fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
    my $src = join('', <$src_fh>);
    close($src_fh);

    ($_, $_, my $meta, $_) = $src =~ /
        ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ($encoder)--$
        (.*?)
        (^[^%].*?)
        ^%\ --END\ \1\ \2--$
    /msgx or die "Encoder unknown: $encoder";

    (my $reqs) = $meta =~ /^% --REQUIRES (.*)--$/mg;
    $reqs = '' unless defined $reqs;

    # Build set of resources to include: dependencies + encoder itself
    my %reqs_set;
    $reqs_set{$_} = 1 foreach split(' ', $reqs);
    $reqs_set{$encoder} = 1;

    # Output resources in UPR order (matching monolithic behavior)
    my @resources;
    while ($upr =~ /^(.*)=(.*)$/mg) {
        my $name = $1;
        $name = 'preamble' if $name eq 'uk.co.terryburton.bwipp';
        push @resources, $name if $reqs_set{$name};
    }

    for my $resource (@resources) {
        next if $seen{$resource}++;

        # Map resource name to file path via UPR
        my $lookup = $resource eq 'preamble' ? 'uk.co.terryburton.bwipp' : $resource;
        (my $relpath) = $upr =~ /^$lookup=(.*)$/m;
        die "Resource not found in UPR: $resource" unless $relpath;

        my $respath = "$resourcedir/$relpath";
        ($respath) = $respath =~ /(.*)/;  # Untaint

        my $res_fh;
        open($res_fh, '<', $respath) || die "Unable to open resource file: $respath";
        my $res = join('', <$res_fh>);
        close($res_fh);

        # Extract body from resource file (same pattern as make_monolithic.pl)
        $res =~ /
            (^%%BeginResource:\ [\w\.]+\ [\w\.-]+?\ .*?$)
            .*?
            (^%%BeginData:.*?$
            .*?
            ^%%EndResource$)
        /msgx or die "Failed to parse resource: $respath";
        my $body = "$1\n$2\n";

        print $fh "$body\n";
    }
}

close($fh);

exit 0;
