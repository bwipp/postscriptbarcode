#!/usr/bin/env ruby
# frozen_string_literal: false

require "postscriptbarcode"

bwipp1 = Postscriptbarcode::BWIPP.new(File.dirname(__FILE__) + "/../../../build/monolithic_package/barcode.ps")
bwipp2 = Postscriptbarcode::BWIPP.new(File.dirname(__FILE__) + "/../../../build/monolithic/barcode.ps")

puts "Packaged version: " + bwipp1.get_version
puts "Unpackaged version: " + bwipp2.get_version

puts "Packaged lines: " + bwipp1.emit_all_resources.lines.count.to_s
puts "Unpackaged lines: " + bwipp2.emit_all_resources.lines.count.to_s

puts "qrcode resource lines: " + bwipp2.emit_required_resources("qrcode").lines.count.to_s
puts "emit_exec lines: " + bwipp2.emit_exec("qrcode", "Hello World", "eclevel=M").lines.count.to_s

encoders = bwipp2.list_encoders
puts "Encoders: " + encoders.length.to_s

families = bwipp2.list_families
puts "Families: " + families.length.to_s
families.each do |family|
  members = bwipp2.list_family_members(family)
  puts "  #{family}: #{members.length} members"
end

props = bwipp2.list_properties("qrcode")
puts "qrcode properties: " + props.length.to_s
props.each do |prop|
  puts "  #{prop}: #{bwipp2.get_property("qrcode", prop)}"
end
