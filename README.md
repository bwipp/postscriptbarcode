Barcode Writer in Pure PostScript
=================================

  * Homepage: https://www.terryburton.co.uk/barcodewriter/
  * Documentation: https://code.google.com/p/postscriptbarcode/wiki/Symbologies
  * Download: https://github.com/bwipp/postscriptbarcode/releases
  * Source: https://github.com/bwipp/postscriptbarcode.git
  * Issue tracker: https://github.com/bwipp/postscriptbarcode/issues
  * Mailing list: http://groups.google.co.uk/group/postscriptbarcode

About BWIPP
-----------

Barcode Writer in Pure Postscript generates all barcode formats entirely within
PostScript so that the process of converting the input data into the printed
output can be performed by the printer or RIP itself. This is ideal for
variable data printing (VDP) and avoids the need to re-implement the barcode
generation process whenever your language needs change.

Since this resource is written in PostScript and interpretted within the
virtual machine of a printer it is compatible with any operating system and
hardware platform.

It makes including any barcode within a PostScript document as simple as
inserting the following directive:

    0 0 moveto (978-1-56581-231-4) (includetext) /isbn /uk.co.terryburton.bwipp findresource exec

There is a web-based demonstration of the project here:

http://www.terryburton.co.uk/barcodewriter/generator/


The Resources
-------------

BWIPP is essentially a set of generic PostScript Level 2 named resources that
are provided in four flavours for ease of use. The one to use depends on how
you intend to deploy the library.

  * "Packaged" or "unpackaged": The named resources have been packaged for DSC
conformance, portability and ease of distribution. You will most likely want to
use a packaged flavour in production, however the unpackaged versions of the
resources are useful for understanding the code, developing the library and
debugging.

  * "Separate files" or "monolithic": The resource is provided as separate files
that are formatted for direct use by Adobe Distiller, GhostScript, a printer
hard disk or a document manager. The monolithic flavours contain all of the
resources in a single file that is suitable for inclusion in the Prolog section
of a PostScript document template or installing to a printer's initial job VM.

This leads to the following set of four files.

For production use:

  * postscriptbarcode-packaged-resource – Packaged; Separate files.
  * postscriptbarcode-monolithic-package – Packaged; Monolithic file. 

For BWIPP development:

  * postscriptbarcode-resource – Unpackaged; Seperate files.
  * postscriptbarcode-monolithic – Unpackaged; Monolithic file.


Downloading
-----------

You can download the prepared packages and the sources from here:

https://github.com/bwipp/postscriptbarcode/releases

Alternatively you can clone the repository: 

    git clone https://github.com/bwipp/postscriptbarcode.git

If you are using Ubuntu you can download the daily build of the trunk of BWIPP
from PPA:

    sudo add-apt-repository ppa:postscriptbarcode-maintainers/ppa
    sudo apt-get update
    sudo apt-get install libpostscriptbarcode


Building
--------

The build requirements are Perl, GNU Make and GhostScript.

Just run make from the root of the source distribution. The flavours are built
into subdirectories of the `build/` directory.
