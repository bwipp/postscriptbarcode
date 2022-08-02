#!/usr/bin/perl -w

# $Id$

use strict;
use File::Temp;
use File::Basename;

my $abspath = `pwd`;
chomp $abspath;

my $infile = $ARGV[0];
my $outfile = $ARGV[1];

(my $resdir) = $outfile =~ m#^(build/[^/]+)/#;
my $packager = $resdir eq 'build/packaged_resource' ? 'make_packaged_resource.ps' : 'make_resource.ps';

open(VER, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <VER>;
close VER;
chomp $version;

open(PS, '<', $infile) || die "File not found: $infile";
my $template = join('', <PS>);
close PS;

$template =~ /
    ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$
    (.*?)
    (^[^%].*?)
    ^%\ --END\ \1\ \2--$
/msgx;

my $resource = $2;
my $meta = $3;
my $body = $4;

(my $reqs) = $meta =~ /^% --REQUIRES (.*)--$/mg;
$reqs = '' unless defined $reqs;

my $neededresources = '';
foreach (split /\s+/, $reqs) {
  if ($_ eq 'preamble') {
    $neededresources.="Category/uk.co.terryburton.bwipp ";
  } else {
    $neededresources.="uk.co.terryburton.bwipp/$_ ";
  }
}
$neededresources =~ s/\s+$//;

open(PS, '>', "$outfile.tmp") || die "Failed to write $outfile";
print PS $body;
close PS;

my $category = 'uk.co.terryburton.bwipp';
my $key = $resource;
if ($resource eq 'preamble') {
  $category = 'Category';
  $key = 'uk.co.terryburton.bwipp';
}

my $vmusage = '0 0';
my $vmusagefile = mktemp('/tmp/vmusage.XXXXXX');

(my $yyyy, my $mm, my $dd, $_, my $rr) = $version =~ /^(\d{4})-(\d{2})-(\d{2})(-(\d{1,2}))?$/ or die 'Malformed version';
my $qualifier = "0.0 $yyyy$mm$dd" . sprintf("%02d",$rr || 0);

print `cd $resdir/Resource && gs -P -dNOSAFER -dQUIET -dNOPAUSE -dBATCH -sDEVICE=nullpage -sInputFilename='$abspath/$outfile.tmp' -sOutputFilename='$abspath/$outfile' -sVMusageFilename='$vmusagefile' -sCategory='$category' -sKey='$key' -sVMusage='$vmusage' -sQualifier='$qualifier' -sVersion='$version' -sNeededResources='$neededresources' -sPostWatermark='$category/$key $qualifier' ../../$packager`;
die 'GS create resource error' if $?;
unlink("$outfile.tmp");

my $vmout = `gs -dQUIET -dNOPAUSE -dBATCH -sDEVICE=nullpage -- $vmusagefile`;
die 'GS measure VMusage error' if $?;
($vmusage) = $vmout =~ /VMusage \((\d+ \d+)\) def/ or die 'Failed to determine VMusage';
unlink($vmusagefile);

# Stamp VMusage into the resource
{
  $^I = '';
  @ARGV = ($outfile);
  while (<>) {
    s/%%VMusage: \d+ \d+/%%VMusage: $vmusage/g;
    s/%%BeginResource: (.*) \d+ \d+/%%BeginResource: $1 $vmusage/g;
    print;
  }
}
