#!/usr/bin/perl -Tw

use strict;

use postscriptbarcode;

$c=new postscriptbarcode::BWIPP("../barcode.ps");
print $c->get_version();

