import SwiftUI

/// Original vector companion: equal costume and abilities for both presentations.
struct HeroView: View {
    let companion: Companion
    var body: some View {
        if companion != .neutral {
            ZStack {
                Circle().fill(.teal.opacity(0.09)).frame(width: 168, height: 168)
                // Cape, boots, and arms use the same shapes for either hero.
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 28, bottomTrailingRadius: 28, topTrailingRadius: 8)
                    .fill(Color.orange.opacity(0.85)).frame(width: 100, height: 92).rotationEffect(.degrees(-8)).offset(y: 33)
                HStack(spacing: 16) {
                    Capsule().fill(.teal).frame(width: 22, height: 32)
                    Capsule().fill(.teal).frame(width: 22, height: 32)
                }.offset(y: 71)
                Capsule().fill(.teal).frame(width: 98, height: 22).rotationEffect(.degrees(-10)).offset(y: 20)
                RoundedRectangle(cornerRadius: 22).fill(.teal).frame(width: 64, height: 69).offset(y: 33)
                Image(systemName: "sparkle").font(.system(size: 28, weight: .bold)).foregroundStyle(.white).offset(y: 29)
                if companion == .girl {
                    RoundedRectangle(cornerRadius: 25).fill(Color.brown.opacity(0.9)).frame(width: 76, height: 69).offset(y: -23)
                }
                Circle().fill(Color(red: 0.72, green: 0.46, blue: 0.29)).frame(width: 68, height: 68).offset(y: -31)
                Ellipse().fill(Color.brown).frame(width: 69, height: 25).rotationEffect(.degrees(-10)).offset(y: -58)
                Capsule().fill(.teal).frame(width: 65, height: 21).offset(y: -34)
                HStack(spacing: 20) {
                    Circle().fill(.white).frame(width: 8, height: 8)
                    Circle().fill(.white).frame(width: 8, height: 8)
                }.offset(y: -34)
                Capsule().fill(.white).frame(width: 17, height: 4).offset(y: -12)
            }.frame(height: 190)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(companion.rawValue + ", a smiling superhero wearing a teal suit and orange cape")
        }
    }
}

struct SupportCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(.teal.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
    }
}
