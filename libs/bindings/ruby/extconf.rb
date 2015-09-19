require 'mkmf'
find_library('postscriptbarcode',nil,'../../c')
find_header('postscriptbarcode.h',nil,'../../c')
create_makefile('postscriptbarcode')
