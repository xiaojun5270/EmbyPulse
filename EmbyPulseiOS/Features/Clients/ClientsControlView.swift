import Charts
import SwiftUI

struct ClientsControlView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ClientsControlViewModel()

    @State private var appFilter: String = "全部"
    @State private var keyword: String = ""
    @State private var showBlockConfirm = false

    private var totalCount: Int {
        viewModel.devices.count
    }

    private var activeCount: Int {
        viewModel.devices.filter(\.isActive).count
    }

    private var blockedCount: Int {
        viewModel.devices.filter(\.isBlocked).count
    }

    private var appOptions: [String] {
        let values = Set(viewModel.devices.map(\.appName))
        return ["全部"] + values.sorted()
    }

    private var filteredDevices: [ClientDeviceItem] {
        viewModel.devices.filter { item in
            let passApp = appFilter == "全部" || item.appName == appFilter
            let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedKeyword.isEmpty {
                return passApp
            }
            let text = [item.name, item.appName, item.lastUser].joined(separator: " ").lowercased()
            return passApp && text.contains(trimmedKeyword.lowercased())
        }
    }

    var body: some View {
        List {
            summarySection
            blacklistSection
            actionSection
            chartSection
            deviceSection
        }
        .navigationTitle("客户端管控")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isExecutingBlock)
            }
        }
        .task {
            await viewModel.load(appState: appState)
        }
        .refreshable {
            await viewModel.load(appState: appState)
        }
        .confirmationDialog(
            "执行阻断将注销黑名单客户端登录状态，确定继续？",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("立即执行", role: .destructive) {
                Task { await viewModel.executeBlock(appState: appState) }
            }
            Button("取消", role: .cancel) {}
        }
        .onChange(of: appOptions) { options in
            if !options.contains(appFilter) {
                appFilter = "全部"
            }
        }
    }

    private var summarySection: some View {
        Section("概览") {
            HStack {
                SummaryBadge(title: "设备总数", value: "\(totalCount)", tint: .blue)
                Spacer()
                SummaryBadge(title: "在线设备", value: "\(activeCount)", tint: .green)
                Spacer()
                SummaryBadge(title: "已拦截", value: "\(blockedCount)", tint: .red)
            }
        }
    }

    private var blacklistSection: some View {
        Section("软件黑名单") {
            HStack(spacing: 10) {
                TextField("客户端名，如 Fileball", text: $viewModel.newBlacklistAppName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                Button("添加") {
                    Task { await viewModel.addBlacklist(appState: appState) }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoading || viewModel.isExecutingBlock)
            }

            if viewModel.blacklist.isEmpty {
                Text("当前黑名单为空")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.blacklist) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.appName)
                                .fontWeight(.semibold)
                            if let createdAt = item.createdAt, !createdAt.isEmpty {
                                Text(createdAt.replacingOccurrences(of: "T", with: " "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("移除", role: .destructive) {
                            Task {
                                await viewModel.removeBlacklist(appState: appState, appName: item.appName)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section("阻断执行") {
            Button(role: .destructive) {
                showBlockConfirm = true
            } label: {
                if viewModel.isExecutingBlock {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("执行全服阻断")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isExecutingBlock || viewModel.blacklist.isEmpty)

            if let hint = viewModel.actionHint {
                Text(hint)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
    }

    private var chartSection: some View {
        Section("统计图") {
            if viewModel.isLoading && viewModel.piePoints.isEmpty && viewModel.barPoints.isEmpty {
                ProgressView("加载中...")
            } else {
                if viewModel.piePoints.isEmpty {
                    Text("暂无客户端生态分布数据")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("客户端生态分布")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Chart(viewModel.piePoints) { point in
                            BarMark(
                                x: .value("数量", point.value),
                                y: .value("客户端", point.label)
                            )
                            .foregroundStyle(.indigo)
                        }
                        .frame(height: chartHeight(for: viewModel.piePoints.count))
                        .chartXAxis {
                            AxisMarks(position: .bottom)
                        }
                    }
                }

                if viewModel.barPoints.isEmpty {
                    Text("暂无高频设备数据")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("高频设备 TOP 10")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Chart(viewModel.barPoints) { point in
                            BarMark(
                                x: .value("次数", point.value),
                                y: .value("设备", point.label)
                            )
                            .foregroundStyle(.orange)
                        }
                        .frame(height: chartHeight(for: viewModel.barPoints.count))
                        .chartXAxis {
                            AxisMarks(position: .bottom)
                        }
                    }
                }
            }
        }
    }

    private var deviceSection: some View {
        Section("设备列表") {
            TextField("搜索 设备/客户端/用户", text: $keyword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Picker("客户端筛选", selection: $appFilter) {
                ForEach(appOptions, id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.menu)

            if filteredDevices.isEmpty {
                Text("暂无匹配设备")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredDevices) { item in
                    ClientDeviceRow(item: item)
                }
            }
        }
    }

    private func chartHeight(for count: Int) -> CGFloat {
        CGFloat(max(180, min(360, count * 26)))
    }
}

private struct SummaryBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(tint)
        }
    }
}

private struct ClientDeviceRow: View {
    let item: ClientDeviceItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(item.isActive ? Color.green : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                statusBadge
            }

            HStack(spacing: 10) {
                Label(item.appName, systemImage: "desktopcomputer")
                Label(item.lastUser, systemImage: "person")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(item.lastActive)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var statusBadge: some View {
        Text(item.isBlocked ? "已拦截" : "正常")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((item.isBlocked ? Color.red : Color.green).opacity(0.15))
            .foregroundStyle(item.isBlocked ? Color.red : Color.green)
            .clipShape(Capsule())
    }
}
