#!/usr/bin/env python

"""Example user of the BWIPP Python binding."""

import sys

import postscriptbarcode

if len(sys.argv) > 1:
    bwipp = postscriptbarcode.BWIPP(filename=sys.argv[1])
    print("Version: " + bwipp.get_version())
else:
    bwipp1 = postscriptbarcode.BWIPP(
        filename="../../../build/monolithic_package/barcode.ps"
    )
    bwipp2 = postscriptbarcode.BWIPP(filename="../../../build/monolithic/barcode.ps")

    print("Packaged version: " + bwipp1.get_version())
    print("Unpackaged version: " + bwipp2.get_version())
    bwipp = bwipp2

    ps = bwipp1.emit_all_resources()
    print("Packaged lines: " + str(ps.count("\n")))

ps = bwipp.emit_all_resources()
print("Unpackaged lines: " + str(ps.count("\n")))

ps = bwipp.emit_required_resources("qrcode")
print("qrcode resource lines: " + str(ps.count("\n")))

ps = bwipp.emit_exec("qrcode", "Hello World", "eclevel=M")
print("emit_exec lines: " + str(ps.count("\n")))

encoders = bwipp.list_encoders()
print("Encoders: " + str(len(encoders)))

families = bwipp.list_families()
print("Families: " + str(len(families)))
for family in families:
    members = bwipp.list_family_members(family)
    print("  " + family + ": " + str(len(members)) + " members")

props = bwipp.list_properties("qrcode")
print("qrcode properties: " + str(props))
for prop in props:
    print("  " + prop + ": " + bwipp.get_property("qrcode", prop))

prop_dict = bwipp.get_properties("qrcode")
print("qrcode property pairs: " + str(len(prop_dict)))
for key, val in prop_dict.items():
    print("  " + key + ": " + val)

print("Hex string: " + bwipp.emit_pshexstr("Hello"))

tmpl = bwipp.emit_template(
    "%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
    "qrcode",
    "Hello World",
    "eclevel=M",
)
print("Template lines: " + str(tmpl.count("\n")))
