import SwiftUI

struct OnboardingView: View {
    var finish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let titles = ["Good taste.\nGreat friends.", "Keep the what.\nRemember the who.", "Less scrolling.\nMore living."]
    private let subtitles = ["A little home for all the things people tell you you’ll love.", "Films, food, games, places. Save the suggestion and the person behind it.", "When “what should we do?” comes up, your next good idea is already here."]

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 7) { Image(systemName: "quote.bubble.fill").foregroundStyle(Color.coral); Text("what was that?").font(.system(.headline, design: .rounded)) }
                    Spacer()
                    Button("Skip") { finish() }.font(.subheadline).foregroundStyle(.secondary)
                }.padding(.top, 12)
                Spacer(minLength: 24)
                ZStack {
                    Circle().fill(Category.place.tint.opacity(0.35)).frame(width: 270, height: 270)
                    ticket(title: page == 1 ? "From Mia" : "A table for two", subtitle: "FOOD · FROM NOAH", category: .food)
                        .rotationEffect(.degrees(page == 2 ? -16 : -12)).offset(x: -26, y: -28)
                    ticket(title: page == 1 ? "Perfect Days" : page == 2 ? "Tonight, sorted." : "Perfect Days", subtitle: "FILM · FROM MIA", category: .film)
                        .rotationEffect(.degrees(page == 2 ? 4 : 8)).offset(x: 24, y: 50)
                    Image(systemName: page == 2 ? "shuffle" : "sparkle").font(.system(size: 23, weight: .medium))
                        .foregroundStyle(Color.coral).padding(20).glassEffect(.regular, in: Circle()).offset(x: 125, y: -90)
                }.frame(maxWidth: .infinity).frame(height: proxy.size.height < 700 ? 260 : 320).accessibilityHidden(true)
                Spacer(minLength: 24)
                Eyebrow(text: "YOUR NEXT GOOD THING")
                Text(titles[page]).font(.system(size: proxy.size.width < 370 ? 36 : 43, weight: .regular, design: .serif)).tracking(-1.5).fixedSize(horizontal: false, vertical: true).padding(.top, 13)
                    .id("title\(page)").transition(.opacity)
                Text(subtitles[page]).font(.body).foregroundStyle(.secondary).lineSpacing(4).fixedSize(horizontal: false, vertical: true).padding(.top, 16)
                Spacer(minLength: 24)
                HStack(spacing: 7) {
                    ForEach(0..<3) { index in Capsule().fill(index == page ? Color.coral : Color.ink.opacity(0.15)).frame(width: index == page ? 25 : 6, height: 6) }
                    Spacer()
                    Text("\(page + 1) / 3").font(.system(.caption, design: .monospaced)).foregroundStyle(.secondary)
                }.padding(.bottom, 24).accessibilityLabel("Page \(page + 1) of 3")
                PrimaryButton(title: page == 2 ? "Make room for good things" : "Sounds like me") {
                    if page == 2 { finish() } else { withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8)) { page += 1 } }
                }.accessibilityIdentifier("onboardingNext")
                Text("No account. Just your people’s good taste.").font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity).padding(.top, 16).padding(.bottom, 18)
            }.padding(.horizontal, 27).foregroundStyle(Color.ink).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.paper)
        }
    }

    private func ticket(title: String, subtitle: String, category: Category) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CategoryArt(category: category).frame(height: 112)
            VStack(alignment: .leading, spacing: 9) {
                Text(subtitle).font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(1.5)
                Text(title).font(.system(size: 22, design: .serif))
            }.foregroundStyle(Color(red: 0.15, green: 0.19, blue: 0.16)).padding(18)
        }.frame(width: 212).background(Color(red: 1, green: 0.99, blue: 0.97)).clipShape(.rect(cornerRadius: 20)).shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 14)
    }
}
