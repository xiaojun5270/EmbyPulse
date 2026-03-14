import SwiftUI

enum ConsoleDesign {
    static let pagePadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16
    static let cardPadding: CGFloat = 14
    static let cardCornerRadius: CGFloat = 18
    static let heroCornerRadius: CGFloat = 22

    static let heroTitleFont: Font = .system(size: 24, weight: .heavy, design: .rounded)
    static let sectionTitleFont: Font = .system(.headline, design: .rounded).weight(.bold)

    static func heroMutedTextColor(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.82) : .secondary
    }

    static func heroBadgeForeground(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.92) : Color.indigo.opacity(0.88)
    }

    static func heroBadgeBackground(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : Color.white.opacity(0.62)
    }

    static func heroPillTitleColor(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.74) : .secondary
    }

    static func heroPillValueColor(isDark: Bool) -> Color {
        isDark ? .white : .primary
    }

    static func heroPillBackground(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.13) : Color.white.opacity(0.72)
    }

    static func heroBorderColor(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.10)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ConsoleBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.bold))
                        Text("返回")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(isDark ? Color.white.opacity(0.96) : Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isDark ? Color.black.opacity(0.34) : Color.white.opacity(0.92))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.10), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.leading, ConsoleDesign.pagePadding)
                .padding(.top, 8)
            }
    }

    private var isDark: Bool {
        colorScheme == .dark
    }
}

extension View {
    func consoleBackButton() -> some View {
        modifier(ConsoleBackButtonModifier())
    }
}
