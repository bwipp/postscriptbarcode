# Barcode Writer in Pure PostScript
# https://bwipp.terryburton.co.uk
#
# Copyright (c) 2004-2026 Terry Burton
#
#
# Run the PostScript test suite against Adobe Acrobat Distiller. Each test
# file runs in its own Distiller invocation since a test failure quits the
# interpreter. Requires build/monolithic/barcode.ps (make monolithic) and a
# Distiller install (see README.md).
#
#   -Distiller <path>   acrodist.exe (default: $env:ACRODIST)
#   -Monolithic <path>  built barcode.ps (default: build/monolithic/barcode.ps)
#   -Timeout <sec>      per-file timeout in seconds (default: 900)
#   -Skip <names>       space-separated test names to skip
#   -Filter <glob>      restrict to matching test names (default: *)

param(
    [string]$Distiller = $env:ACRODIST,
    [string]$Monolithic = "",
    [int]$Timeout = 900,
    [string]$Skip = "",
    [string]$Filter = "*"
)

$ErrorActionPreference = "Continue"

$test = $PSScriptRoot
$root = (Resolve-Path (Join-Path $test "..\..")).Path
if (-not $Monolithic) { $Monolithic = Join-Path $root "build\monolithic\barcode.ps" }
$testsdir   = Join-Path $root "tests\ps_tests"
$testutils  = Join-Path $testsdir "test_utils.ps"
$fontalias  = Join-Path $test "fontalias.ps"

# Treat a missing or bogus path as "interpreter not available" and skip.
if (-not $Distiller -or -not (Test-Path $Distiller)) {
    Write-Output "SKIPPED distiller not available"
    exit 0
}
if (-not (Test-Path $Monolithic)) {
    Write-Output "FAIL missing $Monolithic (run make first)"
    exit 1
}

$distdir = Split-Path $Distiller
$version = (Get-Item $Distiller).VersionInfo.FileVersion
$skipset = @($Skip -split '\s+' | Where-Object { $_ })

$work = Join-Path $env:TEMP ("distiller_tests_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null

$faF = $fontalias  -replace '\\','/'
$tuF = $testutils  -replace '\\','/'
$moF = $Monolithic -replace '\\','/'

$files = Get-ChildItem (Join-Path $testsdir "$Filter.ps.test") | Sort-Object Name

Write-Output "Running tests/distiller_tests with Acrobat Distiller $version"
Write-Output "$($files.Count) test files"

$pass = 0; $skipped = 0; $failed = 0
try {
    foreach ($f in $files) {
        $name = $f.Name -replace '\.ps\.test$',''
        if ($skipset -contains $name) { Write-Output "SKIP $name"; $skipped++; continue }

        $drv = Join-Path $work "$name.ps"
        $log = Join-Path $work "$name.log"
        $tfF = $f.FullName -replace '\\','/'
        # Each file runs in its own instance: fontalias supplies the base-14
        # font names, then the shared test utilities, library and test file.
        $driver = "%!PS-Adobe-3.0`n" +
                  "($faF) run`n($tuF) run`n($moF) run`n($tfF) run`n" +
                  "(FILE-PASSED\n) print flush`n"
        Set-Content -Path $drv -Value $driver -Encoding ASCII

        $sw = [Diagnostics.Stopwatch]::StartNew()
        $p = Start-Process -FilePath $Distiller -ArgumentList "/N","/Q",$drv `
                 -PassThru -WorkingDirectory $distdir -WindowStyle Hidden
        $ok = $p.WaitForExit($Timeout * 1000)
        $sw.Stop()
        $secs = "{0:0.00}" -f $sw.Elapsed.TotalSeconds

        if (-not $ok) {
            try { $p.Kill() } catch {}
            Write-Output "FAIL $name (${secs}s)"
            Write-Output "  timeout after ${Timeout}s"
            $failed++
            continue
        }

        $t = if (Test-Path $log) { Get-Content $log -Raw } else { "" }
        if ($t -match "FILE-PASSED" -and
            $t -notmatch "testError|stackImbalance|dict leak|global VM leak|%%\[ Error") {
            Write-Output "PASS $name (${secs}s)"
            $pass++
        } else {
            Write-Output "FAIL $name (${secs}s)"
            ($t -replace "`r","" -split "`n" | Select-Object -Last 40) |
                ForEach-Object { Write-Output $_ }
            $failed++
        }
    }
} finally {
    Remove-Item $work -Recurse -Force -EA SilentlyContinue
}

Write-Output "distiller tests: $pass passed, $skipped skipped, $failed failed"
exit ([int]($failed -ne 0))
