import SwiftUI
import UIKit

struct SystemSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = SystemSettingsViewModel()
    @State private var selectedUserIDToHide: String = ""

    private var selectableUsers: [EmbyUserOption] {
        viewModel.availableUsersForHiddenSelection()
    }

    var body: some View {
        List {
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

            Section("Emby 核心连接") {
                TextField("Emby 地址", text: $viewModel.draft.embyHost)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Emby API Key", text: $viewModel.draft.embyAPIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("对外服务门户") {
                TextField("公网访问入口", text: $viewModel.draft.embyPublicURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("客户端下载链接（可选）", text: $viewModel.draft.clientDownloadURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("欢迎语（可选）", text: $viewModel.draft.welcomeMessage, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section("MoviePilot 自动化") {
                TextField("MoviePilot 地址", text: $viewModel.draft.moviepilotURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("MoviePilot Token", text: $viewModel.draft.moviepilotToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Pulse 审批回跳地址", text: $viewModel.draft.pulseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await viewModel.testMoviePilot(appState: appState) }
                } label: {
                    if viewModel.isTestingMP {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("测试 MoviePilot 连通性")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving || viewModel.isTestingTMDB || viewModel.isFixingDatabase)
            }

            Section("TMDB 与网络") {
                SecureField("TMDB API Key（可选）", text: $viewModel.draft.tmdbAPIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("全局代理地址（可选）", text: $viewModel.draft.proxyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                HStack(spacing: 10) {
                    Button {
                        Task { await viewModel.testTMDB(appState: appState) }
                    } label: {
                        if viewModel.isTestingTMDB {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("测试 TMDB")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isSaving || viewModel.isTestingMP || viewModel.isFixingDatabase)

                    Button {
                        Task { await viewModel.fixDatabase(appState: appState) }
                    } label: {
                        if viewModel.isFixingDatabase {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("数据库体检/修复")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSaving || viewModel.isTestingTMDB || viewModel.isTestingMP)
                }
            }

            Section("Webhook 安全") {
                TextField("Webhook Token", text: $viewModel.draft.webhookToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                URLDisplayBlock(
                    title: "完整 Webhook 地址",
                    value: viewModel.webhookURL(baseURL: appState.environment.baseURL)
                )
            }

            Section("隐藏用户黑名单") {
                if selectableUsers.isEmpty {
                    Text("暂无可添加用户")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("选择用户", selection: $selectedUserIDToHide) {
                        Text("请选择").tag("")
                        ForEach(selectableUsers) { user in
                            Text(user.userName).tag(user.userID)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("添加到隐藏列表") {
                        viewModel.addHiddenUser(userID: selectedUserIDToHide)
                        selectedUserIDToHide = ""
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedUserIDToHide.isEmpty)
                }

                if viewModel.draft.hiddenUsers.isEmpty {
                    Text("当前未隐藏任何用户")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.draft.hiddenUsers, id: \.self) { userID in
                        HStack {
                            Text(viewModel.userName(for: userID))
                            Spacer()
                            Button("移除", role: .destructive) {
                                viewModel.removeHiddenUser(userID: userID)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .navigationTitle("系统设置中心")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.save(appState: appState) }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("保存")
                    }
                }
                .disabled(viewModel.isTestingTMDB || viewModel.isTestingMP || viewModel.isFixingDatabase)
            }
        }
        .task {
            await viewModel.load(appState: appState)
            if selectedUserIDToHide.isEmpty {
                selectedUserIDToHide = selectableUsers.first?.userID ?? ""
            }
        }
        .refreshable {
            await viewModel.load(appState: appState)
            if !selectableUsers.contains(where: { $0.userID == selectedUserIDToHide }) {
                selectedUserIDToHide = selectableUsers.first?.userID ?? ""
            }
        }
    }
}

private struct URLDisplayBlock: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text(value)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                Spacer()

                Button("复制") {
                    UIPasteboard.general.string = value
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}
