import SwiftUI
import UIKit

struct UserManagementView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = UserManagementViewModel()

    @State private var createName = ""
    @State private var createPassword = ""
    @State private var createHasExpireDate = false
    @State private var createExpireDate = Date()

    @State private var userFilter = ""
    @State private var renewTarget: ManagedUser?
    @State private var renewDaysText = "30"

    @State private var expireTarget: ManagedUser?
    @State private var expireDate = Date()
    @State private var clearExpireDate = false

    @State private var resetPasswordTarget: ManagedUser?
    @State private var resetPasswordText = ""

    @State private var deleteTarget: ManagedUser?
    @State private var showDeleteDialog = false

    @State private var inviteDays = 30
    @State private var inviteCount = 1
    @State private var selectedInviteCodes: Set<String> = []

    private var filteredUsers: [ManagedUser] {
        let keyword = userFilter.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty else { return viewModel.users }
        return viewModel.users.filter { user in
            user.name.lowercased().contains(keyword) || user.id.lowercased().contains(keyword)
        }
    }

    private var validSelectedInviteCodes: [String] {
        selectedInviteCodes.filter { code in
            viewModel.invites.contains(where: { $0.code == code })
        }
    }

    private var activeUsersCount: Int {
        viewModel.users.filter { !$0.isDisabled }.count
    }

    private var adminUsersCount: Int {
        viewModel.users.filter(\.isAdmin).count
    }

    private var availableInvitesCount: Int {
        viewModel.invites.filter { $0.usedCount < $0.maxUses && $0.status == 0 }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel

                if let hint = viewModel.actionHint {
                    statusBanner(hint, tint: .green)
                }
                if let error = viewModel.errorMessage {
                    statusBanner(error, tint: .red)
                }

                createUserSection
                usersSection
                inviteGenerateSection
                generatedCodesSection
                inviteListSection
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("用户管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await viewModel.loadInitial(appState: appState) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoadingUsers || viewModel.isLoadingInvites)
            }
        }
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await viewModel.loadInitial(appState: appState)
        }
        .sheet(item: $renewTarget) { user in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sheetHero(
                            title: "用户续期",
                            subtitle: "设置有效期延长天数",
                            symbol: "calendar.badge.plus"
                        )

                        sheetCard(title: "用户信息", symbol: "person.crop.circle") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.id)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sheetCard(title: "续期天数", symbol: "clock.arrow.circlepath") {
                            TextField("输入整数天数", text: $renewDaysText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(16)
                }
                .background(pageGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            renewTarget = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            let text = renewDaysText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard let days = Int(text), days > 0 else {
                                viewModel.errorMessage = "请输入大于 0 的天数"
                                return
                            }
                            Task {
                                let success = await viewModel.renewUser(
                                    appState: appState,
                                    userID: user.id,
                                    days: days
                                )
                                if success {
                                    renewTarget = nil
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $expireTarget) { user in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sheetHero(
                            title: "编辑到期日",
                            subtitle: "可设置固定日期或清空",
                            symbol: "calendar.badge.exclamationmark"
                        )

                        sheetCard(title: "用户信息", symbol: "person.crop.circle") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name)
                                    .font(.headline)
                                Text("当前到期日：\(viewModel.displayExpireDate(user.expireDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sheetCard(title: "到期配置", symbol: "calendar") {
                            Toggle("清空到期日", isOn: $clearExpireDate)

                            if !clearExpireDate {
                                DatePicker(
                                    "新到期日",
                                    selection: $expireDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(pageGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            expireTarget = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            Task {
                                let success = await viewModel.updateExpireDate(
                                    appState: appState,
                                    userID: user.id,
                                    date: clearExpireDate ? nil : expireDate
                                )
                                if success {
                                    expireTarget = nil
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $resetPasswordTarget) { user in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sheetHero(
                            title: "重置密码",
                            subtitle: "为指定用户设置新密码",
                            symbol: "key.fill"
                        )

                        sheetCard(title: "用户信息", symbol: "person.crop.circle") {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.id)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        sheetCard(title: "新密码", symbol: "lock.shield") {
                            SecureField("请输入新密码", text: $resetPasswordText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(16)
                }
                .background(pageGradient.ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            resetPasswordTarget = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("确认") {
                            Task {
                                let success = await viewModel.resetPassword(
                                    appState: appState,
                                    userID: user.id,
                                    newPassword: resetPasswordText
                                )
                                if success {
                                    resetPasswordTarget = nil
                                    resetPasswordText = ""
                                }
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog("删除用户后不可恢复", isPresented: $showDeleteDialog) {
            if let deleteTarget {
                Button("删除 \(deleteTarget.name)", role: .destructive) {
                    Task {
                        let success = await viewModel.deleteUser(appState: appState, userID: deleteTarget.id)
                        if success {
                            self.deleteTarget = nil
                        }
                    }
                }
            }
            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("账号与邀请中心")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("用户生命周期、权限和邀请码管理")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }

                Spacer(minLength: 0)

                Image(systemName: "person.2.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                    .padding(8)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                heroPill(title: "总用户", value: "\(viewModel.users.count)")
                heroPill(title: "活跃用户", value: "\(activeUsersCount)")
                heroPill(title: "管理员", value: "\(adminUsersCount)")
                heroPill(title: "可用邀请码", value: "\(availableInvitesCount)")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.22, green: 0.27, blue: 0.40), Color(red: 0.16, green: 0.21, blue: 0.31)]
                    : [Color(red: 0.82, green: 0.90, blue: 1.0), Color(red: 0.88, green: 0.97, blue: 0.97)],
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

    private func heroPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(ConsoleDesign.heroPillTitleColor(isDark: isDark))
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var createUserSection: some View {
        sectionCard(
            title: "新建用户",
            subtitle: "快速创建账号并配置到期日",
            symbol: "person.badge.plus.fill"
        ) {
            TextField("用户名", text: $createName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("初始密码（可选）", text: $createPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            Toggle("设置到期日", isOn: $createHasExpireDate)

            if createHasExpireDate {
                DatePicker(
                    "到期日",
                    selection: $createExpireDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
            }

            Button {
                Task {
                    let success = await viewModel.createUser(
                        appState: appState,
                        name: createName,
                        password: createPassword,
                        expireDate: createHasExpireDate ? createExpireDate : nil
                    )
                    if success {
                        createName = ""
                        createPassword = ""
                        createHasExpireDate = false
                        createExpireDate = Date()
                    }
                }
            } label: {
                Text("创建用户")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var usersSection: some View {
        sectionCard(
            title: "用户列表",
            subtitle: filteredUsers.isEmpty ? "暂无数据" : "共 \(filteredUsers.count) 人",
            symbol: "person.text.rectangle.fill"
        ) {
            TextField("筛选用户名 / ID", text: $userFilter)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            if viewModel.isLoadingUsers {
                ProgressView("加载用户中...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else if filteredUsers.isEmpty {
                Text("暂无用户")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(filteredUsers) { user in
                        ManagedUserRow(
                            user: user,
                            baseURL: appState.environment.baseURL,
                            expireText: viewModel.displayExpireDate(user.expireDate),
                            lastLoginText: viewModel.displayLastLogin(user.lastLoginDate),
                            isProcessing: viewModel.processingUserID == user.id,
                            onToggleDisabled: {
                                Task {
                                    _ = await viewModel.setUserDisabled(
                                        appState: appState,
                                        user: user,
                                        disabled: !user.isDisabled
                                    )
                                }
                            },
                            onRenew: {
                                renewTarget = user
                                renewDaysText = "30"
                            },
                            onEditExpire: {
                                expireTarget = user
                                expireDate = viewModel.parseExpireDate(user.expireDate)
                                clearExpireDate = (user.expireDate ?? "").isEmpty
                            },
                            onResetPassword: {
                                resetPasswordTarget = user
                                resetPasswordText = ""
                            },
                            onDelete: {
                                deleteTarget = user
                                showDeleteDialog = true
                            }
                        )
                    }
                }
            }
        }
    }

    private var inviteGenerateSection: some View {
        sectionCard(
            title: "邀请码生成",
            subtitle: "批量生成并设置有效期",
            symbol: "qrcode.viewfinder"
        ) {
            Stepper("有效期：\(inviteDays) 天", value: $inviteDays, in: 1...3650)
            Stepper("生成数量：\(inviteCount)", value: $inviteCount, in: 1...20)

            Button {
                Task {
                    _ = await viewModel.generateInvites(
                        appState: appState,
                        days: inviteDays,
                        count: inviteCount
                    )
                }
            } label: {
                if viewModel.isGeneratingInvite {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("生成邀请码")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isGeneratingInvite)
        }
    }

    @ViewBuilder
    private var generatedCodesSection: some View {
        if !viewModel.generatedInviteCodes.isEmpty {
            sectionCard(
                title: "本次生成",
                subtitle: "点击复制邀请链接",
                symbol: "link.badge.plus"
            ) {
                VStack(spacing: 8) {
                    ForEach(viewModel.generatedInviteCodes, id: \.self) { code in
                        HStack(spacing: 10) {
                            Text(code)
                                .font(.callout.monospaced())
                            Spacer()
                            Button("复制") {
                                UIPasteboard.general.string = inviteURL(code: code)
                                viewModel.actionHint = "邀请码链接已复制"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(rowSurface)
                        )
                    }
                }
            }
        }
    }

    private var inviteListSection: some View {
        sectionCard(
            title: "邀请码列表",
            subtitle: viewModel.invites.isEmpty ? "暂无邀请码" : "共 \(viewModel.invites.count) 条",
            symbol: "list.bullet.rectangle.portrait.fill"
        ) {
            if viewModel.isLoadingInvites {
                ProgressView("加载邀请码中...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else if viewModel.invites.isEmpty {
                Text("暂无邀请码")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.invites) { invite in
                        InviteRow(
                            invite: invite,
                            isSelected: selectedInviteCodes.contains(invite.code),
                            onToggleSelection: {
                                if selectedInviteCodes.contains(invite.code) {
                                    selectedInviteCodes.remove(invite.code)
                                } else {
                                    selectedInviteCodes.insert(invite.code)
                                }
                            },
                            onDelete: {
                                Task {
                                    let success = await viewModel.deleteInvite(appState: appState, code: invite.code)
                                    if success {
                                        selectedInviteCodes.remove(invite.code)
                                    }
                                }
                            },
                            onCopy: {
                                UIPasteboard.general.string = inviteURL(code: invite.code)
                                viewModel.actionHint = "邀请码链接已复制"
                            }
                        )
                    }
                }

                if !validSelectedInviteCodes.isEmpty {
                    Button(role: .destructive) {
                        Task {
                            let success = await viewModel.deleteInvites(
                                appState: appState,
                                codes: validSelectedInviteCodes
                            )
                            if success {
                                selectedInviteCodes.removeAll()
                            }
                        }
                    } label: {
                        Text("删除选中邀请码 (\(validSelectedInviteCodes.count))")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.indigo)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(ConsoleDesign.sectionTitleFont)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content()
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func sheetHero(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.indigo)
                .frame(width: 32, height: 32)
                .background(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                .clipShape(Circle())
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func sheetCard<Content: View>(
        title: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.indigo)
                    .frame(width: 22, height: 22)
                    .background(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            content()
        }
        .padding(ConsoleDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ConsoleDesign.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func statusBanner(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func inviteURL(code: String) -> String {
        var base = appState.environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.hasPrefix("http://") && !base.hasPrefix("https://") {
            base = "http://" + base
        }
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return "\(base)/invite/\(code)"
    }

    private var cardSurface: Color {
        isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88)
    }

    private var rowSurface: Color {
        isDark ? Color(red: 0.19, green: 0.21, blue: 0.25).opacity(0.95) : Color.white.opacity(0.78)
    }

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.10) : Color.black.opacity(0.05)
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

private struct ManagedUserRow: View {
    @EnvironmentObject private var appState: AppState

    let user: ManagedUser
    let baseURL: String
    let expireText: String
    let lastLoginText: String
    let isProcessing: Bool
    let onToggleDisabled: () -> Void
    let onRenew: () -> Void
    let onEditExpire: () -> Void
    let onResetPassword: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: avatarURL()) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    ZStack {
                        Circle()
                            .fill(avatarPlaceholderSurface)
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(user.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)

                    if user.isAdmin {
                        Text("管理员")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    if user.isDisabled {
                        Text("已禁用")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }

                Text("到期日：\(expireText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("最近登录：\(lastLoginText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if isProcessing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Menu {
                    Button(user.isDisabled ? "启用用户" : "禁用用户") { onToggleDisabled() }
                    Button("续期") { onRenew() }
                    Button("设置到期日") { onEditExpire() }
                    Button("重置密码") { onResetPassword() }
                    Button("删除用户", role: .destructive) { onDelete() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.19, green: 0.21, blue: 0.25).opacity(0.95)
            : Color.white.opacity(0.78)
    }

    private var avatarPlaceholderSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.22, green: 0.24, blue: 0.28)
            : Color.white.opacity(0.86)
    }

    private func avatarURL() -> URL? {
        var normalized = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.hasSuffix("/") {
            normalized.removeLast()
        }
        if !normalized.hasPrefix("http://") && !normalized.hasPrefix("https://") {
            normalized = "http://" + normalized
        }
        return URL(string: "\(normalized)/api/user/image/\(user.id)")
    }
}

private struct InviteRow: View {
    @EnvironmentObject private var appState: AppState

    let invite: InviteCodeItem
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    let onCopy: () -> Void

    private var isUsed: Bool {
        invite.usedCount >= invite.maxUses || invite.status != 0
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button {
                onToggleSelection()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(invite.code)
                    .font(.callout.monospaced())
                HStack(spacing: 8) {
                    Text("有效 \(invite.days) 天")
                    Text("使用 \(invite.usedCount)/\(invite.maxUses)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(isUsed ? "已使用" : "可使用")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isUsed ? Color.gray : Color.green).opacity(0.15))
                .foregroundStyle(isUsed ? Color.gray : Color.green)
                .clipShape(Capsule())

            Menu {
                Button("复制链接") { onCopy() }
                Button("删除", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(rowSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.34) : Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var rowSurface: Color {
        appState.appearanceMode == .dark
            ? Color(red: 0.19, green: 0.21, blue: 0.25).opacity(0.95)
            : Color.white.opacity(0.78)
    }
}
