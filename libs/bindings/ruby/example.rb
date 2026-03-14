#!/usr/bin/env ruby
# frozen_string_literal: false

require "postscriptbarcode"

if ARGV.length > 0
  bwipp = Postscriptbarcode::BWIPP.new(ARGV[0])
  puts "Version: " + bwipp.get_version
else
  bwipp1 = Postscriptbarcode::BWIPP.new(File.dirname(__FILE__) + "/../../../build/monolithic_package/barcode.ps")
  bwipp = Postscriptbarcode::BWIPP.new(File.dirname(__FILE__) + "/../../../build/monolithic/barcode.ps")

  puts "Packaged version: " + bwipp1.get_version
  puts "Unpackaged version: " + bwipp.get_version

  puts "Packaged lines: " + bwipp1.emit_all_resources.lines.count.to_s
end

puts "Unpackaged lines: " + bwipp.emit_all_resources.lines.count.to_s

puts "qrcode resource lines: " + bwipp.emit_required_resources("qrcode").lines.count.to_s
puts "emit_exec lines: " + bwipp.emit_exec("qrcode", "Hello World", "eclevel=M").lines.count.to_s

encoders = bwipp.list_encoders
puts "Encoders: " + encoders.length.to_s

families = bwipp.list_families
puts "Families: " + families.length.to_s
families.each do |family|
  members = bwipp.list_family_members(family)
  puts "  #{family}: #{members.length} members"
end

props = bwipp.list_properties("qrcode")
puts "qrcode properties: " + props.length.to_s
props.each do |prop|
  puts "  #{prop}: #{bwipp.get_property("qrcode", prop)}"
end
