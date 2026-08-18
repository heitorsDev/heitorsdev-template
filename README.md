# heitorsdev-ci

Shared CI structure for heitorsDev Node projects, extracted from
[cc-discord](https://github.com/heitorsDev/cc-discord) and
[session-guard](https://github.com/heitorsDev/session-guard), which had grown the
same setup twice.

Use it as a GitHub template for new repos, or run `scripts/adopt.sh` to copy it
into an existing one.

## What's in it

| Path | What it is |
| ---- | ---------- |
| `.github/workflows/ci.yml` | `npm ci` → `npm run lint` → `npm test` on `ubuntu-latest` + `windows-latest`. Merge gate. |
| `.github/workflows/release.yml` | On PR merged to `main`: tag + GitHub Release, version computed from the branch prefix. |
| `src/release/next-version.js` | The bump rule as a tested module — `bumpTypeFromBranch()`, `bumpVersion()`. |
| `src/release/next-version.test.js` | Its unit tests (`node --test`, no framework). |
| `bin/next-version.js` | CLI wrapper the release workflow calls. The workflow's shell computes nothing. |
| `eslint.config.js` | Flat config, `@eslint/js` recommended + Node globals. |
| `AGENTS.md` / `CLAUDE.md` | Agent guidelines — branching, commits, CI discipline, release rules, code quality. `CLAUDE.md` only points at `AGENTS.md`. |
| `docs/adr/0001-…` | Why the matrix is Linux + Windows and why CI is the only merge gate. |
| `docs/adr/0002-…` | Branching model and semver-by-branch-prefix. |
| `docs/agents/` | Issue tracker, triage labels, and domain-doc conventions the skills read. |
| `docs/adopting.md` | Adoption checklist, including the repo settings no script can set. |
| `docs/release-check.md` | The full bump matrix and how to verify it. |
| `scripts/adopt.sh` | Copy the structure into an existing repo (never overwrites). |
| `scripts/bootstrap-labels.sh` | Create the 5 canonical triage labels. |
| `scripts/verify-release.sh` | Replay `release.yml`'s shell against throwaway git repos, asserting every bump case. |

## The release rule in one table

| Branch merged into `main` | Bump | `v1.4.2` becomes |
| ------------------------- | ---- | ---------------- |
| `fix/*` | patch | `v1.4.3` |
| `feat/*` | minor | `v1.5.0` |
| `release/*` | major | `v2.0.0` |
| anything else | none | no tag, no release |

Base version is the latest `vX.Y.Z` tag by semver sort, `0.0.0` if there are
none. `package.json`'s `version` is never synced — git tags are the only source
of truth. Full matrix and edge cases: `docs/release-check.md`.

## Quick start

New repo:

```bash
gh repo create heitorsDev/<new-repo> --template heitorsDev/heitorsdev-ci --public --clone
cd <new-repo> && npm install && npm run lint && npm test
```

Existing repo:

```bash
scripts/adopt.sh ~/path/to/existing-repo
```

Then follow `docs/adopting.md` — in particular branch protection on `main` and
workflow write permissions, which neither path can configure for you.

## Working on this repo

It follows its own rules: branch `fix/*`, `feat/*`, or `release/*`, PR into
`main`, CI green before merge. Before touching `src/release/`,
`bin/next-version.js`, or `release.yml`, both `npm test` and
`scripts/verify-release.sh` must pass. Adopters can pin a tag.
