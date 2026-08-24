# Delegate to AGY v0.1.1

This release makes unattended AGY failures explicit and keeps retries bounded to
evidence-backed transient service outages.

## Highlights

- Structured `NEEDS_FOLLOWUP` receipts classify cancellation, permission denial,
  timeout, transient unavailability, invalid terminal output, process errors,
  terminal errors, and scope drift.
- Only an unchanged `transient_unavailable` result is eligible for one fresh
  retry; deterministic failures stop without consuming another AGY invocation.
- Failure receipts omit raw conversation IDs and error text from durable public
  evidence.
- AGY is instructed to use workspace-native read and edit tools without shell,
  Git, package-manager, test, or network commands; Codex performs validation.
- Fake-AGY regression tests cover failure classification, receipt privacy, safe
  flags, and prompt boundaries.
- A real AGY 1.1.19 scratch-workspace pilot verified `--sandbox`, native file
  editing, exact LF output, receipt binding, and cache validation.

## Installation

Ask Codex:

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.1.
```

Restart or reload Codex after installation. AGY must already be installed and
authenticated interactively. For unattended execution, preview the narrow rule
with `scripts/install-rule.ps1` before applying it, then restart Codex again.

## Safety boundary

This release keeps `--sandbox` and never uses AGY's dangerous permission bypass.
It does not authorize retries, commits, pushes, merges, deployments, dependency
installation, destructive cleanup, arbitrary shell execution, or secret access.
AGY terminal `SUCCESS` and a valid receipt remain execution evidence; Codex must
still inspect actual changes and run the required acceptance checks.
