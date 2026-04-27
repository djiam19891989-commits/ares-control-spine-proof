param(
    [switch]$NoOpenDocs
)

$ErrorActionPreference = "Stop"
$Root = "E:\ARES_RUNTIME\current"
Set-Location $Root

function Step {
    param([string]$Text)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
}

function Wait-Step {
    param([string]$Text = "Press ENTER when ready...")
    Write-Host ""
    Read-Host $Text | Out-Null
}

function Say {
    param([string[]]$Lines)
    Write-Host ""
    Write-Host "SAY:" -ForegroundColor Yellow
    foreach ($Line in $Lines) {
        Write-Host $Line -ForegroundColor White
    }
}

Clear-Host

Step "ARES CLIENT DEMO RELAY BOOTSTRAP"

Write-Host "This relay walks you through the demo recording." -ForegroundColor White
Write-Host "It does not modify code, commit, push, or change evidence files." -ForegroundColor Green
Write-Host "Repo: $Root" -ForegroundColor Green

Wait-Step "Press ENTER to run pre-flight checks..."

Step "1. Git state"
git status --short --branch
if ($LASTEXITCODE -ne 0) { exit 1 }

Step "2. Latest proof/demo commits"
git log --oneline --decorate -10
if ($LASTEXITCODE -ne 0) { exit 1 }

Step "3. Checking demo documents"

$Docs = @(
    "docs\ARES_ONE_PAGE_CAPABILITY_BRIEF.md",
    "docs\ARES_CONTROL_SPINE_INDEX.md",
    "docs\ARES_CLIENT_DEMO_PROOF_PACK.md"
)

foreach ($Doc in $Docs) {
    $Full = Join-Path $Root $Doc
    if (-not (Test-Path $Full)) {
        Write-Host "MISSING: $Doc" -ForegroundColor Red
        exit 1
    }
    Write-Host "FOUND: $Doc" -ForegroundColor Green
}

if (-not $NoOpenDocs) {
    try {
        code $Docs[0] $Docs[1] $Docs[2]
        Write-Host "Opened demo docs in VS Code." -ForegroundColor Green
    } catch {
        Write-Host "Could not auto-open VS Code. Open these manually:" -ForegroundColor Yellow
        foreach ($Doc in $Docs) { Write-Host "- $Doc" }
    }
}

Step "4. Start recording"

Say @(
    "ARES is a governed autonomous engineering runtime.",
    "The point is not just that AI can do work.",
    "The point is that ARES can prove what was proposed, validated, gated,",
    "approved or rejected by the operator, and verified through evidence receipts."
)

Wait-Step "Start your screen recorder now, then press ENTER..."

Step "5. Show document 1: One-page capability brief"

Write-Host "Open tab: docs/ARES_ONE_PAGE_CAPABILITY_BRIEF.md" -ForegroundColor Green
Say @(
    "This is the short client-facing brief.",
    "It explains ARES as a governed autonomous engineering runtime:",
    "validation, MRVL gating, operator approval, execution policy, and evidence receipts."
)

Wait-Step "After showing the brief, press ENTER..."

Step "6. Show document 2: Control Spine Index"

Write-Host "Open tab: docs/ARES_CONTROL_SPINE_INDEX.md" -ForegroundColor Green
Say @(
    "This is the Control Spine Index.",
    "It maps the sealed governance lanes:",
    "Validate decides, MRVL gates, Operator approves, Execution policy classifies risk.",
    "Each lane is frozen with commits and tags."
)

Wait-Step "After showing the Control Spine Index, press ENTER..."

Step "7. Show document 3: Client Demo Proof Pack"

Write-Host "Open tab: docs/ARES_CLIENT_DEMO_PROOF_PACK.md" -ForegroundColor Green
Say @(
    "This proof pack is the client-facing evidence document.",
    "It explains what ARES can currently prove, what is verified by tests,",
    "and what is deliberately out of scope."
)

Wait-Step "After showing the proof pack, press ENTER..."

Step "8. Run one-command verification"

Say @(
    "Now I will run the client demo verification runner.",
    "This executes the governance proof tests in order."
)

Wait-Step "Press ENTER to run .\scripts\run_client_demo_verification.ps1..."

.\scripts\run_client_demo_verification.ps1
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "DEMO VERIFICATION FAILED. Stop recording and debug." -ForegroundColor Red
    exit 1
}

Step "9. Verification passed"

Say @(
    "The final ARES_CLIENT_DEMO_VERIFICATION_OK line means the governance proof stack passed end-to-end.",
    "The simulated warning lines are intentional.",
    "They prove ARES handles evidence write failures without crashing the governance flow",
    "or polluting production evidence."
)

Wait-Step "After explaining the verification output, press ENTER..."

Step "10. Show tagged proof history"

Say @(
    "Each major governance lane is frozen with a Git tag.",
    "That makes the proof versioned, repeatable, and auditable."
)

Wait-Step "Press ENTER to show git log..."

git log --oneline --decorate -12
if ($LASTEXITCODE -ne 0) { exit 1 }

Step "11. Closing line"

Say @(
    "ARES is governed autonomy for engineering workflows.",
    "It is not just an AI agent.",
    "It is a control plane for validating, gating, approving, and proving autonomous engineering decisions."
)

Write-Host ""
Write-Host "DEMO COMPLETE." -ForegroundColor Green
Write-Host "Stop recording now." -ForegroundColor Green
