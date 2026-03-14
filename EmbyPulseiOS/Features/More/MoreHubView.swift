import SwiftUI

struct MoreHubView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroCard

                sectionCard(title: "运营管理", subtitle: "管理端与用户侧流程", symbol: "rectangle.3.group") {
                    NavigationLink {
                        CalendarView().consoleBackButton()
                    } label: {
                        MoreRow(title: "追剧日历", subtitle: "剧集更新与缓存策略", symbol: "calendar.badge.clock", isDark: isDark)
                    }

                    NavigationLink {
                        FeedbackAdminView().consoleBackButton()
                    } label: {
                        MoreRow(title: "反馈工单", subtitle: "报错工单处理与批量操作", symbol: "exclamationmark.bubble", isDark: isDark)
                    }

                    NavigationLink {
                        RequestPortalView().consoleBackButton()
                    } label: {
                        MoreRow(title: "用户侧求片", subtitle: "登录、搜索、提交与报错", symbol: "ticket", isDark: isDark)
                    }

                    NavigationLink {
                        UserManagementView().consoleBackButton()
                    } label: {
                        MoreRow(title: "用户管理", subtitle: "账号、续期、邀请码、批量管理", symbol: "person.2", isDark: isDark)
                    }
                }

                sectionCard(title: "系统工具", subtitle: "服务配置与任务管理", symbol: "wrench.and.screwdriver") {
                    NavigationLink {
                        BotConfigView().consoleBackButton()
                    } label: {
                        MoreRow(title: "Bot/通知配置", subtitle: "Telegram / 企业微信配置", symbol: "bell.badge", isDark: isDark)
                    }

                    NavigationLink {
                        SystemSettingsView().consoleBackButton()
                    } label: {
                        MoreRow(title: "系统设置中心", subtitle: "Emby/TMDB/MP 与数据库工具", symbol: "slider.horizontal.3", isDark: isDark)
                    }

                    NavigationLink {
                        TasksCenterView().consoleBackButton()
                    } label: {
                        MoreRow(title: "任务中心", subtitle: "计划任务启停与别名", symbol: "bolt.horizontal.circle", isDark: isDark)
                    }
                }

                sectionCard(title: "客户端", subtitle: "本地配置与会话管理", symbol: "iphone.gen3") {
                    NavigationLink {
                        SettingsView().consoleBackButton()
                    } label: {
                        MoreRow(title: "本地设置", subtitle: "服务地址与会话控制", symbol: "gearshape", isDark: isDark)
                    }
                }
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("更多")
    }

    private var heroCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("更多功能")
                    .font(ConsoleDesign.heroTitleFont)
                    .foregroundStyle(isDark ? .white : .primary)

                Text("服务配置、任务管理与运营工具入口")
                    .font(.footnote)
                    .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))

                HStack(spacing: 8) {
                    heroTag("运营")
                    heroTag("系统")
                    heroTag("客户端")
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "square.grid.2x2.fill")
                .font(.title2)
                .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                .frame(width: 42, height: 42)
                .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.20, green: 0.25, blue: 0.38), Color(red: 0.16, green: 0.20, blue: 0.32)]
                    : [Color(red: 0.84, green: 0.90, blue: 1.0), Color(red: 0.90, green: 0.96, blue: 0.98)],
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

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.indigo)
                    .frame(width: 32, height: 32)
                    .background(Color.indigo.opacity(isDark ? 0.26 : 0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ConsoleDesign.sectionTitleFont)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                content()
            }
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                        .stroke(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(isDark ? 0.2 : 0.06), radius: 8, x: 0, y: 4)
        )
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

private struct MoreRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isDark: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.indigo.opacity(0.16))
                Image(systemName: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.indigo)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isDark ? Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.96) : Color.white.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.indigo.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
