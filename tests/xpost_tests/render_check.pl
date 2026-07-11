#!/usr/bin/perl

# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton

#
# Structural check of a rendered PGM against the encoder's own
# intermediate representation, so the raster oracle is derived from the
# same invocation rather than from golden images that go stale.
#
#   render_check.pl <mode> <render.pgm> [<info file>] [args...]
#
# Modes:
#   matrix <pgm> <info>
#       info holds PIXX/PIXY/PIXS from a dontdraw run. Locates the
#       symbol by its ink bounding box, derives the module pitch, and
#       requires the centre sample of every module to match pixs.
#   linear <pgm> <info>
#       info holds SBS. Samples a row near the top of the bars and
#       requires the ink/space run sequence to match the sbs widths.
#   presence <pgm> <min ink> <max ink> <max run>
#       For sub-pixel renderings with no exact pixel oracle: require
#       the ink count within [min,max] and no horizontal ink run
#       longer than <max run> (a smeared scanline reads as a long run).
#   area <pgm> <ref.pgm> <tolerance%>
#       Require this render's ink count within tolerance of the
#       reference render's (e.g. a rotated symbol against its
#       unrotated rendering).
#
# Exits 0 on pass; prints a reason and exits 1 on failure.

use strict;
use warnings;

sub fail { print "render_check: @_\n"; exit 1 }

sub read_pgm {
    my ($path) = @_;
    open my $fh, '<:raw', $path or fail("cannot open $path");
    local $/;
    my $data = <$fh>;
    close $fh;
    my ($w, $h, $max, $off, $px);
    if ($data =~ /\A(P[25])\s+(?:#[^\n]*\n\s*)*(\d+)\s+(\d+)\s+(\d+)\s/g) {
        my $kind = $1;
        ($w, $h, $max) = ($2, $3, $4);
        $off = pos($data);
        if ($kind eq 'P5') {
            $px = substr($data, $off);
        } else {
            $px = pack 'C*', split ' ', substr($data, $off);
        }
    } else {
        fail("$path is not a PGM");
    }
    fail("$path truncated") if length($px) < $w * $h;
    return { w => $w, h => $h, px => $px };
}

sub ink { # ($img, $x, $y)
    my ($img, $x, $y) = @_;
    return 0 if $x < 0 || $y < 0 || $x >= $img->{w} || $y >= $img->{h};
    return ord(substr($img->{px}, $y * $img->{w} + $x, 1)) < 128 ? 1 : 0;
}

sub ink_bbox {
    my ($img) = @_;
    my ($x0, $y0, $x1, $y1);
    for my $y (0 .. $img->{h} - 1) {
        my $row = substr($img->{px}, $y * $img->{w}, $img->{w});
        next unless $row =~ /[\x00-\x7f]/;
        my ($first) = $row =~ /^([\x80-\xff]*)/;
        my ($last)  = $row =~ /([\x80-\xff]*)$/;
        my $rx0 = length($first);
        my $rx1 = $img->{w} - 1 - length($last);
        $x0 = $rx0 if !defined $x0 || $rx0 < $x0;
        $x1 = $rx1 if !defined $x1 || $rx1 > $x1;
        $y0 = $y unless defined $y0;
        $y1 = $y;
    }
    fail("no ink in render") unless defined $x0;
    return ($x0, $y0, $x1, $y1);
}

sub ink_count {
    my ($img) = @_;
    my $n = () = $img->{px} =~ /[\x00-\x7f]/g;
    return $n;
}

sub read_info {
    my ($path) = @_;
    open my $fh, '<', $path or fail("cannot open $path");
    my %info;
    while (<$fh>) {
        $info{PIXX} = $1 if /^PIXX (\d+)/;
        $info{PIXY} = $1 if /^PIXY (\d+)/;
        $info{PIXS} = [split ' ', $1] if /^PIXS (.*)/;
        $info{SBS}  = [split ' ', $1] if /^SBS (.*)/;
    }
    close $fh;
    return \%info;
}

my $mode = shift @ARGV or fail("no mode");

if ($mode eq 'matrix') {
    my ($pgm, $inf) = @ARGV;
    my $img = read_pgm($pgm);
    my $info = read_info($inf);
    my ($pixx, $pixy, $pixs) = @$info{qw(PIXX PIXY PIXS)};
    fail("info lacks PIXX/PIXY/PIXS") unless $pixx && $pixy && $pixs;
    fail("pixs length != pixx*pixy") unless @$pixs == $pixx * $pixy;
    my ($x0, $y0, $x1, $y1) = ink_bbox($img);
    my $mw = ($x1 - $x0 + 1) / $pixx;
    my $mh = ($y1 - $y0 + 1) / $pixy;
    fail(sprintf("module pitch not square: %.3f x %.3f", $mw, $mh))
        if abs($mw - $mh) > 0.2;
    fail(sprintf("module pitch too small to sample: %.3f", $mw)) if $mw < 1.5;
    my $bad = 0;
    for my $j (0 .. $pixy - 1) {
        for my $i (0 .. $pixx - 1) {
            my $x = int($x0 + ($i + 0.5) * $mw);
            my $y = int($y0 + ($j + 0.5) * $mh);
            my $want = $pixs->[$j * $pixx + $i] ? 1 : 0;
            my $got = ink($img, $x, $y);
            if ($want != $got) {
                print "render_check: module ($i,$j) want $want got $got\n"
                    if ++$bad <= 5;
            }
        }
    }
    fail("$bad module mismatches of " . ($pixx * $pixy)) if $bad;
    exit 0;
}

if ($mode eq 'linear') {
    my ($pgm, $inf) = @ARGV;
    my $img = read_pgm($pgm);
    my $info = read_info($inf);
    my $sbs = $info->{SBS} or fail("info lacks SBS");
    my ($x0, $y0, $x1, $y1) = ink_bbox($img);
    my $y = $y0 + 2;   # near the top edge every bar is present
    # the symbol bbox can extend past the bars (text, guard marks):
    # scan between the row's own first and last ink
    my $row = substr($img->{px}, $y * $img->{w}, $img->{w});
    fail("no ink on sample row") unless $row =~ /[\x00-\x7f]/;
    my ($lead) = $row =~ /^([\x80-\xff]*)/;
    my ($tail) = $row =~ /([\x80-\xff]*)$/;
    my $rx0 = length($lead);
    my $rx1 = $img->{w} - 1 - length($tail);
    my @runs;          # (ink, width) pairs across the bars
    my $cur = ink($img, $rx0, $y);
    my $len = 0;
    for my $x ($rx0 .. $rx1) {
        my $v = ink($img, $x, $y);
        if ($v == $cur) { $len++ }
        else { push @runs, [$cur, $len]; $cur = $v; $len = 1 }
    }
    push @runs, [$cur, $len];
    # sbs alternates bar/space widths; the symbol begins and ends with
    # a bar, so expected runs are the nonzero sbs entries in order
    my @want = grep { $_->[1] > 0 }
               map { [($_ % 2 == 0) ? 1 : 0, $sbs->[$_]] } 0 .. $#$sbs;
    fail("run count " . @runs . " != sbs runs " . @want) if @runs != @want;
    for my $k (0 .. $#runs) {
        my ($gi, $gw) = @{$runs[$k]};
        my ($wi, $ww) = @{$want[$k]};
        fail("run $k polarity: want $wi got $gi") if $gi != $wi;
        fail("run $k width: want $ww got $gw") if abs($gw - $ww) > 1;
    }
    exit 0;
}

if ($mode eq 'presence') {
    my ($pgm, $min, $max, $maxrun) = @ARGV;
    my $img = read_pgm($pgm);
    my $n = ink_count($img);
    fail("ink $n below $min") if $n < $min;
    fail("ink $n above $max") if $n > $max;
    for my $y (0 .. $img->{h} - 1) {
        my $row = substr($img->{px}, $y * $img->{w}, $img->{w});
        while ($row =~ /([\x00-\x7f]+)/g) {
            fail("row $y has an ink run of " . length($1))
                if length($1) > $maxrun;
        }
    }
    exit 0;
}

if ($mode eq 'area') {
    my ($pgm, $ref, $tol) = @ARGV;
    my $n = ink_count(read_pgm($pgm));
    my $r = ink_count(read_pgm($ref));
    fail("reference has no ink") unless $r;
    my $dev = 100 * abs($n - $r) / $r;
    fail(sprintf("ink %d deviates %.1f%% from reference %d (tol %s%%)",
                 $n, $dev, $r, $tol)) if $dev > $tol;
    exit 0;
}

fail("unknown mode $mode");
