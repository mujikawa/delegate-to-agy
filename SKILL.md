---
name: delegate-to-agy
description: Delegate an implementation task to Google Antigravity CLI (agy), then independently review its workspace changes, run relevant verification, and return review findings to the same AGY conversation when remediation is needed. Use when the user explicitly asks Codex to delegate work to AGY or invokes this skill; do not use for ordinary Codex subagents or review-only requests.
---

# Delegate to AGY

Use AGY as an external implementation agent. Codex remains responsible for scope control, independent review, validation, and the final report.

## Preconditions and boundaries

- Treat explicit use of this skill as authorization to send the scoped task and relevant workspace code to AGY. Do not send secrets, tokens, unrelated files, or environment-variable values.
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

Require a JSON terminal status of `SUCCESS`. Capture the `conversation_id`, response, stderr notices, and any reported validation. A zero process exit alone is insufficient because permission soft-denials may still leave work incomplete.

If a host-authorized AGY run returns a non-`SUCCESS` terminal status:

- Inspect the workspace before deciding what happened. AGY may have left partial changes even when its response claims otherwise.
- If there are no changes, retry at most once as a new conversation from the same absolute workspace root with the full original task and path boundaries. Do not resume the failed conversation; backend restarts or lost workspace context can make a resumed agent search unrelated paths.
- If there are changes, do not retry automatically. Review and validate the artifacts, but report that the AGY run itself failed. Independently verified artifacts may still be usable; never relabel the terminal run as successful.
- Stop after that single fresh retry and report the infrastructure failure if it remains non-`SUCCESS`.

## Review and remediate

After AGY finishes:

1. Compare repository state with the recorded baseline and identify the actual scoped changes. Do not attribute pre-existing or concurrent user changes to AGY.
2. Inspect the implementation independently for correctness, regressions, scope drift, missing tests, and unsafe behavior. Do not accept AGY's summary as review evidence.
3. Run the smallest relevant lint, typecheck, unit, integration, or build checks permitted by the repository. Start focused and expand only when risk warrants it.
4. If the implementation run completed with `SUCCESS` and material findings remain, send concrete findings back to the same conversation:

```text
agy -p "Address these Codex review findings without changing unrelated code: <findings>" --conversation <conversation_id> --mode accept-edits --output-format json --print-timeout <duration-with-unit> --sandbox
```

5. If the implementation run did not complete with `SUCCESS`, use a fresh conversation for any authorized corrective implementation instead of resuming the failed conversation.
6. Re-review the new diff and rerun affected checks. Default to at most two AGY remediation passes; after that, report unresolved findings unless the user requested continued iteration.

Stop immediately if AGY changes files outside scope, overwrites user work, requests credentials, or requires new authority. Preserve evidence and ask the user how to proceed.

## Final report

Report the AGY version and terminal status, conversation ID, files changed, Codex review outcome, validation commands and results, remediation passes, and any unresolved risks. Clearly distinguish AGY's claims from checks Codex actually performed.
