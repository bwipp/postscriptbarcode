#!/usr/bin/perl -w

use strict;

open (my ($ps), '<', 'barcode.ps') || die 'File not found';
$_=join('',<$ps>);
close($ps);
m/
    %\ --BEGIN\ TEMPLATE--
    (.*)
    %\ --END\ TEMPLATE--
    /sx || die 'Unable to parse out the template';
my $template='';
$template.="%!PS-Adobe-2.0 EPSF-2.0\n";
$template.="%%BoundingBox: 0 0 [% width %] [% height %]\n";
$template.="%%EndComments";
$template.=$1;
$template.="10 7 moveto\n";
$template.="[% call %]\n";
$template.="showpage\n";

open (my ($in), '<', 'figs.txt') || die 'File not found';
my @figs=<$in>;
close($in);

foreach (@figs) {
    m/^(.*):(.*):(.*):(.*)$/ || die "Bad line: $_";
    my $filename=$1;
    my $width=$2;
    my $height=$3;
    my $contents=$4;
    my $barcode=$template;
    $barcode=~s/\[% call %\]/$contents/;
    $barcode=~s/\[% width %\]/$width/;
    $barcode=~s/\[% height %\]/$height/;
    open(my ($out), '>', $filename) || die 'Open file failed';
    print $out $barcode;
    close($out);
}
