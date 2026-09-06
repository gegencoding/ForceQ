import Foundation
import Darwin

@main
struct Checks {
    static func main() {
        let roots = [MemoryTarget(pid: 11, bundlePath: "/Applications/Browser.app"),
                     MemoryTarget(pid: 22, bundlePath: "/Applications/Other.app")]
        precondition(MemoryMonitor.owner(pid: 11, path: nil, targets: roots) == 11)
        precondition(MemoryMonitor.owner(pid: 30, path: "/Applications/Browser.app/Contents/Frameworks/Helper.app/Contents/MacOS/Helper", targets: roots) == 11)
        precondition(MemoryMonitor.owner(pid: 30, path: "/Applications/Browser.app-copy/Contents/MacOS/Main", targets: roots) == nil)
        precondition(MemoryMonitor.owner(pid: 30, path: "/System/Library/SharedService", targets: roots) == nil)
        let duplicates = roots + [MemoryTarget(pid: 33, bundlePath: "/Applications/Browser.app")]
        precondition(MemoryMonitor.owner(pid: 30, path: "/Applications/Browser.app/Contents/Helper", targets: duplicates) == nil)
        precondition(MemoryMonitor.owner(pid: 33, path: nil, targets: duplicates) == 33)
        precondition(MemoryMonitor.label(nil) == "—")
        precondition(MemoryMonitor.label(0) == "0 MB")
        precondition(MemoryMonitor.footprint(pid: -1) == nil)
        let before = MemoryMonitor.footprint(pid: getpid())!
        let count = 32 * 1024 * 1024
        let block = malloc(count)!
        memset(block, 42, count)
        let after = MemoryMonitor.footprint(pid: getpid())!
        precondition(after > before + 16 * 1024 * 1024, "Memory allocation was not reflected")
        let sample = MemoryMonitor.sample(targets: [MemoryTarget(pid: getpid(), bundlePath: nil)])
        precondition(sample[getpid()]!.mainBytes != nil)
        precondition(sample[getpid()]!.measuredProcesses == 1)
        free(block)
        print("PASS: helper attribution, duplicates, path boundaries, unavailable values, live allocation and sampling")
    }
}
