# Adopting this CI structure

Two ways in.

## New repo — use the template

`heitorsdev-ci` is marked as a GitHub template repository:

```bash
gh repo create heitorsDev/<new-repo> --template heitorsDev/heitorsdev-ci --public --clone
```

Then in the clone:

1. `package.json` — set `name`, `description`, keep `"version": "0.0.0"`,
   `"private": true` (unless publishing), `"type": "module"`.
2. `AGENTS.md` — replace `<owner>/<repo>` with the real slug, delete the
   "Adopting this template" quote block, add a `## Domain` section if relevant.
3. `README.md` — replace with the project's own.
4. `docs/adr/` — keep 0001 and 0002 as-is; number the project's own decisions
   from 0003 up.
5. `scripts/bootstrap-labels.sh` — run once.
6. Delete `docs/adopting.md` and `scripts/adopt.sh` (template-only).
7. `npm install && npm run lint && npm test`.

## Existing repo — run the adopt script

```bash
git -C ~/heitorsdev-ci pull
~/heitorsdev-ci/scripts/adopt.sh ~/path/to/existing-repo
```

It copies only files that don't already exist and prints what it skipped plus
the remaining manual steps. Merge skipped files by hand — in particular
`AGENTS.md`/`CLAUDE.md` if the repo already has instructions, and ADR numbering
if `docs/adr/0001-*` is taken.

## Required repo settings (neither path can do this for you)

- **Branch protection on `main`**: require a pull request, require the `ci`
  status checks (`ubuntu-latest` and `windows-latest`) to pass.
- **Actions permissions**: `contents: write` is declared in
  `release.yml`, but Settings → Actions → General → Workflow permissions must
  not be locked to read-only, or the tag push fails.
- **Allow GitHub Actions to create releases** — the default `GITHUB_TOKEN` is
  enough; no PAT is needed.

## Verifying the release path without shipping anything

The bump rule is a plain module, so exercise it directly:

```bash
node bin/next-version.js 1.4.2 fix/typo        # → 1.4.3
node bin/next-version.js 1.4.2 feat/new-thing  # → 1.5.0
node bin/next-version.js 1.4.2 release/next    # → 2.0.0
node bin/next-version.js 1.4.2 docs/readme     # → exits 1, prints nothing
```

`npm test` covers the same table plus malformed input. `docs/release-check.md`
has the full expected matrix.
