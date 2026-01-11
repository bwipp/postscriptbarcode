# BWIPP - Barcode Writer in Pure PostScript

## Background

PostScript library generating 100+ barcode formats entirely within PostScript, executed by printer/RIP.

Performance, execution cost, and interpreter compatibility are critical.


## AI Instructions

- Create atomic, logical commits upon completion.
- Do not push commits or rewrite history.
- Use sparse comments explaining "why" not "how".
- Generated code should match existing idioms. Newer encoders such as QR Code are the best source of idiomatic code.
- Maintain existing user API (encoder interfaces and metadata).
- Prefer derived values over opaque constants so that the code is auditable, unless prohibitively expensive (even for lazy init).
- Static data should be hoisted out of the main procedure, and deferred with lazy initialisation if it must be derived
- Static and cached structures should be readonly
- Prefer stack work over dictionary heavy code
- Do not replace stack-based logic with dictionary-heavy abstractions.
- Do not refactor for readability at the expense of execution cost.
- Search for pre-existing patterns before inventing code. Warn if the existing pattern does not appear to follow best practise.
- Warn about potential issues such as potential performance regressions in hot paths.
- Warn about potentially incorrect code when introducing new idioms involving stack-based constructions.
- Do not assume GhostScript-only execution. Assume modern implementation limit, and warn when approaching those limits:
  - Integer representation may be 32- or 64-bit. Do not assume overflow or promotion at 32-bit.
  - Maximum of 65535 entries within dictionaries, arrays, and on the stack. (Assume user might already have entries on the stack.)
  - Maximum string length is 65535 characters.
- If a file is updated then its copyright date should be bumped.


## AI Observations

- AI is not very good at writing and reasoning about stack-based code.
- AI seems unable to accurately track the position of items on the stack, resulting in spurious inputs to `index` and `roll`.
- AI does not consider the side effect of inserting new code into existing stack based code, e.g. later indexes needing to be recalculated.
- AI benefits from being shown a preferred pattern then applying it.


## Build

### Commands

- `make -j $(nproc)`      - Build all distribution targets (resource, packaged_resource, monolithic, monolithic_package)
- `make -j $(nproc) test` - Run tests
- `make clean`            - Clean
- `make build/standalone/<encoder>.ps` - Build standalone encoder

Build requires Ghostscript (`gs`) in PATH and Perl.

Quick iteration when developing a resource:

```bash
make build/resource/Resource/uk.co.terryburton.bwipp/qrcode && \
gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -I build/resource/Resource \
  -c '10 10 moveto (Hello World) () /qrcode /uk.co.terryburton.bwipp findresource exec'
```


### Terminology

"Packaging" refers to PostScript resources processed (by the build system's
"packager") into a form easier to distribute but is harder to debug:

- Efficient byte-based encodings for numbers and operators
- Compressed numeric/string arrays
- ASCII85-wrapped output (watermarked)
- Results in ~30-50% smaller files


### Directory Structure

Core library:

- `src/*.ps.src`                    - PostScript resource source files
- `src/uk.co.terryburton.bwipp.upr` - Resource name to path mapping for all resources; required by Distiller; build system uses the order to determine resource order in monolithic and standalone outputs
- `tests/ps_tests/*.ps.test`        - PostScript test files

Build scripts:

- `build/make_resource.pl`           - Resource builder (invokes GhostScript)
- `build/make_deps.pl`               - Dependency rule generator (creates .d files)
- `build/make_monolithic.pl`         - Monolithic resource assembler
- `build/make_standalone.pl`         - Standalone file assembler (supports multiple encoders)

Build outputs:

- `build/resource/`                      - `make resource`: Unpackaged resources
- `build/packaged_resource/`             - `make packaged_resource`: Packaged resources
- `build/monolithic/barcode.ps`          - `make monolithic`: All encoders combined
- `build/monolithic_package/barcode.ps`  - `make monolithic_package`: Packaged monolithic
- `build/standalone/<encoder>.ps`        - Standalone encoder (manual, only required deps built)


## Resource Source File Structure

Each resource source file has a similar structure:

1. **Header comments**
   - Copyright notice (year should be maintained)

2. **Metadata comments**
   - Declares dependencies between resources (for assembling monolithic resources)
   - For encoders, gives example data (see Encoder Metadata below)

3. **Dependent resource loading**
   - Uses `findresource` to load dependencies into working dictionary

4. **Static data structures**
   - Plain definitions of literal stuctured data (arrays and dicts) that is costly to assemble if executed every call
   - Runs once during resource definition; values immediately referenced by main procedure
   - Names MUST be prefixed with the resource name (e.g., `encoder.charmap`) - the Makefile extracts all `//name` references to populate the packager's atload template, requiring globally unique names
   - `//name` immediate references are resolved at parse time, embedding the value directly into procedures
   - Embedded procedures should have explicit `bind`
   - Must be marked `readonly`

5. **Lazy initialisation procedure**
   - Data that must be computed (expensive) and is deferred until first execution
   - First run derives and stores values (in global VM); subsequent runs load cached values
   - Embedded procedures do not require `bind` (propagates from outer procedure)

6. **Main procedure**
   - Exported by the resource and called on demand
   - Uses immediate references to static data
   - Calls lazy initialisation procedure


#### Encoder Metadata

Encoder source files contain metadata comments:

```postscript
% --BEGIN ENCODER encodername--
% --EXAM: example input data
% --EXOP: example options
% --RNDR: renlinear|renmatrix|renmaximatrix
% --REQUIRES preamble raiseerror [other deps...]
% --END ENCODER encodername--
```

REQUIRES lists dependencies of the resource in order. It is used by the build
system and is API for users that want to assemble the resources into a PS file
prolog.


### Resource output file structure

Built resource files have a similar structure to their source files, with their
source (packaged or otherwise) wrapped by comments that follow the PostScript
language Document Structuring Conventions.

- `BeginResource:` DSC comment contains VM memory usage that is measured by the build system per-resource by pre-loading all dependencies before measurement, so each resource's VMusage reflects only its own consumption.

Monolithic outputs contain comments that feature a "--BEGIN/END TEMPLATE--" marker pair that users can use to splice the relevant contents into the prolog of a PS document.


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
% latevars procedure is called in main procedure:
%
//resource.latevars /init get exec
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
    % 5. Main encoding logic using //encoder.staticdata and loaded data from latevars
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
    % 6. Build output dictionary
    %
    <<
        /ren /renlinear  % or /renmatrix, /renmaximatrix
        % /sbs [...]     % 1D: space-bar-space widths
        % /pixs [...]    % 2D: row-major pixel array
        /opt options
    >>

    %
    % 7. Conditional rendering
    %
    dontdraw not //renlinear if

    end
}
[/barcode] {null def} forall
bind def
/encoder dup load /uk.co.terryburton.bwipp defineresource pop
```


## User API

```postscript
<barcode data string> <options string or dict> /<encoder> /uk.co.terryburton.bwipp findresource exec
```

Example:
```postscript
10 10 moveto
(\(01\)09521234543213(3103)000123) (segments=4 includetext alttext=TEST)  % Note quoting of parentheses in data
/databarexpandedstacked /uk.co.terryburton.bwipp findresource exec
showpage
```


### Barcode Data Parsing (parseinput.ps.src)

Options `parse` and `parsefnc` preprocess data to allow denoting ASCII control characters and non-data characters (FNC1-4, ECI) as printable text

- Uses `^` as escape character:
  - `^NUL`, `^000`-`^255` (with `parse` option)
  - `^FNC1`, `^ECInnnnnn` (with `parsefnc` option)

GS1 AI syntax is first processed by `gs1process.ps.src` before regular parsing


### Options Processing (processoptions.ps.src)

- Accepts space-separated `key=value` pairs or just `key` (to set boolean to true)
- Options update corresponding PostScript variable in the current dictionary, only if it exists
- Values are type checked against the option's default value type, otherwise error is raised


### Error Handling (raiseerror.ps.src)

- Errors raised by calling raiseerror with error name and user-friendly info string
- Uses standard PostScript `stop` mechanism for custom error handlers
- Error names typically follow pattern: `/bwipp.<resource><ErrorType>`, e.g. `/bwipp.code39badCharacter`


### Intermediate Dictionaries

Encoders create a common dictionary structure expected by their renderer:

**1D Barcodes (renlinear):**
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

**2D Barcodes (renmatrix):**
```postscript
<<
    /ren /renmatrix
    /pixs [1 0 1 0 ...]     % row-major array: 1=black, 0=white
    /pixx width             % symbol width in modules
    /pixy height            % symbol height in modules
    /opt options
>>
```

**MaxiCode (renmaximatrix):**
```postscript
<<
    /ren /renmaximatrix
    /pixs [...]             % 30x29 hexagon grid values
    /opt options
>>
```


## Performance

### Ghostscript Observed Behaviour

- Each `/name value def` has fixed cost; name lookup has similar cost
- Basic stack ops (pop, index, roll) have similar cost to dict ops
- Consecutive stack operations have small marginal cost after initial op

### Optimization Patterns

- Use `//name` immediate lookup for static data (avoids runtime structure allocation cost)
- Mark static arrays/dicts `readonly` (prevents accidental modification)
- Defer expensive computation to lazy init (first-run cost, cached thereafter)
- Prefer stack manipulation over creating intermediate dictionaries

### Anti-patterns

- Creating variables (dictionary entries) in hot loops
- Defining static data in the main procedure (hoist to define time, then use `//name`)
- Computing derived data on every invocation (use latevars)

### Hot Loop Stack Pattern

In high computational complexity loops, avoid `/idx exch def`. Keep loop index
on stack, reference with `index` and finally consume with `roll` (rather than
`pop`):

```postscript
% Bad: Creates dictionary entry each iteration
0 1 k {  % E.g. k from outer loop
    /idx exch def
    % Stuff using "idx" variable...
    arr k idx sub 1 sub get
} for

% Good: Loop index consumed by roll
0 1 k 1 sub {  % idx on stack
    % Stuff using "N index" to access idx on the stack...
    % Finally, roll moves idx to top where we consume it:
    arr k 3 -1 roll sub 1 sub get
} for
```

The RSEC loops in qrcode, datamatrix, pdf417 demonstrate advanced uses of this
pattern, including stack-based access to variables outside of the inner loop.

### Profiling

Simple profiling of the overall runtime for some encoder:

```bash
time gs -q -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=nullpage -c \
  '(build/monolithic/barcode.ps) run
   100 { 0 0 moveto (DATA) (options) /encoder /uk.co.terryburton.bwipp findresource exec } repeat'
```

### Detailed Profiling Results

Large 2D symbols have different runtime bottlenecks, for example:

- QR Code v40          - Mask evaluation is ~75% of overall runtime; RSEC is fast
- Data Matrix 144x144  - RSEC codeword calculation (excluding polynomial generation) is ~75% of overall runtime due to many codeword per block
- Aztec Code 32 layers - RSEC coefficients generation is ~95% of overall runtime due to large Galois fields and many ECC codewords

## Testing

- `tests/run_tests` - Top-level test orchestrator
- `tests/ps_tests/*.ps.test` - Individual encoder tests (run from `build/packaged_resource/Resource` directory)
- `tests/test_*/run` - Integration tests for each build variant

### Test Utilities

- `debugIsEqual` - Compare codeword arrays (used with `debugcws` option)
- `isEqual`      - Compare output arrays (pixs, sbs)
- `isError`      - Verify specific error is raised

### Debug Options

- `dontdraw`      - Return structured dict without rendering
- `debugcws`      - Return codeword array
- `debugbits`     - Return bit array
- `debugecc`      - Return error correction data
- `debughexagons` - Return hexagon positions (MaxiCode)


### Test Patterns

Success test - validate 1D barcode graphical structure via sbs array:

```postscript
(INPUT) (dontdraw) encoder /sbs get
[1 2 1 1 ...] debugIsEqual
```

Success test - validate 2D barcode graphical structure via pixs array:

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

For repetitive tests, use template procedures:

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
/er_tmpl {
    exch { 0 (dontdraw) encoder } dup 3 -1 roll 0 exch put
    exch isError
} def

(INVALID)  /bwipp.encoderBadData  er_tmpl
```
