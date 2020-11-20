#!/usr/bin/env python

"""
setup.py file for postscriptbarcode
"""

from distutils.command.build import build
from distutils.core import Command, Extension, setup

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

build.sub_commands = [
    ("build_ext", build.has_ext_modules),
    ("build_py", build.has_pure_modules),
    ("build_clib", build.has_c_libraries),
    ("build_scripts", build.has_scripts),
]

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
