#!/usr/bin/perl -w

use postscriptbarcode;

$c=new postscriptbarcode::BWIPP("../../../build/monolithic_package/barcode.ps");
print $c->get_version();
print $c->emit_all_resources();

