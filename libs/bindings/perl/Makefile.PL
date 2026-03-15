#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

open my $f, '<', "../../CHANGES";
my $ver=<$f>;
close $f;
chomp $ver;

`swig -Wall -perl -o postscriptbarcode_wrap.c -outdir . ../postscriptbarcode.i`;

WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'PM'      => {'postscriptbarcode.pm' => '$(INST_LIB)/postscriptbarcode.pm'},
	'INC'     => '-I../../c',
	'LIBS'    => '-L../../c -lpostscriptbarcode',
	'OBJECT'  => 'postscriptbarcode_wrap.o',
	'VERSION' => $ver,
);
