#!/usr/bin/perl -T

# $Id$

use strict;
use warnings;

my $resourcedir = $ARGV[0] || '';

my $fh;

open($fh, '<', 'src/uk.co.terryburton.bwipp.upr') || die 'Unable to open UPR file';
my $upr = join('', <$fh>);
close $fh;

open($fh, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <$fh>;
close $fh;
chomp $version;

open($fh, '<', 'src/ps.head') || die 'Unable to open ps.head';
my $head = join('', <$fh>);
close $fh;
$head =~ s/XXXX-XX-XX/$version/;
print $head;

print "% --BEGIN TEMPLATE--\n\n";

while ($upr =~ /^(.*)=(.*)$/mg) {

  my $srcfile = "src/$1.ps.src";
  $srcfile = 'src/preamble.ps.src' if $1 eq 'uk.co.terryburton.bwipp';
  my $resfile = "$resourcedir/$2";

  open($fh, '<', $srcfile) || die "Unable to open source file: $srcfile";
  my $src = join('', <$fh>);
  close $fh;

  (my $begin, $_, $_, my $meta, my $end) = $src =~ /
    (^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$)
    (.*?)
    ^[^%].*?
    (^%\ --END\ \2\ \3--$)
  /msgx;

  open($fh, '<', $resfile) || die "Unable to open resource file: $resfile";
  my $res = join('', <$fh>);
  close $fh;
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

exit 0;
