#!/usr/bin/env python

"""Example user of the BWIPP Python binding."""

import postscriptbarcode

bwipp1 = postscriptbarcode.BWIPP("../../../build/monolithic_package/barcode.ps")
bwipp2 = postscriptbarcode.BWIPP("../../../build/monolithic/barcode.ps")
print("Packaged version: " + bwipp1.get_version())
print("Unpackaged version: " + bwipp2.get_version())

ps = bwipp1.emit_all_resources()
print("Packaged lines: " + str(len(ps.split("\n"))))
ps = bwipp2.emit_all_resources()
print("Unpackaged lines: " + str(len(ps.split("\n"))))

ps = bwipp2.emit_required_resources("qrcode")
print("qrcode resource lines: " + str(len(ps.split("\n"))))

ps = bwipp2.emit_exec("qrcode", "Hello World", "eclevel=M")
print("emit_exec lines: " + str(len(ps.split("\n"))))

encoders = bwipp2.list_encoders()
print("Encoders: " + str(len(encoders)))

families = bwipp2.list_families()
print("Families: " + str(len(families)))
for family in families:
    members = bwipp2.list_family_members(family)
    print("  " + family + ": " + str(len(members)) + " members")

props = bwipp2.list_properties("qrcode")
print("qrcode properties: " + str(props))
for prop in props:
    print("  " + prop + ": " + bwipp2.get_property("qrcode", prop))
