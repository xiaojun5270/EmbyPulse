import SwiftUI

struct FeedbackAdminView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = FeedbackAdminViewModel()
    @State private var filter: FeedbackFilter = .pending
    @State private var selectedFeedbackIDs: Set<Int> = []

    private var filteredFeedbacks: [ManagedFeedbackItem] {
        switch filter {
        case .all:
            return viewModel.feedbacks
        default:
            return viewModel.feedbacks.filter { $0.status == filter.statusValue }
        }
    }

    var body: some View {
        List {
            Section {
                Picker("状态", selection: $filter) {
                    ForEach(FeedbackFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.menu)

                if !filteredFeedbacks.isEmpty {
                    Button(selectedFeedbackIDs.count == filteredFeedbacks.count ? "取消全选" : "全选当前筛选") {
                        toggleSelectAll()
                    }
                    .buttonStyle(.bordered)
                }
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

            if !selectedFeedbackIDs.isEmpty {
                Section("批量操作（\(selectedFeedbackIDs.count)项）") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button("修复中") {
                                Task { await performBatch(.fix) }
                            }
                            .buttonStyle(.borderedProminent)

                            Button("已解决") {
                                Task { await performBatch(.done) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)

                            Button("忽略") {
                                Task { await performBatch(.reject) }
                            }
                            .buttonStyle(.bordered)

                            Button("删除", role: .destructive) {
                                Task { await performBatch(.delete) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Section("反馈工单") {
                if viewModel.isLoading && viewModel.feedbacks.isEmpty {
                    ProgressView("加载中...")
                } else if filteredFeedbacks.isEmpty {
                    Text("当前筛选下暂无反馈工单")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredFeedbacks) { item in
                        FeedbackAdminRow(
                            item: item,
                            isSelected: selectedFeedbackIDs.contains(item.id),
                            isOperating: viewModel.isOperating,
                            onToggleSelection: {
                                toggleSelection(id: item.id)
                            },
                            onAction: { action in
                                Task {
                                    await viewModel.perform(action: action, feedbackID: item.id, appState: appState)
                                    selectedFeedbackIDs.remove(item.id)
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("反馈工单")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isOperating)
            }
        }
        .task {
            await viewModel.load(appState: appState)
        }
        .refreshable {
            await viewModel.load(appState: appState)
        }
        .onChange(of: filter) { _ in
            selectedFeedbackIDs = selectedFeedbackIDs.filter { id in
                filteredFeedbacks.contains(where: { $0.id == id })
            }
        }
    }

    private func toggleSelection(id: Int) {
        if selectedFeedbackIDs.contains(id) {
            selectedFeedbackIDs.remove(id)
        } else {
            selectedFeedbackIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        let allIDs = Set(filteredFeedbacks.map(\.id))
        if !allIDs.isEmpty && selectedFeedbackIDs == allIDs {
            selectedFeedbackIDs.removeAll()
        } else {
            selectedFeedbackIDs = allIDs
        }
    }

    private func performBatch(_ action: ManageFeedbackAction) async {
        let ids = selectedFeedbackIDs.sorted()
        await viewModel.performBatch(action: action, feedbackIDs: ids, appState: appState)
        selectedFeedbackIDs.removeAll()
    }
}

private struct FeedbackAdminRow: View {
    let item: ManagedFeedbackItem
    let isSelected: Bool
    let isOperating: Bool
    let onToggleSelection: () -> Void
    let onAction: (ManageFeedbackAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    onToggleSelection()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Color.red : Color.secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.itemName)
                            .font(.headline)
                            .lineLimit(2)
                        Spacer()
                        statusBadge
                    }

                    HStack(spacing: 10) {
                        Text(item.username)
                        Text(item.issueType)
                            .foregroundStyle(.red)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }

                    if let createdAt = item.createdAt, !createdAt.isEmpty {
                        Text(createdAt.replacingOccurrences(of: "T", with: " ").prefix(16))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack {
                Spacer()
                if isOperating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Menu {
                        ForEach(availableActions, id: \.rawValue) { action in
                            if action == .delete {
                                Button(action.title, role: .destructive) {
                                    onAction(action)
                                }
                            } else {
                                Button(action.title) {
                                    onAction(action)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var availableActions: [ManageFeedbackAction] {
        let status = FeedbackStatus(rawValue: item.status)
        switch status {
        case .pending:
            return [.fix, .done, .reject, .delete]
        case .fixing:
            return [.done, .reject, .delete]
        case .done:
            return [.delete]
        case .ignored:
            return [.fix, .delete]
        }
    }

    private var statusBadge: some View {
        let status = FeedbackStatus(rawValue: item.status)
        return Text(status.title)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.15))
            .foregroundStyle(statusColor(status))
            .clipShape(Capsule())
    }

    private func statusColor(_ status: FeedbackStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .fixing:
            return .blue
        case .done:
            return .green
        case .ignored:
            return .gray
        }
    }
}

private enum FeedbackFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case fixing
    case done
    case ignored

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .pending:
            return "待核实"
        case .fixing:
            return "修复中"
        case .done:
            return "已解决"
        case .ignored:
            return "已忽略"
        }
    }

    var statusValue: Int {
        switch self {
        case .all:
            return -1
        case .pending:
            return FeedbackStatus.pending.rawValue
        case .fixing:
            return FeedbackStatus.fixing.rawValue
        case .done:
            return FeedbackStatus.done.rawValue
        case .ignored:
            return FeedbackStatus.ignored.rawValue
        }
    }
}
