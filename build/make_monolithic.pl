#!/usr/bin/perl -Tw

# $Id$

use strict;

my $resourcedir = $ARGV[0] || '';

open(UPR, '<', 'src/uk.co.terryburton.bwipp.upr') || die 'Unable to open UPR file';
my $upr = join('', <UPR>);
close UPR;

open(VER, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <VER>;
close VER;
chomp $version;

open(HEAD, '<', 'src/ps.head') || die 'Unable to open ps.head';
my $head = join('', <HEAD>);
close HEAD;
$head =~ s/XXXX-XX-XX/$version/;
print $head;

print "% --BEGIN TEMPLATE--\n\n";

while ($upr =~ /^(.*)=(.*)$/mg) {

  my $srcfile = "src/$1.ps";
  $srcfile = 'src/preamble.ps' if $1 eq 'uk.co.terryburton.bwipp';
  my $resfile = "$resourcedir/$2";

  open(SRC, '<', $srcfile) || die "Unable to open source file: $srcfile";
  my $src = join('', <SRC>);
  close SRC;

  (my $begin, $_, $_, my $meta, my $end) = $src =~ /
    (^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$)
    (.*?)
    ^[^%].*?
    (^%\ --END\ \2\ \3--$)
  /msgx;

  open(RES, '<', $resfile) || die "Unable to open resource file: $resfile";
  my $res = join('', <RES>);
  close RES;
  $res =~ /
    (^%%BeginResource:\ [\w\.]+\ [\w\.-]+?\ .*?$)
    .*
    (^%%BeginData:.*?$
    .*
    ^%%EndResource$)
  /msgx;
  my $body = "$1\n$2\n";

  print $begin;
  print $meta;
  print $body;
  print "$end\n\n";

}

print "% --END TEMPLATE--\n";
