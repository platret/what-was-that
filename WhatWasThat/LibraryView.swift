import SwiftUI

struct LibraryView: View {
    @Environment(RecStore.self) private var store
    @State private var query = ""
    @State private var category: Category?
    @State private var person: String?
    @State private var status = 0
    @State private var favouritesOnly = false
    @State private var adding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var items: [Recommendation] { store.library.filtered(query: query, category: category, person: person, tried: status == 0 ? false : status == 1 ? true : nil).filter { !favouritesOnly || $0.favourite } }
    private var people: [String] { Array(Set(store.library.recommendations.map(\.person).filter { !$0.isEmpty })).sorted() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow(text: "GOOD TASTE TRAVELS")
                    Text("Worth remembering.").font(.system(size: 37, design: .serif)).tracking(-1.4)
                    Text("Little suggestions. Your next favourite thing.").font(.subheadline).foregroundStyle(.secondary)
                }.padding(.top, 15)
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("A title, a friend, a little detail…", text: $query).font(.subheadline).accessibilityIdentifier("librarySearch")
                    if !query.isEmpty { Button("Clear", systemImage: "xmark.circle.fill") { query = "" }.labelStyle(.iconOnly) }
                }.padding(15).background(Color.ink.opacity(0.045), in: Capsule())
                ScrollView(.horizontal) {
                    HStack(spacing: 9) {
                        chip("Everything", symbol: "square.grid.2x2", selected: category == nil) { category = nil }
                        ForEach(Category.allCases) { value in chip(value.rawValue, symbol: value.symbol, selected: category == value) { category = value } }
                    }
                }.scrollIndicators(.hidden)
                HStack {
                    Picker("Status", selection: $status) { Text("To try").tag(0); Text("Tried").tag(1); Text("All").tag(2) }.pickerStyle(.segmented)
                    Menu {
                        Toggle("Favourites only", isOn: $favouritesOnly)
                        Divider()
                        Button("Everyone") { person = nil }
                        ForEach(people, id: \.self) { friend in Button(friend) { person = friend } }
                    } label: { Image(systemName: person == nil ? "person.2" : "person.2.fill").padding(11).glassEffect() }
                    .accessibilityLabel("Filter by friend")
                }
                if favouritesOnly { Button("Favourites · Clear", systemImage: "heart.fill") { favouritesOnly = false }.font(.caption) }
                if let person {
                    Button { self.person = nil } label: { Label("From \(person) · Clear", systemImage: "xmark.circle").font(.caption) }
                }
                if items.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        HStack { Eyebrow(text: "\(items.count) GOOD \(items.count == 1 ? "IDEA" : "IDEAS")"); Spacer(); Text("Most recent first").font(.caption2).foregroundStyle(.secondary) }.padding(.bottom, 10)
                        ForEach(items) { item in
                            NavigationLink { DetailView(itemID: item.id) } label: { RecCard(item: item) }.buttonStyle(PressStyle())
                            Divider().overlay(Color.ink.opacity(0.03))
                        }
                    }
                }
            }.padding(.horizontal, 24).padding(.bottom, 35)
        }.background(Color.paper).foregroundStyle(Color.ink).navigationTitle("what was that?").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save a recommendation", systemImage: "plus") { adding = true }.accessibilityIdentifier("addRecommendation")
                }
            }.sheet(isPresented: $adding) { EditRecommendationView() }
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: category)
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: status)
    }

    private var emptyState: some View {
        VStack(spacing: 17) {
            Image(systemName: query.isEmpty && category == nil && person == nil ? "bookmark" : "magnifyingglass").font(.system(size: 35, weight: .ultraLight)).padding(24).background(Category.film.tint.opacity(0.35), in: Circle())
            Text(store.library.recommendations.isEmpty ? "“You’d love this.”" : "Nothing here just yet.").font(.system(.title2, design: .serif))
            Text(store.library.recommendations.isEmpty ? "The next time someone says it,\ngive their suggestion a home here." : "Try another filter or save something new.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
            Button("Save your first idea", systemImage: "plus") { adding = true }.font(.subheadline.weight(.semibold)).padding(.top, 5)
        }.frame(maxWidth: .infinity).padding(.vertical, 38)
    }

    private func chip(_ title: String, symbol: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Label(title, systemImage: symbol).font(.caption.weight(.medium)).padding(.horizontal, 15).padding(.vertical, 12).foregroundStyle(selected ? Color.paper : Color.ink).background(selected ? Color.ink : Color.ink.opacity(0.045), in: Capsule()) }.buttonStyle(PressStyle())
    }
}

struct EditRecommendationView: View {
    @Environment(RecStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var item: Recommendation
    @FocusState private var focused: Bool
    private let editing: Bool
    private var valid: Bool { !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && item.link.count <= 2000 && (item.link.isEmpty || item.safeURL != nil) }
    init(item: Recommendation? = nil) { _item = State(initialValue: item ?? Recommendation(title: "", person: "", category: .film)); editing = !(item?.title.isEmpty ?? true) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What was it called?", text: $item.title, axis: .vertical).font(.system(.title2, design: .serif)).focused($focused).accessibilityIdentifier("titleField")
                    Picker("Kind of good thing", selection: $item.category) { ForEach(Category.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) } }
                } header: { Text("The recommendation") }
                Section {
                    TextField("Who told you?", text: $item.person).textContentType(.name).accessibilityIdentifier("personField")
                    let people = Array(Set(store.library.recommendations.map(\.person).filter { !$0.isEmpty })).sorted()
                    if !people.isEmpty {
                        ScrollView(.horizontal) { HStack { ForEach(people, id: \.self) { person in Button(person) { item.person = person }.buttonStyle(.bordered).controlSize(.small) } } }.scrollIndicators(.hidden)
                    }
                } header: { Text("Credit where it’s due") } footer: { Text("Just a first name is lovely. Leave blank for your own discoveries.") }
                Section {
                    TextField("“You have to try the…”", text: $item.note, axis: .vertical).lineLimit(3...6).accessibilityIdentifier("noteField")
                    TextField("Link (optional)", text: $item.link).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    if !item.link.isEmpty && item.safeURL == nil { Text("Use a complete https:// or http:// link.").font(.caption).foregroundStyle(Color.coral) }
                    Picker("Collection", selection: $item.collectionID) {
                        Text("Just in my saved ideas").tag(UUID?.none)
                        ForEach(store.library.collections) { Text($0.name).tag(Optional($0.id)) }
                    }
                } header: { Text("The little details") }
                Section {
                    PrimaryButton(title: editing ? "Save changes" : "Keep this one", symbol: "bookmark") {
                        item.title = String(item.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(200))
                        item.person = String(item.person.trimmingCharacters(in: .whitespacesAndNewlines).prefix(100))
                        item.note = String(item.note.prefix(10000))
                        item.link = item.link.trimmingCharacters(in: .whitespacesAndNewlines)
                        if store.save(item) { UIImpactFeedbackGenerator(style: .soft).impactOccurred(); dismiss() }
                    }.disabled(!valid).opacity(valid ? 1 : 0.5).accessibilityIdentifier("saveRecommendation")
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets())
            }.scrollContentBackground(.hidden).background(Color.paper).navigationTitle(editing ? "A little update" : "Pass it on to future you").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { focused = false; UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } }
                }
        }
    }
}

struct DetailView: View {
    var itemID: UUID
    @Environment(RecStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var deleting = false
    private var item: Recommendation? { store.library.recommendations.first { $0.id == itemID } }

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        CategoryArt(category: item.category, large: true).frame(height: 240).clipShape(.rect(cornerRadius: 28))
                        HStack { Eyebrow(text: item.category.rawValue); Spacer(); Button { var next = item; next.favourite.toggle(); store.save(next) } label: { Image(systemName: item.favourite ? "heart.fill" : "heart").foregroundStyle(Color.coral).padding(12).glassEffect() }.accessibilityLabel(item.favourite ? "Remove favourite" : "Favourite") }
                        Text(item.title).font(.system(size: 39, design: .serif)).tracking(-1)
                        HStack(spacing: 12) {
                            Text(String(item.person.isEmpty ? "✦" : String(item.person.prefix(1))).uppercased()).font(.system(.headline, design: .serif)).frame(width: 42, height: 42).background(item.category.tint, in: Circle()).foregroundStyle(.black.opacity(0.7))
                            VStack(alignment: .leading, spacing: 4) { Text(item.attribution).font(.subheadline.weight(.semibold)); Text("Saved \(item.createdAt.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary) }
                        }
                        if !item.note.isEmpty {
                            VStack(alignment: .leading, spacing: 12) { Eyebrow(text: "THE WORD ON THE STREET"); Text(item.note).font(.system(.title3, design: .serif)).lineSpacing(6).textSelection(.enabled) }.padding(.vertical, 10)
                        }
                        if let collection = store.library.collections.first(where: { $0.id == item.collectionID }) { Label(collection.name, systemImage: collection.symbol).font(.caption).foregroundStyle(.secondary) }
                        if let url = item.safeURL { Link(destination: url) { Label("Open the link", systemImage: "arrow.up.right.square").frame(maxWidth: .infinity).padding(16).glassEffect() } }
                        PrimaryButton(title: item.tried ? "Move back to my list" : "I tried it!", symbol: item.tried ? "arrow.uturn.backward" : "checkmark") {
                            var next = item; next.tried.toggle()
                            if store.save(next) { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                        }.accessibilityIdentifier("toggleTried")
                        ShareLink(item: "\(item.title) · \(item.category.rawValue)\n\(item.attribution)\n\(item.note)\n\(item.link)") { Label("Pass this recommendation on", systemImage: "square.and.arrow.up").font(.subheadline).frame(maxWidth: .infinity).padding(12) }
                    }.padding(24)
                }
            } else { ContentUnavailableView("This idea has moved on", systemImage: "bookmark") }
        }.background(Color.paper).foregroundStyle(Color.ink).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Menu { Button("Edit", systemImage: "pencil") { editing = true }; Button("Delete", systemImage: "trash", role: .destructive) { deleting = true } } label: { Image(systemName: "ellipsis") }.accessibilityLabel("Recommendation options") }
            }.sheet(isPresented: $editing) { if let item { EditRecommendationView(item: item) } }
            .confirmationDialog("Delete this recommendation?", isPresented: $deleting, titleVisibility: .visible) { Button("Delete recommendation", role: .destructive) { if let item, store.remove(item) { dismiss() } } }
    }
}
