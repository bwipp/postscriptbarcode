#!/usr/bin/perl

# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2026 Terry Burton
#
# Hold each resource's REQUIRES line to what the resource needs. A consumer
# makes a standalone program from an encoder by embedding the resources its
# REQUIRES line names, in that order, followed by the encoder (the
# build/standalone targets, libpostscriptbarcode's emit_required_resources),
# so the line must name every resource needed, however indirectly, and each
# before the resources that need it.
#
# For every source file:
#   - each name listed is a resource, listed once, and not the resource itself
#   - each resource the body loads with findresource is listed
#   - the list is closed: what a listed resource requires is listed too
#   - a listed resource comes after everything it requires

use strict;
use warnings;
use lib 'build';
use BWIPP qw(parse_source);

my (%requires, %loads);
for my $file (sort glob 'src/*.ps.src') {
    open(my $fh, '<', $file) || die "Unable to open $file";
    my $src = join('', <$fh>);
    close($fh);
    my $res = parse_source($src);
    $requires{$res->{name}} = [ split ' ', $res->{requires} ];
    $loads{$res->{name}} = [ $res->{body} =~ m{/([\w-]+) dup /uk\.co\.terryburton\.bwipp findresource}g ];
}

my @problems;
for my $name (sort keys %requires) {
    my @req = @{ $requires{$name} };
    my %pos;
    for my $i (0 .. $#req) {
        my $r = $req[$i];
        push @problems, "$name: lists $r, which is not a resource" unless exists $requires{$r};
        push @problems, "$name: lists $r more than once" if exists $pos{$r};
        push @problems, "$name: lists itself" if $r eq $name;
        $pos{$r} //= $i;
    }
    for my $l (@{ $loads{$name} }) {
        push @problems, "$name: loads $l but does not list it" unless exists $pos{$l};
    }
    for my $r (grep { exists $requires{$_} } @req) {
        for my $rr (@{ $requires{$r} }) {
            if (!exists $pos{$rr}) {
                push @problems, "$name: lists $r, which requires $rr, but does not list $rr";
            } elsif ($pos{$rr} > $pos{$r}) {
                push @problems, "$name: lists $rr after $r, which requires it";
            }
        }
    }
}

print "$_\n" for @problems;
exit(@problems ? 1 : 0);
