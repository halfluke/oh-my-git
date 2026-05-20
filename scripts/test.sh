#!/usr/bin/env bash
# Automated pre-commit checks for Oh My Git (Godot 4).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot4}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
	if command -v godot >/dev/null 2>&1; then
		GODOT=godot
	else
		echo "error: set GODOT to your Godot 4 binary (tried: godot4, godot)" >&2
		exit 1
	fi
fi

echo "Using Godot: $($GODOT --version 2>&1 | head -1)"

echo "==> Static config checks"
grep -q 'GODOT_VERSION: 4.3' .github/workflows/build.yml
grep -q 'barichello/godot-ci:4.3' .github/workflows/build.yml
grep -q 'platform="Linux"' export_presets.cfg
grep -q 'name="Mac OS"' export_presets.cfg
grep -q 'script_export_mode=2' export_presets.cfg
grep -q 'GODOT ?= godot4' Makefile

echo "==> Godot headless tests"
"$GODOT" --headless --path "$ROOT" --script res://tools/run_tests.gd

if [[ "${RUN_EXPORT_TEST:-0}" == "1" ]]; then
	echo "==> Linux export smoke test"
	TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates"
	VERSION="$("$GODOT" --version 2>&1 | head -1 | tr -d '\r\n')"
	if [[ ! -d "${TEMPLATE_DIR}/${VERSION}" ]]; then
		echo "error: export templates missing at ${TEMPLATE_DIR}/${VERSION}" >&2
		echo "Install via Editor → Manage Export Templates, or skip with RUN_EXPORT_TEST=0" >&2
		exit 1
	fi
	OUT_DIR="$(mktemp -d)"
	trap 'rm -rf "$OUT_DIR" build/oh-my-git-linux build/oh-my-git-linux.zip' EXIT
	make linux GODOT="$GODOT"
	test -f build/oh-my-git-linux.zip
	echo "Export OK: build/oh-my-git-linux.zip"
fi

echo "All automated tests passed."
