#!/usr/bin/env ruby

require 'postscriptbarcode'

bwipp1=Postscriptbarcode::BWIPP.new(File.dirname(__FILE__)+"/../../../build/monolithic_package/barcode.ps")
bwipp2=Postscriptbarcode::BWIPP.new(File.dirname(__FILE__)+"/../../../build/monolithic/barcode.ps")

puts "Packaged version: " + bwipp1.get_version()
puts "Unpackaged version: " + bwipp2.get_version()

puts "Packaged lines: " + bwipp1.emit_all_resources().lines.count.to_s
puts "Unpackaged lines: " + bwipp2.emit_all_resources().lines.count.to_s

