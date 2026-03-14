import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.moveWeek(by: -1, appState: appState) }
                    } label: {
                        Label("上一周", systemImage: "chevron.left")
                    }

                    Spacer()

                    Button("本周") {
                        Task { await viewModel.resetToCurrentWeek(appState: appState) }
                    }
                    .font(.callout)

                    Spacer()

                    Button {
                        Task { await viewModel.moveWeek(by: 1, appState: appState) }
                    } label: {
                        Label("下一周", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                    }
                }
                .buttonStyle(.bordered)

                if let dateRange = viewModel.weekly?.dateRange {
                    Text("周范围：\(dateRange)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("缓存策略") {
                Picker("缓存 TTL", selection: $viewModel.selectedTTL) {
                    ForEach(viewModel.ttlOptions, id: \.self) { ttl in
                        Text(ttlTitle(ttl)).tag(ttl)
                    }
                }
                .pickerStyle(.menu)

                if let currentTTL = viewModel.weekly?.currentTTL, currentTTL > 0 {
                    Text("当前后端缓存：\(ttlTitle(currentTTL))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task { await viewModel.saveTTLConfig(appState: appState) }
                } label: {
                    if viewModel.isSavingConfig {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("保存缓存配置")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSavingConfig || viewModel.isLoading)
            }

            if let hint = viewModel.actionHint {
                Section {
                    Text(hint)
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            ForEach(viewModel.weekly?.days ?? []) { day in
                Section {
                    if day.items.isEmpty {
                        Text("当天暂无更新")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(day.items) { item in
                            CalendarItemRow(item: item)
                        }
                    }
                } header: {
                    HStack {
                        Text("\(day.weekdayCN) \(formattedDate(day.date))")
                        if day.isToday {
                            Text("Today")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .navigationTitle("追剧日历")
        .overlay {
            if viewModel.isLoading, (viewModel.weekly?.days.isEmpty ?? true) {
                ProgressView("加载中...")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load(appState: appState, forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.load(appState: appState)
        }
        .refreshable {
            await viewModel.load(appState: appState, forceRefresh: true)
        }
    }

    private func formattedDate(_ raw: String) -> String {
        let parts = raw.split(separator: "-")
        guard parts.count == 3 else { return raw }
        return "\(parts[1])-\(parts[2])"
    }

    private func ttlTitle(_ ttl: Int) -> String {
        switch ttl {
        case 0..<3600:
            return "\(ttl) 秒"
        case 3600..<86400:
            return "\(ttl / 3600) 小时"
        default:
            return "\(ttl / 86400) 天"
        }
    }
}

private struct CalendarItemRow: View {
    let item: CalendarItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: posterURL(from: item.posterPath)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    placeholder
                case .empty:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
            .frame(width: 48, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.seriesName)
                    .font(.headline)
                    .lineLimit(1)

                Text("S\(twoDigits(item.season))E\(item.episodeDisplay)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(statusTitle(for: item.status))
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(for: item.status).opacity(0.16))
                .foregroundStyle(statusColor(for: item.status))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
            Image(systemName: "film")
                .foregroundStyle(.secondary)
        }
    }

    private func posterURL(from posterPath: String?) -> URL? {
        guard let posterPath, !posterPath.isEmpty else { return nil }
        if posterPath.hasPrefix("http://") || posterPath.hasPrefix("https://") {
            return URL(string: posterPath)
        }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }

    private func twoDigits(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    private func statusTitle(for status: String) -> String {
        switch status {
        case "ready":
            return "已入库"
        case "missing":
            return "缺失"
        case "today":
            return "今日"
        default:
            return "待播"
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "ready":
            return .green
        case "missing":
            return .red
        case "today":
            return .orange
        default:
            return .gray
        }
    }

}
