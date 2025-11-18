#!/usr/bin/perl -T

use strict;
use warnings;
use File::Basename;

if ($#ARGV < 1) {
    die <<EOF
Usage: $0 <infile> <outfile> [<encoder>...]

If encoders are not specified explicitly, the single encoder name is deduced
from the name of the output file.
EOF
}

my $infile = shift;
my $outfile = shift;

($outfile) = $outfile =~ /(.*)/;   # Untaint

my @encoders = @ARGV;
if (!@encoders) {
    my $encoder = basename($outfile);
    $encoder =~ s/\.ps$//;
    push @encoders, $encoder;
}

my $fh;

open($fh, '<', 'CHANGES') || die 'Unable to open CHANGES';
my $version = <$fh>;
close $fh;
chomp $version;

open($fh, '<', 'src/ps.head') || die 'Unable to open ps.head';
my $head = join('', <$fh>);
close $fh;
$head =~ s/XXXX-XX-XX/$version/;

open($fh, '<', $infile) || die "File not found: $infile";
my $template = join('', <$fh>);
close($fh);

open($fh, '>', $outfile) || die "Failed to write $outfile";
print $fh $head;

my %seen;
for my $encoder (@encoders) {
    ($_, $_, my $meta, $_) = $template =~ /
        ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ($encoder)--$
        (.*?)
        (^[^%].*?)
        ^%\ --END\ \1\ \2--$
    /msgx or die 'Encoder unknown';
    (my $reqs) = $meta =~ /^% --REQUIRES (.*)--$/mg;
    $reqs = '' unless defined $reqs;
    my %reqs = ($encoder => 1);
    $reqs{$_} = 1 foreach split ' ', $reqs;

    while ($template =~ /
        ^%\ --BEGIN\ (ENCODER|RENDERER|RESOURCE)\ ([\w-]+?)--$
        (.*?)
        (^%%.*?)
        (^[^%].*?)
        ^%\ --END\ \1\ \2--$
    /msgx) {
      my $resource = $2;
      my $meta = $3;
      my $dsc = $4;
      my $body = $5;
      next unless $reqs{$resource};
      next if $seen{$resource}++;
      print $fh "$dsc$body\n";
    }
}

close($fh);

exit 0;
