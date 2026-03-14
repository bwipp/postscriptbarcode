#!/bin/bash

# Test Java binding against installed packages

BARCODE_PS="${1:-/usr/share/postscriptbarcode/barcode.ps}"

JAR=""
for candidate in \
	/usr/share/java/libpostscriptbarcode.jar \
	/usr/share/java/postscriptbarcode.jar; do
	if [ -f "$candidate" ]; then
		JAR="$candidate"
		break
	fi
done

if [ -z "$JAR" ]; then
	echo "SKIP: java (libpostscriptbarcode.jar not found)"
	exit 0
fi

if command -v jshell >/dev/null 2>&1; then
	if ! OUTPUT=$(jshell --class-path "$JAR" <(
		cat <<EOF
import uk.co.terryburton.bwipp.BWIPP;
BWIPP bwipp = new BWIPP("$BARCODE_PS");
String ver = bwipp.getVersion();
if (ver == null) {
    System.err.println("Failed to load resource");
    System.exit(1);
}
System.out.println("Version: " + ver);
String[] encoders = bwipp.listEncoders();
System.out.println("Encoders: " + encoders.length);
/exit
EOF
	) 2>&1); then
		echo "FAIL: java"
		echo "$OUTPUT"
		exit 1
	fi
elif command -v java >/dev/null 2>&1; then
	# No jshell; verify the JNI library loads
	OUTPUT=$(java -cp "$JAR" uk.co.terryburton.bwipp.BWIPP 2>&1 || true)
	if echo "$OUTPUT" | grep -q "Main method not found"; then
		true # Class loaded successfully (no main method is expected)
	else
		echo "FAIL: java"
		echo "$OUTPUT"
		exit 1
	fi
else
	echo "SKIP: java (java not installed)"
	exit 0
fi

echo "PASS: java"
exit 0
