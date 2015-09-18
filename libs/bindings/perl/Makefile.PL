#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'PM'      => {'postscriptbarcode.pm' => '$(INST_LIB)/postscriptbarcode.pm'},
	'LIBS'    => '-lpostscriptbarcode',
	'OBJECT'  => 'postscriptbarcode_wrap.o'
);
