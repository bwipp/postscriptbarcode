#!/usr/bin/env python3

"""
setup.py file for postscriptbarcode
"""

from setuptools import Command, Extension, setup

with open("../../../CHANGES", "r") as f:
    ver = f.readline().strip().replace("-", "")


class Test(Command):
    user_options = []

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        import subprocess
        import sys

        errno = subprocess.call([sys.executable, "example.py"])
        raise SystemExit(errno)


postscriptbarcode_module = Extension(
    "_postscriptbarcode",
    sources=["postscriptbarcode.i"],
    include_dirs=["../../c"],
    libraries=["postscriptbarcode"],
    library_dirs=["../../c"],
)

setup(
    name="postscriptbarcode",
    version=ver,
    author="Terry Burton",
    author_email="tez@terryburton.co.uk",
    description="""Python binding for Barcode Writer in Pure PostScript""",
    url="https://bwipp.terryburton.co.uk",
    ext_modules=[postscriptbarcode_module],
    py_modules=["postscriptbarcode"],
    cmdclass={"test": Test},
)
