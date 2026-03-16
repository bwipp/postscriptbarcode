import uk.co.terryburton.bwipp.BWIPP;
import uk.co.terryburton.bwipp.InitOpts;

public class Example {

    static {
        System.loadLibrary("postscriptbarcode_jni");
    }

    public static void main(final String[] args) {
        BWIPP bwipp;

        if (args.length > 0) {
            bwipp = new BWIPP(new InitOpts().filename(args[0]));
            if (bwipp.getVersion() == null) {
                    System.err.println("Failed to load resource");
                    System.exit(1);
            }
            System.out.println("Version: " + bwipp.getVersion());
        } else {
            BWIPP bwipp1 = new BWIPP(new InitOpts()
                .filename("../../../build/monolithic_package/barcode.ps"));

            if (bwipp1.getVersion() == null) {
                    System.err.println("Failed to load resource");
                    System.exit(1);
            }

            bwipp = new BWIPP(new InitOpts()
                .filename("../../../build/monolithic/barcode.ps"));

            if (bwipp.getVersion() == null) {
                    System.err.println("Failed to load resource");
                    System.exit(1);
            }

            System.out.println("Packaged version: " + bwipp1.getVersion());
            System.out.println("Unpackaged version: " + bwipp.getVersion());

            String ps = bwipp1.emitAllResources();
            System.out.println("Packaged lines: "
                + ps.chars().filter(c -> c == '\n').count());
        }

        String ps = bwipp.emitAllResources();
        System.out.println("Unpackaged lines: "
            + ps.chars().filter(c -> c == '\n').count());

        ps = bwipp.emitRequiredResources("qrcode");
        System.out.println("qrcode resource lines: "
            + ps.chars().filter(c -> c == '\n').count());

        ps = bwipp.emitExec("qrcode", "Hello World", "eclevel=M");
        System.out.println("emit_exec lines: "
            + ps.chars().filter(c -> c == '\n').count());

        String[] encoders = bwipp.listEncoders();
        System.out.println("Encoders: " + encoders.length);

        String[] families = bwipp.listFamilies();
        System.out.println("Families: " + families.length);
        for (String family : families) {
            String[] members = bwipp.listFamilyMembers(family);
            System.out.println("  " + family + ": "
                + members.length + " members");
        }

        String[] props = bwipp.listProperties("qrcode");
        System.out.println("qrcode properties: " + props.length);
        for (String prop : props) {
            System.out.println("  " + prop + ": "
                + bwipp.getProperty("qrcode", prop));
        }

        java.util.Map<String, String> propMap = bwipp.getProperties("qrcode");
        System.out.println("qrcode property pairs: " + propMap.size());
        for (java.util.Map.Entry<String, String> e : propMap.entrySet()) {
            System.out.println("  " + e.getKey() + ": " + e.getValue());
        }

        System.out.println("Hex string: " + bwipp.emitPshexstr("Hello"));

        String tmpl = bwipp.emitTemplate(
            "%dat %opt %enc /uk.co.terryburton.bwipp findresource exec",
            "qrcode", "Hello World", "eclevel=M");
        System.out.println("Template lines: "
            + tmpl.chars().filter(c -> c == '\n').count());

    }

}
