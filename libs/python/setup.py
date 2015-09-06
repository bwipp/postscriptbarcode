#!/usr/bin/env python

"""
setup.py file for postscriptbarcode
"""

from distutils.core import setup, Extension

postscriptbarcode_module = Extension(
	'_postscriptbarcode',
	sources=['postscriptbarcode_wrap.c', 'postscriptbarcode.c'],
)

setup(name = 'postscriptbarcode',
	version = '0.1',
	author      = "Terry Burton",
	description = """Python binding for Barcode Writer in Pure PostScript""",
	ext_modules = [postscriptbarcode_module],
	py_modules = ["postscriptbarcode"],
)

