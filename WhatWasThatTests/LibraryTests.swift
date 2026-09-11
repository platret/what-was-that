import XCTest
@testable import WhatWasThat

final class LibraryTests: XCTestCase {
    func testRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("data.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let value = Library.examples
        try LibraryDisk.write(value, to: url)
        XCTAssertEqual(try LibraryDisk.read(from: url), value)
    }
    func testFilteringIncludesFriendAndNotesButExcludesTried() {
        var value = Library.examples
        value.recommendations[0].tried = true
        XCTAssertEqual(value.filtered(person: "Mia").count, 2)
        XCTAssertEqual(value.filtered(query: "HEADPHONES").first?.title, "Firewatch")
        XCTAssertEqual(value.filtered(category: .film, tried: false).count, 0)
        XCTAssertEqual(value.filtered(tried: false).count, 3)
    }
    func testImportDeduplicatesAndPreservesExistingEdits() throws {
        let original = Library.examples
        let collection = original.collections[0]
        let package = CollectionPackage(collection: collection, recommendations: original.recommendations.filter { $0.collectionID == collection.id })
        let decoded = try CollectionPackage.decode(JSONEncoder().encode(package))
        var once = decoded.merged(into: Library())
        once.recommendations[0].note = "My own note"
        let twice = decoded.merged(into: once)
        XCTAssertEqual(once, twice)
        XCTAssertEqual(twice.collections.count, 1)
        XCTAssertTrue(twice.recommendations.allSatisfy { $0.collectionID == collection.id })
    }
    func testRejectsUntrustedImportsAndUnsafeLinks() throws {
        var package = CollectionPackage(collection: RecCollection(name: "Test"), recommendations: [])
        package.format = "something-else"
        XCTAssertThrowsError(try CollectionPackage.decode(JSONEncoder().encode(package)))
        XCTAssertThrowsError(try CollectionPackage.decode(Data(repeating: 0, count: 5_000_001)))
        var item = Recommendation(title: "Title", person: "Friend", category: .other, link: "javascript:alert(1)")
        XCTAssertNil(item.safeURL)
        item.link = "https://example.com"
        XCTAssertNotNil(item.safeURL)
    }
    @MainActor func testStorePersistsEditsDeletionAndCollectionRemoval() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("library.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let store = RecStore(url: url)
        XCTAssertTrue(store.addCollection("Weekend", symbol: "sun.max"))
        var item = Recommendation(title: "An idea", person: "Mia", category: .place, collectionID: store.library.collections[0].id)
        XCTAssertTrue(store.save(item))
        item.tried = true
        XCTAssertTrue(store.save(item))
        let reopened = RecStore(url: url)
        XCTAssertEqual(reopened.library.recommendations, [item])
        reopened.removeCollection(reopened.library.collections[0])
        XCTAssertNil(reopened.library.recommendations[0].collectionID)
        XCTAssertTrue(reopened.remove(item))
        XCTAssertTrue(RecStore(url: url).library.recommendations.isEmpty)
    }
    @MainActor func testCorruptLibraryIsNotOverwritten() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let original = Data("broken".utf8)
        try original.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let store = RecStore(url: url)
        XCTAssertFalse(store.save(Recommendation(title: "New", person: "", category: .film)))
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
}
