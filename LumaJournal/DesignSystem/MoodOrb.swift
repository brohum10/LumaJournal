import SwiftUI

struct MoodOrb: View {
    let score: Int?
    private var color: Color {
        switch score ?? 3 {
        case 1: .purple
        case 2: .blue
        case 4: .orange
        case 5: .pink
        default: .indigo
        }
    }

    var body: some View {
        Circle()
            .fill(LinearGradient(colors: [color, color.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 44, height: 44)
            .overlay(Image(systemName: "sparkles").foregroundStyle(.white))
            .accessibilityHidden(true)
    }
}
