#!/usr/bin/perl

use ExtUtils::MakeMaker;

`swig -Wall -perl -o postscriptbarcode_wrap.c -outdir . ../postscriptbarcode.i`;

WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'PM'      => {'postscriptbarcode.pm' => '$(INST_LIB)/postscriptbarcode.pm'},
	'INC'     => '-I../../c',
	'LIBS'    => '-L../../c -lpostscriptbarcode',
	'OBJECT'  => 'postscriptbarcode_wrap.o',
);
