---
name: delegate-to-agy
description: Delegate an implementation task to Google Antigravity CLI (agy), then independently review its workspace changes, run relevant verification, and return review findings to the same AGY conversation when remediation is needed. Use when the user explicitly asks Codex to delegate work to AGY or invokes this skill; do not use for ordinary Codex subagents or review-only requests.
---

# Delegate to AGY

Use AGY as an external implementation agent. Codex remains responsible for scope control, independent review, validation, and the final report.

## Preconditions and boundaries

- Treat explicit use of this skill as authorization to send the scoped task and relevant workspace code to AGY. Do not send secrets, tokens, unrelated files, or environment-variable values.
- For private repository content, record a disclosure authorization packet before
  delegation: the trusted user turn, canonical repository, exact read paths or
  content classes, write paths, and exclusions. Verify that a subagent's inherited
  context actually contains that user authorization; a fixed turn count or a
  coordinator relay alone is not proof at a host approval boundary.
- When a Codex subagent will invoke AGY, ensure that worker directly inherits the
  user's explicit external-delegation authorization as trusted input. Some host
  approval surfaces do not treat coordinator-relayed text as equivalent user
  authorization. If launch is rejected at that boundary, do not bypass it or
  repeatedly resend the same relay; create a replacement only with explicit user
  authorization for that topology and direct inheritance.
- Preserve the user's existing changes. Never require a clean worktree, discard changes, create commits, push, install dependencies, or perform external or destructive actions unless the user separately authorized them.
- Run only one write-capable agent in the target workspace at a time. Do not let AGY and another agent edit the same files concurrently.
- Verify `agy` is available with `Get-Command agy` on Windows or `command -v agy` on POSIX, and record `agy --version`.
- Before a write-capable delegation, resolve and record the canonical absolute repository root, `git status --short`, and the relevant diff. If the workspace is not under Git, restrict the task to named paths and use available scoped file comparisons; tell the user when reliable change attribution is not possible.

## Delegate

Build an outcome-focused prompt that includes:

- the requested implementation and acceptance criteria;
- the canonical absolute workspace root and the canonical absolute paths AGY may read or write;
- an instruction to stay inside that root and never search sibling directories, user-home folders, other drives, or guessed paths;
- allowed files or directories and explicit out-of-scope areas;
- the expected final output shape, including required files, directories, and
  objective-specific structural or value invariants;
- relevant repository instructions and existing user changes that must be preserved;
- a prohibition on commits, pushes, destructive cleanup, unrelated refactors, and secret access;
- a request to summarize changed files, validation attempted, and unresolved issues.

Invoke the initial implementation as a fresh headless conversation from the target workspace. Do not pass `--continue` or `--conversation` on this first run. For a write-capable task, set AGY to `accept-edits` mode so an authorized workspace edit does not end as a headless permission soft-denial. Prefer JSON output, a task-appropriate timeout with an explicit unit, and AGY's sandbox:

```text
agy -p "<scoped prompt>" --mode accept-edits --output-format json --print-timeout <duration-with-unit> --sandbox
```

Do not use `--dangerously-skip-permissions` unless the user explicitly authorizes that exact risk after being told it auto-approves AGY tool calls. Prefer scoped AGY permission rules when AGY must run specific commands. It is acceptable for Codex to run validation itself when headless AGY soft-denies a command.

AGY headless execution depends on its cached authenticated profile outside the workspace and on Google network access. In the current Codex environment these are known to be unavailable inside the normal workspace sandbox, so do not perform a sandbox-first AGY attempt. Request narrowly scoped host approval for each exact AGY implementation or remediation invocation and run it once with AGY's own `--sandbox` still enabled. Do not request broad Codex filesystem/network access, approve arbitrary `agy -p` prompts, or interpret a denied host approval as failed AGY authentication.

For unattended automation, read [references/automation.md](references/automation.md) and use [scripts/invoke-agy.ps1](scripts/invoke-agy.ps1) instead of invoking `agy` directly. Create `<workspace>/.agy/task.json` using the documented schema, then run the installed wrapper with only `-TaskFile <absolute-task-path>`. The wrapper derives the workspace from the task-file location, validates all paths, pins safe AGY flags, rejects main Git worktrees, and detects post-run scope drift. Git repositories must use a clean linked worktree; non-Git validation workspaces must be isolated directories named `agy-scratch-*`. A persistent Codex rule may allow the installed wrapper path; generate it with [scripts/install-rule.ps1](scripts/install-rule.ps1), but never allow a general `agy`, `agy -p`, `pwsh`, or `pwsh -Command` prefix. Codex rules load after Codex restarts.

Before the first real invocation, run the wrapper once with `-ValidateOnly`. Put
every final destination needed by a valid result in the initial `write_paths`;
the successful receipt cannot later authorize a broader directory or a moved
output. When practical, complete AGY semantic review and likely remediation before
materializing large ignored dependency or build trees. If validation requires
those trees earlier, record that later wrapper remediation may be ineligible and
prepare the bounded Codex capability handoff instead of deleting the environment.

The unattended prompt prohibits shell, Git, package-manager, test, and network
commands inside AGY. Give AGY explicit read paths and let Codex run validation.
Do not relax this boundary merely because AGY attempted an unapproved discovery
command.

Require a JSON terminal status of `SUCCESS`. Capture the `conversation_id`, response, stderr notices, and any reported validation. A zero process exit alone is insufficient because permission soft-denials may still leave work incomplete.

If a host-authorized AGY run returns a non-`SUCCESS` terminal status:

- Inspect the workspace before deciding what happened. AGY may have left partial changes even when its response claims otherwise.
- Read the structured failure receipt. Retry only when `retryable` is `true`, the
  category is `transient_unavailable`, and there are no workspace changes.
  Permission denial, cancellation, timeout, invalid output, process failure, and
  scope drift are deterministic stop conditions, not retry opportunities.
- A permitted retry is at most one new conversation from the same absolute
  workspace root with the full original task and path boundaries. Do not resume
  the failed conversation; backend restarts or lost workspace context can make a
  resumed agent search unrelated paths.
- If there are changes, do not retry automatically. Review and validate the artifacts, but report that the AGY run itself failed. Independently verified artifacts may still be usable; never relabel the terminal run as successful.
- Stop after that single fresh retry and report the infrastructure failure if it remains non-`SUCCESS`.

## Review and remediate

After AGY finishes:

1. Compare repository state with the recorded baseline and identify the actual scoped changes. Do not attribute pre-existing or concurrent user changes to AGY.
2. Run an objective-specific semantic probe before expensive validation. When the
   recorded baseline did not already satisfy the Definition of Done, require the
   expected non-empty diff for a mutating task and verify the declared final
   output shape or metric: for example required module directories, reduced
   monolith size, unchanged selectors with resolved-value equivalence, or the
   exact behavioral artifact. A valid receipt with an unexplained no-op or wrong
   structure is a concrete finding, not completion.
3. Inspect the implementation independently for correctness, regressions, scope drift, missing tests, and unsafe behavior. Do not accept AGY's summary as review evidence.
4. Run the smallest relevant lint, typecheck, unit, integration, or build checks permitted by the repository. Start focused and expand only when risk warrants it.
   A successful receipt proves task/output binding, not semantic acceptance. For
   exact text bytes across platforms, prefer repository-owned EOL policy and
   verify the immutable committed blob when that is the intended portability
   boundary.
5. If the implementation run completed with `SUCCESS` and material findings remain, send concrete findings back to the same conversation:

```text
agy -p "Address these Codex review findings without changing unrelated code: <findings>" --conversation <conversation_id> --mode accept-edits --output-format json --print-timeout <duration-with-unit> --sandbox
```

6. If the implementation run did not complete with `SUCCESS`, follow its failure
   receipt. Use a fresh conversation only for an authorized retryable transient
   failure; otherwise stop or create a newly scoped task after resolving the
   deterministic cause.
7. Re-review the new diff and rerun affected checks. When no loop budget was
   declared, default to at most two AGY remediation passes. If the user or owning
   coordinator explicitly selected a higher economics-based hard cap, such as 10,
   honor that ceiling. It is not a target: each pass must address a new concrete
   finding or produce changed verification evidence. Stop early on repeated
   no-progress failure, no net diff, deterministic infrastructure failure, scope
   drift, new authority, or an operation AGY cannot perform with its permitted
   tools.

When AGY reports that the remaining work is outside its capability or permitted
tool boundary, stop before the hard cap and hand the task back to Codex. Preserve
the baseline, actual diff, completed acceptance criteria, remaining gap, failed or
unavailable operation, validation evidence, receipt, conversation routing, and the
smallest next action. Codex may finish only the already authorized scope and must
independently review the combined result. Do not describe a valid capability
handoff as an exhausted retry or synthesize AGY `SUCCESS`.

Classify a capability handoff with one concise evidence-backed reason such as
`runtime_materialized`, `runtime_only_finding`, `unsupported_operation`,
`external_disclosure_denied`, or `new_authority_required`. The category explains
why the executor changed; it does not expand Codex's authorized scope.

Stop immediately if AGY changes files outside scope, overwrites user work, requests credentials, or requires new authority. Preserve evidence and ask the user how to proceed.

For unattended work, prefer this phase order when dependencies permit it:

```text
ValidateOnly -> AGY implementation -> semantic probe and review
-> AGY remediation -> runtime materialization -> focused checks -> broad gate
```

A sandbox or host-approval rejection before process creation, a wrapper
validation-only rejection, and a receipt cache hit are not AGY invocations and do
not consume the loop budget. Record them separately from product remediation.
When a pre-process disclosure decision blocks AGY, record `invocations: 0`, the
authorization boundary, and the bounded Codex handoff category. Do not describe
the event as an AGY failure or retry the same relay.

## Final report

Report the AGY version and terminal status, failure category and retryability when
applicable, conversation routing status, files changed, Codex review outcome,
validation commands and results, remediation passes, capability handoff when one
occurred and its category, per-invocation usage deltas from the receipt, and
unresolved risks. Report pre-process decisions, validation-only runs, cache hits,
and real invocations as separate counters; use an explicit zero for a blocked run
that never created an AGY process.
Distinguish AGY's conversation-cumulative counters from each invocation delta;
report unavailable fields as unavailable. Keep raw conversation IDs out of public
issues, trackers, and release evidence.
