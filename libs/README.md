BWIPP Helper C Library and Bindings
===================================

The purpose of the C library and SWIG-based bindings for other languages is to
provide helper functions for manipulating the Barcode Writer in Pure PostScript
resources based on metadata contained within the monolithic barcode.ps file.

It is hoped that these can provide a stable and robust interface to BWIPP that
avoids the need for frontends to parse and process the PostScript resource file
directly or embed lots of static data about the resources in their code.


Building
--------

Build and install the C library first:

    cd c
    make
    make test
    make install  # Optional

Build and install the relevant bindings:

    cd bindings
    export LANGS="java perl python ruby"  # Optionally select specific bindings
    make
    make test
    make install  # Optional

