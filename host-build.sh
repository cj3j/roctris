#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

OUTPUT_DIR="./target"
OUTPUT_BIN="$OUTPUT_DIR/host-build"
mkdir -p "$OUTPUT_DIR"
roc build --linker=legacy --output "$OUTPUT_BIN" ./platform/main-build.roc
"$OUTPUT_BIN"
