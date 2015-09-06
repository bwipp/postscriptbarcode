#!/usr/bin/env ruby

require './postscriptbarcode'

c=Postscriptbarcode::BWIPP.new("../../build/monolithic_package/barcode.ps")
c.get_version()

