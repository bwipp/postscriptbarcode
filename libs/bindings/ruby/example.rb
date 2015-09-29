#!/usr/bin/env ruby

require 'postscriptbarcode'

c=Postscriptbarcode::BWIPP.new(File.dirname(__FILE__)+"/../../../build/monolithic_package/barcode.ps")
print "Version: " + c.get_version() + "\n"
print c.emit_all_resources()

