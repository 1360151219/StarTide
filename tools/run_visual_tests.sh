#!/usr/bin/env bash

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

"$GODOT" --path "$ROOT" --script res://tools/test_responsive_screenshots.gd
