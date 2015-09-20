BWIPP Helper C Library and Bindings
===================================

The purpose of the C library and SWIG-based bindings for other languages is to
provide helper functions for manipulating the Barcode Writer in Pure PostScript
resources based on metadata contained within the monolithic barcode.ps file.

It is hoped that these can provide a stable and robust interface to BWIPP that
avoids the need for frontends to parse and process the PostScript resource file
directly or embed lots of static data about the resources in their code.

**PACKAGERS** The interfaces are currently incomplete so please do not package
the C library or bindings just yet. I'll create Debian and RedHat packaging
when I think it's ready. Thanks!


How to build and use the various bindings
-----------------------------------------

Build and install the C library first:

```
cd c
make
make install  # (Optionally)
```

The build the relevant bindings:

```
cd bindings
make
make install

Or selectively:

make LANGS="java perl python ruby"
make install LANGS="java perl python ruby"
```

How to check these are working without installing:

```
cd python
LD_LIBRARY_PATH=. ./example.py
```

```
cd perl
LD_LIBRARY_PATH=blib/arch/auto/postscriptbarcode ./example.pl
```

```

./example.rb
```

```
cd java
javac example.java
java -cp . -Djava.library.path=. example
```

