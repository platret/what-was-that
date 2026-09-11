import WidgetKit
import SwiftUI
import AppIntents

enum WidgetCategory: String, AppEnum {
    case any, films, food, games, places, other
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
    static let caseDisplayRepresentations: [WidgetCategory: DisplayRepresentation] = [.any: "Anything", .films: "Films", .food: "Food", .games: "Games", .places: "Places", .other: "Other"]
    var category: Category? {
        switch self { case .any: nil; case .films: .film; case .food: .food; case .games: .game; case .places: .place; case .other: .other }
    }
}

enum WidgetColour: String, AppEnum {
    case sage, peach, lavender, cream
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Colour")
    static let caseDisplayRepresentations: [WidgetColour: DisplayRepresentation] = [.sage: "Sage", .peach: "Peach", .lavender: "Lavender", .cream: "Cream"]
    var colour: Color {
        switch self { case .sage: Color(red: 0.86, green: 0.89, blue: 0.72); case .peach: Color(red: 0.97, green: 0.78, blue: 0.65); case .lavender: Color(red: 0.80, green: 0.82, blue: 0.96); case .cream: Color(red: 0.97, green: 0.96, blue: 0.93) }
    }
}

struct CollectionEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Collection")
    static let defaultQuery = CollectionQuery()
    var id: String
    var name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct CollectionQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CollectionEntity] { try await suggestedEntities().filter { identifiers.contains($0.id) } }
    func suggestedEntities() async throws -> [CollectionEntity] {
        try LibraryDisk.read().collections.map { CollectionEntity(id: $0.id.uuidString, name: $0.name) }
    }
}

struct PickConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Your next good thing"
    static let description = IntentDescription("Choose the kind of recommendation and make it your colour.")
    @Parameter(title: "Category", default: .any) var category: WidgetCategory
    @Parameter(title: "Colour", default: .sage) var colour: WidgetColour
    @Parameter(title: "Collection") var collection: CollectionEntity?
}

struct PickEntry: TimelineEntry {
    var date: Date
    var item: Recommendation?
    var colour: WidgetColour = .sage
}

struct PickProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PickEntry { PickEntry(date: .now, item: Recommendation(title: "Your next good thing", person: "your people", category: .film)) }
    func snapshot(for configuration: PickConfiguration, in context: Context) async -> PickEntry {
        if context.isPreview { return placeholder(in: context) }
        return entries(configuration).first ?? PickEntry(date: .now)
    }
    func timeline(for configuration: PickConfiguration, in context: Context) async -> Timeline<PickEntry> { Timeline(entries: entries(configuration), policy: .atEnd) }
    private func entries(_ config: PickConfiguration) -> [PickEntry] {
        let library = (try? LibraryDisk.read()) ?? Library()
        let candidates = library.filtered(category: config.category.category, tried: false).filter { config.collection == nil || $0.collectionID?.uuidString == config.collection?.id }.shuffled()
        return (0..<6).map { index in PickEntry(date: .now.addingTimeInterval(Double(index) * 3600), item: candidates.isEmpty ? nil : candidates[index % candidates.count], colour: config.colour) }
    }
}

struct PickWidgetView: View {
    var entry: PickEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: "quote.bubble"); Spacer(); Image(systemName: "arrow.up.right") }.font(.caption)
                Spacer(minLength: 0)
                Text(entry.item?.title ?? "Good things\nstart here.").font(.system(family == .systemSmall ? .title3 : .title2, design: .serif)).lineLimit(3).minimumScaleFactor(0.8)
                Text(entry.item?.attribution ?? "Save your first idea").font(.caption2).lineLimit(1)
            }
            if family == .systemMedium { Image(systemName: entry.item?.category.symbol ?? "bookmark").font(.system(size: 47, weight: .ultraLight)).frame(width: 70).rotationEffect(.degrees(-12)) }
        }.foregroundStyle(Color(red: 0.15, green: 0.20, blue: 0.16)).containerBackground(entry.colour.colour, for: .widget)
            .widgetURL(URL(string: "whatwasthat://recommendation/\(entry.item?.id.uuidString ?? "home")"))
    }
}

@main struct WhatWasThatWidgets: Widget {
    let kind = "WhatWasThatPick"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PickConfiguration.self, provider: PickProvider()) { PickWidgetView(entry: $0) }
            .configurationDisplayName("Your next good thing")
            .description("A recommendation from your people. Pick a category, collection, and colour.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
