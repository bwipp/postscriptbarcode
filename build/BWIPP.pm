package BWIPP;

# vim: set sw=4 sts=4 et:

# Copyright (c) 2004-2026 Terry Burton
#
# Permission is hereby granted, free of charge, to any
# person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without
# limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions
# of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    read_version
    read_upr
    parse_source
    read_head
    extract_resource_body
);

#
# Compiled regex patterns
#

# Source file markers: % --BEGIN ENCODER qrcode-- ... % --END ENCODER qrcode--
my $resource_type_rx = qr/ ENCODER | RENDERER | RESOURCE /x;
my $resource_name_rx = qr/ [\w-]+? /x;

my $source_rx = qr/
    (?<begin_line>^%\ --BEGIN\ (?<type>${resource_type_rx})\ (?<name>${resource_name_rx})--$)
    (?<meta>.*?)
    (?<body>^[^%].*?)
    (?<end_line>^%\ --END\ \k<type>\ \k<name>--$)
/msx;

# Source file metadata
my $requires_rx = qr/
    ^%\ --REQUIRES\ (?<requires>.*)--$
/mx;

# UPR file entries: name=path
my $upr_entry_rx = qr/
    ^ (?<name>.*) = (?<path>.*) $
/mx;

# Built resource file DSC structure
my $dsc_category_rx = qr/ [\w\.]+ /x;
my $dsc_key_rx      = qr/ [\w\.-]+? /x;
my $dsc_vmusage_rx  = qr/ .*? /x;

my $res_header_rx = qr/
    ^%%BeginResource:\ ${dsc_category_rx}\ ${dsc_key_rx}\ ${dsc_vmusage_rx}$
/mx;

my $res_data_rx = qr/
    ^%%BeginData:.*?$
    .*?
    ^%%EndResource$
/msx;

my $resource_body_rx = qr/
    (?<header>${res_header_rx})
    .*?
    (?<data>${res_data_rx})
/msx;


#
# Functions
#

# First line of CHANGES, untainted
sub read_version {
    open(my $fh, '<', 'CHANGES') || die 'Unable to open CHANGES';
    my $version = <$fh>;
    close $fh;
    chomp $version;
    ($version) = $version =~ m/(.*)/;  # Untaint
    return $version;
}

# Parse UPR file into ordered entries and lookup hash
sub read_upr {
    open(my $fh, '<', 'src/uk.co.terryburton.bwipp.upr') || die 'Unable to open UPR file';
    my $upr = join('', <$fh>);
    close $fh;
    my @entries;
    my %lookup;
    while ($upr =~ /$upr_entry_rx/g) {
        push @entries, [$+{name}, $+{path}];
        $lookup{$+{name}} = $+{path};
    }
    return (\@entries, \%lookup);
}

# Extract resource metadata from .ps.src content
sub parse_source {
    my ($src) = @_;
    $src =~ /$source_rx/ or die 'Failed to parse source';
    my %m = %+;
    my ($requires) = $m{meta} =~ /$requires_rx/;
    $requires = '' unless defined $requires;
    return {
        type       => $m{type},
        name       => $m{name},
        meta       => $m{meta},
        body       => $m{body},
        begin_line => $m{begin_line},
        end_line   => $m{end_line},
        requires   => $requires,
    };
}

# Read ps.head with version substitution
sub read_head {
    my ($version) = @_;
    open(my $fh, '<', 'src/ps.head') || die 'Unable to open ps.head';
    my $head = join('', <$fh>);
    close $fh;
    $head =~ s/XXXX-XX-XX/$version/;
    return $head;
}

# Extract DSC-wrapped body from a built resource file
sub extract_resource_body {
    my ($res) = @_;
    $res =~ /$resource_body_rx/ or die 'Failed to parse resource body';
    return "$+{header}\n$+{data}\n";
}

1;
