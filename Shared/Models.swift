import Foundation

let sharedGroup = "group.com.platret.whatwasthat.shared"

enum Category: String, Codable, CaseIterable, Identifiable {
    case film = "Films", food = "Food", game = "Games", place = "Places", other = "Other"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .film: "film"; case .food: "fork.knife"; case .game: "gamecontroller"; case .place: "mountain.2"; case .other: "sparkles" }
    }
    var verb: String {
        switch self { case .film: "Watch something"; case .food: "Find a good bite"; case .game: "Play something"; case .place: "Go somewhere"; case .other: "Try something new" }
    }
}

struct Recommendation: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var person: String
    var category: Category
    var note = ""
    var link = ""
    var collectionID: UUID?
    var createdAt = Date()
    var tried = false
    var favourite = false
    var safeURL: URL? {
        guard let url = URL(string: link), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
        return url
    }
    var attribution: String { person.isEmpty ? "A little self-discovery" : "From \(person)" }
}

struct RecCollection: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var symbol = "square.stack"
}

struct Library: Codable, Equatable {
    var version = 1
    var recommendations: [Recommendation] = []
    var collections: [RecCollection] = []

    func filtered(query: String = "", category: Category? = nil, person: String? = nil, tried: Bool? = nil) -> [Recommendation] {
        recommendations.filter { item in
            (category == nil || item.category == category) &&
            (person == nil || item.person == person) &&
            (tried == nil || item.tried == tried) &&
            (query.isEmpty || [item.title, item.person, item.note].joined(separator: " ").localizedCaseInsensitiveContains(query))
        }.sorted { $0.createdAt > $1.createdAt }
    }

    static var examples: Library {
        let weekend = RecCollection(name: "A slow weekend", symbol: "sun.max")
        let nights = RecCollection(name: "One more episode", symbol: "moon.stars")
        var library = Library(recommendations: [
            Recommendation(title: "Perfect Days", person: "Mia", category: .film, note: "The kind of film that makes an ordinary day feel a little more special.", collectionID: nights.id),
            Recommendation(title: "That little ramen place", person: "Noah", category: .food, note: "The one around the corner. Ask Noah for the address!", collectionID: weekend.id),
            Recommendation(title: "Firewatch", person: "Leo", category: .game, note: "Go in knowing as little as possible. Headphones on.", collectionID: weekend.id),
            Recommendation(title: "A morning by the lake", person: "Mia", category: .place, note: "Coffee, a book, and absolutely no plans.", collectionID: weekend.id)
        ], collections: [weekend, nights])
        for index in library.recommendations.indices { library.recommendations[index].createdAt = Date().addingTimeInterval(Double(-index) * 3600) }
        return library
    }
}

enum LibraryDisk {
    static var directory: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedGroup)
        ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WhatWasThat", isDirectory: true)
    }
    static var url: URL { directory.appendingPathComponent("library.json") }
    static func read(from url: URL = url) throws -> Library {
        guard FileManager.default.fileExists(atPath: url.path) else { return Library() }
        let library = try JSONDecoder().decode(Library.self, from: Data(contentsOf: url))
        guard library.version == 1 else { throw LibraryError.unsupportedVersion }
        guard library.recommendations.count <= 5000, library.collections.count <= 1000,
              Set(library.recommendations.map(\.id)).count == library.recommendations.count,
              Set(library.collections.map(\.id)).count == library.collections.count,
              library.recommendations.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.title.count <= 200 && $0.person.count <= 100 && $0.note.count <= 10000 && $0.link.count <= 2000 }),
              library.collections.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.name.count <= 100 }) else { throw LibraryError.invalidImport }
        return library
    }
    static func write(_ library: Library, to url: URL = url) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(library).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

enum LibraryError: LocalizedError {
    case unsupportedVersion, invalidImport, tooLarge, readOnly
    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "This collection needs a newer version of What Was That?."
        case .invalidImport: "This file isn't a valid What Was That? collection."
        case .tooLarge: "This file is too large. Please import a collection smaller than 5 MB."
        case .readOnly: "Your saved library could not be read. To protect your original file, changes are paused. Close the app and try again."
        }
    }
}

struct CollectionPackage: Codable {
    var format = "com.platret.whatwasthat.collection"
    var version = 1
    var collection: RecCollection
    var recommendations: [Recommendation]

    static func decode(_ data: Data) throws -> CollectionPackage {
        guard data.count <= 5_000_000 else { throw LibraryError.tooLarge }
        let value = try JSONDecoder().decode(Self.self, from: data)
        guard value.format == "com.platret.whatwasthat.collection", value.version == 1,
              !value.collection.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              value.collection.name.count <= 100, value.recommendations.count <= 5000,
              value.recommendations.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.title.count <= 200 && $0.person.count <= 100 && $0.note.count <= 10000 && $0.link.count <= 2000 }) else { throw LibraryError.invalidImport }
        return value
    }

    func merged(into library: Library) -> Library {
        var result = library
        if !result.collections.contains(where: { $0.id == collection.id }) { result.collections.append(collection) }
        let known = Set(result.recommendations.map(\.id))
        var inserted = known
        for var item in recommendations where !inserted.contains(item.id) {
            item.collectionID = collection.id
            result.recommendations.append(item)
            inserted.insert(item.id)
        }
        return result
    }
}
