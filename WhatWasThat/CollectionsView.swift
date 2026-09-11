import SwiftUI
import UniformTypeIdentifiers

extension UTType { static let wwtCollection = UTType(exportedAs: "com.platret.whatwasthat.collection", conformingTo: .json) }

struct CollectionsView: View {
    @Environment(RecStore.self) private var store
    @State private var creating = false
    @State private var importing = false
    @State private var pending: CollectionPackage?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Eyebrow(text: "BETTER TOGETHER").padding(.top, 15)
                Text("Good things,\nin good company.").font(.system(size: 39, design: .serif)).tracking(-1)
                Text("A weekend away. A film night. A list to pass around.").font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                if store.library.collections.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "square.stack").font(.system(size: 48, weight: .ultraLight)).foregroundStyle(Color.coral)
                        Text("Make a little collection.").font(.system(.title2, design: .serif))
                        Text("Group your ideas, then share a copy\nwith someone who’ll love them.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 38)
                }
                ForEach(Array(store.library.collections.enumerated()), id: \.element.id) { index, collection in
                    NavigationLink { CollectionDetailView(collectionID: collection.id) } label: {
                        VStack(alignment: .leading, spacing: 25) {
                            HStack { Image(systemName: collection.symbol).font(.system(size: 26, weight: .light)); Spacer(); Image(systemName: "arrow.up.right") }
                            VStack(alignment: .leading, spacing: 8) {
                                Text(collection.name).font(.system(size: 28, design: .serif))
                                let count = store.library.recommendations.filter { $0.collectionID == collection.id }.count
                                Text("\(count) saved \(count == 1 ? "idea" : "ideas")").font(.caption)
                            }
                        }.padding(25).frame(maxWidth: .infinity, alignment: .leading).background(Category.allCases[index % Category.allCases.count].tint, in: .rect(cornerRadius: 25)).foregroundStyle(Color(red: 0.16, green: 0.20, blue: 0.17))
                    }.buttonStyle(PressStyle())
                }
                PrimaryButton(title: "Start a collection", symbol: "plus") { creating = true }.accessibilityIdentifier("newCollection")
                Button { importing = true } label: { Label("Import a shared collection", systemImage: "square.and.arrow.down").font(.subheadline).frame(maxWidth: .infinity).padding(8) }
            }.padding(.horizontal, 24).padding(.bottom, 35)
        }.background(Color.paper).foregroundStyle(Color.ink).navigationTitle("Collections").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $creating) { NewCollectionView() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.wwtCollection, .json]) { result in
                do {
                    let url = try result.get(); let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 5_000_000 else { throw LibraryError.tooLarge }
                    pending = try CollectionPackage.decode(Data(contentsOf: url))
                } catch { store.error = error.localizedDescription }
            }
            .sheet(isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })) { if let pending { ImportPreview(package: pending) { self.pending = nil } } }
    }
}

struct NewCollectionView: View {
    @Environment(RecStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var symbol = "sun.max"
    private let symbols = ["sun.max", "moon.stars", "heart", "map", "sparkles", "cup.and.saucer"]
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 25) {
                Text("Give good ideas\na place to belong.").font(.system(size: 33, design: .serif))
                TextField("A slow weekend…", text: $name).font(.title3).padding(20).background(Color.ink.opacity(0.05), in: .rect(cornerRadius: 18)).accessibilityIdentifier("collectionName")
                HStack { ForEach(symbols, id: \.self) { value in Button { symbol = value } label: { Image(systemName: value).frame(maxWidth: .infinity).padding(.vertical, 15).foregroundStyle(symbol == value ? Color.coral : Color.ink).background(symbol == value ? Color.coral.opacity(0.12) : .clear, in: Circle()) }.accessibilityLabel(value) } }
                PrimaryButton(title: "Make it a collection", symbol: "plus") { if store.addCollection(name, symbol: symbol) { dismiss() } }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("saveCollection")
                Spacer()
            }.padding(25).background(Color.paper).navigationTitle("A new collection").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.presentationDetents([.medium, .large])
    }
}

struct CollectionDetailView: View {
    var collectionID: UUID
    @Environment(RecStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var deleting = false
    @State private var adding = false
    private var collection: RecCollection? { store.library.collections.first { $0.id == collectionID } }
    var body: some View {
        ScrollView {
            if let collection {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: collection.symbol).font(.system(size: 42, weight: .light)).foregroundStyle(Color.coral).padding(.top, 25)
                    Text(collection.name).font(.system(size: 39, design: .serif))
                    let items = store.library.recommendations.filter { $0.collectionID == collectionID }
                    Eyebrow(text: "\(items.count) GOOD IDEAS")
                    if items.isEmpty { Text("Add recommendations to this collection to get it started.").foregroundStyle(.secondary) }
                    ForEach(items) { item in NavigationLink { DetailView(itemID: item.id) } label: { RecCard(item: item) }.buttonStyle(PressStyle()) }
                    Button("Add a recommendation", systemImage: "plus") { adding = true }.buttonStyle(.bordered)
                    Divider()
                    Text("Good taste is better shared.").font(.system(.title2, design: .serif))
                    Text("Send a copy via AirDrop, Messages, or Files. Your friend can open it in What Was That?. Future edits stay on each person’s device.").font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                    if let shareURL {
                        ShareLink(item: shareURL) { Label("Share collection", systemImage: "square.and.arrow.up").fontWeight(.semibold).frame(maxWidth: .infinity).padding(18).glassEffect() }.accessibilityIdentifier("shareCollection")
                    } else {
                        Button("Prepare collection to share", systemImage: "square.and.arrow.up") { prepareShare(collection) }
                    }
                }.padding(24)
                .task { prepareShare(collection) }.onChange(of: store.library) { prepareShare(collection) }
            }
        }.background(Color.paper).foregroundStyle(Color.ink).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Delete collection", systemImage: "trash") { deleting = true } } }
            .confirmationDialog("Delete this collection? Your recommendations will stay in Saved.", isPresented: $deleting, titleVisibility: .visible) { Button("Delete collection", role: .destructive) { if let collection { store.removeCollection(collection); if store.error == nil { dismiss() } } } }
            .sheet(isPresented: $adding) { EditRecommendationView(item: Recommendation(title: "", person: "", category: .film, collectionID: collectionID)) }
    }
    private func prepareShare(_ collection: RecCollection) { do { shareURL = try store.export(collection) } catch { store.error = error.localizedDescription } }
}

struct ImportPreview: View {
    var package: CollectionPackage
    var done: () -> Void
    @Environment(RecStore.self) private var store
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: package.collection.symbol).font(.largeTitle).foregroundStyle(Color.coral)
                Text(package.collection.name).font(.system(size: 34, design: .serif))
                Text("\(package.recommendations.count) recommendations, with the people and little details attached.").foregroundStyle(.secondary)
                Text("This adds a copy to your library. Existing ideas won’t be replaced, and importing the same file twice won’t create duplicates.").font(.subheadline).foregroundStyle(.secondary)
                PrimaryButton(title: "Keep this collection", symbol: "square.and.arrow.down") { if store.importPackage(package) { done() } }
                Spacer()
            }.padding(28).background(Color.paper).navigationTitle("A good thing, passed on").navigationBarTitleDisplayMode(.inline).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: done) } }
        }.presentationDetents([.medium, .large])
    }
}
