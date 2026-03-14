import Photos
import SwiftUI
import UIKit

struct ReportWorkshopView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ReportWorkshopViewModel()
    @State private var isSavingPoster = false
    @State private var saveHint: String?
    @State private var previewImage: UIImage?
    @State private var previewLoadError: String?
    @State private var isLoadingPreview = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ConsoleDesign.sectionSpacing) {
                heroPanel
                filtersSection
                previewSection
                actionsSection
                summarySection
                topListSection
            }
            .padding(ConsoleDesign.pagePadding)
        }
        .background(pageGradient.ignoresSafeArea())
        .navigationTitle("映迹工坊")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadInitial(appState: appState)
        }
        .refreshable {
            await viewModel.refreshData(appState: appState)
        }
        .onChange(of: viewModel.selectedUserID) { _ in
            Task { await viewModel.refreshData(appState: appState) }
        }
        .onChange(of: viewModel.selectedPeriod) { _ in
            Task { await viewModel.refreshData(appState: appState) }
        }
        .task(id: previewURLKey) {
            await loadPreviewImage()
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("映迹工坊")
                        .font(ConsoleDesign.heroTitleFont)
                        .foregroundStyle(isDark ? .white : .primary)
                    Text("生成海报、推送 Bot、保存本地相册")
                        .font(.footnote)
                        .foregroundStyle(ConsoleDesign.heroMutedTextColor(isDark: isDark))
                }

                Spacer()

                Image(systemName: "photo.artframe")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(ConsoleDesign.heroBadgeForeground(isDark: isDark))
                    .padding(8)
                    .background(ConsoleDesign.heroBadgeBackground(isDark: isDark))
                    .clipShape(Circle())
            }

            HStack(spacing: 8) {
                heroPill(title: "用户", value: viewModel.selectedUserTitle())
                heroPill(title: "周期", value: viewModel.selectedPeriod.title)
                heroPill(title: "主题", value: viewModel.selectedTheme.title)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.24, green: 0.27, blue: 0.38), Color(red: 0.18, green: 0.20, blue: 0.29)]
                    : [Color(red: 0.82, green: 0.91, blue: 1.0), Color(red: 0.87, green: 0.98, blue: 0.97)],
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
                .lineLimit(1)
                .foregroundStyle(ConsoleDesign.heroPillValueColor(isDark: isDark))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ConsoleDesign.heroPillBackground(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var filtersSection: some View {
        sectionCard(
            title: "海报参数",
            subtitle: "筛选用户、时间周期和主题风格",
            symbol: "slider.horizontal.3"
        ) {
            Picker("用户", selection: $viewModel.selectedUserID) {
                Text("全服概览").tag("all")
                ForEach(viewModel.users) { user in
                    Text(user.userName).tag(user.userID)
                }
            }
            .pickerStyle(.menu)

            Picker("周期", selection: $viewModel.selectedPeriod) {
                ForEach(ReportPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)

            Picker("主题", selection: $viewModel.selectedTheme) {
                ForEach(ReportTheme.allCases) { theme in
                    Text(theme.title).tag(theme)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var previewSection: some View {
        sectionCard(
            title: "海报预览",
            subtitle: "当前参数生成结果",
            symbol: "photo.stack.fill"
        ) {
            if isLoadingPreview {
                ProgressView("加载预览中...")
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(borderColor, lineWidth: 1)
                    )
            } else if let posterData = viewModel.posterData {
                localPreviewFallback(posterData)
            } else if let previewLoadError {
                VStack(spacing: 10) {
                    Text(previewLoadError)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("重试预览加载") {
                        Task { await loadPreviewImage(force: true) }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, minHeight: 240, alignment: .center)
            } else {
                Text("请先配置服务地址")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
            }
        }
    }

    private func localPreviewFallback(_ data: PosterData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.selectedUserTitle())
                    .font(.headline.weight(.bold))
                Spacer(minLength: 0)
                Text(viewModel.selectedPeriod.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(isDark ? 0.16 : 0.62))
                    .clipShape(Capsule())
            }

            Text(localPreviewHint)
                .font(.caption)
                .foregroundStyle(isDark ? Color.white.opacity(0.82) : .secondary)

            HStack(spacing: 8) {
                localPreviewMetric(title: "播放", value: "\(data.plays)")
                localPreviewMetric(title: "时长", value: String(format: "%.1f h", data.hours))
                localPreviewMetric(title: "全服", value: "\(data.serverPlays)")
            }

            if data.topList.isEmpty {
                Text("暂无榜单数据")
                    .font(.footnote)
                    .foregroundStyle(isDark ? Color.white.opacity(0.82) : .secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(data.topList.prefix(4).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Text("#\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 30)
                                .foregroundStyle(isDark ? Color.white.opacity(0.9) : .primary)

                            AsyncImage(url: posterURL(for: item.itemID)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    posterPlaceholder
                                }
                            }
                            .frame(width: 42, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.itemName)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                Text("播放 \(item.count) 次")
                                    .font(.caption)
                                    .foregroundStyle(isDark ? Color.white.opacity(0.78) : .secondary)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(isDark ? 0.12 : 0.66))
                        )
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: isDark
                    ? [Color(red: 0.24, green: 0.27, blue: 0.38), Color(red: 0.18, green: 0.20, blue: 0.29)]
                    : [Color(red: 0.82, green: 0.91, blue: 1.0), Color(red: 0.87, green: 0.98, blue: 0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private func localPreviewMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(isDark ? Color.white.opacity(0.78) : .secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(isDark ? Color.white : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(isDark ? 0.14 : 0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var actionsSection: some View {
        sectionCard(
            title: "快捷操作",
            subtitle: "刷新、保存相册、推送 Bot",
            symbol: "bolt.fill"
        ) {
            HStack(spacing: 10) {
                Button {
                    Task { await viewModel.refreshData(appState: appState) }
                } label: {
                    if viewModel.isLoadingData {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("刷新预览")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isPushing || isSavingPoster)

                Button {
                    Task { await savePosterToPhotoLibrary() }
                } label: {
                    if isSavingPoster {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("保存到相册")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(viewModel.isLoadingData || viewModel.previewURL(baseURL: appState.environment.baseURL) == nil)

                Button {
                    Task { await viewModel.pushReport(appState: appState) }
                } label: {
                    if viewModel.isPushing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("推送到 Bot")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isLoadingData || isSavingPoster)
            }

            if let hint = viewModel.actionHint {
                statusBanner(hint, tint: .green)
            }
            if let saveHint {
                statusBanner(saveHint, tint: .green)
            }
            if let errorMessage = viewModel.errorMessage {
                statusBanner(errorMessage, tint: .red)
            }
        }
    }

    private var summarySection: some View {
        sectionCard(
            title: "统计摘要",
            subtitle: "播放强度和热点标签",
            symbol: "chart.bar.fill"
        ) {
            if viewModel.isLoadingData && viewModel.posterData == nil {
                ProgressView("加载统计数据...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let data = viewModel.posterData {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    summaryPill(title: "播放次数", value: "\(data.plays)", tint: .indigo, icon: "play.circle.fill")
                    summaryPill(title: "专注时长", value: String(format: "%.1f h", data.hours), tint: .mint, icon: "clock.fill")
                    summaryPill(title: "全服总播", value: "\(data.serverPlays)", tint: .orange, icon: "waveform.path.ecg")
                }

                if !data.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(data.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.indigo.opacity(isDark ? 0.24 : 0.14))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            } else {
                Text("暂无统计数据")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var topListSection: some View {
        sectionCard(
            title: "Top 内容",
            subtitle: "报表周期内的高热内容",
            symbol: "list.number"
        ) {
            if let items = viewModel.posterData?.topList, !items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(items.prefix(10).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Text("#\(index + 1)")
                                .font(.caption.bold())
                                .frame(width: 32)
                                .foregroundStyle(.secondary)

                            AsyncImage(url: posterURL(for: item.itemID)) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                default:
                                    posterPlaceholder
                                }
                            }
                            .frame(width: 42, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.itemName)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                Text("播放 \(item.count) 次 · \(String(format: "%.1f", item.durationHours)) 小时")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(rowSurface)
                        )
                    }
                }
            } else {
                Text("暂无榜单数据")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    private func summaryPill(title: String, value: String, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(tint)
            Text(value)
                .font(.headline.weight(.bold))
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(isDark ? 0.18 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func statusBanner(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(tint)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var posterPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(placeholderSurface)
            Image(systemName: "film.stack")
                .foregroundStyle(.secondary)
        }
    }

    private func posterURL(for itemID: String) -> URL? {
        guard !itemID.isEmpty else { return nil }
        var base = appState.environment.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !base.hasPrefix("http://") && !base.hasPrefix("https://") {
            base = "http://" + base
        }
        if base.hasSuffix("/") {
            base.removeLast()
        }
        return URL(string: "\(base)/api/proxy/smart_image?item_id=\(itemID)&type=Primary")
    }

    private func savePosterToPhotoLibrary() async {
        guard let previewURL = viewModel.previewURL(baseURL: appState.environment.baseURL) else {
            saveHint = "无可保存的海报预览"
            return
        }

        isSavingPoster = true
        saveHint = nil
        do {
            let data: Data
            if let previewImage, let imageData = previewImage.pngData() {
                data = imageData
            } else if let posterData = viewModel.posterData,
                      let localImage = renderLocalPreviewImage(from: posterData),
                      let imageData = localImage.pngData() {
                data = imageData
            } else {
                data = try await fetchPreviewData(from: previewURL)
            }
            let authorized = await requestPhotoAccess()
            guard authorized else {
                throw SavePosterError.photoPermissionDenied
            }
            try await savePhotoData(data)
            saveHint = "海报已保存到系统相册"
        } catch {
            saveHint = "保存失败：\(error.localizedDescription)"
        }
        isSavingPoster = false
    }

    private var previewURLKey: String {
        viewModel.previewURL(baseURL: appState.environment.baseURL)?.absoluteString ?? "preview-empty"
    }

    private var isPillowMissing: Bool {
        (previewLoadError ?? "").lowercased().contains("pillow")
    }

    private var localPreviewHint: String {
        if isPillowMissing {
            return "服务器缺少 Pillow，已切换为 App 本地预览"
        }
        if previewLoadError != nil {
            return "服务端海报不可用，已切换为 App 本地预览"
        }
        return "App 本地预览"
    }

    private func renderLocalPreviewImage(from data: PosterData) -> UIImage? {
        let content = localPreviewFallback(data)
            .frame(width: 380, alignment: .topLeading)
            .frame(minHeight: 540, alignment: .topLeading)
            .padding(12)
            .background(isDark ? Color.black : Color.white)

        let renderer = ImageRenderer(content: content)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func loadPreviewImage(force: Bool = false) async {
        guard let previewURL = viewModel.previewURL(baseURL: appState.environment.baseURL) else {
            previewImage = nil
            previewLoadError = "请先配置服务地址"
            return
        }

        isLoadingPreview = true
        if force {
            previewImage = nil
        }
        previewLoadError = nil

        do {
            let data = try await fetchPreviewData(from: previewURL)
            guard let image = UIImage(data: data) else {
                throw SavePosterError.invalidPreviewData
            }
            previewImage = image
        } catch {
            previewImage = nil
            previewLoadError = "预览加载失败：\(error.localizedDescription)"
        }

        isLoadingPreview = false
    }

    private func fetchPreviewData(from url: URL) async throws -> Data {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = .shared
        config.httpShouldSetCookies = true
        config.timeoutIntervalForRequest = 90
        config.timeoutIntervalForResource = 180
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)

        var request = URLRequest(url: url)
        request.timeoutInterval = 90
        request.setValue("image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")

        var lastError: Error?
        for attempt in 0...1 {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw SavePosterError.invalidPreviewData
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                        throw SavePosterError.sessionExpired
                    }

                    let message = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if let message, !message.isEmpty {
                        throw SavePosterError.serverMessage(message.prefix(80).description)
                    }
                    throw SavePosterError.invalidPreviewData
                }

                let isImage = (httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "")
                    .lowercased()
                    .contains("image")
                if !isImage {
                    let message = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if let message, !message.isEmpty {
                        throw SavePosterError.serverMessage(message.prefix(80).description)
                    }
                    throw SavePosterError.invalidPreviewData
                }
                return data
            } catch {
                lastError = error
                guard attempt == 0, shouldRetry(error) else {
                    throw error
                }
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }

        throw lastError ?? SavePosterError.unknown
    }

    private func shouldRetry(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private var cardSurface: Color {
        isDark ? Color(red: 0.15, green: 0.17, blue: 0.20).opacity(0.95) : Color.white.opacity(0.88)
    }

    private var rowSurface: Color {
        isDark ? Color(red: 0.18, green: 0.20, blue: 0.24).opacity(0.96) : Color.white.opacity(0.84)
    }

    private var placeholderSurface: Color {
        isDark ? Color(red: 0.18, green: 0.20, blue: 0.24) : Color.white.opacity(0.8)
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

    private func requestPhotoAccess() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch current {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        default:
            return false
        }
    }

    private func savePhotoData(_ data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? SavePosterError.unknown)
                }
            }
        }
    }
}

private enum SavePosterError: LocalizedError {
    case photoPermissionDenied
    case invalidPreviewData
    case sessionExpired
    case serverMessage(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .photoPermissionDenied:
            return "未授予相册访问权限"
        case .invalidPreviewData:
            return "海报预览数据异常"
        case .sessionExpired:
            return "会话已失效，请重新登录"
        case .serverMessage(let message):
            return message
        case .unknown:
            return "未知错误"
        }
    }
}
