#!/usr/bin/perl -Tw

#
#  cat gs1-syntax-dictionary.txt | ./build-gs1-syntax-dict.pl
#
use strict;
use Data::Dumper;

print "    /gs1syntax <<\n";
print "\n";

my $ai_rx = qr/
    (
        (0\d)
    |
        ([1-9]\d{1,3})
    )
/x;

my $ai_rng_rx = qr/${ai_rx}(-${ai_rx})?/;

my $flags_rx = qr/
    [
        *?!"%&'()+,.:;<=>@[_`{|}~
        \$  \-  \/  \\  \]  \^
    ]+
/x;

my $type_mand_rx = qr/
    [XNYZ]
    (
        ([1-9]\d?)
        |
        (\.\.[1-9]\d?)
    )
/x;

my $type_opt_rx = qr/
    \[${type_mand_rx}\]
/x;

my $type_rx = qr/
    (
        ${type_mand_rx}
        |
        ${type_opt_rx}
    )
/x;

my $comp_rx = qr/
    ${type_rx}
    (,\w+)*
/x;

my $spec_rx = qr/
    ${comp_rx}
    (\s+${comp_rx})*
/x;

my $keyval_rx = qr/
    (
        (\w+)
        |
        (\w+=\S+)
    )
/x;

my $title_rx = qr/\S.*\S/;

# 123  *  N13,csum,key [X..17]  req=01,321 ex=42,101 dlpkey=22,10|789  # EXAMPLE TITLE
my $entry_rx = qr/
    ^
    (?<ais>${ai_rng_rx})
    (
        \s+
        (?<flags>${flags_rx})
    )?
    \s+
    (?<spec>${spec_rx})
    (
        \s+
        (?<keyvals>
            (${keyval_rx}\s+)*
            ${keyval_rx}
        )
    )?
    (
        \s+
        \#
        \s
        (?<title>${title_rx})
    )?
    \s*
    $
/x;

my $lastspecstr = '';
my $first = 1;

while (<>) {

    chomp;

    $_ =~ /^#/ and next;
    $_ =~ /^\s*$/ and next;

    $_ =~ $entry_rx or die "Bad entry: $_";

    my $ais = $+{ais};
    my $flags = $+{flags} || '';
    my $spec = $+{spec};
    my $keyvals = $+{keyvals} || '';
#    my $title = $+{title} || '';       # ignored

    my $specstr = "        <<\n            /parts [\n";
    foreach (split /\s+/, $spec) {

        (my $cset, my $linters) = split(',', $_, 2);

        (my $opt, $cset, my $len) = $cset =~ /^(\[?)(.)(.*?)\]?$/;
        $opt = $opt ? 'true ' : 'false';
        $len = "1$len" if $len =~ /^\.\./;
        $len = "$len..$len" if $len !~ /\./;
        (my $min, my $max) = $len =~ /^(\d+)\.\.(\d+)$/;
        $min = sprintf('% 2s', $min);
        $max = sprintf('% 2s', $max);

        $linters=$linters || '';
        my @linters=split(',', $linters);
        $linters='';
        $linters .= "/lint$_ " foreach @linters;
        $linters =~ s/^\s+|\s+$//g;
        $linters = " $linters " unless $linters eq '';

        $specstr .= "                << /cset /$cset  /min $min  /max $max  /opt $opt  /linters [$linters] >>\n";

    }
    $specstr .= "            ]\n";

    my %attrs = ();
    foreach (split /\s+/, $keyvals) {
        (my $key, $_, my $value) = $_ =~ /^([^=]+)(=(.*))?$/;
        $attrs{$key} = [] unless defined $attrs{$key};
        push @{$attrs{$key}}, $value if $value;
    }

    # Flatten, split and markup "ex"
    $specstr .= "            /ex     [ " . join(' ', map { "($_)" } map { split ',' } @{$attrs{ex}}) . " ]\n" if defined $attrs{'ex'};

    # Split and markup "req"
    my $reqspec = '';
    $reqspec .= "[ " . join(' ', map { '[ (' . join(') (', split '\+') . ') ]' } map { split ',' } $_) . " ] " foreach @{$attrs{'req'}};
    $specstr .= "            /req    [ $reqspec]\n" if $reqspec;

    # Pick first (only), split and markup "dlpkey"
    if (defined $attrs{'dlpkey'}) {
        my $dlpkeyspec = '';
        $dlpkeyspec .= "[ " . join(' ', map { "($_)" } split ',', $_) . " ] " foreach split '\|', @{$attrs{'dlpkey'}}[0] || '';
        $specstr .= "            /dlpkey [ $dlpkeyspec]\n";
    }

    # dlattr defaults to true since most AIs are valid DL URI attributes
    $specstr .= "            /dlattr false\n" if $flags !~ /\?/;

    $specstr .= "        >>\n";

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
