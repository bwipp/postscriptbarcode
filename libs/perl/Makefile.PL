#!/usr/bin/perl

use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'    => 'postscriptbarcode',
	'OBJECT'  => 'postscriptbarcode.o postscriptbarcode_wrap.o'
);
