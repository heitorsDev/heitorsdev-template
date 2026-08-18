# AGENTS.md

Single source of instructions for agents working in this repo. `CLAUDE.md` only
points here — never duplicate content between the two.

> **Adopting this template**: replace `<owner>/<repo>` below with the real slug
> (`scripts/adopt.sh` does it for you), then delete this quote block and add a
> `## Domain` section if the repo has one. Everything else is meant to survive
> verbatim.

## Branching

- One branch per ticket. Prefix carries the release meaning:
  - `fix/<slug>` → patch release on merge to `main`
  - `feat/<slug>` → minor release on merge to `main`
  - `release/<slug>` → major release on merge to `main` (integration branch
    that stages several tickets; `release/next` is as valid as `release/0.2.0`)
  - anything else (`docs/*`, `chore/*`, `test/*`) → no release, no tag
- Granular commits: one small change per commit. Never one squashed blob per
  ticket.
- `main` is reached **only** through a pull request. No direct pushes.
- A `feat/*` or `fix/*` branch may merge into a `release/*` branch to stage
  work; that merge releases nothing by itself.

## Commits and PRs

- Write commit messages and PR bodies in normal prose — imperative subject,
  no trailing period, body explaining *why* when the diff doesn't say it.
- Conventional-commit syntax is **not** used. The branch prefix is the only
  release signal; do not add commit-message discipline as a second mechanism.
- Never `git push --force` to `main` or to any branch with an open PR.
- Do not commit or push unless explicitly asked.

## CI is the merge gate

`.github/workflows/ci.yml`:

- Triggers: `pull_request` (any base — covers `feat/*` → `release/*` and
  `release/*` → `main`) and `push` to `release/**`.
- Matrix: `ubuntu-latest` + `windows-latest`, `fail-fast: false`.
- Steps: `npm ci`, `npm run lint`, `npm test`.

Rules that keep it meaningful:

- **The Windows leg is a portability check, not a support claim.** Most logic
  is platform-independent; a stray POSIX-path or separator assumption is a real
  bug regardless of what ships. Keep OS-specific resolvers out of the tested
  path, or branch on `process.platform` — never let an import-time resolver
  throw on Windows.
- **No test may call a filesystem resolver's default.** Every test injects its
  own directory. This is what keeps the Windows leg green.
- **No live anything in CI**: no network, no real external process, no real
  credentials, no live session. Fixtures and injected boundaries only.
- **Before opening a PR, run `npm run lint && npm test` locally.** Reporting
  work as done without them is a false completion.
- **The release workflow is not a gate** and must never be relied on as one.

## Releases

`.github/workflows/release.yml` fires on `pull_request` `closed`, guarded by
`merged == true`, base `main`, and a `fix/`/`feat/`/`release/` head branch.

- Base version = latest `vX.Y.Z` git tag by semver sort
  (`git tag --list 'v*' --sort=-v:refname`). Never a tag date, never a branch
  name, never a file.
- Bump size comes from the head branch prefix (see **Branching**). A
  `release/*` merge is always major, regardless of what it staged.
- Output: a `vX.Y.Z` tag pushed to `origin` plus a GitHub Release created with
  `--generate-notes`.
- **`package.json`'s `version` is not kept in sync.** Git tags are the sole
  source of truth — leave it at `0.0.0` and never bump it in a PR.
- **The bump rule is a tested module, not shell.** `src/release/next-version.js`
  exports `bumpTypeFromBranch()` and `bumpVersion()`; `bin/next-version.js` is
  the CLI the workflow calls. The workflow's `run:` block computes nothing
  itself. Change the rule in the module and its test, never in YAML.
- Never create tags or GitHub Releases by hand. No human types a version number
  anywhere.
- Before changing anything in `src/release/`, `bin/next-version.js`, or
  `release.yml`, run both `npm test` and `scripts/verify-release.sh` (the latter
  replays the workflow's shell against throwaway git repos and asserts every
  bump case). The full matrix lives in `docs/release-check.md`.
- Out of scope: changelog generation, registry publishing, marketplace
  submission.

## Agent skills

### Issue tracker

GitHub Issues (`gh` CLI), repo `<owner>/<repo>`. See `docs/agents/issue-tracker.md`.

### Triage labels

Standard 5 labels: `needs-triage`, `needs-info`, `ready-for-agent`,
`ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.
Bootstrap them in a fresh repo with `scripts/bootstrap-labels.sh`.

### Domain docs

Single-context — `CONTEXT.md` + `docs/adr/` at repo root. See
`docs/agents/domain.md`.

## Code quality

- Never duplicate code. If the same logic (or near-identical logic) is needed
  in two places, extract it into a shared module and have both call sites use
  it — don't copy/adapt it a second time.
- Zero runtime dependencies by default. Embed the small amount of protocol or
  glue code needed rather than taking a dependency. Dev dependencies for
  lint/test only.
- Module layout: `vendors` / `controller` / `service`. Entry points (hooks,
  bins, handlers) are thin stdin/stdout adapters over a `service.js` that holds
  the logic and takes its I/O boundaries as injectable options.
- Every decision worth arguing about lands as an ADR in `docs/adr/`, numbered
  sequentially, with a `## Status` / `## Context` / `## Decision` /
  `## Consequences` shape. Superseding is allowed; rewriting history is not.
