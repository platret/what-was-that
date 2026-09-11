import SwiftUI

extension Color {
    static let paper = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.09, green: 0.10, blue: 0.09, alpha: 1) : UIColor(red: 0.97, green: 0.96, blue: 0.93, alpha: 1) })
    static let ink = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1) : UIColor(red: 0.14, green: 0.18, blue: 0.16, alpha: 1) })
    static let coral = Color(red: 0.88, green: 0.27, blue: 0.16)
}

extension Category {
    var tint: Color {
        switch self {
        case .film: Color(red: 0.86, green: 0.89, blue: 0.72)
        case .food: Color(red: 0.97, green: 0.78, blue: 0.65)
        case .game: Color(red: 0.80, green: 0.82, blue: 0.96)
        case .place: Color(red: 0.71, green: 0.86, blue: 0.81)
        case .other: Color(red: 0.96, green: 0.88, blue: 0.64)
        }
    }
}

struct Eyebrow: View {
    var text: String
    var body: some View { Text(text.uppercased()).font(.system(.caption2, design: .monospaced, weight: .medium)).tracking(2).foregroundStyle(.secondary) }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    var title: String
    var symbol = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol) }
                .padding(.horizontal, 24).padding(.vertical, 19)
                .foregroundStyle(.white).background(Color.coral, in: Capsule())
        }.buttonStyle(PressStyle())
    }
}

struct CategoryArt: View {
    var category: Category
    var large = false
    var body: some View {
        ZStack {
            category.tint
            Circle().stroke(.black.opacity(0.07), lineWidth: 1).frame(width: large ? 250 : 100).offset(x: large ? 75 : 35, y: large ? -65 : -25)
            Circle().stroke(.black.opacity(0.07), lineWidth: 1).frame(width: large ? 190 : 70).offset(x: large ? 75 : 35, y: large ? -65 : -25)
            Image(systemName: category.symbol).font(.system(size: large ? 70 : 30, weight: .light)).foregroundStyle(Color(red: 0.20, green: 0.25, blue: 0.21)).rotationEffect(.degrees(-12))
            if large {
                Image(systemName: "sparkle").font(.title2).offset(x: 100, y: -45)
                Text("GOOD THINGS, PASSED ON.").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(3).offset(y: 83)
            }
        }.clipped().accessibilityHidden(true)
    }
}

struct RecCard: View {
    var item: Recommendation
    var body: some View {
        HStack(spacing: 16) {
            CategoryArt(category: item.category).frame(width: 76, height: 88).clipShape(.rect(cornerRadius: 17))
            VStack(alignment: .leading, spacing: 7) {
                Text(item.category.rawValue.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.6).foregroundStyle(.secondary)
                Text(item.title).font(.system(.headline, design: .serif)).foregroundStyle(Color.ink).lineLimit(2)
                Text(item.attribution).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: item.tried ? "checkmark.circle.fill" : item.favourite ? "heart.fill" : "arrow.up.right")
                .font(.system(size: 14)).foregroundStyle(item.favourite ? Color.coral : Color.ink.opacity(0.5))
        }.padding(.vertical, 12).contentShape(Rectangle())
            .accessibilityElement(children: .combine)
    }
}
