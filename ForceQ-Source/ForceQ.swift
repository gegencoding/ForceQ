import SwiftUI
import AppKit

struct RunningApp: Identifiable {
    let application: NSRunningApplication
    var id: pid_t { application.processIdentifier }
    var name: String { application.localizedName ?? "Adsız uygulama" }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var apps: [RunningApp] = []
    @Published var selection: pid_t?
    @Published var search = ""
    @Published var memory: [pid_t: MemoryReading] = [:]
    @Published var includeHelpers = true
    @Published var sortByMemory = true
    @Published var updatedAt: Date?
    private var isSampling = false
    func bytes(for app: RunningApp) -> UInt64? {
        includeHelpers ? memory[app.id]?.groupedBytes : memory[app.id]?.mainBytes
    }
    func memoryLabel(for app: RunningApp) -> String {
        let value = bytes(for: app)
        let partial = includeHelpers && (memory[app.id]?.failedProcesses ?? 0) > 0
        return (partial && value != nil ? "≥ " : "") + MemoryMonitor.label(value)
    }
    func memoryHelp(for app: RunningApp) -> String {
        guard let reading = memory[app.id] else { return "Bellek ölçülüyor…" }
        if !includeHelpers { return "Yalnızca ana sürecin macOS bellek ayak izi. Yardımcı süreçler dahil değil." }
        return "\(reading.measuredProcesses) süreç ölçüldü. Uygulama paketindeki yardımcılar dahil. Paket dışındaki ve paylaşılan sistem hizmetleri dahil değil." +
            (reading.failedProcesses > 0 ? " Bazı süreçler okunamadı; gösterilen değer eksik olabilir." : "")
    }
    @Published var status = "Bir uygulama seçerek başlayın."
    var visibleApps: [RunningApp] {
        apps.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }.sorted {
            if sortByMemory {
                let a = bytes(for: $0), b = bytes(for: $1)
                if a != b { return (a ?? 0) > (b ?? 0) || (a != nil && b == nil) }
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
    var selected: RunningApp? { visibleApps.first { $0.id == selection } }
    func refresh() {
        apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated &&
            $0.processIdentifier != ProcessInfo.processInfo.processIdentifier &&
            $0.bundleIdentifier != "com.apple.finder"
        }.map { RunningApp(application: $0) }.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        if !apps.contains(where: { $0.id == selection }) { selection = nil }
        let active = Set(apps.map(\.id))
        memory = memory.filter { active.contains($0.key) }
        guard !isSampling else { return }
        isSampling = true
        let targets = apps.map {
            MemoryTarget(pid: $0.id, bundlePath: $0.application.bundleURL?.resolvingSymlinksInPath().path)
        }
        Task {
            let readings = await Task.detached(priority: .utility) {
                MemoryMonitor.sample(targets: targets)
            }.value
            self.memory = readings
            self.updatedAt = Date()
            self.isSampling = false
        }
    }
    func stop(_ target: RunningApp) {
        let app = target.application
        guard !app.isTerminated else {
            status = "\(target.name) zaten kapanmış."; refresh(); return
        }
        guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
              app.bundleIdentifier != "com.apple.finder", app.activationPolicy == .regular else {
            status = "Bu uygulama kapatılamaz."; return
        }
        if app.forceTerminate() {
            status = "\(target.name) için kapatma isteği gönderildi."
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                self.refresh()
                if app.isTerminated { self.status = "\(target.name) kapatıldı." }
            }
        } else { status = "macOS, \(target.name) için kapatma isteğini kabul etmedi." }
    }
}

struct ContentView: View {
    @StateObject private var model = AppModel()
    @State private var pending: RunningApp?
    @State private var showingConfirmation = false
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Açık uygulamalar").font(.title2.bold())
                    Text("Belleği izleyin, seçin, kapatın.").foregroundStyle(.secondary)
                }
                Spacer()
                Button { model.refresh() } label: { Image(systemName: "arrow.clockwise") }
                    .help("Listeyi yenile").accessibilityLabel("Listeyi yenile")
            }.padding(20)
            TextField("Uygulama ara", text: $model.search)
                .textFieldStyle(.roundedBorder).padding(.horizontal, 20).padding(.bottom, 12)
            HStack {
                Toggle("Yardımcı süreçler dahil", isOn: $model.includeHelpers)
                    .toggleStyle(.checkbox)
                    .help("Aynı uygulama paketindeki yardımcı süreçlerin ölçülebilen belleğini toplar. Paylaşılan sistem hizmetleri dahil değildir.")
                Spacer()
                Picker("Sıralama", selection: $model.sortByMemory) {
                    Text("Ada göre").tag(false)
                    Text("Belleğe göre").tag(true)
                }.labelsHidden().frame(width: 135)
            }.font(.caption).padding(.horizontal, 20).padding(.bottom, 10)
            HStack {
                Text("UYGULAMA")
                Spacer()
                Text("BELLEK")
            }.font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, 26).padding(.bottom, 4)
            List(selection: $model.selection) {
                ForEach(model.visibleApps) { app in
                    HStack(spacing: 12) {
                        if let icon = app.application.icon {
                            Image(nsImage: icon).resizable().scaledToFit().frame(width: 36, height: 36)
                        } else {
                            Image(systemName: "app").resizable().scaledToFit().frame(width: 32, height: 32)
                        }
                        Text(app.name).font(.body.weight(.medium))
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(model.memoryLabel(for: app)).font(.body.monospacedDigit().weight(.medium))
                            Text("PID " + String(app.id)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                        }.frame(minWidth: 88, alignment: .trailing)
                            .help(model.memoryHelp(for: app))
                    }.padding(.vertical, 5).tag(app.id)
                }
            }.listStyle(.inset)
            .overlay {
                if model.visibleApps.isEmpty {
                    Text(model.search.isEmpty ? "Listelenecek uygulama yok." : "Eşleşen uygulama yok.")
                        .foregroundStyle(.secondary).allowsHitTesting(false)
                }
            }
            Divider()
            VStack(alignment: .leading, spacing: 12) {
                Text(model.status).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(model.visibleApps.count) uygulama · v1.1")
                        Text(model.updatedAt == nil ? "Bellek ölçülüyor…" : "Bellek 3 saniyede bir güncellenir")
                    }.font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("Zorla Kapat", role: .destructive) {
                        pending = model.selected
                        showingConfirmation = pending != nil
                    }.buttonStyle(.borderedProminent).tint(.orange).disabled(model.selected == nil)
                }
            }.padding(16)
        }
        .frame(minWidth: 500, idealWidth: 520, minHeight: 520, idealHeight: 680)
        .onAppear { model.refresh() }
        .onReceive(timer) { _ in model.refresh() }
        .alert("\(pending?.name ?? "Uygulama") zorla kapatılsın mı?", isPresented: $showingConfirmation) {
            Button("Vazgeç", role: .cancel) { pending = nil }
            Button("Zorla Kapat", role: .destructive) {
                if let target = pending { model.stop(target) }
                pending = nil
            }
        } message: {
            Text("Kaydedilmemiş değişiklikler kaybolabilir.")
        }
    }
}

@main
struct ForceQApp: App {
    var body: some Scene {
        Window("ForceQ", id: "main") { ContentView() }
            .defaultSize(width: 520, height: 680)
    }
}
