#!/bin/bash

# Detect the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Detect where the .repo folder is located relative to the script
if [ -d "$SCRIPT_DIR/../.repo" ]; then
    TARGET_DIR="$SCRIPT_DIR/../.repo/local_manifests"
    REPO_ROOT="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/.repo" ]; then
    TARGET_DIR="$SCRIPT_DIR/.repo/local_manifests"
    REPO_ROOT="$SCRIPT_DIR"
else
    echo "❌ Error: Could not find the .repo folder."
    echo "Make sure this repository clone is located at the root of your Android source."
    exit 1
fi

# Ensure the destination folder exists
mkdir -p "$TARGET_DIR"

echo "=============================================="
echo "  Dynamic Local Manifests Selector"
echo "=============================================="

# 2. Dynamically detect devices (folders containing .xml files)
# Using SCRIPT_DIR explicitly avoids tracking global AOSP manifests if run from root
cd "$SCRIPT_DIR" || exit 1
MAP_DEVICES=($(find . -maxdepth 2 -name "*.xml" -not -path '*/.*' | cut -d'/' -f2 | sort -u))
cd - > /dev/null

if [ ${#MAP_DEVICES[@]} -eq 0 ]; then
    echo "❌ No devices with .xml files were found in the repository."
    exit 1
fi

# Add the exit option to the menu
OPTIONS_DEVICES=("${MAP_DEVICES[@]}" "Exit")

echo "Select the DEVICE:"
select DEVICE in "${OPTIONS_DEVICES[@]}"; do
    case $DEVICE in
        "Exit")
            exit 0
            ;;
        "")
            echo "Invalid option."
            ;;
        *)
            echo "Selected device: $DEVICE"
            break
            ;;
    esac
done

echo ""

# 3. Dynamically detect .xml files inside the selected device folder
cd "$SCRIPT_DIR/$DEVICE" || exit 1
MAP_MANIFESTS=($(ls *.xml 2>/dev/null))
cd - > /dev/null

if [ ${#MAP_MANIFESTS[@]} -eq 0 ]; then
    echo "❌ No .xml files found inside $DEVICE."
    exit 1
fi

OPTIONS_MANIFESTS=("${MAP_MANIFESTS[@]}" "Back/Exit")

echo "Select the MANIFEST:"
select MANIFEST_NAME in "${OPTIONS_MANIFESTS[@]}"; do
    case $MANIFEST_NAME in
        "Back/Exit")
            exit 0
            ;;
        "")
            echo "Invalid option."
            ;;
        *)
            echo "Selected manifest: $MANIFEST_NAME"
            break
            ;;
    esac
done

echo ""
echo "Copying the selected manifest to $TARGET_DIR/manifest.xml..."

# Safe copy using absolute script directory paths
cp "$SCRIPT_DIR/$DEVICE/$MANIFEST_NAME" "$TARGET_DIR/manifest.xml"

if [ $? -eq 0 ]; then
    echo "=============================================="
    echo "✔ Manifest applied successfully!"
    echo "Path: $TARGET_DIR/manifest.xml"
    echo "=============================================="
else
    echo "=============================================="
    echo "❌ Error copying the manifest file."
    echo "=============================================="
fi
