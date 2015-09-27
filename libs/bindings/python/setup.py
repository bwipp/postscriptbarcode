#!/usr/bin/env python

"""
setup.py file for postscriptbarcode
"""

from distutils.core import setup, Extension

with open('../../../CHANGES', 'r') as f:
    ver = f.readline().strip().replace("-", "")

postscriptbarcode_module = Extension(
	'_postscriptbarcode',
	sources=['postscriptbarcode.i'],
	include_dirs = ['../../c'],
	libraries=['postscriptbarcode'],
	library_dirs=['../../c'],
)

setup(name = 'postscriptbarcode',
	version     = ver,
	author      = "Terry Burton",
	description = """Python binding for Barcode Writer in Pure PostScript""",
	ext_modules = [postscriptbarcode_module],
	py_modules  = ["postscriptbarcode"],
)

