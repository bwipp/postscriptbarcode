import uk.co.terryburton.bwipp.BWIPP;

public class Example {

    static {
        System.loadLibrary("postscriptbarcode");
    }

    public static void main(final String[] args) {
        BWIPP bwipp1 =
            new BWIPP("../../../build/monolithic_package/barcode.ps");

        if (bwipp1.getVersion() == null) {
                System.err.println("Failed to load resource");
                System.exit(1);
        }

        BWIPP bwipp2 =
            new BWIPP("../../../build/monolithic/barcode.ps");

        if (bwipp2.getVersion() == null) {
                System.err.println("Failed to load resource");
                System.exit(1);
        }

        System.out.println("Packaged version: " + bwipp1.getVersion());
        System.out.println("Unpackaged version: " + bwipp2.getVersion());

        String ps = bwipp1.emitAllResources();
        System.out.println("Packaged lines: "
            + ps.split("\r\n|\r|\n").length);

        ps = bwipp2.emitAllResources();
        System.out.println("Unpackaged lines: "
            + ps.split("\r\n|\r|\n").length);

        ps = bwipp2.emitRequiredResources("qrcode");
        System.out.println("qrcode resource lines: "
            + ps.split("\r\n|\r|\n").length);

        ps = bwipp2.emitExec("qrcode", "Hello World", "eclevel=M");
        System.out.println("emit_exec lines: "
            + ps.split("\r\n|\r|\n").length);

        String[] encoders = bwipp2.listEncoders();
        System.out.println("Encoders: " + encoders.length);

        String[] families = bwipp2.listFamilies();
        System.out.println("Families: " + families.length);
        for (String family : families) {
            String[] members = bwipp2.listFamilyMembers(family);
            System.out.println("  " + family + ": "
                + members.length + " members");
        }

        String[] props = bwipp2.listProperties("qrcode");
        System.out.println("qrcode properties: " + props.length);
        for (String prop : props) {
            System.out.println("  " + prop + ": "
                + bwipp2.getProperty("qrcode", prop));
        }

    }

}
