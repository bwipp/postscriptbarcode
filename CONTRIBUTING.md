# Barcode Writer in Pure PostScript (Contributing)

This document is authoritative for both human contributors and automated tools.

All constraints are intentional and reflect hard-won experience with PostScript
performance, RIP compatibility, and maintenance risk.


## Background

PostScript library generating 100+ barcode formats entirely within PostScript, executed by printer/RIP.

Performance, execution cost, and interpreter compatibility are critical.


## Contribution Rules and Constraints

These must be followed, otherwise you must be prepared to defend your choices:

- Create atomic, logical commits that complete one task.
- If a file is updated then its copyright date should be bumped. Ensure that the current year is used.
- Create an entry in CHANGES for each user-visible change. If the current change block has been published, create a new block dated "XXXX-XX-XX". Observe the layout and style of pre-existing contents.
- Unless the changes are tiny and consistent, there should be one commit per updated resource.
- Use sparse comments explaining "why" not "how".
- Ensure that code comments describe only the current code and do not reference changes made with respect to old code - that's what commit descriptions are for.
- New code should match existing idioms. Complex encoders such as QR Code are the best source of idiomatic code.
- Maintain existing user API (encoder interfaces and metadata).
- Prefer derived values over opaque constants so that the code is auditable, unless prohibitively expensive (even for lazy init).
- Static data should be hoisted out of the main procedure, and deferred with lazy initialisation if it must be derived
- Static and cached structures should be `readonly` by the time they are used in the main procedure
- Prefer stack work over dictionary heavy code, especially in hot loops.
- Do not replace stack-based logic with dictionary-heavy abstractions.
- Do not refactor for readability at the expense of execution cost.
- Do not assume GhostScript-only execution. Assume modern implementation limit, and warn when approaching those limits:
  - Integer representation may be 32- or 64-bit. Do not assume overflow or promotion at 32-bit. Encoders that require 64-bit integers should detect this and exit gracefully.
  - Maximum of 65535 entries within dictionaries, arrays, and on the stack. (Assume user might already have entries on the stack.)
  - Maximum string length of 65535 characters. Maximum name length of 127 characters.
  - Where an allocation could exceed these limits, wrap it with a `stopped` guard (see Implementation Limit Guards below).
- Integer literals in source code must not exceed the signed 32-bit range (−2147483648 to 2147483647). The packager encodes integers as 32-bit binary tokens; larger values are silently corrupted. Compute large values at define time from small operands and reference via `//name` (see Packager Integer Limitation below).
- Tests should be extended to cover any error conditions raised by new code.


## Additional AI rules

- Do not push commits or rewrite history.
- Always search for and follow pre-existing patterns before writing code. Warn if the existing pattern does not appear to follow best practise.
- Warn about potential issues such as potential performance regressions in hot paths.
- Warn about potentially incorrect code when introducing new idioms involving stack-based constructions.
- Don't ever `git reset` to try to rewrite history when there is a risk of losing recent work.
- Backup work before running irreversible commands such as `sed` against a large number of files.
- Plan complex tasks. Interview the user regarding significant design choices.
- To analyse barcode image output, generate a PNM image (that can be directly interpreted) using `contrib/development/make_image.sh pnm <encoder> <data> [options] > output.pnm`. Requires `build/monolithic/barcode.ps` (i.e. run `make` first).


## AI Observations

- AI is not very good at writing and reasoning about stack-based code.
- AI seems unable to accurately track the position of items on the stack, resulting in spurious inputs to `index` and `roll`.
- AI does not consider the side effect of inserting new code into existing stack based code, e.g. later indexes needing to be recalculated.
- AI benefits from being shown a preferred pattern then applying it.


## Build

### Commands

- `make -j $(nproc)`                           - Build all distribution targets (resource, packaged_resource, monolithic, monolithic_package)
- `make -j $(nproc) test`                      - Run all tests; should be ran before declaring a code change complete
- `make clean`                                 - Clean
- `make build/standalone/<encoder>.ps`         - Build standalone encoder
- `make build/standalone_package/<encoder>.ps` - Build packaged standalone encoder
- `make syncsyntaxdict`                        - Sync gs1process.ps.src with latest upstream GS1 Syntax Dictionary
- `make -C wikidocs -f __pandoc/Makefile pst-barcode-docs` - Generate pst-barcode-doc.tex for pst-barcode LaTeX package

Note: On MacOS it's `sysctl -n hw.ncpu` instead of `$(nproc)`.

Build requires Ghostscript (`gs`) in `PATH` and Perl.

Quick iteration when developing a resource (with custom invocation):

```bash
make build/resource/Resource/uk.co.terryburton.bwipp/qrcode && \
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
  -c '10 10 moveto (Hello World) () /qrcode /uk.co.terryburton.bwipp findresource exec'
```

Or (with a debug option):

```bash
make build/resource/Resource/uk.co.terryburton.bwipp/qrcode && \
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
  -c '/uk.co.terryburton.bwipp.global_ctx << /enabledebug true >> def' \
  -c '10 10 moveto (Hello World) (debugcws) /qrcode /uk.co.terryburton.bwipp findresource exec'
```

Or (with standard tests):

```bash
make build/resource/Resource/uk.co.terryburton.bwipp/qrcode && \
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
        -f tests/ps_tests/test_utils.ps -f tests/ps_tests/qrcode.ps.test
```

### Terminology

"Packaging" refers to PostScript resources processed (by the build system's
"packager") into a form easier to distribute but is harder to debug:

- Efficient byte-based encodings for numbers and operators
- Compressed numeric/string arrays
- ASCII85-wrapped output (watermarked)
- Results in ~30-50% smaller files

**Packager Integer Limitation:** The packager encodes integers as signed 32-bit
binary tokens. Literals outside that range are silently corrupted. Compute
large values at define time from small operands and reference via `//name`.

"Global context" is an optional dictionary configured in **global VM**
containing optional keys that affect the behaviour of BWIPP:

- `preload`        - Perform eager initialisation of normally lazy variables during resource definition
- `enabledebug`    - Allow the user to set debug options (e.g. `debugcws`), for development purposes including activation of hooks
- `enabledontdraw` - Allow the user to set dontdraw, in case they are providing custom renderers
- `hooks`          - Dictionary of hook procedures for debugging purposes, including profiling
- `default_*`      - Defaults for certain renderer options set by the user, e.g. `default_barcolor`
- `loosespec`        - Enable best-fit specification mode globally (implies `strictspec`, lenient)
- `strictspec`       - Enable strict physical specification mode globally
- `propspec`       - Enable proportional specification mode globally (linear only)

For example:

```postscript
currentglobal
true setglobal
/uk.co.terryburton.bwipp.global_ctx << /preload true >> def
setglobal
```

### Directory Structure

Core library:

- `src/*.ps.src`                          - PostScript resource source files
- `src/uk.co.terryburton.bwipp.upr`       – PostScript resource index mapping resource names to file paths; required by Distiller and used by the build system to enforce resource order in monolithic and standalone outputs
- `tests/ps_tests/*.ps.test`              - PostScript test files

Build scripts:

- `build/make_resource.pl`                - Resource builder (invokes GhostScript)
- `build/make_deps.pl`                    - Dependency rule generator (creates .d files)
- `build/make_monolithic.pl`              - Monolithic resource assembler
- `build/make_standalone.pl`              - Standalone file assembler (supports multiple encoders)

Automatic build outputs:

- `build/resource/`                       - `make resource`: Unpackaged resources
- `build/packaged_resource/`              - `make packaged_resource`: Packaged resources
- `build/monolithic/barcode.ps`           - `make monolithic`: All encoders combined
- `build/monolithic_package/barcode.ps`   - `make monolithic_package`: Packaged monolithic

On-demand build outputs:

- `build/standalone/<encoder>.ps`         - Standalone encoder containing all required resource dependencies
- `build/standalone_package/<encoder>.ps` - As above, but packaged


## Code structure

### Resource Source File Structure

Each resource source file has a similar structure:

1. **Header comments**
   - Project name and URL
   - VIM modeline
   - Copyright notice (year should be maintained)
   - License text

2. **Metadata comments**
   - Declares dependencies between resources (for assembling monolithic resources)
   - For encoders, gives example data (see Encoder Metadata below)

3. **Allocation mode setup**
   - Object storage placed in global VM
   - Executable arrays packed for efficiency

4. **Dependent resource loading**
   - Uses `findresource` to load dependencies into working dictionary

5. **Hooks setup**
   - Call `setuphooks` to create encoder-specific or generic hook procedures
   - Enables profiling and debugging via global context hooks

6. **Static data structures**
   - Plain definitions of literal structured data (arrays and dicts)
   - Runs once during resource definition, with values immediately referenced by main procedure; allocate once during initialisation, then reuse at runtime
   - Names MUST be prefixed with the resource name (e.g., `encoder.charmap`) - the Makefile extracts all `//name` references to populate the packager's atload template, requiring globally unique names
   - `//name` immediate references are resolved at parse time, embedding the value directly into procedures
   - Embedded procedures should have explicit `bind`
   - Must be marked `readonly`

7. **Initialisation of any FIFO caches**
   - Definition of cache capacity parameters and loading of parameter overrides from global context
   - Definition of a generator procedure and a cardinality function
   - Executing the `fifocache` resource to return a named "FIFO cache object"

8. **Lazy initialisation procedure**
   - Data that must be computed (expensive) and is deferred until first execution
   - First run derives and stores values (in global VM); subsequent runs load cached values
   - Embedded procedures do not require `bind` (propagates from outer procedure)

9. **Main procedure**
   - Exported by the resource and called on demand
   - Uses immediate references to static data
   - Calls lazy initialisation procedure
   - Makes use of any named FIFO caches by executing their `fetch` method
   - Bind the main procedure whilst inhibiting binding of non-standard operators defined on some RIPs, i.e. `barcode`

10. **Resource definition**
    - Define the main procedure as a resource

11. **Allocation mode restore**
    - Return to previous defaults


### Encoder Metadata

Encoder source files contain metadata comments:

```postscript
% --BEGIN ENCODER encodername--
% --DESC: Human-readable description
% --EXAM: example input data
% --EXOP: example options
% --RNDR: renlinear|renmatrix|renmaximatrix
% --FMLY: Family Name
% --REQUIRES preamble raiseerror [other deps...]
% --END ENCODER encodername--
```

`REQUIRES` lists dependencies of the resource in order. It is used by the build
system and is API for users that want to assemble the resources into a PS file
prolog. It is not transitive: If must list the recursive dependencies of all
required resources.

`DESC` and `FMLY` apply only to encoders. Utility resources (e.g. `preamble`,
`raiseerror`, renderers) intentionally omit both. Internal encoders (e.g.
`gs1-cc`, `raw`, `daft`) intentionally omit `FMLY`, which groups encoders into
families for the C library API.


### Resource output file structure

Built resource files have a similar structure to their source files, with their
source (packaged or otherwise) wrapped by comments that follow the PostScript
language Document Structuring Conventions.

- `BeginResource:` DSC comment contains VM memory usage that is measured by the build system per-resource by pre-loading all dependencies before measurement, so each resource's VMusage reflects only its own consumption.

Monolithic outputs contain comments that feature a `--BEGIN/END TEMPLATE--` marker pair that users can use to splice the relevant contents into the prolog of a PS document.


### Lazy Initialisation Pattern

```postscript
/resource.latevars dup 16 dict def load /init {
    currentglobal
    true setglobal  % Lazy vars must be in global VM, like resource definitions

    //resource.latevars begin

    %
    % Derived data computed here (e.g., Reed-Solomon tables, lookup dicts)
    %
    /charvals 256 dict def
    % ... populate charvals ...
    /charvals charvals readonly def

    %
    % Redefine /init to just load cached values on subsequent calls
    %
    /init { //resource.latevars {def} forall } def

    end

    //resource.latevars /init get exec

    setglobal
} bind put

/uk.co.terryburton.bwipp.global_ctx dup where {  % Do eager initialisation, if desired
    exch get /preload known {//resource.latevars /init get exec} if
} {pop} ifelse

%
% latevars procedure is called in main procedure, **after** options processing
%
% User must not be able to override variables defined in latevars via options.
%
/resource {
   % Options processing code
   ...
   //resource.latevars /init get exec
   ...
}
```

### Resource Registration

Resources are registered to the `/uk.co.terryburton.bwipp` category:

```postscript
/encodername dup load /uk.co.terryburton.bwipp defineresource pop
```

Dependencies are loaded at the start of the resource definition:

```postscript
N dict
dup /raiseerror dup /uk.co.terryburton.bwipp findresource put
dup /parseinput dup /uk.co.terryburton.bwipp findresource put
begin
    % resource definitions using //raiseerror, //parseinput
end
```


### Main Procedure Structure

Example for an encoder:

```postscript
/encoder {
    20 dict begin
    {  % stopped context for error cleanup

    %
    % 1. Option defaults
    %
    /dontdraw false def
    /parse false def
    /option1 defaultvalue def

    %
    % 2. Process input
    %
    //processoptions exec /options exch def
    /barcode exch def

    %
    % 3. Initialize lazy computation
    %
    //encoder.latevars /init get exec

    %
    % 4. Validation (with early return on error)
    %
    barcode () eq {
        /bwipp.encoderEmptyData (Data must not be empty) //raiseerror exec
    } if

    %
    % 5. Apply AST spec overrides and resolve physical specification
    %
    /encoder ast /apply_ast //render exec not { //raiseerror exec } if
    /resolve_strictspec //render exec

    %
    % 6. Main encoding logic using //encoder.staticdata and loaded data from latevars
    %
    % The barcode generation process is typically some variation of these steps:
    %   - High-level encoding to codewords
    %   - Termination and padding
    %   - Symbol size selection
    %   - Blocking data for Reed-Solomon ECC generation
    %   - Matrix construction with fixtures
    %   - Data layout in matrix
    %   - Mask evaluation and selection
    %   - Function module placement
    %

    %
    % 7. Resolve bar height from spec (linear only, before bhs/bbs construction)
    %
    /resolve_height //render exec

    %
    % 8. Build output dictionary
    %
    <<
        /ren /renlinear  % or /renmatrix, /renmaximatrix
        % /sbs [...]     % 1D: space-bar-space widths
        % /pixs [...]    % 2D: row-major pixel array
        /strictspec strictspec
        /xdim xdim
        /xmin xmin
        /xmax xmax
        /modunit modunit
        /opt options
    >>

    %
    % 9. Conditional rendering
    %
    dontdraw not //renlinear if

    } stopped {end stop} if  % Prevent dict stack leak on error
    end
}
[/barcode] {null def} forall  % Inhibit binding of non-standard operators defined on some RIPs
bind def
/encoder dup load /uk.co.terryburton.bwipp defineresource pop
```


### Resource calling pattern and error handling

Upon encountering an error, a resource shall clean up **only** its own stack
entries and then call the `raiseerror` procedure. This halts execution and
results in either a custom error handler or a user-provided `stopped` context
being run.

To avoid orphaning stack entries when a resource does not run to completion — such
as when another resource invokes `raiseerror` — resources must execute other
resources only with a clean stack.

To avoid leaving entries on the dict stack when an error is raised, each
resource's `stopped` context catches the `stop` from `raiseerror`, and then
runs `{end stop}` to close the dictionary and re-propagate.

An example is "wrapper encoders" that delegate to another encoder with
modified options:

```postscript
% Good: /args is only pushed after inner encoder succeeds
barcode options //innerencoder exec /args exch def
```


### Implementation Limit Guards

When an encoder's input can cause an internal allocation (string, array or
dictionary) to exceed the guaranteed PostScript implementation limits, the
allocation must be wrapped with `stopped` to catch the error gracefully.
GhostScript has higher limits so these guards may only trigger on other
interpreters.

The guard must pop the failed size operand left on the stack by `stopped` and
raise a descriptive error:

```postscript
barcode length 8 mul { string } stopped {
    pop /bwipp.encoderInputTooLarge (Input data exceeds implementation limits) //raiseerror exec
} if /bits exch def
```


## User API

```postscript
<barcode data string> <options string or dict> /<encoder> /uk.co.terryburton.bwipp findresource exec
```

Example:
```postscript
10 10 moveto
(\(01\)09521234543213(3103)000123)      % Data: Note quoting of parentheses
(segments=4 includetext alttext=TEST)   % Options
/databarexpandedstacked                 % Encoder
/uk.co.terryburton.bwipp findresource exec
showpage
```


### Options Processing (`processoptions.ps.src`)

- Accepts space-separated `key=value` pairs or just `key` (to set boolean to true)
- Options update corresponding PostScript variable in the current dictionary, only if it exists
- Values are type checked against the option's default value type, otherwise error is raised


### Barcode Data Parsing (`parseinput.ps.src`)

Options `parse` and `parsefnc` preprocess data to allow denoting ASCII control characters and non-data characters (FNC1-4, ECI) as printable text

- Uses `^` as escape character:
  - `^NUL`, `^000`-`^255` (with `parse` option)
  - `^FNC1`, `^ECInnnnnn` (with `parsefnc` option)

GS1 AI syntax is first processed by `gs1process.ps.src` before regular parsing


### GS1 Application Identifier Syntax and GS1 DigitalLink Processing (`gs1process.ps.src`)

Processes GS1 data and validates against the [GS1 Barcode Syntax Dictionary](https://github.com/gs1/gs1-syntax-dictionary),
which describes each Application Identifier's format specification (component
data types and lengths), and component validation rules (using "linters").

The `contrib/development` directory contains:

- `gs1-syntax-dictionary.txt` - Local copy of the GS1 Syntax Dictionary
- `build-gs1-syntax-dict.pl` - Maintainer script to transform it into the `/gs1syntax` code structure

**Calling convention:**

For bracketed AI syntax:

```postscript
(\(01\)09521234543213\(10\)ABC123)               /ai //gs1process exec  % => ais vals fncs
```

For a GS1 Digital Link URI:

```postscript
(https://id.gs1.org/01/09521234543213/10/ABC123) /dl //gs1process exec  % => ais vals fncs
```

- `ais`  - Application Identifier strings (e.g., `[(01) (10)]`)
- `vals` - Corresponding value strings (e.g., `[(09521234543213) (ABC123)]`)
- `fncs` - Boolean array indicating which AIs require FNC1 separator (based on `contrib/development/ai_not_needing_fnc1.txt`)

`parseinput` is applied to each extracted AI value (from `vals`) of bracketed AI syntax inputs, and to the overall URI for GS1 Digital Link inputs.

GS1-enabled encoders can disable validation checks using the `dontlint` option.


### Error Handling (`raiseerror.ps.src`)

- Errors are raised by popping stack items added by current resource, pushing a user-friendly info string and error name, then calling `raiseerror`
- Uses standard PostScript `stop` mechanism to invoke custom error handlers or a `stopped` context
- Error names typically follow pattern: `/bwipp.<resource><ErrorType>`, e.g., `/bwipp.code39badCharacter`

Example custom error handlers in `contrib/development/`:

- `error_handler_to_stderr.ps` - Writes BWIPP errors to stderr (for scripted/batch use)
- `error_handler_as_image.ps`  - Renders error message as page output (for viewers)


### Intermediate Dictionaries

Encoders create a common dictionary structure expected by their renderer:

**1D Barcodes (`renlinear`):**
```postscript
<<
    /ren /renlinear
    /sbs [1 2 1 1 ...]      % space-bar-space widths (digits 0-9)
    /bhs [0.5 0.5 ...]      % bar heights
    /bbs [0 0 ...]          % bar baseline positions
    /txt [[...] [...]]      % text elements: [string x y font size]
    /opt options
>>
```

**2D Barcodes (`renmatrix`):**
```postscript
<<
    /ren /renmatrix
    /pixs [1 0 1 0 ...]     % row-major array: 1=black, 0=white
    /pixx width             % symbol width in modules
    /pixy height            % symbol height in modules
    /opt options
>>
```

**MaxiCode (`renmaximatrix`):**
```postscript
<<
    /ren /renmaximatrix
    /pixs [...]             % 30x29 hexagon grid values
    /opt options
>>
```

Callers can access the intermediate dictionary by setting the `dontdraw` options with `enabledontdraw` set in global context.


### Default Normalised Units

The renderers operate in harmonised normalised units chosen for integer
pixel-locking at 72 DPI:

- **Linear (`renlinear`):** 1pt per X-dimension module (narrow bar), 72pt
  (1 inch) default bar height. At 72 DPI, 1 module = 1 device pixel.
- **Matrix (`renmatrix`):** `modunit` points per module (1pt or 2pt depending
  on symbology). Output dict `width`/`height` = `cols * modunit / 72` inches.
- **MaxiCode (`renmaximatrix`):** Fixed 2.4945 scale from 1pt modules to
  0.88mm hexagons. Hex geometry uses √3-based constants for correct aspect
  ratio at any scale; pixel-locking of hex vertices is inherently imperfect
  on a square grid.

External scaling or the `width`/`height` options resize from these defaults.
The `strictspec` system (below) provides an alternative path that renders at
specification-accurate physical dimensions.


### Grid Fitting (`render.ps.src`)

`render.gridfit` snaps module boundaries to whole device pixels, eliminating
anti-aliasing artefacts in bitmap output.

**Device resolution:** When `griddpi` is provided by the caller, it is used
directly as the target resolution — no hardware probing occurs and gridfit
can operate on devices that would otherwise be skipped (e.g., nullpage).
When auto-detected (`griddpi=0`), `defaultmatrix` is queried; bogus values
cause gridfit to silently skip via the `hwxres` guard.

**Rounding modes:**
- Default: round to nearest whole pixel per module
- `width` forced (renlinear only): floor, to avoid exceeding requested width
- `strictspec` with spec bounds: smart rounding — try round first; if the
  effective X-dimension falls outside `xmin`/`xmax`, try the alternate
  direction; if neither fits, return `/errorname (info) false` to the caller

**Signature:** `magnitude xdim xmin xmax usefloor snapy /gridfit //render exec`
returns `true` on success, `/errorname (info) false` on spec violation. The
caller (renderer) is responsible for cleanup (`grestore`) before raising the
error via `raiseerror`.

**EPS safety:** When `gridfit` is not enabled (and `griddpi` is not set), no
device-dependent operators (`defaultmatrix`, `dtransform`) are executed.
`strictspec` without gridfit is fully EPS-safe.


### Physical Specification System (`render.ps.src`, encoders)

Shared helpers in the `render` resource enable encoders to generate output at
physical specification dimensions.

**Specification modes** control how symbology dimensions relate to spec:

- **No spec** (default): 1pt per module. Encoder's default bar height.
  Modules land on pixel boundaries at 72 DPI. The user scales externally
  to reach their target X-dimension.

- **`propspec`** (linear only): 1pt per module, but bar height is derived
  from the spec ratio `hnom/xnom`, rounded to a whole number of points
  (pixel-locked). The coordinate system stays at 1pt-per-module so modules
  remain pixel-locked at 72 DPI — the user applies a single scale factor
  to hit both their target X-dimension and resolution. Silently falls back
  to default height when `hnom` is not available (harmless no-op).
  User-supplied `height` overrides the derived value. EPS-safe.

- **`strictspec`**: The renderer scales the symbol to physical spec
  dimensions derived from `xnom` (or explicit `xdim`). Bar height is
  derived from `hnom/xnom` (not pixel-locked). The output is at the
  correct absolute size for direct placement in a page layout. Use with
  `gridfit`/`griddpi` to additionally snap to device pixels for bitmap
  output. EPS-safe without gridfit. `gridfit` without explicit `griddpi`
  probes the device via `defaultmatrix`/`dtransform` (not EPS-safe).
  Strict: errors if `xnom`/`xdim` missing or effective X outside bounds.

- **`loosespec`**: Implies `strictspec`. Lenient variant that silently falls
  back to default dimensions when `xnom`/`xdim` is missing, suppresses
  bounds violations, and picks the closest-to-spec gridfit snap when
  neither rounding direction is in-spec. The recommended mode for
  general-purpose output.

`propspec` exists because `strictspec` changes the coordinate system away
from 1pt-per-module, which makes external scaling for bitmap generation
less predictable. `propspec` retains the 1pt base while applying the spec
height ratio — the only spec-aware mode that is fully EPS-safe and
naturally pixel-locked.

All three modes (`strictspec`, `propspec`, `loosespec`) can be set per-symbol
via options or globally via `global_ctx`. Each encoder reads global
defaults via the `global_encoder_defaults` dispatch helper, guarded by
`_dontdraw` so that sub-encoders called by wrappers do not re-read
global defaults. Typical global configurations:

```postscript
/uk.co.terryburton.bwipp.global_ctx << /loosespec true >> def                  % General purpose (vector, EPS)
/uk.co.terryburton.bwipp.global_ctx << /loosespec true /gridfit true >> def    % Bitmap output
/uk.co.terryburton.bwipp.global_ctx << /strictspec true >> def                 % Strict validation
```

**Options:** `strictspec` (bool), `propspec` (bool, linear only), `loosespec`
(bool), `mag` (real, default 1.0), `xdim` (mm), `hdim` (mm), `ast`
(string, default `(default)`), `xnom`/`hnom`/`xmin`/`xmax` (mm, sentinel
-1.0), `modunit` (int). `height` defaults to -1.0 (sentinel); each
encoder falls back to its own default when the sentinel survives.

**Application Specification Tables (ASTs):** `render.ast` is a static readonly
dict mapping encoder names to named spec profiles (GS1 SSTs 1-13, ISO
defaults). Entries may share dicts via `index` to reduce allocation.
`apply_ast` fills -1.0 sentinel values from the selected profile into the
caller's dict using `currentdict`; user-provided values (non-sentinel) are
preserved. When the encoder is in the AST table but the requested profile
is not found, `default` silently passes; non-default profiles error.

**Helpers in render (dispatch table):**

- `global_encoder_defaults` — reads `loosespec`, `strictspec`, `propspec` from
  `global_ctx` when local values are false; guarded by `_dontdraw` to
  prevent sub-encoders from re-reading. `loosespec` implies `strictspec`.
- `global_renderer_defaults` — reads `default_barcolor`,
  `default_backgroundcolor`, `default_bordercolor`, `default_inkspread`,
  `default_griddpi`, `default_gridfit` from `global_ctx`
- `apply_ast` — fills spec sentinels from AST; returns `true` or
  `/errorname (info) false`
- `resolve_strictspec` — validates `mag`/`xdim` exclusivity, resolves `xdim`
  from `xnom * mag`, resolves `hdim` from `hnom * mag` (if defined in
  caller's dict), validates bounds via `validate_xdim`. Under `loosespec`:
  silently disables `strictspec` when `xnom`/`xdim` missing, suppresses
  bounds errors
- `resolve_height` — pure function, returns derived height on the stack
  (or current `height` if not applicable). Derives when
  `hnom != -1 AND (strictspec OR (propspec AND height == sentinel))`.
  Pixel-locks (rounds) under propspec; not under strictspec.
- `validate_xdim` — low-level `xdim xmin xmax` bounds check; returns `true`
  or `/errorname (info) false` with formatted error string

**Encoder integration pattern** (see `ean13.ps.src` for linear,
`qrcode.ps.src` for matrix):

1. Declare spec options with -1.0 sentinels (including `height`,
   `loosespec`, `propspec`, `strictspec`)
2. After processoptions, apply global defaults:
   ```postscript
   /apply //processoptions exec /options exch def
   /global_encoder_defaults //render exec
   ```
3. After input validation, call AST and strictspec resolution:
   ```postscript
   /ENCODER ast /apply_ast //render exec not { //raiseerror exec } if
   /resolve_strictspec //render exec
   ```
4. For linear encoders, resolve height with fallback to encoder default:
   ```postscript
   /height /resolve_height //render exec dup -1 eq { pop <default> } if def
   ```
5. Pass `strictspec`, `loosespec`, `xdim`, `xmin`, `xmax`, `modunit` in the
   intermediate dict

**Linear encoders** add `propspec`, `hdim`, `hnom` and call `resolve_height`.
**Matrix encoders** omit these; `modunit` is typically 2 (1 for stacked-linear
types such as pdf417, micropdf417, codablockf, code16k, code49).

**Renderer scaling:** Each renderer applies `xdim 72 mul 25.4 div modunit div
dup scale` when `strictspec` is true. `renmaximatrix` divides additionally by
its existing 2.4945 scale factor.

**Inkspread under strictspec:** Renderers adjust inkspread to maintain a fixed
physical amount (mm) rather than a proportional reduction. For `renlinear`,
the adjustment is applied before bar width computation (since bars are
pre-computed into the `bars` array). For `renmatrix` and `renmaximatrix`, it
is applied after the strictspec scale, before module rendering.

**Wrapper framework:** The outermost encoder consumes the AST. All wrappers
that have their own AST entry must:

1. Declare spec options (including `propspec`, `hnom`, `ast`)
2. Call `apply_ast` under their own encoder name
3. Call `resolve_strictspec`
4. `options (ast) undef` and `options (mag) undef` — consumed, do not
   leak to inner encoder
5. Put all resolved spec values into `options` for the inner encoder
6. For wrappers with a non-1.0 height default: fall back only when the
   sentinel survives and propspec won't derive:
   ```postscript
   height -1.0 eq { propspec hnom -1 ne and not { /height <default> def } if } if
   ```

Simple wrappers without their own AST (code32, hibccode128, etc.) need no
spec handling — options flow through transparently. Their `height` should
default to -1.0 (sentinel) so propspec/strictspec can derive via the inner
encoder.

**Composite wrappers** call both a linear encoder and gs1-cc. Spec options
must reach the linear encoder but NOT gs1-cc (the 2D component has
independent scaling). Strip `strictspec`/`propspec` from options after the
linear encoder call and before the gs1-cc call:
```postscript
options (strictspec) undef
options (propspec) undef
```
For `gs1-128composite` which uses `<< options {} forall >>` clones, strip
from the clone passed to gs1-cc.


## Performance

### Ghostscript Observed Behaviour

- Dict reads are ~1.3x faster than stack `index`; writes (`def`) are ~1.25x slower than reads
- Stack manipulation wins by avoiding `def`, not by faster access
- `forall` avoids per-iteration `get` overhead compared to `for` + `get`
- `N index` cost is independent of stack depth
- `getinterval` cost is fixed regardless of size (returns a view, not a copy)


### Optimization Patterns

- Use `//name` immediate lookup for static data (avoids runtime allocation and dictionary lookups); use directly rather than creating local aliases (e.g., `//encoder.fnc1` not `/fnc1 //encoder.fnc1 def`)
- Defer expensive computation to lazy init (first-run cost, cached thereafter)
- When `latevars` needs a helper function, define it in static scope (bind it; see `auspost.rsprod`) and reference via `//encoder.helper exec`

**Conditional Assignment Pattern**

Use an inline condition when performing simple conditional assignments:

```postscript
% Bad: Verbose
condition {
    /a 2 def
} {
    /a 5 def
} ifelse

% Good: Concise
/a condition { 2 } { 5 } ifelse def
```


**"Switch" blocks (common exit)**

Long `ifelse` chains can be replaced with a "common exit" pattern for
maintainability. Nested `ifelse` avoids the `repeat`/`exit` overhead, so prefer it in hot paths.

```postscript
% Nested ifelse (faster, harder to modify)
condition1 {
    /c1
} {
condition2 {
    /c2
} ... {
    /default
} ifelse ... } ifelse

% Common exit (slower, easier to maintain)
1 {  % Common exit
    condition1 { /c1 exit } if
    condition2 { /c2 exit } if
    ...
    /default
} repeat
/result exch def
```

**Loops with conditional exit**

Loops should be commented as such in the first line:

```postscript
{  % loop
    condition { exit } if
    ...
} loop
```

**Reading Global Context**

Read configuration from (optional) global context with a default:

```postscript
/configvalue 42 def  % Default
/uk.co.terryburton.bwipp.global_ctx dup where {
    exch get /configkey 2 copy known {get /configvalue exch def} {pop pop} ifelse
} {pop} ifelse
```


**Module-Level Caching with FIFO caches**

For expensive computations that benefit from caching across invocations (e.g.,
generation of Reed-Solomon polynomial coefficients), use the `fifocache`
resource:

```postscript
/encoder.coeffscachemax   N def    % Override with global_ctx.encoder.coeffscachemax
/encoder.coeffscachelimit M def    % Override with global_ctx.encoder.coeffscachelimit
/uk.co.terryburton.bwipp.global_ctx dup where {
    exch get dup
    /encoder.coeffscachemax   2 copy known {get /encoder.coeffscachemax   exch def} {pop pop} ifelse
    /encoder.coeffscachelimit 2 copy known {get /encoder.coeffscachelimit exch def} {pop pop} ifelse
} {pop} ifelse

/encoder.coeffscache encoder.coeffscachemax encoder.coeffscachelimit //fifocache exec def

/encoder.coeffscachefetch {
    /key exch def
    key
    { //encoder.gencoeffs exec }  % Generator procedure
    { length }                    % Cardinality function; applied to output of generator procedure
    //encoder.coeffscache /fetch get exec
} bind def
```

Cache parameter guidelines:

- `max` limits cache entry count (number of keys); `limit` limits total elements (as measured by cardinality function)
- Set `limit=0` to disable caching
- Set `max` and `limit` high enough to avoid evictions when memory allows


### Anti-patterns

- Creating variables (dictionary entries) in hot loops
- Defining static data in the main procedure (hoist to define time, then use `//name`)
- Computing derived data on every invocation (use `latevars`)


**Array Extension in Loops**

Avoid `/arr [ arr aload pop newelem ] def` within loops. This idiom creates a
new array each iteration by unpacking the old array onto the stack, adding new
elements, then repacking.

```postscript
% Bad: O(n^2) array rebuilding
/result [] def
0 1 n 1 sub {
    /i exch def
    /result [ result aload pop i computeValue ] def
} for

% Good: Pre-allocate and fill
/result n array def
0 1 n 1 sub {
    /i exch def
    result i i computeValue put
} for
```

When array size isn't known in advance, `mark ... counttomark array astore` is
fastest (~2x faster than pre-allocate, ~5x faster than aload rebuild):

```postscript
mark
0 1 n 1 sub { computeValue } for  % Leave values on the stack
counttomark array astore
/result exch def
```

If use of stack is difficult, e.g. due to complex backtracking, then
pre-allocate and, if size is bounded, over-size then trim with `getinterval`.

Extension of small arrays with `/arr [ arr aload pop ... ] def` is
acceptable for one-time operations outside loops.


**Hot Loop Stack Pattern**

In hot loops, avoid `/idx exch def` which incurs `def` overhead each iteration.
Keep loop index on stack instead:

```postscript
% Bad: Creates dictionary entry each iteration
0 1 k {  % E.g. k from an outer loop
    /idx exch def
    % Stuff using "idx" variable...
    arr k idx sub 1 sub get
} for

% Good: Iterator referenced by "index" and finally consumed by "roll"
0 1 k 1 sub {  % idx on stack
    % Stuff using "N index" to access idx on the stack...
    % Finally, roll moves idx to top where we consume it:
    arr k 3 -1 roll sub 1 sub get
} for
```

The RSEC loops in `qrcode`, `datamatrix`, `pdf417` demonstrate advanced uses of this
pattern, including stack-based access to variables outside of the inner loop.


**Updating a dictionary item**

When applying a function to a dictionary key:

```postscript
% Bad: More lookups; verbose
dic /item dic /item get 1 add put

% Good: Clean; efficient
dic /item 2 copy get 1 add put
```

**Beware built-in operators**

When a procedure is `bind`ed, names that match operators are resolved at bind
time. Using operator names as variables causes unexpected behavior:

```postscript
% count is a built-in operator that returns stack depth
(a) (b) (c) count =   % prints 3

% Problem: "count" as a variable in a bound procedure
/badproc {
    /count 5 def
    /count count 1 add def   % BUG: count resolves to operator
    count
} bind def

badproc =   % prints 0 (stack depth), not 6!
```

Common operators to avoid as variable names: `count`, `length`, `index`.


### Profiling

Simple profiling of the overall runtime for some encoder:

```bash
time gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -c \
  '(build/monolithic/barcode.ps) run
   100 { 0 0 moveto (DATA) (options) /encoder /uk.co.terryburton.bwipp findresource exec } repeat'
```

Detailed per-phase timing using the resource timer utility:

```bash
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage \
   -I build/resource/Resource -f contrib/development/resource_timer.ps -c '
   0 0 moveto (DATA) (options) /encoder /uk.co.terryburton.bwipp findresource exec
   resource_timer_report
'
```

The resource timer uses the hooks framework to measure time spent in each phase
of resource execution, with hierarchical grouping of related phases.


### Hooks Framework

Resources may be configured to permit named "hooks" at any point in their code:

The following placed at the beginning of the resource definition will create
two hooks (`before` and `after`):

```postscript
/qrcode [/before /after] //setuphooks exec
```

Hooks accept a single parameter and may appear anywhere in the code (as many
times as required):

```postscript
(matrix.layout) //qrcode.before exec
...
(matrix.layout) //qrcode.after exec
```

The above as examples of existing hooks placed at execution phase boundaries.

**Configuring hooks procedures:**

By default hooks will do nothing other than pop the parameter.

The above pair of hooks is intended to allow measurement of time spent in each
phase via the definition of suitable procedures within global context.

The global context must be configured with `enabledebug` set and a `hooks`
dictionary containing custom procedures related to the hooks, for example:

```postscript
currentglobal true setglobal
/uk.co.terryburton.bwipp.global_ctx <<
    /enabledebug true
    /hooks <<
        /before {20 string cvs print ( before ) print print ( ) print realtime =}
        /after  {20 string cvs print ( after  ) print print ( ) print realtime =}
    >>
>> def
setglobal
```

Example output:
```text
datamatrix before setup.define 20
datamatrix after  setup.define 21
datamatrix before setup.latevars 22
datamatrix after  setup.latevars 40
...
```

When triggered, a hook procedure receives the resource name that triggered it,
as well as the parameter from the code.

To configure a hook procedure for the named hooks in just a single encoder,
create a hooks entries named like `qrcode.before`.


### Profiling Results

Performance enhancements are welcome, but significant gains are hard won. Large 2D symbols have different bottlenecks: QR Code is mask evaluation bound; Data Matrix, Aztec, and PDF417 are RSEC bound (mitigated by FIFO caches). See encoder source for attempted optimizations.


## Testing

- `tests/run_tests`              - Top-level test orchestrator to run tests for all build variants
- `tests/<variant>/run`          - Script to run the tests for a single build variant
- `tests/ps_tests/test_utils.ps` - PostScript test utility functions
- `tests/ps_tests/*.ps.test`     - Individual resource tests (run from either `build/resource/Resource` or `build/packaged_resource/Resource`); require that test_utils.ps utility is loaded
- `tests/ps_tests/test.ps`       - PostScript test entrypoint: Loads utility functions then runs all resource tests

The `test_utils.ps` file contains the following utility functions required for
all resource tests:

- `debugIsEqual` - Compare codeword arrays (used with `debugcws` option)
- `isEqual`      - Compare output arrays (`pixs`, `sbs`)
- `isError`      - Verify specific error is raised

To access the intermediate dictionary without rendering, each of the encoders
support the following option, which requires `enabledontdraw` to be set in
global context:

- `dontdraw`      - Return structured dict without rendering

Encoders may have one or more of the following debug options, each of which
requires `enabledebug` to be set in global context:

- `debugcws`      - Return codeword array
- `debugbits`     - Return bit array
- `debugecc`      - Return error correction data
- `debughexagons` - Return hexagon positions (MaxiCode)

### Examples of one off testing and debugging

Run tests for just one of the encoders:

```postscript
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
        -f tests/ps_tests/test_utils.ps -f tests/ps_tests/qrcode.ps.test
```

Debug an encoder's high-level encoding codeword generation:

```postscript
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
        -c '10 10 moveto (TEST) (debugcws) /qrcode /uk.co.terryburton.bwipp findresource exec =='
```

Debug an encoder's ECC codeword generation:

```postscript
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
        -c '10 10 moveto (TEST) (debugecc) /datamatrix /uk.co.terryburton.bwipp findresource exec =='
```


### Test Patterns

Success test - validate 1D barcode graphical structure via `sbs` array:

```postscript
(INPUT) (dontdraw) encoder /sbs get
[1 2 1 1 ...] debugIsEqual
```

Success test - validate 2D barcode graphical structure via `pixs` array:

```postscript
(INPUT) (dontdraw) encoder /pixs get
[
    1 0 1 0 ...    % Aligned to shape of 2D bitmap
    0 1 0 1 ...
] debugIsEqual
```

Success test - validate encoder codeword output:

```postscript
{
    (TESTING) (debugcws) encoder
} [32 61 39 ...] debugIsEqual
```

Error test:

```postscript
{ (INPUT) (dontdraw) encoder } /bwipp.encoderErrorName isError
```

For repetitive tests, use template procedures, for example:

```postscript
/eq_tmpl {
    exch { 0 (dontdraw) encoder /sbs get } dup 3 -1 roll 0 exch put
    exch isEqual
} def

(12345678)  [1 1 1 1 2 ...]  eq_tmpl
(87654321)  [1 2 1 1 1 ...]  eq_tmpl
```

```postscript
/eq_tmpl {
    3 1 roll { 0 0 encoder /pixs get }
    dup 3 -1 roll 1 exch put      % insert options
    dup 3 -1 roll 0 exch put      % insert data
    isEqual
} def

(DATA) (eclevel=M) [...pixs...] eq_tmpl
```

```postscript
%
% Success-only smoke test; not comparing output
%
/ok_tmpl {
    { 0 setanycolor true } dup 3 -1 roll 0 exch put
    true isEqual
} def

(112233) ok_tmpl
```

```postscript
%
% Expecting an error
%
/er_tmpl {
    exch { 0 (dontdraw) encoder } dup 3 -1 roll 0 exch put
    exch isError
} def

(INVALID)  /bwipp.encoderBadData  er_tmpl
```


### Errors test coverage

Test for errors that are raised by the code should be comprehensive.

However some linter errors cannot be triggered because they are masked by other
checks.

GS1 format checks error that are impossible due to format validation running
before linters:
- `GS1valueTooShortForOffsetGCP` - AIs have min >= 14
- `GS1badDateLength` - AIs have fixed-length date fields
- `GS1badTimeLength` - linter defined but unused
- `GS1badPieceTotalLength` - AIs have fixed even length
- `GS1couponTooShortGCPVLI`, `GS1couponTooShortFormatCode` - AIs have min >= 1
- `GS1badLatitudeLength`, `GS1badLongitudeLength` - AIs have fixed length

Unreachable due to earlier validation:
- `GS1UnknownCSET82Character` - `lintcset82` catches first
- `GS1alphaTooLong` - max length fits primes array
- `GS1requiresNonDigit` - checksum requires non-digits


## Documentation

Documentation is hosted in the wiki at
<https://github.com/bwipp/postscriptbarcode/wiki>, and these pages are the
source for the PDF and HTML documentation that is hosted at in GitHub Releases.


### Wikidocs Submodule

The `wikidocs/` directory is a Git submodule that tracks the project's GitHub wiki repository.

The GitHub Actions workflow (`.github/workflows/ci.yml`) builds the
documentation. Upon release (i.e. pushing a tag), the job uploads the build
documentation to GitHub releases as `postscriptbarcode-manual.pdf` and
`postscriptbarcode-manual.html`.

To regenerate the documentation locally:

```bash
git -C wikidocs pull origin master
git add wikidocs
got commit -m "Bumped wikidocs"
```

### Building Documentation

From the `wikidocs` directory:

```bash
make -f __pandoc/Makefile all
```

Outputs:
- `__pandoc/barcodewriter.pdf` - Complete PDF manual
- `__pandoc/barcodewriter.html` - Self-contained HTML documentation

The build requires Pandoc, the Haskell runtime and LaTeX.


### Wiki Example Images

Example images in the wiki are generated from formatted code blocks in the
markdown files:

```text
Data:    <barcode data>
Options: <encoder options>
Encoder: <encoder name>
```

Followed by an image reference: `![](images/<name>.svg)`

**Generating individual images:**

```bash
contrib/development/make_image.sh svg qrcode 'Hello World' '' > qrcode.svg
contrib/development/make_image.sh pdf qrcode 'Hello World' '' > qrcode.pdf
```

The script supports `png`, `pnm`, `eps`, `pdf`, and `svg` formats. Wiki images use SVG
for the GitHub wiki and PDF for LaTeX documentation.

**Regenerating all wiki images:**

```bash
wikidocs/__pandoc/regenerate_images.pl
```

Both scripts require `build/monolithic/barcode.ps` (run `make` first).


### Adding a New Symbology

**Source code:**
1. `src/<symbology>.ps.src` - Create the resource file (use existing encoder as template)
2. `src/uk.co.terryburton.bwipp.upr` - Add entry to the resource index
3. `tests/ps_tests/<symbology>.ps.test` - Create test file
4. Verify build: `make build/standalone/<symbology>.ps`

**Wiki content for symbologies** (in `wikidocs/` submodule):
1. `symbologies/<Symbology-Name>.md` - Create the documentation page
2. `symbologies/_Sidebar.md` - Add link in appropriate category section
3. `symbologies/Symbologies-Reference.md` - Add entry with thumbnail image(s)
4. `images/<name>.svg` and `images/<name>.pdf` - Example images (use `scale=1`)
5. Related symbology pages - Add cross-references if applicable

**Wiki content for options** (in `wikidocs/` submodule):
1. `options/<Option-Name>.md` - Create the documentation page
2. `options/_Sidebar.md` - Add link in appropriate section
3. `options/Options-Reference.md` - Add entry if applicable

**Build system:**
1. `wikidocs/__pandoc/Makefile` - Add to `REF_FILES` in appropriate category

**Release tasks** (maintainer only):
- Update homepage in `postscriptbarcode` `gh-pages` branch
- Update GitHub project tags


## Packaging

### OBS (Open Build Service)

Distribution packages are built on OBS for multiple targets across DEB, RPM,
and Arch-based distributions, using two projects:

| Project                                                                                                                                 | Purpose     | Source     | Version format                      |
|-----------------------------------------------------------------------------------------------------------------------------------------|-------------|------------|-------------------------------------|
| [`home:terryburton:postscriptbarcode`](https://build.opensuse.org/package/show/home:terryburton:postscriptbarcode/libpostscriptbarcode) | **Release** | Pinned tag | `@PARENT_TAG@`                      |
| `home:terryburton:postscriptbarcode:dev`                                                                                                | Dev/nightly | HEAD       | `@PARENT_TAG@.@TAG_OFFSET@~nightly` |

**Packaging files:**

- `debian/`                                             - DEB packaging
- `packaging-examples/rpm-based/postscriptbarcode.spec` - RPM spec file
- `packaging-examples/arch-linux/PKGBUILD`              - Arch packaging

**Triggering builds:**

The release project's services run on commit and can be re-triggered via
`osc service remoterun`. Trigger promptly after tagging, before further
commits land. The dev project builds from HEAD on each trigger.

```bash
# Release
osc service remoterun home:terryburton:postscriptbarcode libpostscriptbarcode
osc results home:terryburton:postscriptbarcode libpostscriptbarcode

# Dev/nightly
osc service remoterun home:terryburton:postscriptbarcode:dev libpostscriptbarcode
osc results home:terryburton:postscriptbarcode:dev libpostscriptbarcode
```

### Package Install Tests

Post-install smoke tests verify that packages work after installation. Shared
test scripts in `packaging-examples/install_tests/` run across all distros.

**Package test scripts:**

- `test_postscript.sh`  - Loads `barcode.ps` in GhostScript and generates a barcode
- `test_clib.sh`        - Compiles and runs C example against installed library
- `test_<binding>.sh`   - Tests binding via installed example

## Release Process

1. Update CHANGES date: `sed -i '1s/XXXX-XX-XX/YYYY-MM-DD/' CHANGES` and commit
2. Review CHANGES; verify wikidocs has corresponding symbology/option pages
3. Update wikidocs submodule if needed: `git -C wikidocs pull origin master`
4. Push commits, wait for CI: `gh run watch`
5. After CI succeeds: `make tag && git push origin YYYY-MM-DD`
6. Verify release: `gh release view YYYY-MM-DD`
7. Trigger OBS release build (promptly, before further commits land):
   `osc service remoterun home:terryburton:postscriptbarcode libpostscriptbarcode`
8. Add next placeholder: `sed -i '1i XXXX-XX-XX\n\n*\n\n' CHANGES` and commit/push


## PostScript Language Reminders

**Stack operations:**
```postscript
(a) (b) (c) 3  1 roll => (c) (a) (b)
(a) (b) (c) 3 -1 roll => (b) (c) (a)
(a) (b) (c) 1 index => (a) (b) (c) (b)
(a) (b) (c) /x 1 index def => x = (c), not (b) due to /x on stack!
```

**`readonly` returns a new reference:**
```postscript
/a [ 1 2 3 ] def   % a is writable
a readonly pop     % achieves nothing; a still writable
/c a readonly def  % c is readonly; a remains writable
```

**String literals are shared across invocations** (arrays/dicts are not):
```postscript
/proc {
    /a (0000) def    % Safer: /a (0000) 4 string copy def
    a 0 (1234) putinterval
} def
proc  % First run: a = "1234"
proc  % Subsequent: a starts as "1234", not "0000"!
```
