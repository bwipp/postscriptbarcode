# Security Policy

## Threat Model

BWIPP is a pure PostScript library that generates barcode graphics. It:

- Runs entirely within the hosting PostScript interpreter (printer, RIP,
  Ghostscript, Distiller, etc.) with the same privileges as that interpreter.
- Does not access the network, filesystem, or any external resources beyond
  what the interpreter itself provides.
- Processes user-supplied barcode data strings and options to produce graphical
  output. None of this data is executable code.

An attacker who can supply arbitrary PostScript to an interpreter already has
full access to that interpreter's capabilities. BWIPP does not extend the
interpreter's attack surface.

## What Is a Vulnerability

A vulnerability is a bug in which barcode data or options — passed through the
documented encoder interface — causes the PostScript interpreter to behave in a
way that compromises the security of the hosting system, such as:

- **Unbounded resource consumption** without any implementation limit being
  reached.
- **Interpreter crashes** from data that exceeds reasonable PostScript
  implementation limits (string length, dictionary size, stack depth).
- **Attempted access to system data** such as arbitrary file access or reading
  process memory.

## What Is Not a Vulnerability

Most reported security bugs in BWIPP are "just bugs." The following are not
considered security vulnerabilities, and should be reported openly via the
[issue tracker](https://github.com/bwipp/postscriptbarcode/issues):

- **Incorrect barcode output** from valid input (a correctness bug).
- **PostScript errors** (e.g. `stackunderflow`, `rangecheck`) caused by
  malformed input data or options — the library validates input and raises
  descriptive errors; unhandled cases are ordinary bugs (that should be
  reported as such).
- **API misuse** — calling encoders with incorrect stack state, wrong argument
  types, or outside the documented calling convention.
- **Issues in debug/development features** that require `enabledebug` or
  `enabledontdraw` to be explicitly set in global context.

## Supported Versions

All development is done against the current head of the master branch,
with a single train of releases being tagged from the master branch
regularly and often. Bugfixes are not backported to old versions.

## Reporting a Vulnerability

If an issue meets the above definition of a security vulnerability, consider
reporting it openly via the
[issue tracker](https://github.com/bwipp/postscriptbarcode/issues). For BWIPP,
transparency is more useful than embargo.

If you determine that the issue is so serious as to place users' systems at
grave risk then feel free to contact the maintainer directly. But it is
unlikely to result in coordinated disclosure: the ecosystem is too diverse,
with the code finding itself in many esoteric places.

## Known Security Issues

None.
