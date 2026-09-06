#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p .build-cache
swiftc -parse-as-library -module-cache-path .build-cache MemoryMonitor.swift Tests/MemoryMonitorTests.swift -o .build-cache/memory-tests
.build-cache/memory-tests
