#!/usr/bin/env bash

# We don't want -e because we want to capture the exit status of the roc build command.
# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
#set -euxo pipefail

# roc build returns 2 for warnings
RET_WARNING=2

APP_NAME="roctris"
OUTPUT_DIR="./target"
OUTPUT_BIN="$OUTPUT_DIR/$APP_NAME"
mkdir -p "$OUTPUT_DIR"

# run `roc check` first since `roc build` can crash if there are compile errors
roc check "./game/$APP_NAME.roc"
ROC_CHECK_STATUS=$?

if [ $ROC_CHECK_STATUS -ne 0 ]; then
    if [ $ROC_CHECK_STATUS -ne 2 ]; then
        echo "Roc check failed."
        exit 1
    fi
    echo "Roc check had a warning."
else
    echo "Roc check success."
fi

roc build --linker=legacy --output "$OUTPUT_BIN" "./game/$APP_NAME.roc"
ROC_BUILD_STATUS=$?

if [ $ROC_BUILD_STATUS -ne 0 ]; then
    if [ $ROC_BUILD_STATUS -ne 2 ]; then
        echo "Roc build failed."
        exit 1
    fi
    echo "Roc build had a warning."
else
    echo "Roc build success."
fi

echo ""
echo "Launching app..."

 "$OUTPUT_BIN"
