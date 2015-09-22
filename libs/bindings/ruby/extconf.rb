require 'mkmf'
$LIBS << " -L ../../c -lpostscriptbarcode"
$CFLAGS << " -I../../c -fPIC"
create_makefile('postscriptbarcode')
