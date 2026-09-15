#!/usr/bin/env bash
set -euo pipefail

REPO="AluciTech/wiki-scitools"
VERSION=""
DEST_DIR=""
COMMANDS_ONLY=0
NO_CONFIG=0

usage() {
  echo "Usage: curl -fsSL <url>/install.sh | bash -s -- [options] <dest>"
  echo ""
  echo "Arguments:"
  echo "  <dest>   Agent config folder (e.g., .claude/ ~/.claude/ .opencode/ .agents/)"
  echo "           commands/ and skills/ are installed underneath it, and a"
  echo "           wikiScitools config is merged into <dest>/settings.local.json."
  echo ""
  echo "Options:"
  echo "  --version <tag>   Install a specific version (e.g., v1.0.0). Defaults to latest."
  echo "  --commands-only   Skip skills/. Use for agents without skill support (e.g. opencode)."
  echo "  --no-config       Do not touch <dest>/settings.local.json."
  echo "  -h, --help        Show this help."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      if [[ -z "$VERSION" ]]; then
        echo "Error: --version requires a tag argument."
        exit 1
      fi
      shift 2
      ;;
    --commands-only)
      COMMANDS_ONLY=1
      shift
      ;;
    --no-config)
      NO_CONFIG=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      DEST_DIR="$1"
      shift
      ;;
  esac
done

if [[ -z "$DEST_DIR" ]]; then
  usage
  exit 1
fi

# Normalize: dest is the agent root, not the commands folder. Tolerate a legacy
# `<dest>/commands` argument.
DEST_DIR="${DEST_DIR%/}"
DEST_DIR="${DEST_DIR%/commands}"

REF="${VERSION:-main}"
RAW_BASE="https://raw.githubusercontent.com/$REPO/$REF"
TREE_URL="https://api.github.com/repos/$REPO/git/trees/$REF?recursive=1"

# Which top-level dirs to pull.
if [[ "$COMMANDS_ONLY" -eq 1 ]]; then
  ROOTS="commands"
else
  ROOTS="commands skills"
fi

confirm_overwrite() {
  local file="$1"
  if [ -f "$file" ]; then
    printf "%s already exists. Overwrite? [y/N] " "$file"
    read -r answer </dev/tty
    case "$answer" in
      [yY][eE][sS]|[yY]) return 0 ;;
      *) echo "  skipped $file"; return 1 ;;
    esac
  fi
  return 0
}

# List every file path under the selected roots, recursively, via the git trees
# API.
list_files() {
  local tree files pattern
  tree=$(curl -fsSL "$TREE_URL")
  pattern=$(echo "$ROOTS" | tr ' ' '|')
  files=$(echo "$tree" \
    | grep -o '"path": *"[^"]*"' \
    | sed 's/.*"path": *"\([^"]*\)".*/\1/' \
    | grep -E "^($pattern)/" \
    | grep -E '\.(md|json)$')
  if [[ -z "$files" ]]; then
    echo "Error: no files found under [$ROOTS] at ref $REF" >&2
    exit 1
  fi
  echo "$files"
}

install_file() {
  local path="$1"
  local dest="$DEST_DIR/$path"

  if confirm_overwrite "$dest"; then
    mkdir -p "$(dirname "$dest")"
    curl -fsSL "$RAW_BASE/$path" -o "$dest"
    echo "  installed $dest"
  fi
}

TEMPLATE_PATH="docs/templates/settings.local.example.json"

# Merge the wikiScitools config block into <dest>/settings.local.json. Never
# clobbers the file: the agent's own settings (permissions, env, ...) are
# preserved, and an existing wikiScitools block is left exactly as the user
# edited it.
install_config() {
  local target="$DEST_DIR/settings.local.json"
  local tmpl merged

  # Already configured anywhere on the lookup path? Leave everything alone.
  for f in "$DEST_DIR/settings.local.json" "$HOME/.claude/settings.local.json"; do
    if [ -f "$f" ] && grep -q '"wikiScitools"' "$f"; then
      echo "Config already present in $f - left untouched."
      return 0
    fi
  done
  for f in "./wiki-scitools.config.json" "$HOME/.claude/wiki-scitools.config.json" \
           "$HOME/.config/wiki-scitools/config.json"; do
    if [ -f "$f" ]; then
      echo "Legacy config found at $f - left untouched."
      echo "  -> current layout is a wikiScitools block in settings.local.json; migrate when convenient."
      return 0
    fi
  done

  tmpl=$(mktemp) || return 1
  if ! curl -fsSL "$RAW_BASE/$TEMPLATE_PATH" -o "$tmpl"; then
    echo "Warning: could not fetch $TEMPLATE_PATH - skipping config."
    rm -f "$tmpl"
    return 0
  fi

  mkdir -p "$DEST_DIR"

  if [ ! -f "$target" ]; then
    mv "$tmpl" "$target"
    echo ""
    echo "Created $target"
    echo "  -> EDIT IT: set wikiScitools.knowledgeBase to your wiki's absolute path."
    return 0
  fi

  # File exists and has no wikiScitools block: merge, preserving every existing
  # key.
  merged=$(mktemp) || { rm -f "$tmpl"; return 1; }
  if command -v jq >/dev/null 2>&1; then
    jq -s '.[0] + {wikiScitools: .[1].wikiScitools}' "$target" "$tmpl" > "$merged" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$target" "$tmpl" "$merged" <<'PY' 2>/dev/null
import json, sys
cur = json.load(open(sys.argv[1]))
tpl = json.load(open(sys.argv[2]))
cur["wikiScitools"] = tpl["wikiScitools"]
json.dump(cur, open(sys.argv[3], "w"), indent=2, ensure_ascii=False)
open(sys.argv[3], "a").write("\n")
PY
  else
    : > "$merged"
  fi

  if [ -s "$merged" ]; then
    cp "$target" "$target.bak"
    mv "$merged" "$target"
    echo ""
    echo "Merged wikiScitools config into $target (backup: $target.bak)"
    echo "  -> EDIT IT: set wikiScitools.knowledgeBase to your wiki's absolute path."
  else
    mv "$tmpl" "$DEST_DIR/settings.local.wiki-scitools.example.json"
    echo ""
    echo "Warning: neither jq nor python3 available - could not merge safely."
    echo "  Template written to $DEST_DIR/settings.local.wiki-scitools.example.json"
    echo "  -> copy its wikiScitools block into $target by hand."
  fi
  rm -f "$tmpl" "$merged"
}

echo "Installing [$ROOTS] into $DEST_DIR/ (ref: $REF)"
echo ""

while IFS= read -r f; do
  install_file "$f"
done <<< "$(list_files)"

if [[ "$NO_CONFIG" -eq 0 ]]; then
  install_config
fi

echo ""
echo "Done."
