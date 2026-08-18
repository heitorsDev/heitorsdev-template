# heitorsdev-template

Template for TypeScript Node repos: [Matt Pocock's engineering
skills](https://github.com/mattpocock/skills) already wired up, a Linux + Windows
merge gate, and releases whose version nobody types by hand.

Extracted from [cc-discord](https://github.com/heitorsDev/cc-discord) and
[session-guard](https://github.com/heitorsDev/session-guard), which had
independently grown the same setup twice — plus the TypeScript layer neither of
them had.

Use it as a GitHub template for new repos, or run `scripts/adopt.sh` to copy the
structure into an existing one.

## What's in it

### CI and release

| Path | What it is |
| ---- | ---------- |
| `.github/workflows/ci.yml` | `npm ci` → `typecheck` → `lint` → `test` on `ubuntu-latest` + `windows-latest`, Node 22. The merge gate. |
| `.github/workflows/release.yml` | On PR merged to `main`: tag + GitHub Release, version computed from the branch prefix. |
| `src/release/next-version.ts` | The bump rule as a tested module — `bumpTypeFromBranch()`, `bumpVersion()`. |
| `src/release/next-version.test.ts` | Its tests (`node --test`, no framework). |
| `bin/next-version.ts` | CLI the release workflow calls. The workflow's shell computes nothing. |
| `scripts/verify-release.sh` | Replays `release.yml`'s shell against throwaway git repos, asserting every bump case. |
| `docs/release-check.md` | The full bump matrix and how to verify it. |

### TypeScript

| Path | What it is |
| ---- | ---------- |
| `tsconfig.json` | Strict + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`, `noEmit`, `erasableSyntaxOnly`, `.ts` import specifiers. |
| `eslint.config.js` | Flat config, type-aware `typescript-eslint` via `projectService`. |
| `package.json` | `typecheck` / `lint` / `test`, plus `verify` running all three. Node `>=22.18`. |

No build step: source is `.ts`, run directly by Node's native type stripping.
What you edit is what runs — see
[ADR 0003](./docs/adr/0003-typescript-run-from-source-no-build.md).

### Agent standards

| Path | What it is |
| ---- | ---------- |
| `AGENTS.md` | The instructions — branching, commits, CI discipline, release rules, TypeScript rules, code quality. |
| `CLAUDE.md` | Points at `AGENTS.md`. Nothing is duplicated between them. |
| `docs/agents/skills.md` | Which skill reads which file, and the flow these repos actually used. |
| `docs/agents/issue-tracker.md` | GitHub Issues via `gh` — every operation the skills need, incl. wayfinder maps and native issue dependencies. |
| `docs/agents/triage-labels.md` | The 5 canonical triage roles → this repo's label strings. |
| `docs/agents/domain.md` | `CONTEXT.md` + `docs/adr/` layout and the rules for consuming them. |
| `scripts/bootstrap-labels.sh` | Create the triage + wayfinder labels. |

The three adapter files are the verbatim output of `/setup-matt-pocock-skills`
for a GitHub-Issues, single-context repo — so **don't re-run that skill** in a
fresh clone unless switching trackers.

### Decisions

| ADR | Subject |
| --- | ------- |
| [0001](./docs/adr/0001-ci-matrix-and-merge-gate.md) | Why the matrix is Linux + Windows, and why CI is the only merge gate |
| [0002](./docs/adr/0002-branching-and-semver-by-branch-prefix.md) | Branching model and semver-by-branch-prefix |
| [0003](./docs/adr/0003-typescript-run-from-source-no-build.md) | TypeScript, erasable syntax only, run from source |

## The release rule in one table

| Branch merged into `main` | Bump | `v1.4.2` becomes |
| ------------------------- | ---- | ---------------- |
| `fix/*` | patch | `v1.4.3` |
| `feat/*` | minor | `v1.5.0` |
| `release/*` | major | `v2.0.0` |
| anything else | none | no tag, no release |

Base version is the latest `vX.Y.Z` tag by semver sort, `0.0.0` if there are
none. `package.json`'s `version` is never synced — git tags are the only source
of truth. Full matrix and edge cases: [`docs/release-check.md`](./docs/release-check.md).

## Quick start

New repo:

```bash
gh repo create heitorsDev/<new-repo> --template heitorsDev/heitorsdev-template --public --clone
cd <new-repo> && npm install && npm run verify
```

Existing repo:

```bash
scripts/adopt.sh ~/path/to/existing-repo
```

Then follow [`docs/adopting.md`](./docs/adopting.md) — in particular branch
protection on `main` and workflow write permissions, which neither path can
configure for you.

## Working on this repo

It follows its own rules: branch `fix/*`, `feat/*`, or `release/*`, PR into
`main`, CI green before merge. Before touching `src/release/`,
`bin/next-version.ts`, or `release.yml`, both `npm run verify` and
`scripts/verify-release.sh` must pass. Adopters can pin a tag.
