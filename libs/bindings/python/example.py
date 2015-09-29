#!/usr/bin/env python

import postscriptbarcode

bwipp1=postscriptbarcode.BWIPP("../../../build/monolithic_package/barcode.ps")
bwipp2=postscriptbarcode.BWIPP("../../../build/monolithic/barcode.ps")
print("Packaged version: " + bwipp1.get_version())
print("Unpackaged version: " + bwipp2.get_version())

ps=bwipp1.emit_all_resources()
print("Packaged lines: " + str(len(ps.split('\n'))))
ps=bwipp2.emit_all_resources()
print("Unpackaged lines: " + str(len(ps.split('\n'))))

