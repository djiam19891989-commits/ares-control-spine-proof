# Client Demo Verification Runner

## What This Proves

`run_client_demo_verification.ps1` runs the local ARES proof-pack checks in a fixed order. It verifies that the validation, MRVL validation gate, operator approval ledger, and execution approval gate lanes import and behave as expected.

The runner uses only the repo-local Python runtime at `.\.venv\Scripts\python.exe`. It does not call external LLMs directly. Evidence-writing tests use isolated temporary ledgers and assert production evidence is unchanged where applicable.

## How To Run

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_client_demo_verification.ps1
```

## Expected Final Output

Each test prints a `PASS` line. A successful full run ends with:

```text
ARES_CLIENT_DEMO_VERIFICATION_OK
```

## Governance Lanes Verified

- Validate reality pass and validation evidence receipt generation.
- MRVL validation gate policy and isolated runtime evidence probe.
- Operator approval ledger mappings and isolated runtime evidence probe.
- Execution approval gate policy and no-evidence runtime probe.
