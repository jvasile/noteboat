#!/bin/bash
# Generate version.dart with build timestamp and auto-increment build number

# Get build mode (debug or release), default to release
MODE=${1:-release}

# Get version from pubspec.yaml
VERSION_LINE=$(grep '^version:' pubspec.yaml | sed 's/version: //')
VERSION_NUM=$(echo "$VERSION_LINE" | cut -d'+' -f1)
BUILD_NUM=$(echo "$VERSION_LINE" | cut -d'+' -f2)

# Increment build number
NEW_BUILD_NUM=$((BUILD_NUM + 1))

# Update pubspec.yaml with new build number
sed -i "s/^version: .*/version: ${VERSION_NUM}+${NEW_BUILD_NUM}/" pubspec.yaml

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')

# For debug builds, include build number. For release, just version number
if [ "$MODE" = "debug" ]; then
    DISPLAY_VERSION="${VERSION_NUM}+${NEW_BUILD_NUM}"
else
    DISPLAY_VERSION="${VERSION_NUM}"
fi

# Generate version.dart
cat > lib/version.dart << EOF
// This file is auto-generated at build time
// DO NOT EDIT - will be overwritten by build process
const String appVersion = '$DISPLAY_VERSION';
const String buildTimestamp = '$TIMESTAMP';
EOF

echo "Generated lib/version.dart with version $DISPLAY_VERSION and timestamp $TIMESTAMP"
echo "Build number incremented: $BUILD_NUM -> $NEW_BUILD_NUM"
