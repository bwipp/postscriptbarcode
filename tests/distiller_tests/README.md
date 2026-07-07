# Distiller test variant

Run the BWIPP test suite against Adobe Acrobat Distiller.

## Requirements

- `acrodist.exe` from an Acrobat install, or a portable tree built by
  `assemble-distiller.sh` below. Not included here; supply your own licensed
  copy.
- `build/monolithic/barcode.ps` (`make monolithic`).
- Windows with PowerShell.

## Build a portable Distiller

`assemble-distiller.sh` builds a self-contained Distiller tree from an Acrobat
archive you are licensed to use. Requires `7z`, `unshield`, `sha256sum`.

One archive known to work is the Internet Archive item `adobe-acrobat-5.0.1.7z`
(148,758,180 bytes, example SHA-256
`446c06ae42c4d71d0298188ad2587178708b58a0e04545efb4035078ec1b2477`; override
`EXPECT_SHA256` for a different archive):

```sh
curl -fLo 'Adobe Acrobat 5.0.1.7z' \
  https://archive.org/download/adobe-acrobat-5.0.1.7z/Adobe%20Acrobat%205.0.1.7z
tests/distiller_tests/assemble-distiller.sh 'Adobe Acrobat 5.0.1.7z' ./out
# -> ./out/Distiller/
```

## Run

`barcode.ps` must be built where the toolchain is (Ghostscript, Perl, make) —
typically not the Windows host — and supplied to the runner.

From a POSIX shell, which builds it and pushes it with the harness, provisions
the host from `DIST_SRC`, runs, and relays the exit code (the host must be
reachable over SSH with PowerShell as its default shell):

```sh
make -j "$(nproc)" monolithic
HOST=user@winhost DIST_SRC=./out/Distiller tests/distiller_tests/remote.sh
```

Or directly on the Windows host, once a built `barcode.ps` has been copied over:

```powershell
pwsh tests/distiller_tests/run.ps1 `
  -Distiller C:\path\to\Distiller\acrodist.exe `
  -Monolithic C:\path\to\barcode.ps
```

| `run.ps1` parameter | Default          | Purpose                          |
|---------------------|------------------|----------------------------------|
| `-Distiller`        | `$env:ACRODIST`  | path to `acrodist.exe`            |
| `-Monolithic`       | repo build path  | built `barcode.ps`                |
| `-Timeout`          | `900`            | per-file timeout in seconds       |
| `-Skip`             | *(empty)*        | test names to skip                |
| `-Filter`           | `*`              | restrict to matching test names   |

Prints `PASS`/`FAIL`/`SKIP` per file with a summary, and exits non-zero on
failure.
