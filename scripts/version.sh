# scripts/version.sh
#!/bin/bash
set -e
	
# 允许外部指定源码目录，默认当前目录
SRC_DIR="${1:-.}"

# 输出格式：key=value，方便 Jenkins/source 读取
get_version_info() {
    local upstream_version company_patch full_version git_short git_branch
    
    # Git commit short
    git_short=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    # Git branch
    git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    
    # Upstream version: 优先从 git tag (v*) 提取，其次从 version.h
    upstream_version=$(
        git -C "${SRC_DIR}" describe --tags --exact-match 2>/dev/null | sed 's/^v//' || \
        grep 'REDIS_VERSION' ${SRC_DIR}/src/version.h 2>/dev/null | head -1 | grep -oP '"\K[^"]+' || \
        echo "unknown"
    )
    
    # Company patch: 从 company tag 提取，或默认 0
    company_patch=$(
        git describe --tags --match "*-company-*" 2>/dev/null | sed 's/.*-company-//' | cut -d- -f1 || \
        echo "0"
    )
    
    # Full version
    full_version="${upstream_version}-company-${company_patch}"
    
    # 输出（key=value 格式，Jenkins 可以直接 source）
    echo "GIT_COMMIT_SHORT=${git_short}"
    echo "GIT_BRANCH_NAME=${git_branch}"
    echo "UPSTREAM_VERSION=${upstream_version}"
    echo "COMPANY_PATCH=${company_patch}"
    echo "VERSION=${full_version}"
}

# 生成产物文件名
get_package_name() {
    local build_number=${1:-0}
    source <(get_version_info)
    echo "PACKAGE_NAME=redis-${VERSION}-${GIT_BRANCH_NAME}-${GIT_COMMIT_SHORT}-${build_number}.tar.gz"
}

# 主逻辑
case "${1:-info}" in
    info)
        get_version_info
        ;;
    package)
        get_package_name "${2:-0}"
        ;;
    full)
        get_version_info
        get_package_name "${2:-0}"
        ;;
    *)
        echo "Usage: $0 {info|package [build_num]|full [build_num]}" >&2
        exit 1
        ;;
esac
