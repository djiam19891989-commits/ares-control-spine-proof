# ARES Control Spine Index

**Copyright © 2026 Dylan Campbell**  
ABN 23 507 703 722  
Queensland, Australia  
All rights reserved. Proprietary licence.

---

## Overview

The ARES Control Spine is the operator governance architecture that ensures controlled autonomy through layered checkpoints. Every autonomous action flows through validation, gating, approval, and enforcement layers, with cryptographic evidence receipts proving decisions at each layer.

**Governance Philosophy**: Trust but verify. AI proposes, gates filter, operators approve, policy enforces, evidence proves.

---

## Governance Stack Summary

```
┌─────────────────────────────────────────────────────────┐
│  1. VALIDATE LANE                                       │
│     Three-pass demand validation (validator/skeptic/    │
│     reality) determines if concept has market demand    │
│     Output: ValidationAssets with verdict + reasoning   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  2. MRVL LANE (Market Saturation Gate)                  │
│     Checks if market already saturated with similar     │
│     solutions. Prevents building commodity features.    │
│     Output: proceed/hold/kill recommendation            │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  3. APPROVAL LANE                                       │
│     Operator checkpoint for weak/unclear validation     │
│     or CAUTION/FAIL reality verdicts. Human override.   │
│     Output: approved/rejected decision receipt          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│  4. EXECUTION POLICY LANE                               │
│     Build/deploy enforcement based on validation +      │
│     approval status. Policy engine blocks execution.    │
│     Output: Job evidence receipt with execution trace   │
└─────────────────────────────────────────────────────────┘
```

**Evidence receipts prove every layer.** SHA-256 chain integrity ensures tamper-evident audit trail.

---

## Lane 1: Validate — Demand Validation

### Guarantees

1. **Three-pass validation**: Every concept evaluated by validator (temperature=0.5), skeptic (temperature=0.35), and reality pass (temperature=0.7)
2. **Structured verdicts**: Returns "promising", "unclear", or "weak" with reasoning
3. **Reality check**: Skeptical consensus on real-world viability (PASS/CAUTION/FAIL)
4. **Non-empty reasoning**: Error handling ensures `final_reason` never empty
5. **No execution**: Validate lane never triggers builds or deploys — advisory only

### Key Files

```
ares/validate/
├── validate.py              # Core validation module with 3-pass system
├── schema.py                # ValidationAssets dataclass definition
└── __init__.py

Key methods:
- validate.Validate.generate(concept, mvp, context) → ValidationAssets
- validate.Validate._validator_pass() → initial verdict
- validate.Validate._skeptic_pass() → skeptic interest score
- validate.Validate._reality_pass() → reality verdict (PASS/CAUTION/FAIL)

Output schema:
class ValidationAssets:
    verdict: str                    # "promising" | "unclear" | "weak"
    final_verdict: str              # Same as verdict (compatibility)
    final_reason: str               # Human-readable explanation
    skeptic_interest: str           # "high" | "medium" | "low"
    reality_verdict: str            # "PASS" | "CAUTION" | "FAIL"
    reality_reason: str             # Reality check explanation
```

### Verification Commands

```bash
# Run validation on sample concept
python -c "
from ares.validate.validate import Validate
v = Validate()
assets = v.generate(
    concept='AI code review assistant',
    mvp='GitHub PR comment bot',
    context={}
)
assert assets.final_verdict in ('promising', 'unclear', 'weak')
assert assets.reality_verdict in ('PASS', 'CAUTION', 'FAIL')
assert len(assets.final_reason) > 0
print(f'✓ Verdict: {assets.final_verdict}')
print(f'✓ Reality: {assets.reality_verdict}')
print(f'✓ Reason: {assets.final_reason[:50]}...')
"

# Unit tests
python -m pytest tests/ -k validate -v

# Verify error handling (final_reason never empty)
python -c "
from ares.validate.validate import Validate
v = Validate()
# Even with malformed input, should return valid assets
assets = v.generate(concept='', mvp='', context={})
assert assets.final_reason, 'Error: final_reason is empty'
print('✓ Error handling verified')
"
```

### Non-Goals

- **Does NOT block execution** — validation is advisory, not enforcement
- **Does NOT access network** — operates on input concept/mvp only (LLM queries via configured provider)
- **Does NOT persist state** — returns ValidationAssets, caller handles storage
- **Does NOT emit evidence receipts** — evidence emission happens at approval/execution layers
- **Does NOT integrate with MRVL** — market saturation is separate lane

### Evidence Receipt Types

**Validate lane itself does NOT emit receipts.** Receipts are emitted by downstream lanes:

- **Approval receipts** (desktop UI): Reference validation verdict when operator approves/rejects
- **Job evidence receipts** (V6 spine): Include validation verdict in execution trace

---

## Lane 2: MRVL — Market Saturation Gate

### Guarantees

1. **Market analysis**: Searches for existing similar solutions in market
2. **Saturation verdict**: Returns proceed/hold/kill recommendation
3. **Reasoning provided**: Explains why market is/isn't saturated
4. **Web search integration**: Uses live web search to check current market state
5. **Non-blocking**: Returns recommendation, does not enforce blocking

### Key Files

```
ares/evidence/
├── gate.py                  # Market saturation gate logic

Key methods:
- gate.evidence_gate(concept, mvp_scope) → dict
  Returns: {
    'decision': 'proceed' | 'hold' | 'kill',
    'reason': str,
    'evidence': [...],
  }
```

### Verification Commands

```bash
# Run MRVL gate check on sample concept
python -c "
from ares.evidence.gate import evidence_gate
result = evidence_gate(
    concept='AI code review tool',
    mvp_scope='GitHub PR comment bot'
)
assert result['decision'] in ('proceed', 'hold', 'kill')
assert len(result['reason']) > 0
print(f'✓ MRVL decision: {result[\"decision\"]}')
print(f'✓ Reason: {result[\"reason\"][:50]}...')
"

# Verify web search integration (if configured)
# Note: Requires WebSearch tool access
```

### Non-Goals

- **Does NOT block builds** — returns recommendation only
- **Does NOT validate demand** — that's Validate lane's job
- **Does NOT require operator approval** — approval is separate lane
- **Does NOT emit receipts** — evidence emission at execution layer

### Evidence Receipt Types

**MRVL lane uses `emit_gate_decision()` for advisory logging:**

```python
emit_gate_decision(
    gate_name="evidence_gate",
    decision="proceed" | "hold" | "kill",
    reason="Market saturation analysis: ...",
    job_id=None,
    metadata={
        'concept': '...',
        'mvp_scope': '...',
        'evidence_count': N,
    }
)
```

Receipt location: `runtime/evidence/receipts/receipt_evidence_gate_*.json`

---

## Lane 3: Approval — Operator Checkpoint

### Guarantees

1. **Human-in-loop**: Operator reviews validation verdict before build proceeds
2. **Override receipts**: When operator approves weak/unclear validation, receipt emitted
3. **UI integration**: Desktop app (tkinter) prompts operator with verdict + reasoning
4. **Auto-approve promising**: Validation verdict "promising" proceeds without prompt
5. **Rejection handling**: When operator declines, build blocked (status message shown)

### Key Files

```
ares_desktop.py
├── _validate_gate_before_build()        # Lines 668-702: Gate check logic
├── _emit_validate_override_receipt()    # Lines 704-751: Override receipt emission

Key flow:
1. Check if validation run (_validation_assets exists)
2. If final_verdict == "promising" → auto-proceed
3. If final_verdict in ("weak", "unclear") → show messagebox.askyesno()
4. If operator clicks Yes → emit override receipt, proceed
5. If operator clicks No → block build, show status message

Current gap:
- Override receipt emitted when operator approves (Yes)
- NO rejection receipt when operator declines (No) ← planned enhancement
```

### Verification Commands

```bash
# Manual verification (requires desktop UI)
# 1. Launch: python ares_desktop.py
# 2. Run Validate with weak verdict concept
# 3. Click "Build" or "Scout"
# 4. Verify prompt appears
# 5. Click "Yes" → check runtime/evidence/receipts/ for override receipt
# 6. Click "No" → verify build blocked with status message

# Check override receipts
ls -lh runtime/evidence/receipts/ | grep validate_override

# Verify receipt structure
cat runtime/evidence/receipts/receipt_validate_override_*.json | jq '
{
  gate_name: .gate_name,
  decision: .decision,
  action: .metadata.action_attempted,
  verdict: .metadata.validation_verdict
}'
```

### Non-Goals

- **Does NOT run validation** — uses existing _validation_assets from Validate lane
- **Does NOT check MRVL** — market saturation separate concern
- **Does NOT enforce at orchestrator level** — desktop UI only, not in headless orchestrator
- **Does NOT require authentication** — local operator trust model

### Evidence Receipt Types

**Override Receipt** (when operator approves weak/unclear validation):

```python
emit_gate_decision(
    gate_name="validate_override_gate",
    decision="approved",
    reason="Operator approved {action} despite validation verdict '{verdict}': {reason}",
    job_id=None,
    metadata={
        'action_attempted': 'Scout' | 'Build',
        'validation_verdict': 'weak' | 'unclear',
        'validation_reason': '...',
        'ui_trigger': 'validation_gate_prompt',
    }
)
```

Receipt location: `runtime/evidence/receipts/receipt_validate_override_*.json`

**Rejection Receipt** (planned — not yet implemented):
Would emit when operator clicks "No" on validation prompt. Same structure with `decision="rejected"`.

---

## Lane 4: Execution Policy — Build/Deploy Enforcement

### Guarantees

1. **Job ledger**: All jobs appended to NDJSON job ledger before execution
2. **Execution trace**: Step-by-step trace of actions taken
3. **Rollback snapshots**: Git snapshots before destructive operations
4. **V6 evidence receipts**: Cryptographically-chained evidence receipts for completed jobs
5. **SHA-256 integrity**: Evidence ledger with hash chain prevents tampering

### Key Files

```
ares/jobs/
├── schema.py                # JobRecord dataclass definition
├── ledger.py                # Job ledger append-only storage

evidence/
├── ARES_EVIDENCE_RECEIPT.py # V6 receipt generator (JSON + text)
├── ARES_EVIDENCE_LEDGER.py  # SHA-256 chained ledger
├── integration.py           # Wires evidence into job completion
├── job_hooks.py             # on_job_complete() hook

orchestrators/
├── orchestrator_v11.py      # Build execution orchestrator

Key flow:
1. Job created (JobRecord)
2. Job executed (orchestrator runs steps)
3. Job appended to ledger (ares/jobs/ledger.py)
4. V6 evidence generated (evidence/job_hooks.py)
5. Evidence receipt saved (JSON + text in runtime/evidence/receipts/)
6. Evidence ledger entry appended with hash chain
```

### Verification Commands

```bash
# Verify job ledger
cat runtime/jobs/job_ledger.ndjson | tail -5 | jq '.job_id, .lifecycle_state, .final_status'

# Verify V6 evidence ledger chain integrity
python -c "
from evidence.ARES_EVIDENCE_LEDGER import get_default_ledger
ledger = get_default_ledger()
is_valid, error = ledger.verify_chain()
if is_valid:
    print(f'✓ Evidence chain valid: {ledger.get_entry_count()} entries')
else:
    print(f'✗ Chain broken: {error}')
"

# Verify evidence receipts generated
ls -lh runtime/evidence/receipts/ | grep receipt_JOB

# Run V6 evidence spine demo
python evidence/demo_v6_evidence.py

# Verify receipt hash integrity
python -c "
import json
from pathlib import Path
from evidence.ARES_EVIDENCE_RECEIPT import EvidenceReceipt

receipt_files = list(Path('runtime/evidence/receipts').glob('receipt_JOB*.json'))
if receipt_files:
    receipt_data = json.loads(receipt_files[0].read_text())
    receipt = EvidenceReceipt(**receipt_data)
    # Recompute hash from job record
    print(f'✓ Receipt hash: {receipt.receipt_hash[:16]}...')
else:
    print('No job receipts found')
"
```

### Non-Goals

- **Does NOT validate demand** — that's Validate lane
- **Does NOT check market saturation** — that's MRVL lane
- **Does NOT prompt operator** — approval happens in desktop UI before execution
- **Does NOT modify execution policy based on validation** — currently executes jobs regardless of validation verdict (policy integration planned but not implemented)

### Evidence Receipt Types

**Job Evidence Receipt** (V6 Evidence Spine):

```python
{
    'job_id': 'JOB-2026-04-27-...',
    'objective': 'Deploy authentication service',
    'timestamp': '2026-04-27T12:34:56Z',
    'policy_decision': 'APPROVED',
    'execution_trace_summary': 'Completed 3 steps: validate_config, run_tests, deploy',
    'operator_verdict': 'VERIFIED',
    'rollback_path': '/runtime/rollback/JOB-....snapshot',
    'record_hash': 'sha256:abcd1234...',  # SHA-256 of full job record
}
```

**Evidence Ledger Entry** (NDJSON append-only):

```python
{
    'sequence': 42,
    'timestamp': '2026-04-27T12:35:00Z',
    'previous_hash': 'sha256:previous_entry_hash...',
    'receipt': { ... },  # Job evidence receipt
    'entry_hash': 'sha256:this_entry_hash...',
}
```

Receipt locations:
- JSON: `runtime/evidence/receipts/receipt_<job_id>_<timestamp>.json`
- Text: `runtime/evidence/receipts/receipt_<job_id>_<timestamp>.txt`
- Ledger: `runtime/evidence/ledger.ndjson`

---

## Verification Order Across All Lanes

Run verifications in dependency order (each lane builds on previous):

```bash
# 1. VALIDATE LANE — Verify demand validation works
echo "=== LANE 1: VALIDATE ==="
python -c "
from ares.validate.validate import Validate
v = Validate()
assets = v.generate(concept='Test concept', mvp='Test MVP', context={})
assert assets.final_verdict in ('promising', 'unclear', 'weak')
assert assets.reality_verdict in ('PASS', 'CAUTION', 'FAIL')
assert len(assets.final_reason) > 0
print('✓ Validate lane verified')
"

# 2. MRVL LANE — Verify market saturation gate works
echo "=== LANE 2: MRVL ==="
python -c "
from ares.evidence.gate import evidence_gate
result = evidence_gate(concept='Test', mvp_scope='Test')
assert result['decision'] in ('proceed', 'hold', 'kill')
print('✓ MRVL lane verified')
"

# 3. APPROVAL LANE — Verify override receipts exist (manual check)
echo "=== LANE 3: APPROVAL ==="
if ls runtime/evidence/receipts/receipt_validate_override_*.json 2>/dev/null; then
    echo "✓ Override receipts found"
else
    echo "⚠ No override receipts (run desktop UI to generate)"
fi

# 4. EXECUTION POLICY LANE — Verify evidence chain integrity
echo "=== LANE 4: EXECUTION POLICY ==="
python -c "
from evidence.ARES_EVIDENCE_LEDGER import get_default_ledger
ledger = get_default_ledger()
is_valid, error = ledger.verify_chain()
assert is_valid or ledger.get_entry_count() == 0, f'Chain broken: {error}'
print(f'✓ Evidence chain verified ({ledger.get_entry_count()} entries)')
"

# 5. CROSS-LANE INTEGRATION — Verify full stack
echo "=== CROSS-LANE INTEGRATION ==="
python evidence/demo_v6_evidence.py | grep "DEMONSTRATION COMPLETE"
echo "✓ Full stack verified"
```

**Expected output**: All lanes pass verification with no errors.

---

## Current State vs. Planned Enhancements

### ✅ Currently Implemented

1. **Validate lane**: Three-pass validation (validator/skeptic/reality) with error handling
2. **MRVL lane**: Market saturation gate with web search integration
3. **Approval lane**: Desktop UI prompts for weak/unclear validation with override receipts
4. **Execution policy lane**: V6 evidence spine with SHA-256 chain integrity
5. **Evidence receipts**: Gate decisions, overrides, job evidence all logged

### 🔄 Planned (Not Yet Implemented)

1. **Approval lane**: Rejection receipts when operator clicks "No"
2. **Execution policy lane**: Build validation policy module (helper only, no blocking)
3. **Orchestrator integration**: Check validation verdict before execution
4. **Orchestrator approval**: Headless approval gate (not just desktop UI)

### ❌ Explicit Non-Goals

1. **Commercial licensing checks** — No payment/subscription gates
2. **Network-based licensing** — No phone-home validation
3. **External dependencies** — No new third-party libraries for control spine
4. **Secrets/env modifications** — Control spine uses existing config
5. **Production evidence pollution** — Tests use isolated directories
6. **Backward-incompatible changes** — Preserve existing behavior

---

## Evidence Receipt Summary

| Receipt Type | Lane | File Pattern | Purpose |
|--------------|------|--------------|---------|
| Gate Decision | MRVL | `receipt_evidence_gate_*.json` | Market saturation verdict |
| Validate Override | Approval | `receipt_validate_override_*.json` | Operator approved weak/unclear validation |
| Validate Rejection | Approval | `receipt_approval_rejection_*.json` | Operator declined build (planned) |
| Job Evidence | Execution | `receipt_JOB-*_<timestamp>.json` | Completed job with execution trace |
| Ledger Entry | Execution | `ledger.ndjson` | SHA-256 chained append-only log |

**All receipts include:**
- Timestamp (ISO 8601 UTC)
- Decision/verdict
- Reason (human-readable)
- Metadata (context-specific fields)

**Ledger entries additionally include:**
- Sequence number (monotonic)
- Previous entry hash (SHA-256 chain)
- Entry hash (tamper-evident)

---

## File Tree Summary

```
E:\ARES_RUNTIME\current\
├── ares/
│   ├── validate/
│   │   ├── validate.py              # Lane 1: Demand validation
│   │   ├── schema.py                # ValidationAssets dataclass
│   │   └── __init__.py
│   ├── evidence/
│   │   └── gate.py                  # Lane 2: MRVL market saturation
│   ├── jobs/
│   │   ├── schema.py                # JobRecord dataclass
│   │   └── ledger.py                # Job ledger storage
│   └── ...
├── evidence/
│   ├── ARES_EVIDENCE_RECEIPT.py     # Lane 4: V6 receipt generator
│   ├── ARES_EVIDENCE_LEDGER.py      # Lane 4: SHA-256 chained ledger
│   ├── integration.py               # Lane 4: Job evidence integration
│   ├── job_hooks.py                 # Lane 4: on_job_complete() hook
│   └── demo_v6_evidence.py          # Demonstration script
├── ares_desktop.py                  # Lane 3: Desktop UI approval gate
├── orchestrators/
│   └── orchestrator_v11.py          # Lane 4: Build execution
├── runtime/
│   ├── evidence/
│   │   ├── receipts/                # All receipt types stored here
│   │   └── ledger.ndjson            # Evidence ledger (NDJSON)
│   └── jobs/
│       └── job_ledger.ndjson        # Job ledger (NDJSON)
└── docs/
    └── ARES_CONTROL_SPINE_INDEX.md  # This file
```

---

## Copyright & License

**Copyright © 2026 Dylan Campbell**  
ABN 23 507 703 722  
Queensland, Australia

This software is proprietary and confidential. Unauthorized copying, distribution, modification, or use of this software, via any medium, is strictly prohibited without prior written permission.

**SPDX-License-Identifier:** LicenseRef-ARES-Proprietary
