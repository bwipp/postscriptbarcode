#!/usr/bin/perl -Tw

#
#  cat gs1-format-spec.txt | ./build-gs1-syntax-dict.pl
#

use strict;

print "    /gs1syntax <<\n";
print "\n";

my $lastspecstr = '';
my $first = 1;

while (<>) {

    chomp;

    (my $ais, my $spec) = $_ =~ /^([0-9-]+)\s+(.*)\s*$/ or next;

    my @elms = split(/\s+/, $spec);

    my $specstr = "        [\n";
    foreach (@elms) {

        (my $cset, my $checks) = split(',', $_, 2);

        ($cset, my $len) = $cset =~ /^(.)(.*)$/;
        $len = "1$len" if $len =~ /^\.\./;
        $len = "$len..$len" if $len !~ /\./;
        (my $min, my $max) = $len =~ /^(\d+)\.\.(\d+)$/;
        $min = sprintf('% 2s', $min);
        $max = sprintf('% 2s', $max);

        $checks=$checks || '';
        my @checks=split(',', $checks);
        $checks='';
        $checks .= "/lint$_ " foreach @checks;
        $checks =~ s/^\s+|\s+$//g;
        $checks = " $checks " unless $checks eq '';

        $specstr .= "        << /cset /$cset  /min $min  /max $max  /check [$checks] >>\n";

    }
    $specstr .= "        ]\n";

    $ais = "$ais-$ais" if $ais !~ /-/;
    (my $aimin, my $aimax) = $ais =~ /^(\d+)-(\d+)$/;

    if ($specstr ne $lastspecstr) {
        print "        pop\n\n" if $first != 1;
        print $specstr;
    }

    print "        ($_) exch dup\n" for ($aimin..$aimax);

    $lastspecstr = $specstr;

    $first = 0;

}

print "        pop\n";
print "\n";
print "    >> def\n"
