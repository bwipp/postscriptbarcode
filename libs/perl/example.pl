#!/usr/bin/perl -Tw

use strict;

use postscriptbarcode;

$c=new postscriptbarcode::BWIPP("../../build/monolithic_package/barcode.ps");
print $c->get_version();

