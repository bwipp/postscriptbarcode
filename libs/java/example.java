public class example {
  static {
    System.loadLibrary("postscriptbarcode");
  }

  public static void main(String args[]) {
	BWIPP c = new BWIPP("../../build/monolithic_package/barcode.ps");
	System.out.println(c.emit_all_resources());
  }

}
