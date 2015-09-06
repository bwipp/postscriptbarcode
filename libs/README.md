How to build and use the various bindings
=========================================

*** Python ***

```
cd python
swig -Wall -python postscriptbarcode.i
python setup.py build_ext --inplace
LD_LIBRARY_PATH=. ./example.py
```


*** Perl ***

```
cd perl
swig -Wall -perl postscriptbarcode.i
./Makefile.PL
make
LD_LIBRARY_PATH=blib/arch/auto/postscriptbarcode ./example.pl
```


*** Ruby ***

```
cd ruby
swig -Wall -ruby postscriptbarcode.i
ruby extconf.rb
make
./example.rb
```


*** Java ***

```
cd java
swig -Wall -java postscriptbarcode.i
gcc -fPIC -Wall -Wextra -shared postscriptbarcode.c postscriptbarcode_wrap.c -o libpostscriptbarcode.so -L../c -lpostscriptbarcode -I/usr/lib/jvm/java-8-oracle/include -I/usr/lib/jvm/java-8-oracle/include/linux
LD_LIBRARY_PATH=. java example
```


