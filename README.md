# delegate-to-agy

A Codex skill that delegates a tightly scoped implementation task to Google
Antigravity CLI (`agy`), then requires Codex to independently inspect the
workspace changes and run the relevant verification.

This is a community project. It is not affiliated with or endorsed by OpenAI
or Google.

## What it does

1. Codex records the workspace baseline and defines explicit read, write, and
   out-of-scope paths.
2. AGY implements the requested change in a fresh conversation.
3. The wrapper rejects task-control changes and writes outside the allowlist.
4. Codex reviews the actual diff and runs focused tests independently.
5. Review findings can be returned to the same AGY conversation for bounded
   remediation.

The unattended wrapper also writes a receipt that binds the successful AGY
conversation, task hash, and output hashes. An unchanged successful task can
therefore return a cached result without contacting AGY again.

## Requirements

- Windows with PowerShell 7.
- Codex and Git available on `PATH`.
- Google Antigravity CLI (`agy`) installed and authenticated interactively at
  least once.
- A clean linked Git worktree for repository automation, or an isolated
  non-Git directory named `agy-scratch-*`.

## Install

Clone the skill into the Codex skills directory:

```powershell
$codexRoot = if ($env:CODEX_HOME) {
    $env:CODEX_HOME
} else {
    Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
}

git clone https://github.com/mujikawa/delegate-to-agy.git `
    (Join-Path $codexRoot 'skills\delegate-to-agy')
```

Restart Codex so it discovers the skill. You can then ask Codex to use
`$delegate-to-agy` for a scoped implementation task.

## Optional unattended execution

AGY needs its authenticated host profile and network access, which are not
available inside the normal Codex workspace sandbox. This repository includes
a narrow Codex execution rule for the validated wrapper. Preview the rule
before installing it:

```powershell
Set-Location (Join-Path $codexRoot 'skills\delegate-to-agy')
./scripts/install-rule.ps1
./scripts/install-rule.ps1 -Apply
```

Restart Codex after applying the rule. The generated rule allows only the
installed `invoke-agy.ps1` path. It does not authorize arbitrary `agy`,
`pwsh`, or shell commands.

For the JSON task schema, validation-only mode, receipt behavior, and workspace
requirements, read [Unattended automation](references/automation.md).

## Trust and safety model

- Invoking the skill authorizes sending the scoped task and explicitly listed
  source files to AGY. Do not include secrets, credentials, `.env` files, or
  unrelated proprietary code.
- AGY runs with `--sandbox`; the wrapper does not use
  `--dangerously-skip-permissions`.
- Paths must remain inside the delegated workspace. Rooted paths, `..` escapes,
  reparse-point traversal, overlapping exclusions, dirty baselines, and
  undeclared writes are rejected.
- The unattended wrapper rejects a repository's main worktree. Use a dedicated
  linked worktree so AGY cannot overwrite unrelated local changes.
- Commits, pushes, merges, deployments, dependency installation, and
  destructive cleanup are intentionally outside the wrapper and require
  separate user authorization.
- AGY's success response is not treated as proof. Codex remains responsible for
  reviewing the actual changes and running verification.

## Repository layout

```text
SKILL.md                     Skill entrypoint and review workflow
agents/openai.yaml           Codex UI metadata
references/automation.md     Unattended task schema and invariants
scripts/invoke-agy.ps1       Validated AGY invocation wrapper
scripts/install-rule.ps1     Preview/apply the narrow Codex rule
tests/fixtures/              Linked-worktree validation fixture
```

## Validate the skill

Use the validator bundled with Codex's `skill-creator` skill:

```powershell
python <CODEX_HOME>/skills/.system/skill-creator/scripts/quick_validate.py .
```

`tests/fixtures/linked-worktree` is intentionally checked in with an
unimplemented function. It is an end-to-end delegation fixture: copy the
repository into a linked worktree, delegate the fixture implementation, and
then run:

```powershell
npm test --prefix tests/fixtures/linked-worktree
```

## License

Licensed under the [MIT License](LICENSE). Copyright (c) 2026 mujikawa.
