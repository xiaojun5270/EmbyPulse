import SwiftUI
import UIKit

struct BotConfigView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = BotConfigViewModel()

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

            Section("推送场景") {
                Toggle("启用 Bot 引擎", isOn: $viewModel.draft.enableBot)
                Toggle("播放状态通知", isOn: $viewModel.draft.enableNotify)
                Toggle("新资源入库通知", isOn: $viewModel.draft.enableLibraryNotify)
            }

            Section("Telegram") {
                SecureField("Bot Token", text: $viewModel.draft.tgBotToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("Admin Chat ID（可选）", text: $viewModel.draft.tgChatID)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await viewModel.testTelegram(appState: appState) }
                } label: {
                    if viewModel.isTestingTelegram {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("发送 Telegram 测试")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving || viewModel.isTestingWeCom)
            }

            Section("企业微信基础") {
                TextField("企业 ID (wecom_corpid)", text: $viewModel.draft.wecomCorpid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("应用 Secret (wecom_corpsecret)", text: $viewModel.draft.wecomCorpsecret)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("应用 ID (wecom_agentid)", text: $viewModel.draft.wecomAgentid)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                TextField("接收人 (wecom_touser)", text: $viewModel.draft.wecomTouser)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    Task { await viewModel.testWeCom(appState: appState) }
                } label: {
                    if viewModel.isTestingWeCom {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("发送企业微信测试")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving || viewModel.isTestingTelegram)
            }

            Section("企业微信回调") {
                SecureField("回调 Token（可选）", text: $viewModel.draft.wecomToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField("Encoding AESKey（可选）", text: $viewModel.draft.wecomAESKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                URLDisplayRow(
                    title: "企业微信回调 URL",
                    value: viewModel.wecomWebhookURL(baseURL: appState.environment.baseURL)
                )
            }

            Section("企业微信代理") {
                TextField("API 代理地址", text: $viewModel.draft.wecomProxyURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if viewModel.draft.enableLibraryNotify {
                Section("Emby 入库 Webhook") {
                    URLDisplayRow(
                        title: "Webhook URL",
                        value: viewModel.telegramWebhookURL(baseURL: appState.environment.baseURL)
                    )
                }
            }

            Section("内置指令") {
                BotCommandRow(command: "/stats", description: "每日/周播放统计报表")
                BotCommandRow(command: "/now", description: "实时正在播放")
                BotCommandRow(command: "/latest", description: "最新入库资源")
                BotCommandRow(command: "/recent", description: "最近播放历史")
                BotCommandRow(command: "/search", description: "搜索媒体资源")
                BotCommandRow(command: "/check", description: "网络连通性检查")
            }
        }
        .navigationTitle("Bot与通知")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { _ = await viewModel.save(appState: appState) }
                } label: {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("保存")
                    }
                }
                .disabled(viewModel.isTestingTelegram || viewModel.isTestingWeCom)
            }
        }
        .task {
            await viewModel.load(appState: appState)
        }
        .refreshable {
            await viewModel.load(appState: appState)
        }
    }
}

private struct URLDisplayRow: View {
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

                Spacer(minLength: 0)

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

private struct BotCommandRow: View {
    let command: String
    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Text(command)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.indigo.opacity(0.15))
                .foregroundStyle(.indigo)
                .clipShape(Capsule())

            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}
