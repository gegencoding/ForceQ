import Foundation
import Darwin

struct MemoryTarget: Sendable {
    let pid: pid_t
    let bundlePath: String?
}

struct MemoryReading: Sendable {
    var mainBytes: UInt64?
    var totalBytes: UInt64 = 0
    var measuredProcesses = 0
    var failedProcesses = 0
    var groupedBytes: UInt64? { measuredProcesses > 0 ? totalBytes : nil }
}

enum MemoryMonitor {
    // Physical footprint is macOS memory accounting, not virtual address space.
    static func footprint(pid: pid_t) -> UInt64? {
        var info = rusage_info_v2()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_V2, $0)
            }
        }
        return result == 0 ? info.ri_phys_footprint : nil
    }

    static func processIDs() -> [pid_t]? {
        let required = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard required > 0 else { return nil }
        var ids = [pid_t](repeating: 0, count: Int(required) / MemoryLayout<pid_t>.stride + 256)
        let bytes = ids.withUnsafeMutableBytes {
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, $0.baseAddress, Int32($0.count))
        }
        guard bytes > 0 else { return nil }
        return Array(ids.prefix(Int(bytes) / MemoryLayout<pid_t>.stride)).filter { $0 > 0 }
    }

    static func executablePath(pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let count = buffer.withUnsafeMutableBytes {
            proc_pidpath(pid, $0.baseAddress, UInt32($0.count))
        }
        guard count > 0 else { return nil }
        return String(cString: buffer)
    }

    // Attribute only executables physically inside a known app bundle. Do not
    // guess from process names or claim unrelated/shared system services.
    static func owner(pid: pid_t, path: String?, targets: [MemoryTarget]) -> pid_t? {
        if targets.contains(where: { $0.pid == pid }) { return pid }
        guard let path else { return nil }
        let matches = targets.filter {
            guard let root = $0.bundlePath else { return false }
            return path.hasPrefix(root + "/")
        }
        guard let length = matches.compactMap({ $0.bundlePath?.count }).max() else { return nil }
        let nearest = matches.filter { $0.bundlePath?.count == length }
        // Multiple instances of one bundle: do not count helpers twice.
        return nearest.count == 1 ? nearest[0].pid : nil
    }

    static func sample(targets: [MemoryTarget]) -> [pid_t: MemoryReading] {
        var readings = Dictionary(uniqueKeysWithValues: targets.map { ($0.pid, MemoryReading()) })
        let listed = processIDs()
        let ids = Set((listed ?? []) + targets.map(\.pid))
        for pid in ids {
            let path = targets.contains(where: { $0.pid == pid }) ? nil : executablePath(pid: pid)
            guard let root = owner(pid: pid, path: path, targets: targets) else { continue }
            let bytes = footprint(pid: pid)
            var reading = readings[root]!
            if root == pid { reading.mainBytes = bytes }
            if let bytes {
                reading.totalBytes += bytes
                reading.measuredProcesses += 1
            } else { reading.failedProcesses += 1 }
            readings[root] = reading
        }
        if listed == nil {
            for key in Array(readings.keys) { readings[key]!.failedProcesses += 1 }
        }
        return readings
    }

    static func label(_ bytes: UInt64?) -> String {
        guard let bytes else { return "—" }
        let value = Double(bytes)
        if value >= 1_000_000_000 {
            return String(format: "%.2f GB", value / 1_000_000_000)
        }
        if value > 0 && value < 1_000_000 { return "<1 MB" }
        return String(format: "%.0f MB", value / 1_000_000)
    }
}
