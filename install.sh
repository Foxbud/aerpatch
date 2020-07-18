#!/usr/bin/env sh



ROOT_DIR="$(cd "$(dirname "$(dirname "$(dirname "$0")")")"; pwd -P)"
GAME_BIN="$ROOT_DIR/HyperLightDrifter"
BACKUP_BIN="$ROOT_DIR/HyperLightDrifter.bak"
PATCH_FILE="$ROOT_DIR/aersrc/patch/patch.r2"



rm "$GAME_BIN" || exit 1
cp "$BACKUP_BIN" "$GAME_BIN" || exit 1
radare2 -nwqi "$PATCH_FILE" "$GAME_BIN"
