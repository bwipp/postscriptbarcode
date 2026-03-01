# Security Policy

## Threat Model

BWIPP is a pure PostScript library that generates barcode graphics. It runs
entirely within the hosting PostScript interpreter (printer, RIP, Ghostscript,
Distiller, etc.) with the same privileges as that interpreter.

Users supply barcode data strings and options (as a string or dict) through the
documented encoder interface. These inputs are assumed to be correctly escaped
at the integration boundary (e.g. passed as hex-encoded strings); PostScript
injection via the host application's input handling is outside BWIPP's scope.

For some uses of BWIPP, the hosting interpreter may be long-running and shared
between unrelated users whose barcode data is private.

## What Is a Vulnerability

A vulnerability is a bug in which barcode data or options passed through the
documented encoder interface causes any of the following:

- **Arbitrary code execution** — input data or options are interpreted as
  executable PostScript.
- **Information disclosure** — barcode data or options from one invocation leak
  into a subsequent invocation (cross-user data exposure in a shared
  interpreter). This does not include derived state such as cached
  computational results that carry no user data.
- **Denial of service** — unbounded resource consumption (infinite loops,
  unbounded allocation), or algorithmic complexity that is disproportionate to
  input size (e.g. O(n²) processing of large input).
- **Interpreter state corruption** — State (e.g. graphics, static data) is
  corrupted in a way that persists beyond the current invocation, affecting
  subsequent barcode generation.

## What Is Not a Vulnerability

Most reported security bugs in BWIPP are "just bugs." The following are not
considered security vulnerabilities, and should be reported openly via the
[issue tracker](https://github.com/bwipp/postscriptbarcode/issues):

- **Incorrect barcode output** from valid input (a correctness bug).
- **PostScript errors** (e.g. `stackunderflow`, `rangecheck`) caused by
  malformed input data or options — the library validates input and raises
  descriptive errors; unhandled cases are ordinary bugs.
- **API misuse** — calling encoders with incorrect stack state, wrong argument
  types, or outside the documented calling convention.
- **Issues in debug/development features** that require `enabledebug` or
  `enabledontdraw` to be explicitly set in global context.
- **Interpreter bugs** — crashes or misbehaviour in the hosting interpreter
  triggered by valid PostScript operations (e.g. font loading side effects from
  user-specified `textfont`). These are the interpreter's responsibility.
- **Downstream scanning injection** — BWIPP faithfully encodes whatever data
  fits the symbology's character set. Sanitisation of scanned barcode message
  content is the responsibility of downstream systems.

## Supported Versions

All development is done against the current head of the master branch, with a
single train of releases being tagged from the master branch regularly and
often. Bugfixes are not backported to old versions.

## Reporting a Vulnerability

Even if an issue meets the above definition of a security vulnerability,
consider reporting it openly via the
[issue tracker](https://github.com/bwipp/postscriptbarcode/issues). For BWIPP,
transparency is more useful than embargo.

If you determine that the issue is so serious as to place users' systems at
grave risk then feel free to contact the maintainer directly. But it is
unlikely to result in coordinated disclosure: the ecosystem is too diverse,
with the code finding itself in many esoteric places.

## Known Security Issues

None at this time.
