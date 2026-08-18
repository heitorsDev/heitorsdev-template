#!/usr/bin/env bash
# Create the 5 canonical triage labels in the current repo (idempotent).
# See docs/agents/triage-labels.md.
set -euo pipefail

create() {
  gh label create "$1" --color "$2" --description "$3" --force
}

create "needs-triage"    "d876e3" "Maintainer needs to evaluate this issue"
create "needs-info"      "fbca04" "Waiting on reporter for more information"
create "ready-for-agent" "0e8a16" "Fully specified, ready for an AFK agent"
create "ready-for-human" "1d76db" "Requires human implementation"
create "wontfix"         "ffffff" "Will not be actioned"

echo "triage labels ready"
