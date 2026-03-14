import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @State private var isShowingRegister = false

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    headerView
                    formCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 26)
            }
        }
        .onAppear {
            viewModel.serverURL = appState.environment.baseURL
        }
        .sheet(isPresented: $isShowingRegister) {
            NavigationStack {
                RegisterView(defaultServerURL: viewModel.serverURL) { serverURL, username in
                    if !serverURL.isEmpty {
                        viewModel.serverURL = serverURL
                    }
                    if !username.isEmpty {
                        viewModel.username = username
                    }
                }
            }
            .environmentObject(appState)
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.09, blue: 0.21), Color(red: 0.06, green: 0.26, blue: 0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 40)
                .offset(x: -130, y: -300)

            Circle()
                .fill(Color.blue.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 44)
                .offset(x: 150, y: 280)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 420, height: 420)
                .rotationEffect(.degrees(24))
                .blur(radius: 28)
                .offset(x: 120, y: -180)
        }
    }

    private var headerView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                Text("Emby Pulse iOS")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.14))
            .clipShape(Capsule())

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.13))
                    .frame(width: 88, height: 88)
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("管理员登录")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            Text("连接服务端后进入仪表盘与分析中心")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.top, 6)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            labeledInput(
                title: "服务地址",
                symbol: "network",
                placeholder: "例如 https://your-domain:998",
                text: $viewModel.serverURL,
                keyboard: .URL
            )

            labeledInput(
                title: "管理员用户名",
                symbol: "person.crop.circle",
                placeholder: "输入管理员账号",
                text: $viewModel.username
            )

            labeledSecureInput(
                title: "密码",
                symbol: "lock.shield",
                placeholder: "输入密码",
                text: $viewModel.password
            )

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.78))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            Button {
                Task { await viewModel.submit(appState: appState) }
            } label: {
                Group {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("登录控制台")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.17, green: 0.63, blue: 1.0), Color(red: 0.04, green: 0.46, blue: 0.94)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isSubmitting)

            Button("邀请码注册账号") {
                isShowingRegister = true
            }
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.94))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("提示：首次安装请先填写服务地址，再使用管理员账户登录。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func labeledInput(
        title: String,
        symbol: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 20)
                TextField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(keyboard)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            )
        }
    }

    private func labeledSecureInput(
        title: String,
        symbol: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 20)
                SecureField(placeholder, text: text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.15))
            )
        }
    }
}
