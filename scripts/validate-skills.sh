#!/usr/bin/env bash
# Validate the repository's skill source structure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATUS=0

if [[ ! -d "$REPO_ROOT/skills" ]]; then
  echo "Missing skills directory: $REPO_ROOT/skills" >&2
  exit 1
fi

shopt -s nullglob
skill_dirs=("$REPO_ROOT"/skills/*)

if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "No skills found under $REPO_ROOT/skills" >&2
  exit 1
fi

for skill_dir in "${skill_dirs[@]}"; do
  [[ -d "$skill_dir" ]] || continue

  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_file" ]]; then
    echo "FAIL $skill_name: missing SKILL.md" >&2
    STATUS=1
    continue
  fi

  declared_name="$(awk -F': *' '/^name:/{print $2; exit}' "$skill_file" | tr -d '"'\''')"
  declared_description="$(awk -F': *' '/^description:/{print $2; exit}' "$skill_file")"

  if [[ -z "$declared_name" ]]; then
    echo "FAIL $skill_name: missing name frontmatter" >&2
    STATUS=1
  elif [[ "$declared_name" != "$skill_name" ]]; then
    echo "FAIL $skill_name: name frontmatter is '$declared_name'" >&2
    STATUS=1
  fi

  if [[ -z "$declared_description" ]]; then
    echo "FAIL $skill_name: missing description frontmatter" >&2
    STATUS=1
  fi

  echo "OK $skill_name"
done

if [[ -d "$REPO_ROOT/commands" ]]; then
  command_files=("$REPO_ROOT"/commands/*.md)
  if [[ ${#command_files[@]} -gt 0 ]]; then
    for command_file in "${command_files[@]}"; do
      echo "OK command $(basename "$command_file")"
    done
  fi
fi

exit "$STATUS"
