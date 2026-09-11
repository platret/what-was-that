import SwiftUI

@main struct WhatWasThatApp: App {
    @State private var store: RecStore
    @AppStorage("onboarded") private var onboarded = false
    @State private var openedItem: Recommendation?
    @State private var pendingPackage: CollectionPackage?

    init() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing") {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ui-library.json")
            if args.contains("--reset") {
                try? FileManager.default.removeItem(at: url)
                UserDefaults.standard.set(false, forKey: "onboarded")
            }
            _store = State(initialValue: RecStore(url: url))
        } else if args.contains("--screenshots") {
            _store = State(initialValue: RecStore(preview: true))
            UserDefaults.standard.set(true, forKey: "onboarded")
        } else { _store = State(initialValue: RecStore()) }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded { RootView() }
                else { OnboardingView { withAnimation(.smooth) { onboarded = true } } }
            }.environment(store).tint(.coral).preferredColorScheme(nil)
                .sheet(item: $openedItem) { item in NavigationStack { DetailView(itemID: item.id) }.environment(store) }
                .sheet(isPresented: Binding(get: { pendingPackage != nil }, set: { if !$0 { pendingPackage = nil } })) {
                    if let package = pendingPackage { ImportPreview(package: package) { pendingPackage = nil }.environment(store) }
                }
                .alert("Something needs attention", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
                .onOpenURL { url in
                    if url.scheme == "whatwasthat", let id = UUID(uuidString: url.lastPathComponent) {
                        openedItem = store.library.recommendations.first { $0.id == id }
                    } else if url.isFileURL {
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        do {
                            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                            guard size <= 5_000_000 else { throw LibraryError.tooLarge }
                            pendingPackage = try CollectionPackage.decode(Data(contentsOf: url))
                        } catch { store.error = error.localizedDescription }
                    }
                }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Saved", systemImage: "bookmark") { NavigationStack { LibraryView() } }
            Tab("Pick for me", systemImage: "shuffle") { NavigationStack { PickView() } }
            Tab("Collections", systemImage: "square.stack") { NavigationStack { CollectionsView() } }
            Tab("You", systemImage: "person.crop.circle") { NavigationStack { SettingsView() } }
        }
    }
}
