Named Resource Flavours
=======================

The contents of the `Resource` directory provides Barcode Writer in Pure PostScript as generic PostScript Level 2 named resources split into separate files structured for ease of deployment.

This standard delivery mechanism allows BWIPP resources to be added to a PostScript virtual machine's resource search path, or pre-downloaded to a printer's memory or permanent storage, or supplied by a document manager, all without any change in the code an application generates to use the resources.

Prepared tarballs of BWIPP packaged into the named resource flavours are available from https://github.com/bwipp/postscriptbarcode/releases/latest with filenames such as `postscriptbarcode-resource` and `postscriptbarcode-packaged-resource`. Alternatively you can build these flavours from source with `make resource` or `make packaged_resource`.


Deploying the Named Resource
----------------------------

An application or administrator must first make the BWIPP resources available to the print system as described for a variety of situations below. An application will then generate code like the following.

In the file's `Setup` or `PageSetup` section:

    /qrcode dup /uk.co.terryburton.bwipp findresource def

and in the page description where a barcode is needed:

    0 0 moveto (BWIPP) (eclevel=M) qrcode

If the application needs to import the resource under a different name to avoid a conflict, then the setup could be:

    /foo /qrcode /uk.co.terryburton.bwipp findresource def

followed by:

    0 0 moveto (BWIPP1) (eclevel=M) foo
    0 0 moveto (BWIPP2) (eclevel=M) foo
    ...

(The above is analogous to `from uk.co.terryburton.bwipp import qrcode as foo` in other languages.)

Or, to generate a few barcodes with no setup section or local name at all:

    0 0 moveto (BWIPP) (eclevel=M) /qrcode /uk.co.terryburton.bwipp findresource exec

This technique also reduces the possibility of namespace collision when using the library's procedures with other code.

If the definitions for the routines that generate and render the barcode are not already resident in memory then they will be fetched from a standard resource location in a way that is transparent to the user.


### GhostScript

Unpack the contents of the Resource directory to somewhere accessible to the application.

Specify the location of the Resource files using the `-I` or `-sGenericResourceDir` parameters. Where the resource search path defaults to `./Resource` (or equivalent) you can omit this parameter when running GhostScript from the location of the Resource files.

Example for Windows users:

    gswin64c.exe -dSAFER -I%rom%Resource/;C:/bwipp/Resource/ "C:/create-barcode.ps"


### Adobe Distiller

Unpack the contents of the Resource directory to somewhere accessible to the application. Ensure that `PSRESOURCEPATH` contains the directory containing the `.upr` file when Distiller is run. The contents should be a list of directories separated by colons, to be searched in order with two consecutive colons to indicate where the default location should fall within the search order.


### Printer Hard Disk

If a printer with a hard disk option is used, the resources can be downloaded once and remain available across power cycles. Resources can be downloaded with a vendor-specific tool, or by sending them to the printer with a snippet of PostScript at the top that queries the printer for the correct file name and creates the file.


### PostScript Document Manager

Unpack the contents of the Resource directory to somewhere accessible to your document manager software then include the `%%DocumentNeededResources` and `%%IncludeResource` DSC comments at the appropriate locations within your PostScript output. The document manager software can be configured to transparently insert the requested resources as necessary.

Any specific instructions for common document manager software are welcome.

