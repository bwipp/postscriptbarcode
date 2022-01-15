import uk.co.terryburton.bwipp.*;

public class Example {
  static {
    System.loadLibrary("postscriptbarcode");
  }

  public static void main(String args[]) {
	BWIPP bwipp1 = new BWIPP("../../../build/monolithic_package/barcode.ps");
	if (bwipp1.get_version() == null) {
		System.err.println("Failed to load resource");
		System.exit(1);
	}
	BWIPP bwipp2 = new BWIPP("../../../build/monolithic/barcode.ps");
	if (bwipp2.get_version() == null) {
		System.err.println("Failed to load resource");
		System.exit(1);
	}
	System.out.println("Packaged version: "+bwipp1.get_version());
	System.out.println("Unpackaged version: "+bwipp2.get_version());
	String ps=bwipp1.emit_all_resources();
	System.out.println("Packaged lines: "+ps.split("\r\n|\r|\n").length);
	ps=bwipp2.emit_all_resources();
	System.out.println("Unpackaged lines: "+ps.split("\r\n|\r|\n").length);
  }

}
