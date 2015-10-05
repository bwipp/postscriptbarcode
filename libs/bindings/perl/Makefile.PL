#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

open my $f, '<', "../../SOVERSION"; 
my $maj=<$f>; 
close $f;
chomp $maj;
open my $f, '<', "../../../CHANGES"; 
my $min=<$f>; 
close $f;
chomp $min;
$min=~s/-//g;

`swig -Wall -perl -o postscriptbarcode_wrap.c -outdir . ../postscriptbarcode.i`;

WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'PM'      => {'postscriptbarcode.pm' => '$(INST_LIB)/postscriptbarcode.pm'},
	'INC'     => '-I../../c',
	'LIBS'    => '-L../../c -lpostscriptbarcode',
	'OBJECT'  => 'postscriptbarcode_wrap.o',
	'VERSION' => "$maj.$min",
);
