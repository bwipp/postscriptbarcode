#!/usr/bin/perl -T

# $Id$

use strict;
use File::Temp;
use warnings;
use File::Basename;
use Cwd qw(abs_path getcwd);

$ENV{PATH} = '/usr/bin';

(my $abspath) = abs_path(getcwd()) =~ /(.*)/;

my $infile = $ARGV[0];
my $outfile = $ARGV[1];

($outfile) = $outfile =~ /(.*)/;  # Untaint

(my $resdir) = $outfile =~ m#^(build/[^/]+)/#;
my $packager = $resdir eq 'build/packaged_resource' ? 'make_packaged_resource.ps' : 'make_resource.ps';

my $fh;

open($fh, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <$fh>;
close $fh;
chomp $version;
($version) = $version =~ m/(.*)/;  # Untaint

open($fh, '<', $infile) || die "File not found: $infile";
my $template = join('', <$fh>);
close $fh;

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

open($fh, '>', "$outfile.tmp") || die "Failed to write $outfile";
print $fh $body;
close $fh;

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

exit 0;
