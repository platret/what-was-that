import SwiftUI

struct PickView: View {
    @Environment(RecStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var category: Category?
    @State private var pickedID: UUID?
    @State private var spinning = false
    @State private var rotation = 0.0
    @State private var pickerTask: Task<Void, Never>?
    private var candidates: [Recommendation] { store.library.filtered(category: category, tried: false) }
    private var picked: Recommendation? { candidates.first { $0.id == pickedID } }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Eyebrow(text: "LET A GOOD IDEA FIND YOU").padding(.top, 14)
                Text("Your next\ngood thing.").font(.system(size: 39, design: .serif)).tracking(-1.4).multilineTextAlignment(.center)
                Text("A little nudge from people you trust.").font(.subheadline).foregroundStyle(.secondary)
                Menu {
                    Button("Anything sounds good") { reset(nil) }
                    ForEach(Category.allCases) { value in Button(value.verb, systemImage: value.symbol) { reset(value) } }
                } label: { HStack { Text(category?.verb ?? "Anything sounds good"); Image(systemName: "chevron.down").font(.caption2) }.font(.subheadline).padding(.horizontal, 20).padding(.vertical, 14).glassEffect() }
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Category.food.tint).rotationEffect(.degrees(-5)).padding(.horizontal, 8)
                    RoundedRectangle(cornerRadius: 28).fill(Category.place.tint).rotationEffect(.degrees(4)).padding(.horizontal, 6)
                    VStack(spacing: 19) {
                        if let picked {
                            Image(systemName: picked.category.symbol).font(.system(size: 45, weight: .ultraLight)).foregroundStyle(Color.coral)
                            Eyebrow(text: "YOUR NEXT GOOD THING")
                            Text(picked.title).font(.system(size: 31, design: .serif)).multilineTextAlignment(.center)
                            Text(picked.attribution).font(.subheadline).foregroundStyle(.secondary)
                            NavigationLink("Tell me more →") { DetailView(itemID: picked.id) }.font(.subheadline.weight(.semibold))
                        } else {
                            Image(systemName: "shuffle").font(.system(size: 60, weight: .ultraLight)).foregroundStyle(Color.coral).rotationEffect(.degrees(rotation))
                            Text(candidates.isEmpty ? "Good things start\nwith one suggestion." : "Something good\nis in the cards.").font(.system(size: 29, design: .serif)).multilineTextAlignment(.center)
                            Text(candidates.isEmpty ? "Save an idea in this category first." : "\(candidates.count) untried \(candidates.count == 1 ? "idea" : "ideas"), picked with care.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.frame(maxWidth: .infinity).frame(minHeight: 210).padding(22).background(Color.paper, in: .rect(cornerRadius: 26)).overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.ink.opacity(0.10)))
                }.padding(.horizontal, 16).padding(.vertical, 10)

            }.padding(.horizontal, 26).padding(.bottom, 18)
        }.background(Color.paper).foregroundStyle(Color.ink).navigationTitle("A little serendipity").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    PrimaryButton(title: spinning ? "Finding your next thing…" : picked == nil ? "Pick for me" : "Another good idea", symbol: "shuffle") { pick() }.disabled(candidates.isEmpty || spinning).opacity(candidates.isEmpty ? 0.45 : 1).accessibilityIdentifier("shufflePick")
                    Text("Only things you haven’t tried. Always from your list.").font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(.horizontal, 26).padding(.top, 12).padding(.bottom, 12).background(Color.paper)
            }
            .onDisappear { pickerTask?.cancel(); spinning = false }
    }

    private func reset(_ value: Category?) { pickerTask?.cancel(); spinning = false; category = value; pickedID = nil }
    private func pick() {
        let previous = pickedID
        pickedID = nil; spinning = true
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.65)) { rotation += 360 }
        pickerTask = Task { @MainActor in
            if !reduceMotion { try? await Task.sleep(for: .milliseconds(650)) }
            guard !Task.isCancelled else { return }
            let pool = candidates.count > 1 ? candidates.filter { $0.id != previous } : candidates
            withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.8)) { pickedID = pool.randomElement()?.id; spinning = false }
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
}
