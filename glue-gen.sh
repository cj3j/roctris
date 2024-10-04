#!/usr/bin/env bash

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euxo pipefail

# Find the directory where the 'roc' executable is located
ROC_DIR=$(dirname "$(which roc)")

# Check if 'roc' was found
if [ -z "$ROC_DIR" ]; then
    echo "'roc' executable not found in PATH."
    exit 1
fi

# Get the root roc directory
ROC_ROOT_DIR="$ROC_DIR/../.."

# Check if the directory exists
if [ ! -d "$ROC_ROOT_DIR" ]; then
    echo "Roc root directory '$ROC_ROOT_DIR' does not exist."
    exit 1
fi

# Get the RustGlue spec path
RUST_GLUE_SPEC="$ROC_ROOT_DIR/crates/glue/src/RustGlue.roc"

# Check if the glue spec exists
if [ ! -f "$RUST_GLUE_SPEC" ]; then
    echo "RustGlue spec path '$RUST_GLUE_SPEC' does not exist."
    exit 1
fi

# generate the glue
roc glue "$RUST_GLUE_SPEC" platform/crates/ platform/main-glue.roc
