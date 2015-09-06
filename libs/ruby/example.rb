#!/usr/bin/env ruby

require './postscriptbarcode'

c=Postscriptbarcode::BWIPP.new("../barcode.ps")
c.get_version()

