#!/usr/bin/env bash
# Copy this repo's CI structure into an existing project.
#
#   scripts/adopt.sh /path/to/target-repo
#
# Copies workflows, the release module + its test, the eslint config, the agent
# docs, and the shared ADRs. Files that already exist in the target are skipped
# and listed at the end — nothing is overwritten.
set -euo pipefail

TARGET="${1:-}"
if [ -z "${TARGET}" ]; then
  echo "usage: scripts/adopt.sh <path-to-target-repo>" >&2
  exit 1
fi
if [ ! -d "${TARGET}/.git" ]; then
  echo "adopt: ${TARGET} is not a git repository" >&2
  exit 1
fi

SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FILES=(
  ".github/workflows/ci.yml"
  ".github/workflows/release.yml"
  "src/release/next-version.ts"
  "src/release/next-version.test.ts"
  "bin/next-version.ts"
  "eslint.config.js"
  "tsconfig.json"
  "AGENTS.md"
  "CLAUDE.md"
  "docs/agents/domain.md"
  "docs/agents/issue-tracker.md"
  "docs/agents/triage-labels.md"
  "docs/agents/skills.md"
  "docs/adr/0001-ci-matrix-and-merge-gate.md"
  "docs/adr/0002-branching-and-semver-by-branch-prefix.md"
  "docs/adr/0003-typescript-run-from-source-no-build.md"
  "docs/release-check.md"
  "scripts/bootstrap-labels.sh"
  "scripts/verify-release.sh"
)

SKIPPED=()
COPIED=()

for FILE in "${FILES[@]}"; do
  if [ -e "${TARGET}/${FILE}" ]; then
    SKIPPED+=("${FILE}")
    continue
  fi
  mkdir -p "${TARGET}/$(dirname "${FILE}")"
  cp "${SOURCE}/${FILE}" "${TARGET}/${FILE}"
  COPIED+=("${FILE}")
done

# ADRs land as 0001/0002 only in a repo with no ADRs yet; otherwise renumber by
# hand and reference them from the existing set.
if [ ${#COPIED[@]} -gt 0 ]; then
  printf 'copied:\n'
  printf '  %s\n' "${COPIED[@]}"
fi
if [ ${#SKIPPED[@]} -gt 0 ]; then
  printf 'skipped (already present, merge by hand):\n'
  printf '  %s\n' "${SKIPPED[@]}"
fi

REPO_SLUG="$(git -C "${TARGET}" remote get-url origin 2>/dev/null \
  | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##' || true)"

cat <<EOF

next steps in ${TARGET}:
  1. Replace <owner>/<repo> in AGENTS.md with ${REPO_SLUG:-<owner>/<repo>}.
  2. Delete the "Adopting this template" quote block at the top of AGENTS.md.
  3. package.json: "type": "module", "engines": { "node": ">=22.18" }, scripts
     typecheck ("tsc --noEmit") / lint ("eslint .") / test ("node --test
     src/**/*.test.ts") / verify (all three), and devDependencies @eslint/js,
     eslint ^9, typescript ^5.9, typescript-eslint ^8, @types/node.
  4. Leave package.json "version" at 0.0.0 — git tags are the source of truth.
  5. npm install && npm run verify
  6. scripts/bootstrap-labels.sh  (triage + wayfinder labels)
  7. scripts/verify-release.sh    (asserts every version-bump case)
  8. Protect main: require the ci checks, require a PR.
  9. Already-JS repo? Either rename to .ts incrementally (Node runs both) or
     drop tsconfig.json and the typecheck script and keep the rest.
EOF
