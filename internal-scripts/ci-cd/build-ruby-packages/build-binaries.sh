#!/bin/bash
set -e

SELFDIR=$(dirname "$0")
ROOTDIR=$(cd "$SELFDIR/../../.." && pwd)
# shellcheck source=../../../lib/library.sh
source "$ROOTDIR/lib/library.sh"

require_envvar ENVIRONMENT_NAME
require_envvar VARIANT_NAME
require_envvar RUBY_PACKAGE_VERSION_ID


BUILD_IMAGE_NAME="fullstaq/ruby-build-env-$ENVIRONMENT_NAME"
BUILD_IMAGE_TAG=$(read_single_value_file "$ROOTDIR/environments/$ENVIRONMENT_NAME/image_tag")

if [[ "$VARIANT_NAME" = jemalloc ]]; then
    MOUNT_ARGS=(-v "$(pwd)/jemalloc-bin.tar.gz:/input/jemalloc-bin.tar.gz:ro")
else
    MOUNT_ARGS=()
fi

touch "ruby-bin-$VARIANT_NAME.tar.gz"

exec docker run --rm --init \
    -v "$ROOTDIR:/system:ro" \
    -v "$(pwd)/ruby-src.tar.gz:/input/ruby-src.tar.gz:ro" \
    -v "$(pwd)/ruby-bin-$VARIANT_NAME.tar.gz:/output/ruby-bin.tar.gz" \
    -v "$(pwd)/cache-$VARIANT_NAME:/cache:delegated" \
    "${MOUNT_ARGS[@]}" \
    -e "VARIANT=$VARIANT_NAME" \
    -e "BUILD_CONCURRENCY=2" \
    -e "PACKAGE_VERSION=$RUBY_PACKAGE_VERSION_ID" \
    -e "ENVIRONMENT_NAME=$ENVIRONMENT_NAME" \
    --user "$(id -u):$(id -g)" \
    "$BUILD_IMAGE_NAME:$BUILD_IMAGE_TAG" \
    /system/container-entrypoints/build-ruby
