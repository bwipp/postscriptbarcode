BWIPP Helper C Library and Bindings
===================================

The purpose of the C library and SWIG-based bindings for other languages is to
provide helper functions for manipulating the Barcode Writer in Pure PostScript
resources based on metadata contained within the monolithic barcode.ps file.

It is hoped that these can provide a stable and robust interface to BWIPP that
avoids the need for frontends to parse and process the PostScript resource file
directly or embed lots of static data about the resources in their code.


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
make LANGS="java perl python ruby"
make install LANGS="java perl python ruby"
```

How to check these are working without installing:

```
cd python
LD_LIBRARY_PATH=../../c PYTHONPATH=build/lib.*/_postscriptbarcode.so python example.py
```

```
cd perl
LD_LIBRARY_PATH=../../c perl -I blib/arch/auto/postscriptbarcode -I blib/lib example.pl
```

```

LD_LIBRARY_PATH=../../c ruby -I . example.rb
```

```
cd java
javac -cp .:libpostscriptbarcode.jar example.java
LD_LIBRARY_PATH=../../c java -cp .:libpostscriptbarcode.jar -Djava.library.path=. example
```

