#!/bin/bash
#
# This script builds the Go application for multiple platforms, creating
# ZIP archives for each one, ready for a GitHub release.

# Exit immediately if a command exits with a non-zero status.
set -e

# The name of your application, taken from the Makefile's APP_NAME.
APP_NAME="boot-go"

# The directory where release artifacts will be created.
DIST_DIR="dist"

# A list of platforms to build for, in OS/ARCH format.
PLATFORMS=(
    "windows/amd64"
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
)

# Clean up the distribution directory before starting.
echo "Cleaning up old release files..."
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

# --- Main Build Loop ---
for platform in "${PLATFORMS[@]}"; do
    # Split the platform string into OS and architecture.
    IFS='/' read -r GOOS GOARCH <<< "$platform"

    # Set the output binary name. Add .exe for Windows.
    OUTPUT_NAME="${APP_NAME}"
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="${APP_NAME}.exe"
    fi

    echo "Building for ${GOOS}/${GOARCH}..."

    # Run the cross-compilation command. The CGO_ENABLED=0 flag creates
    # a statically linked binary, which is more portable.
    env CGO_ENABLED=0 GOOS="$GOOS" GOARCH="$GOARCH" go build -o "${DIST_DIR}/${OUTPUT_NAME}" ./cmd/"${APP_NAME}"

    # Create a ZIP archive for the platform.
    pushd "${DIST_DIR}" > /dev/null
    zip "${APP_NAME}-${GOOS}-${GOARCH}.zip" "${OUTPUT_NAME}"
    rm "${OUTPUT_NAME}" # Clean up the raw binary after zipping.
    popd > /dev/null

done

echo "✅ All builds complete! Release files are in the '${DIST_DIR}/' directory."