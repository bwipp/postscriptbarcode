#!/usr/bin/perl -w
use strict;

die 'Requires two arguments' if (@ARGV!=2);

open(PS,'barcode.ps') || die 'File not found';
$_=join('',<PS>);
close(PS);

print "%!PS-Adobe-2.0\n";

m/
    %\ --BEGIN\ TEMPLATE--
    (.*)
    %\ --END\ TEMPLATE--
    /sx || die 'Unable to parse out the template';
print $1;

for (my $i=$ARGV[0], my $j=0; $i<$ARGV[1]; $i++, $j++) {
    my $x=100+150*(int($j/7));
    my $y=100+100*($j%7);
    print "gsave\n";
    print "$x $y moveto\n";
    print "($i) (includetext) /ean13 /uk.co.terryburton.bwipp findresource exec\n";
    print "grestore\n";
}

print "showpage\n";

