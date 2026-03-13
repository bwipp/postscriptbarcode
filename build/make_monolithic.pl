#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

# $Id$

use strict;
use warnings;
use lib 'build';
use BWIPP qw(read_version read_upr read_head parse_source extract_resource_body);

my $resourcedir = $ARGV[0] || '';

my $version = read_version();
my ($upr_entries) = read_upr();

print read_head($version);

print "% --BEGIN TEMPLATE--\n\n";

for my $entry (@$upr_entries) {
    my ($name, $relpath) = @$entry;

    my $srcfile = "src/$name.ps.src";
    $srcfile = 'src/preamble.ps.src' if $name eq 'uk.co.terryburton.bwipp';
    my $resfile = "$resourcedir/$relpath";

    open(my $fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
    my $src = join('', <$fh>);
    close $fh;

    my $parsed = parse_source($src);

    open($fh, '<', $resfile) || die "Unable to open resource file: $resfile";
    my $res = join('', <$fh>);
    close $fh;
    my $body = extract_resource_body($res);

    print $parsed->{begin_line};
    print $parsed->{meta};
    print $body;
    print "$parsed->{end_line}\n\n";

}

print "% --END TEMPLATE--\n";

exit 0;
