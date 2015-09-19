#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'PM'      => {'postscriptbarcode.pm' => '$(INST_LIB)/postscriptbarcode.pm'},
	'INC'    => '-I../../c',
	'LIBS'    => '-L../../c -lpostscriptbarcode',
	'OBJECT'  => 'postscriptbarcode_wrap.o'
);
