import SwiftUI

struct UtilitiesHomeView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("运营工具中心")
                        .font(.headline)
                    Text("集中管理媒体质量、客户端风控、Bot通知与媒体检索。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            Section("质量与风控") {
                NavigationLink {
                    AdvancedStatsView()
                } label: {
                    UtilityRow(
                        title: "数据洞察",
                        subtitle: "热门内容、活跃用户、勋章画像、入库与媒体库视图",
                        systemImage: "chart.xyaxis.line"
                    )
                }

                NavigationLink {
                    InsightView()
                } label: {
                    UtilityRow(
                        title: "质量盘点/洞察",
                        subtitle: "分辨率/编码/HDR 分类查看，支持批量忽略与恢复",
                        systemImage: "rectangle.3.group.bubble.left.fill"
                    )
                }

                NavigationLink {
                    ClientsControlView()
                } label: {
                    UtilityRow(
                        title: "客户端管控",
                        subtitle: "黑名单管理、设备列表筛选与一键阻断",
                        systemImage: "desktopcomputer.trianglebadge.exclamationmark"
                    )
                }
            }

            Section("通知与检索") {
                NavigationLink {
                    BotConfigView()
                } label: {
                    UtilityRow(
                        title: "Bot/通知配置",
                        subtitle: "Telegram/企业微信配置、测试与回调地址管理",
                        systemImage: "bell.badge.fill"
                    )
                }

                NavigationLink {
                    LibrarySearchView()
                } label: {
                    UtilityRow(
                        title: "媒体库搜索",
                        subtitle: "按关键词检索媒体并跳转 Emby",
                        systemImage: "magnifyingglass"
                    )
                }
            }

            Section("系统与自动化") {
                NavigationLink {
                    SystemSettingsView()
                } label: {
                    UtilityRow(
                        title: "系统设置中心",
                        subtitle: "Emby/TMDB/MoviePilot 配置、Webhook 与数据库体检",
                        systemImage: "slider.horizontal.3"
                    )
                }

                NavigationLink {
                    TasksCenterView()
                } label: {
                    UtilityRow(
                        title: "任务中心",
                        subtitle: "计划任务查看、启动停止、中文别名管理",
                        systemImage: "bolt.horizontal.circle.fill"
                    )
                }

                NavigationLink {
                    ReportWorkshopView()
                } label: {
                    UtilityRow(
                        title: "映迹工坊",
                        subtitle: "观影报告预览与 Bot 推送",
                        systemImage: "photo.on.rectangle.angled"
                    )
                }
            }
        }
        .navigationTitle("工具")
    }
}

private struct UtilityRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.indigo)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
