#!/usr/bin/perl -Tw

# $Id$

use strict;

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
  my $reqfiles = "$targetdir/$provfile : ";
  foreach my $req (split /\s+/, $reqs) {
    $req = 'uk.co.terryburton.bwipp' if $req eq 'preamble';
    (my $reqfile) = $upr =~ /^$req=(.*)$/m;
    $reqfiles .= "$targetdir/$reqfile ";
  }
  print "$reqfiles\n";
}
