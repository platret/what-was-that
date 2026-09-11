import SwiftUI
import WidgetKit

@MainActor @Observable final class RecStore {
    private(set) var library = Library()
    var error: String?
    private let fileURL: URL
    private var readable = true

    init(url: URL = LibraryDisk.url, preview: Bool = false) {
        fileURL = url
        if preview { library = .examples; return }
        do { library = try LibraryDisk.read(from: url) }
        catch { readable = false; self.error = "Your library couldn't be opened. Your original file is safe. \(error.localizedDescription)" }
    }

    @discardableResult func commit(_ next: Library) -> Bool {
        guard readable else { error = LibraryError.readOnly.localizedDescription; return false }
        do {
            try LibraryDisk.write(next, to: fileURL)
            library = next
            WidgetCenter.shared.reloadAllTimelines()
            return true
        } catch { self.error = "Couldn't save your change. \(error.localizedDescription)"; return false }
    }

    @discardableResult func save(_ item: Recommendation) -> Bool {
        var next = library
        if let index = next.recommendations.firstIndex(where: { $0.id == item.id }) { next.recommendations[index] = item }
        else { next.recommendations.insert(item, at: 0) }
        return commit(next)
    }

    @discardableResult func remove(_ item: Recommendation) -> Bool {
        var next = library
        next.recommendations.removeAll { $0.id == item.id }
        return commit(next)
    }

    @discardableResult func addCollection(_ name: String, symbol: String) -> Bool {
        var next = library
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        next.collections.append(RecCollection(name: String(trimmed.prefix(100)), symbol: symbol))
        return commit(next)
    }

    func removeCollection(_ collection: RecCollection) {
        var next = library
        next.collections.removeAll { $0.id == collection.id }
        for index in next.recommendations.indices where next.recommendations[index].collectionID == collection.id {
            next.recommendations[index].collectionID = nil
        }
        commit(next)
    }

    func importPackage(_ package: CollectionPackage) -> Bool { commit(package.merged(into: library)) }

    func export(_ collection: RecCollection) throws -> URL {
        let package = CollectionPackage(collection: collection, recommendations: library.recommendations.filter { $0.collectionID == collection.id })
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(collection.id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = collection.name.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "-")
        let url = directory.appendingPathComponent("\(name.isEmpty ? "Collection" : name).wwt")
        try JSONEncoder().encode(package).write(to: url, options: .atomic)
        return url
    }
}
