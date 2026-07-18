#!/bin/bash
set -e

SRC_DIR="${1:-.}"
BUILD_NUM="${2:-0}"

cd "$SRC_DIR" || { echo "ERROR: cannot cd to $SRC_DIR"; exit 1; }

git_short=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || echo "unknown")

upstream_version=$(
    git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || \
    grep 'REDIS_VERSION' src/version.h 2>/dev/null | head -1 | grep -oP '"\K[^"]+' || \
    echo "unknown"
)

company_patch=$(
    git describe --tags --match "*-company-*" 2>/dev/null | sed 's/.*-company-//' | cut -d- -f1 || \
    echo "0"
)

full_version="${upstream_version}-company-${company_patch}"

echo "GIT_COMMIT_SHORT=${git_short}"
echo "GIT_BRANCH_NAME=${git_branch}"
echo "UPSTREAM_VERSION=${upstream_version}"
echo "COMPANY_PATCH=${company_patch}"
echo "VERSION=${full_version}"
echo "PACKAGE_NAME=redis-${full_version}-${git_branch}-${git_short}-${BUILD_NUM}.tar.gz"
