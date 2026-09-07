# Delegate to AGY v0.1.5

This release clarifies execution modes and Codex handoffs without changing the
wrapper, task schema, receipt format, or external-executor retry caps.

## Changes

- Ordinary interactive delegation preserves a recorded dirty baseline; unattended
  wrapper execution still requires a clean linked worktree or isolated scratch
  directory. Mode selection makes those prerequisites unambiguous.
- Reaching an AGY cap or capability boundary stops AGY invocation. Codex may finish
  already-authorized work unless the user requires AGY-only completion.
- Host denials cannot be bypassed through an executor change. Unexpected changes
  stop dependent writes while unaffected inspection and validation can continue.
- User-facing summaries focus on outcome, verification, AGY status, Codex handoff,
  and blockers. Detailed counters and routing stay in authorized private records.

## Validation and compatibility

Skill structure, local reference resolution, diff hygiene, and static handoff
scenarios are checked. No new live AGY reliability or model-efficiency claim is
made. Existing task files and receipts remain valid; invocation scripts are
unchanged. The default two remediation passes and one eligible transient retry
remain in place. The existing fake-AGY wrapper regression suite passes without
contacting AGY.

## Install

```text
Use $skill-installer to install mujikawa/delegate-to-agy at ref v0.1.5.
```
