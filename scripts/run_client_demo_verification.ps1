$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location -LiteralPath $RepoRoot

$Python = Join-Path $RepoRoot ".venv\Scripts\python.exe"
$Tests = @(
    "tests/test_validate_reality.py",
    "tests/test_orchestrator_validation_gate.py",
    "tests/test_orchestrator_validation_gate_runtime_evidence.py",
    "tests/test_operator_approval_ledger.py",
    "tests/test_operator_approval_runtime_probe.py",
    "tests/test_execution_approval_gate.py",
    "tests/test_execution_approval_runtime_probe.py"
)

Write-Host "ARES Client Demo Verification"
Write-Host "Repo: $RepoRoot"
Write-Host ""

if (-not (Test-Path -LiteralPath $Python)) {
    Write-Host "FAIL python runtime missing: $Python" -ForegroundColor Red
    exit 1
}

foreach ($Test in $Tests) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $Test))) {
        Write-Host "FAIL missing required test: $Test" -ForegroundColor Red
        exit 1
    }
}

foreach ($Test in $Tests) {
    Write-Host "RUN  $Test"
    & $Python $Test
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -ne 0) {
        Write-Host "FAIL $Test (exit $ExitCode)" -ForegroundColor Red
        exit $ExitCode
    }
    Write-Host "PASS $Test" -ForegroundColor Green
    Write-Host ""
}

Write-Host "ARES_CLIENT_DEMO_VERIFICATION_OK" -ForegroundColor Green
