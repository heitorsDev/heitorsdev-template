# Release check: what each kind of change produces

The bump is decided by the **head branch prefix** of the PR merging into `main`,
applied to the **latest `vX.Y.Z` git tag**. Nothing else — not commit messages,
not `package.json`, not the branch's version-looking suffix.

## The matrix

| Head branch merged into `main` | Latest tag | Tag created | Release |
| ------------------------------ | ---------- | ----------- | ------- |
| `fix/<slug>`                   | `v1.4.2`   | `v1.4.3`    | yes     |
| `feat/<slug>`                  | `v1.4.2`   | `v1.5.0`    | yes     |
| `release/<slug>`               | `v1.4.2`   | `v2.0.0`    | yes     |
| `release/9.9.9`                | `v1.4.2`   | `v2.0.0`    | yes — the name is ignored |
| `docs/<slug>`                  | `v1.4.2`   | none        | no      |
| `chore/<slug>`                 | `v1.4.2`   | none        | no      |
| `feature/<slug>`               | `v1.4.2`   | none        | no — only `feat/` matches |
| `fixes/<slug>`                 | `v1.4.2`   | none        | no — only `fix/` matches |
| `fix/<slug>`                   | none       | `v0.0.1`    | yes     |
| `feat/<slug>`                  | none       | `v0.1.0`    | yes     |
| `release/<slug>`               | none       | `v1.0.0`    | yes     |
| `fix/<slug>`                   | `v1.9.0`, `v1.10.0` | `v1.10.1` | yes — semver sort, not lexical |
| `feat/<slug>`                  | `v0.9.9`   | `v0.10.0`   | yes     |
| `fix/<slug>`                   | `v1.2.3`, `nightly` | `v1.2.4` | yes — non-`v*` tags ignored |
| `fix/a/b/c`                    | `v1.2.3`   | `v1.2.4`    | yes — nested slugs fine |

A merge into a `release/*` branch (rather than into `main`) produces nothing —
the workflow's `if` requires `base.ref == 'main'`.
A closed-but-unmerged PR produces nothing — it requires `merged == true`.

## Running the check

```bash
npm test                      # unit tests for the bump module
scripts/verify-release.sh     # replays release.yml's shell against real git repos
```

`scripts/verify-release.sh` builds a throwaway repo per row above, runs the
workflow step's exact shell body, and asserts the tag that would be pushed. Both
must pass before touching anything in `src/release/`, `bin/next-version.js`, or
`release.yml`.

## Fail-soft, not fail-red

An unrecognised prefix makes `bin/next-version.js` exit non-zero; the workflow
step catches that and exits `0` without setting an output, so the tag and
release steps are skipped by their `if:` guards. A `docs/*` merge therefore shows
a **green** release run that did nothing — that's correct, not a silent failure.
The `::debug::` lines say which branch was rejected if you need to confirm.
