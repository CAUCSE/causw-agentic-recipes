#!/usr/bin/env bash
# Link a skill from this repository into a target project's agent tool directory.

set -euo pipefail

usage() {
  echo "Usage: $0 <skill-name> <project-path> [claude|codex|cursor]" >&2
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 1
fi

SKILL_NAME="$1"
PROJECT_PATH="$2"
TOOL="${3:-claude}"

case "$TOOL" in
  claude) TOOL_DIR=".claude" ;;
  codex) TOOL_DIR=".codex" ;;
  cursor) TOOL_DIR=".cursor" ;;
  *)
    echo "Unsupported tool: $TOOL" >&2
    usage
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SOURCE="$REPO_ROOT/skills/$SKILL_NAME"
PROJECT_ROOT="$(cd "$PROJECT_PATH" && pwd)"
SKILLS_DIR="$PROJECT_ROOT/$TOOL_DIR/skills"
LINK_PATH="$SKILLS_DIR/$SKILL_NAME"

if [[ ! -d "$SKILL_SOURCE" ]]; then
  echo "Skill not found: $SKILL_SOURCE" >&2
  exit 1
fi

if [[ ! -f "$SKILL_SOURCE/SKILL.md" ]]; then
  echo "Missing SKILL.md: $SKILL_SOURCE" >&2
  exit 1
fi

mkdir -p "$SKILLS_DIR"

if [[ -e "$LINK_PATH" || -L "$LINK_PATH" ]]; then
  if [[ -L "$LINK_PATH" ]] && [[ "$(readlink "$LINK_PATH")" == "$SKILL_SOURCE" ]]; then
    echo "Already linked: $LINK_PATH -> $SKILL_SOURCE"
    exit 0
  fi
  echo "Path already exists: $LINK_PATH" >&2
  exit 1
fi

ln -s "$SKILL_SOURCE" "$LINK_PATH"
echo "Linked: $LINK_PATH -> $SKILL_SOURCE"
