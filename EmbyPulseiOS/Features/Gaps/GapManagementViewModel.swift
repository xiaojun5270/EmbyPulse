import Foundation

@MainActor
final class GapManagementViewModel: ObservableObject {
    @Published var scanState = GapScanState()
    @Published var autoScanEnabled = false
    @Published var ignores: [GapIgnoredItem] = []

    @Published var isLoading = false
    @Published var isLoadingIgnores = false
    @Published var isOperating = false
    @Published var errorMessage: String?
    @Published var actionHint: String?

    private var pollTask: Task<Void, Never>?

    var sortedSeries: [GapSeriesItem] {
        scanState.results
            .sorted { lhs, rhs in
                if lhs.missingCount == rhs.missingCount {
                    return lhs.seriesName.localizedCompare(rhs.seriesName) == .orderedAscending
                }
                return lhs.missingCount > rhs.missingCount
            }
    }

    var totalMissingEpisodes: Int {
        scanState.results.reduce(0) { $0 + $1.missingCount }
    }

    func loadInitial(appState: AppState) async {
        isLoading = true
        errorMessage = nil
        actionHint = nil

        await fetchScanState(appState: appState)
        await fetchAutoStatus(appState: appState)
        await loadIgnores(appState: appState)
        isLoading = false

        if scanState.isScanning {
            startPolling(appState: appState)
        }
    }

    func refresh(appState: AppState) async {
        errorMessage = nil
        await fetchScanState(appState: appState)
        await fetchAutoStatus(appState: appState)
        await loadIgnores(appState: appState)

        if scanState.isScanning {
            startPolling(appState: appState)
        } else {
            stopPolling()
        }
    }

    func startScan(appState: AppState) async {
        guard !scanState.isScanning else { return }
        isOperating = true
        errorMessage = nil
        actionHint = nil
        do {
            try await appState.apiClient.startGapScan(baseURL: appState.environment.baseURL)
            actionHint = "缺集深度重扫已启动"
            await fetchScanState(appState: appState)
            startPolling(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
        isOperating = false
    }

    func updateAutoScan(appState: AppState, enabled: Bool) async {
        let oldValue = autoScanEnabled
        autoScanEnabled = enabled
        do {
            try await appState.apiClient.setGapAutoScan(
                baseURL: appState.environment.baseURL,
                enabled: enabled
            )
            actionHint = enabled ? "已开启自动巡检" : "已关闭自动巡检"
        } catch {
            autoScanEnabled = oldValue
            errorMessage = error.localizedDescription
        }
    }

    func ignoreEpisode(appState: AppState, series: GapSeriesItem, episode: GapEpisodeItem) async {
        guard !isOperating else { return }
        isOperating = true
        errorMessage = nil
        actionHint = nil
        do {
            try await appState.apiClient.ignoreGapEpisode(
                baseURL: appState.environment.baseURL,
                seriesID: series.seriesID,
                seriesName: series.seriesName,
                season: episode.season,
                episode: episode.episode
            )

            var updatedSeries = series
            updatedSeries = GapSeriesItem(
                seriesID: series.seriesID,
                seriesName: series.seriesName,
                tmdbID: series.tmdbID,
                poster: series.poster,
                embyURL: series.embyURL,
                gaps: series.gaps.filter { item in
                    !(item.season == episode.season && item.episode == episode.episode)
                }
            )
            replaceSeries(updatedSeries)

            actionHint = "已忽略 \(series.seriesName) \(episode.codeText)"
            await loadIgnores(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
        isOperating = false
    }

    func ignoreSeries(appState: AppState, series: GapSeriesItem) async {
        guard !isOperating else { return }
        isOperating = true
        errorMessage = nil
        actionHint = nil
        do {
            try await appState.apiClient.ignoreGapSeries(
                baseURL: appState.environment.baseURL,
                seriesID: series.seriesID,
                seriesName: series.seriesName
            )
            scanState = GapScanState(
                isScanning: scanState.isScanning,
                progress: scanState.progress,
                total: scanState.total,
                currentItem: scanState.currentItem,
                results: scanState.results.filter { $0.seriesID != series.seriesID },
                error: scanState.error
            )
            actionHint = "已忽略整剧：\(series.seriesName)"
            await loadIgnores(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
        isOperating = false
    }

    func loadIgnores(appState: AppState) async {
        isLoadingIgnores = true
        do {
            ignores = try await appState.apiClient.fetchGapIgnores(baseURL: appState.environment.baseURL)
        } catch {
            guard !NetworkError.isCancellation(error) else {
                isLoadingIgnores = false
                return
            }
            errorMessage = error.localizedDescription
            ignores = []
        }
        isLoadingIgnores = false
    }

    func restoreIgnore(appState: AppState, item: GapIgnoredItem) async {
        guard !isOperating else { return }
        isOperating = true
        errorMessage = nil
        actionHint = nil
        do {
            try await appState.apiClient.unignoreGap(baseURL: appState.environment.baseURL, item: item)
            ignores.removeAll { $0.id == item.id }
            actionHint = "已恢复：\(item.seriesName)"
            await fetchScanState(appState: appState)
        } catch {
            errorMessage = error.localizedDescription
        }
        isOperating = false
    }

    func fetchConfig(appState: AppState) async -> GapClientConfig? {
        do {
            return try await appState.apiClient.fetchGapConfig(baseURL: appState.environment.baseURL)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func saveConfig(appState: AppState, config: GapClientConfig) async -> Bool {
        do {
            try await appState.apiClient.saveGapConfig(
                baseURL: appState.environment.baseURL,
                config: config
            )
            actionHint = "缺集下载器配置已保存"
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func searchResources(
        appState: AppState,
        series: GapSeriesItem,
        season: Int,
        episodes: [Int],
        customKeyword: String? = nil
    ) async -> GapMPSearchData? {
        do {
            return try await appState.apiClient.searchGapResources(
                baseURL: appState.environment.baseURL,
                seriesID: series.seriesID,
                seriesName: series.seriesName,
                season: season,
                episodes: episodes,
                customKeyword: customKeyword
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func submitDownload(
        appState: AppState,
        series: GapSeriesItem,
        season: Int,
        episodes: [Int],
        selected: GapMPTorrentResult
    ) async -> Bool {
        guard !isOperating else { return false }
        isOperating = true
        errorMessage = nil
        actionHint = nil

        do {
            let message = try await appState.apiClient.submitGapDownload(
                baseURL: appState.environment.baseURL,
                seriesID: series.seriesID,
                seriesName: series.seriesName,
                tmdbID: series.tmdbID,
                season: season,
                episodes: episodes,
                torrent: selected
            )
            markEpisodesStatus(seriesID: series.seriesID, season: season, episodes: Set(episodes), status: 2)
            actionHint = message
            isOperating = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isOperating = false
            return false
        }
    }

    func stopBackgroundWork() {
        stopPolling()
    }

    private func fetchScanState(appState: AppState) async {
        do {
            let state = try await appState.apiClient.fetchGapScanProgress(baseURL: appState.environment.baseURL)
            scanState = state
            if let backendError = state.error, !backendError.isEmpty {
                errorMessage = backendError
            }
        } catch {
            guard !NetworkError.isCancellation(error) else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func fetchAutoStatus(appState: AppState) async {
        do {
            autoScanEnabled = try await appState.apiClient.fetchGapAutoScanEnabled(baseURL: appState.environment.baseURL)
        } catch {
            guard !NetworkError.isCancellation(error) else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func replaceSeries(_ series: GapSeriesItem) {
        var updated = scanState.results
        if let index = updated.firstIndex(where: { $0.seriesID == series.seriesID }) {
            if series.gaps.isEmpty {
                updated.remove(at: index)
            } else {
                updated[index] = series
            }
            scanState = GapScanState(
                isScanning: scanState.isScanning,
                progress: scanState.progress,
                total: scanState.total,
                currentItem: scanState.currentItem,
                results: updated,
                error: scanState.error
            )
        }
    }

    private func markEpisodesStatus(seriesID: String, season: Int, episodes: Set<Int>, status: Int) {
        var updated = scanState.results
        guard let index = updated.firstIndex(where: { $0.seriesID == seriesID }) else {
            return
        }
        let series = updated[index]
        let patched = series.gaps.map { item -> GapEpisodeItem in
            guard item.season == season, episodes.contains(item.episode) else {
                return item
            }
            return GapEpisodeItem(
                season: item.season,
                episode: item.episode,
                title: item.title,
                status: status
            )
        }
        updated[index] = GapSeriesItem(
            seriesID: series.seriesID,
            seriesName: series.seriesName,
            tmdbID: series.tmdbID,
            poster: series.poster,
            embyURL: series.embyURL,
            gaps: patched
        )
        scanState = GapScanState(
            isScanning: scanState.isScanning,
            progress: scanState.progress,
            total: scanState.total,
            currentItem: scanState.currentItem,
            results: updated,
            error: scanState.error
        )
    }

    private func startPolling(appState: AppState) {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_200_000_000)
                } catch {
                    break
                }

                await fetchScanState(appState: appState)
                if !scanState.isScanning {
                    await loadIgnores(appState: appState)
                    if actionHint == nil {
                        actionHint = "扫描已完成"
                    }
                    break
                }
            }
            pollTask = nil
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}
