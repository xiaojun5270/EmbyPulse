import SwiftUI

struct AnalysisHubView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                    heroCard

                    LazyVGrid(columns: gridColumns(for: proxy.size.width), spacing: 12) {
                        analysisLink(
                            title: "内容排行",
                            subtitle: "年度风云榜与极客入围名单",
                            symbol: "chart.bar.doc.horizontal",
                            accent: .blue
                        ) {
                            HistoryTrendView()
                        }

                        analysisLink(
                            title: "映迹工坊",
                            subtitle: "报表预览、主题样式、推送发送",
                            symbol: "sparkles.rectangle.stack",
                            accent: .orange
                        ) {
                            ReportWorkshopView()
                        }

                        analysisLink(
                            title: "数据洞察",
                            subtitle: "画像、趋势、日志、库视图",
                            symbol: "waveform.path.ecg.rectangle",
                            accent: .mint
                        ) {
                            AdvancedStatsView()
                        }

                        analysisLink(
                            title: "质量盘点",
                            subtitle: "分辨率矩阵与回收站",
                            symbol: "checklist.unchecked",
                            accent: .purple
                        ) {
                            InsightView()
                        }

                        analysisLink(
                            title: "缺集管理",
                            subtitle: "自动巡检、深度重扫、回收站",
                            symbol: "dot.radiowaves.left.and.right",
                            accent: .indigo
                        ) {
                            GapManagementView()
                        }
                    }
                }
                .padding(ConsoleDesign.pagePadding)
            }
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("分析")
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分析工作台")
                .font(ConsoleDesign.heroTitleFont)
                .foregroundStyle(isDark ? .white : .primary)

            Text("从排行、海报、洞察到质量盘点，集中进入运营分析模块")
                .font(.footnote)
                .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))

            HStack(spacing: 8) {
                heroTag("5 个模块")
                heroTag("运营视角")
                heroTag("即时刷新")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.18, green: 0.30, blue: 0.42), Color(red: 0.14, green: 0.23, blue: 0.33)]
                    : [Color(red: 0.74, green: 0.89, blue: 1.0), Color(red: 0.88, green: 0.96, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.heroCornerRadius, style: .continuous)
                .stroke(ConsoleDesign.heroBorderColor(isDark: isDark), lineWidth: 1)
        )
    }

    private func heroTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(isDark ? 0.14 : 0.74))
            .clipShape(Capsule())
    }

    private func analysisLink<Destination: View>(
        title: String,
        subtitle: String,
        symbol: String,
        accent: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination().consoleBackButton()
        } label: {
            AnalysisCard(
                title: title,
                subtitle: subtitle,
                symbol: symbol,
                tint: accent,
                isDark: isDark
            )
        }
        .buttonStyle(.plain)
    }

    private func gridColumns(for width: CGFloat) -> [GridItem] {
        if width >= 680 {
            return [
                GridItem(.flexible(minimum: 280), spacing: 12),
                GridItem(.flexible(minimum: 280), spacing: 12)
            ]
        }
        return [GridItem(.flexible(), spacing: 12)]
    }

    private var pageGradient: LinearGradient {
        if isDark {
            return LinearGradient(
                colors: [Color(red: 0.07, green: 0.10, blue: 0.16), Color(red: 0.08, green: 0.14, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color(red: 0.96, green: 0.97, blue: 1.0), Color(red: 0.95, green: 0.99, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var isDark: Bool {
        appState.appearanceMode == .dark
    }
}

private struct AnalysisCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let isDark: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(0.15))
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                        .stroke(tint.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: tint.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
