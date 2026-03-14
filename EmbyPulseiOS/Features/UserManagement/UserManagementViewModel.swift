import Foundation

@MainActor
final class UserManagementViewModel: ObservableObject {
    @Published var users: [ManagedUser] = []
    @Published var invites: [InviteCodeItem] = []
    @Published var generatedInviteCodes: [String] = []

    @Published var isLoadingUsers = false
    @Published var isLoadingInvites = false
    @Published var processingUserID: String?
    @Published var isGeneratingInvite = false

    @Published var errorMessage: String?
    @Published var actionHint: String?

    func loadInitial(appState: AppState) async {
        async let usersTask: Void = refreshUsers(appState: appState)
        async let invitesTask: Void = refreshInvites(appState: appState)
        _ = await (usersTask, invitesTask)
    }

    func refreshUsers(appState: AppState) async {
        isLoadingUsers = true
        errorMessage = nil

        do {
            users = try await appState.apiClient.fetchManagedUsers(baseURL: appState.environment.baseURL)
            users.sort { lhs, rhs in
                if lhs.isDisabled == rhs.isDisabled {
                    return lhs.name.localizedCompare(rhs.name) == .orderedAscending
                }
                return !lhs.isDisabled && rhs.isDisabled
            }
        } catch {
            errorMessage = error.localizedDescription
            users = []
        }

        isLoadingUsers = false
    }

    func refreshInvites(appState: AppState) async {
        isLoadingInvites = true
        errorMessage = nil

        do {
            invites = try await appState.apiClient.fetchInvites(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            invites = []
        }

        isLoadingInvites = false
    }

    func createUser(
        appState: AppState,
        name: String,
        password: String,
        expireDate: Date?
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "用户名不能为空"
            return false
        }

        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.createManagedUser(
                baseURL: appState.environment.baseURL,
                name: trimmedName,
                password: trimmedPassword.isEmpty ? nil : trimmedPassword,
                expireDate: expireDate.map { Self.apiDateFormatter.string(from: $0) }
            )
            actionHint = "用户已创建"
            await refreshUsers(appState: appState)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func setUserDisabled(appState: AppState, user: ManagedUser, disabled: Bool) async -> Bool {
        processingUserID = user.id
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.updateManagedUser(
                baseURL: appState.environment.baseURL,
                userID: user.id,
                isDisabled: disabled
            )
            actionHint = disabled ? "用户已禁用" : "用户已启用"
            await refreshUsers(appState: appState)
            processingUserID = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            processingUserID = nil
            return false
        }
    }

    func renewUser(appState: AppState, userID: String, days: Int) async -> Bool {
        guard days > 0 else {
            errorMessage = "续期天数必须大于 0"
            return false
        }

        processingUserID = userID
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.renewManagedUsers(
                baseURL: appState.environment.baseURL,
                userIDs: [userID],
                days: days
            )
            actionHint = "续期成功 (+\(days) 天)"
            await refreshUsers(appState: appState)
            processingUserID = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            processingUserID = nil
            return false
        }
    }

    func updateExpireDate(appState: AppState, userID: String, date: Date?) async -> Bool {
        processingUserID = userID
        errorMessage = nil
        actionHint = nil

        let expireDate = date.map { Self.apiDateFormatter.string(from: $0) } ?? ""

        do {
            try await appState.apiClient.updateManagedUser(
                baseURL: appState.environment.baseURL,
                userID: userID,
                expireDate: expireDate
            )
            actionHint = date == nil ? "已清空到期日" : "到期日已更新"
            await refreshUsers(appState: appState)
            processingUserID = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            processingUserID = nil
            return false
        }
    }

    func resetPassword(appState: AppState, userID: String, newPassword: String) async -> Bool {
        let password = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !password.isEmpty else {
            errorMessage = "新密码不能为空"
            return false
        }

        processingUserID = userID
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.updateManagedUser(
                baseURL: appState.environment.baseURL,
                userID: userID,
                password: password
            )
            actionHint = "密码已重置"
            processingUserID = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            processingUserID = nil
            return false
        }
    }

    func deleteUser(appState: AppState, userID: String) async -> Bool {
        processingUserID = userID
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.deleteManagedUser(
                baseURL: appState.environment.baseURL,
                userID: userID
            )
            actionHint = "用户已删除"
            await refreshUsers(appState: appState)
            processingUserID = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            processingUserID = nil
            return false
        }
    }

    func generateInvites(appState: AppState, days: Int, count: Int) async -> Bool {
        guard days > 0 else {
            errorMessage = "邀请码有效期必须大于 0 天"
            return false
        }
        guard count > 0 else {
            errorMessage = "邀请码数量必须大于 0"
            return false
        }

        isGeneratingInvite = true
        errorMessage = nil
        actionHint = nil

        do {
            generatedInviteCodes = try await appState.apiClient.generateInvites(
                baseURL: appState.environment.baseURL,
                days: days,
                count: count
            )
            actionHint = "已生成 \(generatedInviteCodes.count) 个邀请码"
            await refreshInvites(appState: appState)
            isGeneratingInvite = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isGeneratingInvite = false
            return false
        }
    }

    func deleteInvite(appState: AppState, code: String) async -> Bool {
        guard !code.isEmpty else { return false }
        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.deleteInvites(
                baseURL: appState.environment.baseURL,
                codes: [code]
            )
            actionHint = "邀请码已删除"
            await refreshInvites(appState: appState)
            generatedInviteCodes.removeAll { $0 == code }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteInvites(appState: AppState, codes: [String]) async -> Bool {
        let validCodes = codes.filter { !$0.isEmpty }
        guard !validCodes.isEmpty else { return false }

        errorMessage = nil
        actionHint = nil

        do {
            try await appState.apiClient.deleteInvites(
                baseURL: appState.environment.baseURL,
                codes: validCodes
            )
            actionHint = "已删除 \(validCodes.count) 个邀请码"
            await refreshInvites(appState: appState)
            generatedInviteCodes.removeAll { validCodes.contains($0) }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func displayExpireDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "未设置" }
        return raw
    }

    func displayLastLogin(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "从未登录" }

        if let date = Self.isoDateFormatter.date(from: raw) {
            return Self.displayDateFormatter.string(from: date)
        }
        if let date = Self.simpleISODateFormatter.date(from: raw) {
            return Self.displayDateFormatter.string(from: date)
        }

        if raw.count >= 16 {
            return String(raw.prefix(16)).replacingOccurrences(of: "T", with: " ")
        }
        return raw
    }

    func parseExpireDate(_ raw: String?) -> Date {
        guard let raw, !raw.isEmpty else { return Date() }
        return Self.apiDateFormatter.date(from: raw) ?? Date()
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    private static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let simpleISODateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
