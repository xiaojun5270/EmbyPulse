import SwiftUI

struct TasksCenterView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = TasksCenterViewModel()

    @State private var renameTarget: ScheduledTask?
    @State private var renameText: String = ""

    var body: some View {
        List {
            if !viewModel.runningTasks.isEmpty {
                Section("运行中任务") {
                    ForEach(viewModel.runningTasks) { task in
                        RunningTaskRow(
                            task: task,
                            isOperating: viewModel.isOperating(taskID: task.id),
                            onStop: {
                                Task { await viewModel.stop(task: task, appState: appState) }
                            }
                        )
                    }
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

            if viewModel.groups.isEmpty {
                Section {
                    if viewModel.isLoading {
                        ProgressView("加载任务中...")
                    } else {
                        Text("暂无任务数据")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ForEach(viewModel.groups) { group in
                    Section(group.title) {
                        ForEach(group.tasks) { task in
                            TaskRow(
                                task: task,
                                isOperating: viewModel.isOperating(taskID: task.id),
                                onStart: {
                                    Task { await viewModel.start(task: task, appState: appState) }
                                },
                                onStop: {
                                    Task { await viewModel.stop(task: task, appState: appState) }
                                },
                                onRename: {
                                    renameTarget = task
                                    renameText = task.name == task.originalName ? "" : task.name
                                },
                                onResetName: {
                                    Task {
                                        await viewModel.rename(
                                            task: task,
                                            translatedName: "",
                                            appState: appState
                                        )
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("任务中心")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.load(appState: appState) }
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
            await viewModel.load(appState: appState)
        }
        .sheet(item: $renameTarget) { task in
            NavigationStack {
                Form {
                    Section("原任务名") {
                        Text(task.originalName)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section("中文别名") {
                        TextField("留空后保存可恢复默认", text: $renameText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                .navigationTitle("任务别名")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            renameTarget = nil
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            Task {
                                await viewModel.rename(
                                    task: task,
                                    translatedName: renameText,
                                    appState: appState
                                )
                                renameTarget = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct RunningTaskRow: View {
    let task: ScheduledTask
    let isOperating: Bool
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                if isOperating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("停止", role: .destructive) {
                        onStop()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            ProgressView(value: task.displayProgress, total: 100)
                .tint(.blue)

            Text("进度 \(String(format: "%.1f", task.displayProgress))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

private struct TaskRow: View {
    let task: ScheduledTask
    let isOperating: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onRename: () -> Void
    let onResetName: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .lineLimit(2)

                    if task.name != task.originalName {
                        Text(task.originalName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                if task.isRunning {
                    Text("运行中")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.16))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                } else {
                    statusBadge
                }
            }

            if task.isRunning {
                ProgressView(value: task.displayProgress, total: 100)
                    .tint(.blue)
            }

            HStack(spacing: 10) {
                if let result = task.lastExecutionResult {
                    Text("最近执行：\(result.statusTitle)")
                        .foregroundStyle(statusColor(result.statusColorHex))
                } else {
                    Text("最近执行：无记录")
                        .foregroundStyle(.secondary)
                }

                if let time = task.lastExecutionResult?.endTimeUTC, !time.isEmpty {
                    Text(formatTime(time))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption2)

            HStack {
                Spacer()

                if isOperating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Menu {
                        if task.isRunning {
                            Button("停止任务", role: .destructive) {
                                onStop()
                            }
                        } else {
                            Button("启动任务") {
                                onStart()
                            }
                        }
                        Button("设置别名") {
                            onRename()
                        }
                        if task.name != task.originalName {
                            Button("恢复默认名") {
                                onResetName()
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

    private var statusBadge: some View {
        Text(task.lastExecutionResult?.statusTitle ?? "无记录")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(task.lastExecutionResult?.statusColorHex ?? "gray").opacity(0.16))
            .foregroundStyle(statusColor(task.lastExecutionResult?.statusColorHex ?? "gray"))
            .clipShape(Capsule())
    }

    private func statusColor(_ key: String) -> Color {
        switch key {
        case "green":
            return .green
        case "red":
            return .red
        case "orange":
            return .orange
        default:
            return .gray
        }
    }

    private func formatTime(_ raw: String) -> String {
        raw.replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")
            .prefix(16)
            .description
    }
}
