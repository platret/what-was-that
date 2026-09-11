import SwiftUI
import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct SettingsView: View {
    @Environment(RecStore.self) private var store
    @State private var onboarding = false
    @State private var samples = false
    @State private var exporting = false
    @State private var importing = false
    @State private var backup: BackupDocument?
    @State private var pendingRestore: Library?
    @State private var restored = false
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "YOUR LITTLE BOOK OF GOOD TASTE")
                    Text("Made of recommendations.\nBuilt around people.").font(.system(size: 30, design: .serif)).tracking(-0.8)
                    Text("\(store.library.recommendations.count) saved · \(store.library.recommendations.filter(\.tried).count) tried · \(Set(store.library.recommendations.map(\.person).filter { !$0.isEmpty }).count) people").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 12)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            Section("Make it yours") {
                NavigationLink { WidgetGuide() } label: { Label("Your next idea, on your Home Screen", systemImage: "rectangle.grid.2x2") }
                Button { onboarding = true } label: { Label("A little hello, again", systemImage: "hand.wave") }
                if store.library.recommendations.isEmpty { Button { samples = true } label: { Label("Explore with sample recommendations", systemImage: "sparkles") } }
            }
            Section {
                Button {
                    do { backup = BackupDocument(data: try JSONEncoder().encode(store.library)); exporting = true }
                    catch { store.error = error.localizedDescription }
                } label: { Label("Export my library", systemImage: "square.and.arrow.up") }
                Button { importing = true } label: { Label("Restore a backup", systemImage: "arrow.counterclockwise") }
                NavigationLink { PrivacyView() } label: { Label("A private little corner", systemImage: "lock") }
            } header: { Text("Your data belongs to you") } footer: { Text("Saved on this device. No account, ads, or tracking. Collection sharing and widgets are included in this edition.") }
            Section {
                Link(destination: URL(string: "https://platret.github.io/what-was-that/")!) { Label("Visit our little home on the web", systemImage: "arrow.up.right") }
                Link(destination: URL(string: "https://github.com/platret/what-was-that/issues")!) { Label("Have an idea?", systemImage: "bubble") }
            }
            Section { Text("what was that?\nMade with care by platret · 1.0").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: .infinity) }.listRowBackground(Color.clear)
        }.scrollContentBackground(.hidden).background(Color.paper).foregroundStyle(Color.ink).navigationTitle("A little about you").navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $onboarding) { OnboardingView { onboarding = false } }
            .confirmationDialog("Add four fictional examples to explore the app?", isPresented: $samples, titleVisibility: .visible) { Button("Add sample recommendations") { store.commit(.examples) } }
            .fileExporter(isPresented: $exporting, document: backup, contentType: .json, defaultFilename: "What-Was-That-Backup") { if case .failure(let error) = $0 { store.error = error.localizedDescription } }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get(); let access = url.startAccessingSecurityScopedResource(); defer { if access { url.stopAccessingSecurityScopedResource() } }
                    guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 5_000_000 else { throw LibraryError.tooLarge }
                    let library = try LibraryDisk.read(from: url)
                    guard library.recommendations.count <= 5000 else { throw LibraryError.tooLarge }
                    pendingRestore = library
                } catch { store.error = error.localizedDescription }
            }
            .alert("Restore this backup?", isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } })) {
                Button("Cancel", role: .cancel) { pendingRestore = nil }
                Button("Replace library", role: .destructive) { if let pendingRestore { restored = store.commit(pendingRestore) }; pendingRestore = nil }
            } message: { Text("This replaces your current library with \(pendingRestore?.recommendations.count ?? 0) recommendations. Export your current library first if you want to keep a copy.") }
            .alert("Your library is back", isPresented: $restored) { Button("Lovely", role: .cancel) { } }
    }
}

struct WidgetGuide: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Eyebrow(text: "A LITTLE NUDGE")
                Text("Good ideas.\nRight where you are.").font(.system(size: 38, design: .serif))
                VStack(alignment: .leading, spacing: 16) { Image(systemName: "shuffle").font(.title); Text("Your next\ngood thing.").font(.system(size: 30, design: .serif)); Text("FROM YOUR PEOPLE").font(.system(.caption2, design: .monospaced)).tracking(2) }.foregroundStyle(.black.opacity(0.8)).padding(28).frame(maxWidth: .infinity, alignment: .leading).background(Category.film.tint, in: .rect(cornerRadius: 27))
                Text("1. Touch and hold your Home Screen.\n\n2. Tap Edit, then Add Widget.\n\n3. Search for What Was That? and choose a size.\n\n4. Hold the widget and choose Edit Widget to pick a category, colour, or collection.").font(.body).lineSpacing(5)
                Text("The widget rotates through your untried recommendations. Tap one to see the full story. iOS decides when widgets refresh.").font(.subheadline).foregroundStyle(.secondary)
            }.padding(25)
        }.background(Color.paper).navigationTitle("Your custom widget").navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                Image(systemName: "lock").font(.system(size: 44, weight: .ultraLight)).foregroundStyle(Color.coral)
                Text("Your people.\nYour private little list.").font(.system(size: 37, design: .serif))
                Text("What Was That? keeps recommendations on your device, in a shared app container so your widgets can show them too. We don’t run a server, collect analytics, or upload your library.")
                Text("Sharing a recommendation or collection sends the titles, names, notes, and links you chose to include. Review these before sharing. The recipient gets a copy; changes don’t sync between devices.")
                Text("Opening an external link takes you to that website and its privacy policy. Exported backups contain your full library. Device backups may include app data according to your iPhone’s backup settings.")
                Text("You can delete individual recommendations and collections, or remove the app and its widgets to remove its local data. Keep an exported backup if you want to restore it later.")
            }.lineSpacing(5).padding(25)
        }.background(Color.paper).navigationTitle("Privacy, simply").navigationBarTitleDisplayMode(.inline)
    }
}
