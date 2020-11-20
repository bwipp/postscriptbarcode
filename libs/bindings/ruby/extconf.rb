# frozen_string_literal: false

require "mkmf"
$LIBS << " -L ../../c -lpostscriptbarcode"
$CFLAGS << " -I../../c -fPIC"

swig = find_executable "swig"
if swig
  $stdout.write "Using '#{swig}' to generate wrapper code... "
  %x{#{swig} -Wall -ruby -o postscriptbarcode_wrap.c -outdir . ../postscriptbarcode.i }
  $stdout.write "done\n"
  $distcleanfiles += ["postscriptbarcode_wrap.c"]
else
  $stderr.write "You need SWIG to compile this extension.\n"
  exit 1
end

create_makefile("postscriptbarcode")
