#!/usr/bin/perl -Tw

#
#  Find the GCP length from a given GCP-prefixed string using the XML instance
#  of the GS1 Company Prefix (GCP) Length Table
#
#  https://www.gs1.org/standards/bc-epc-interop
#
#  Note that the input here must be prefixed by the GCP, so any extra data that
#  proceeds the GCP in a GS1 key must first be stripped, such as the Indicator
#  Digit in a GTIN-14 and the Extension Digit in an SSCC-18.
#


use strict;

use constant XML_FILE => 'gcpprefixformatlist.xml';


#
#  Globals populated by init()
#
my %gcppfxlen = ();
my $minplen;
my $maxplen;


#
#  Populate the GS1 GCP Length Table hash using a rough parse of the XML file
#  via a regex
#
sub init {
    $minplen = 1000;
    $maxplen = 0;
    open my $fh, '<', XML_FILE or die "Could not open file";
    while (<$fh>) {
        chomp;
        next unless (my $pfx, my $len) = $_ =~ m#<entry prefix="(\d+)" gcpLength="(\d+)"/>#;
        $gcppfxlen{$pfx} = $len;
        my $plen = length $pfx ;
        $minplen = $plen if $plen < $minplen;
        $maxplen = $plen if $plen > $maxplen;
    }
    close $fh;
}


#
#  Perform tests on the data from the XML file
#
sub sanity_check {

    foreach my $pfx (keys %gcppfxlen) {

        # No smaller prefix of the entry may exist
        for (1..length($pfx)-1) {
            die "Prefix of prefix $pfx exists!" if defined $gcppfxlen{substr($pfx, 0, $_)};
        }

        # The GCP length cannot be smaller than the prefix
        my $len = $gcppfxlen{$pfx};
        die "GCP length is smaller than the prefix itself for $pfx" if $len && $len < length($pfx);

    }

}


#
#  Use the GS1 GCP Length Table hash to find the length of the GCP that
#  prefixes a given string. Returns:
#
#    undef - Prefix is not defined
#    <0    - Negated length of GCP, which exceeds overall length of input
#     0    - Prefix is defined as not a GCP (zero length)
#    >0    - Length of GCP
#
sub find_gcp_length {
    $_ = shift;
    my $l;
    for (my $i = $minplen;
         $i <= $maxplen && $i <= length && not defined($l = $gcppfxlen{substr $_, 0, $i});
         $i++) {};
    return ($l && $l > length) ? -$l : $l;
}


#
#  Helper for generating a 8 to 20 digit random string
#
sub random_num {
    my @chars = ('1'..'9');
    my $out = '';
    $out .= $chars[int rand @chars] for (1..(int(rand(12))+8));
    return $out;
}


##########
#  Main  #
##########

init();
sanity_check();

while (1) {
    my $key = random_num();
    my $len = find_gcp_length($key);
    if (not defined $len) {
        print "KEY: $key => Prefix not defined\n";
    } elsif ($len < 0) {
        $len *= -1;
        print "KEY: $key => GCP length $len exceeds length of input\n";
    } elsif ($len == 0) {
        print "KEY: $key => Prefix is not a GCP\n";
    } else {
        my $gcp = substr $key, 0, $len;
        my $rem = substr $key, $len;
        print "KEY: $key => GCP: $gcp ; REM: $rem\n";
    }
}

