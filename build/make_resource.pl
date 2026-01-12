#!/usr/bin/perl -T

# vim: set sw=4 sts=4 et:

# $Id$

use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path getcwd);
use IPC::Cmd qw(can_run);

$ENV{PATH} = '/usr/local/bin:/usr/bin';

my $gs = can_run('gs') or die 'gs not installed in path';

(my $abspath) = abs_path(getcwd()) =~ /(.*)/;

my $infile = $ARGV[0];
my $outfile = $ARGV[1];

($outfile) = $outfile =~ /(.*)/;  # Untaint

END {
    if ($? != 0) {
        unlink("$outfile.tmp");
        unlink($outfile);
    }
}

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

open($fh, '>', "$outfile.tmp") || die "Failed to write $outfile.tmp";
print $fh $body;
close $fh;

my $category = 'uk.co.terryburton.bwipp';
my $key = $resource;
if ($resource eq 'preamble') {
    $category = 'Category';
    $key = 'uk.co.terryburton.bwipp';
}

my $vmusage = '0 0';

(my $yyyy, my $mm, my $dd, $_, my $rr) = $version =~ /^(\d{4})-(\d{2})-(\d{2})(-(\d{1,2}))?$/ or die 'Malformed version';
my $qualifier = "0.0 $yyyy$mm$dd" . sprintf("%02d",$rr || 0);

{
    use File::Temp qw(tempfile);
    my ($vmusage_fh, $vmusagefile) = tempfile('vmusage.XXXXXX', DIR => '/tmp', UNLINK => 1);
    ($vmusagefile) = $vmusagefile =~ /(.*)/;  # Untaint

    my $oldpwd = getcwd();
    ($oldpwd) = $oldpwd =~ /(.*)/;  # Untaint
    chdir("$resdir/Resource") or die "Cannot chdir to $resdir/Resource: $!";

    open(my $gs_fh, '-|', $gs, '-P', '-dNOSAFER', '-dQUIET', '-dNOPAUSE', '-dBATCH', '-sDEVICE=nullpage', "-sInputFilename=$abspath/$outfile.tmp", "-sOutputFilename=$abspath/$outfile", "-sVMusageFilename=$vmusagefile", "-sCategory=$category", "-sKey=$key", "-sVMusage=$vmusage", "-sQualifier=$qualifier", "-sVersion=$version", "-sNeededResources=$neededresources", "-sPostWatermark=$category/$key $qualifier", "../../$packager")
        or die "Cannot execute gs: $!";
    print while <$gs_fh>;
    close $gs_fh or die 'GS create resource error';

    chdir($oldpwd) or die "Cannot chdir back to $oldpwd: $!";
    unlink("$outfile.tmp");

    open(my $vm_fh, '-|', $gs, '-dQUIET', '-dNOPAUSE', '-dBATCH', '-sDEVICE=nullpage', '--', $vmusagefile, '2>&1')
        or die "Cannot execute gs for VMusage: $!";
    my $vmout = do { local $/; <$vm_fh> };
    close $vm_fh or die "GS measure VMusage error: $vmout";
    ($vmusage) = $vmout =~ /VMusage \((\d+ \d+)\) def/ or die 'Failed to determine VMusage';

    # $vmusagefile auto-deleted when $vmusage_fh goes out of scope
}

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

$? = 0;  # Mark successful completion
exit 0;
