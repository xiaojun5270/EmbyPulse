import Foundation

struct GapScanProgressResponse: Decodable {
    let status: String
    let data: GapScanState?
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent(GapScanState.self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct GapScanState: Decodable {
    let isScanning: Bool
    let progress: Int
    let total: Int
    let currentItem: String
    let results: [GapSeriesItem]
    let error: String?

    enum CodingKeys: String, CodingKey {
        case isScanning = "is_scanning"
        case progress
        case total
        case currentItem = "current_item"
        case results
        case error
    }

    init(
        isScanning: Bool = false,
        progress: Int = 0,
        total: Int = 0,
        currentItem: String = "",
        results: [GapSeriesItem] = [],
        error: String? = nil
    ) {
        self.isScanning = isScanning
        self.progress = progress
        self.total = total
        self.currentItem = currentItem
        self.results = results
        self.error = error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isScanning = Self.decodeBool(container, key: .isScanning)
        progress = Self.decodeInt(container, key: .progress)
        total = Self.decodeInt(container, key: .total)
        currentItem = (try? container.decodeIfPresent(String.self, forKey: .currentItem)) ?? ""
        results = (try? container.decodeIfPresent([GapSeriesItem].self, forKey: .results)) ?? []
        error = decodeOptionalString(from: container, forKey: .error)
    }

    var progressRate: Double {
        guard total > 0 else { return isScanning ? 0.04 : 1.0 }
        return max(0, min(1, Double(progress) / Double(total)))
    }

    private static func decodeInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? container.decode(String.self, forKey: key), let int = Int(value) {
            return int
        }
        return 0
    }

    private static func decodeBool(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return ["true", "1", "yes", "on"].contains(value.lowercased())
        }
        return false
    }
}

struct GapSeriesItem: Decodable, Identifiable {
    let seriesID: String
    let seriesName: String
    let tmdbID: String?
    let poster: String?
    let embyURL: String?
    let gaps: [GapEpisodeItem]

    var id: String { seriesID }

    enum CodingKeys: String, CodingKey {
        case seriesID = "series_id"
        case seriesName = "series_name"
        case tmdbID = "tmdb_id"
        case poster
        case embyURL = "emby_url"
        case gaps
    }

    init(
        seriesID: String,
        seriesName: String,
        tmdbID: String?,
        poster: String?,
        embyURL: String?,
        gaps: [GapEpisodeItem]
    ) {
        self.seriesID = seriesID
        self.seriesName = seriesName
        self.tmdbID = tmdbID
        self.poster = poster
        self.embyURL = embyURL
        self.gaps = gaps
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        seriesID = (try? container.decodeIfPresent(String.self, forKey: .seriesID)) ?? UUID().uuidString
        seriesName = (try? container.decodeIfPresent(String.self, forKey: .seriesName)) ?? "未知剧集"
        tmdbID = decodeOptionalString(from: container, forKey: .tmdbID)
        poster = try? container.decodeIfPresent(String.self, forKey: .poster)
        embyURL = try? container.decodeIfPresent(String.self, forKey: .embyURL)
        gaps = (try? container.decodeIfPresent([GapEpisodeItem].self, forKey: .gaps)) ?? []
    }

    var missingCount: Int {
        gaps.count
    }

    var groupedBySeason: [GapSeasonGroup] {
        let grouped = Dictionary(grouping: gaps) { $0.season }
        return grouped.keys.sorted().map { season in
            GapSeasonGroup(
                season: season,
                episodes: grouped[season, default: []].sorted { lhs, rhs in
                    lhs.episode < rhs.episode
                }
            )
        }
    }
}

struct GapEpisodeItem: Decodable, Identifiable, Hashable {
    let season: Int
    let episode: Int
    let title: String
    let status: Int

    var id: String { "s\(season)e\(episode)" }

    enum CodingKeys: String, CodingKey {
        case season
        case episode
        case title
        case status
    }

    init(season: Int, episode: Int, title: String, status: Int) {
        self.season = season
        self.episode = episode
        self.title = title
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        season = Self.decodeInt(container, key: .season)
        episode = Self.decodeInt(container, key: .episode)
        title = (try? container.decodeIfPresent(String.self, forKey: .title)) ?? "第 \(episode) 集"
        status = Self.decodeInt(container, key: .status)
    }

    var codeText: String {
        "S\(String(format: "%02d", season))E\(String(format: "%02d", episode))"
    }

    private static func decodeInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int {
        if let value = try? container.decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return Int(value)
        }
        if let value = try? container.decode(String.self, forKey: key), let int = Int(value) {
            return int
        }
        return 0
    }
}

struct GapSeasonGroup: Identifiable {
    let season: Int
    let episodes: [GapEpisodeItem]

    var id: Int { season }
}

struct GapAutoStatusResponse: Decodable {
    let status: String
    let enabled: Bool
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case enabled
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        message = decodeOptionalString(from: container, forKey: .message)

        if let value = try? container.decode(Bool.self, forKey: .enabled) {
            enabled = value
        } else if let value = try? container.decode(Int.self, forKey: .enabled) {
            enabled = value != 0
        } else if let value = try? container.decode(String.self, forKey: .enabled) {
            enabled = ["true", "1", "yes", "on"].contains(value.lowercased())
        } else {
            enabled = false
        }
    }
}

struct GapIgnoresResponse: Decodable {
    let status: String
    let data: [GapIgnoredItem]?
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent([GapIgnoredItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct GapIgnoredItem: Decodable, Identifiable, Hashable {
    let type: String
    let rawID: String
    let seriesName: String
    let target: String
    let time: String

    var id: String { "\(type)-\(rawID)" }

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case seriesName = "series_name"
        case target
        case time
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? container.decodeIfPresent(String.self, forKey: .type)) ?? "record"
        seriesName = (try? container.decodeIfPresent(String.self, forKey: .seriesName)) ?? "未知剧集"
        target = (try? container.decodeIfPresent(String.self, forKey: .target)) ?? "-"
        time = (try? container.decodeIfPresent(String.self, forKey: .time)) ?? "-"

        if let intID = try? container.decode(Int.self, forKey: .id) {
            rawID = String(intID)
        } else if let stringID = try? container.decode(String.self, forKey: .id) {
            rawID = stringID
        } else {
            rawID = UUID().uuidString
        }
    }

    var typeTitle: String {
        switch type {
        case "perfect":
            return "完结免检"
        case "record":
            return "忽略记录"
        default:
            return "记录"
        }
    }
}

struct GapConfigResponse: Decodable {
    let status: String
    let data: [String: JSONValue]?
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent([String: JSONValue].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct GapClientConfig: Equatable {
    var clientType: String = ""
    var clientURL: String = ""
    var clientUser: String = ""
    var clientPass: String = ""

    init() {}

    init(map: [String: JSONValue]) {
        clientType = map["client_type"]?.stringValue ?? ""
        clientURL = map["client_url"]?.stringValue ?? ""
        clientUser = map["client_user"]?.stringValue ?? ""
        clientPass = map["client_pass"]?.stringValue ?? ""
    }
}

struct GapMPSearchResponse: Decodable {
    let status: String
    let data: GapMPSearchData?
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent(GapMPSearchData.self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct GapMPSearchData: Decodable {
    let genes: [String]
    let results: [GapMPTorrentResult]

    enum CodingKeys: String, CodingKey {
        case genes
        case results
    }

    init(genes: [String] = [], results: [GapMPTorrentResult] = []) {
        self.genes = genes
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genes = (try? container.decodeIfPresent([String].self, forKey: .genes)) ?? []
        results = (try? container.decodeIfPresent([GapMPTorrentResult].self, forKey: .results)) ?? []
    }
}

struct GapMPTorrentResult: Codable, Identifiable {
    let id: String
    let title: String
    let site: String
    let sizeBytes: Double
    let seeders: Int
    let matchScore: Int
    let isPack: Bool
    let tags: [String]
    let raw: [String: JSONValue]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawMap = (try? container.decode([String: JSONValue].self)) ?? [:]
        raw = rawMap

        title = rawMap["ui_title"]?.stringValue
            ?? rawMap["name"]?.stringValue
            ?? rawMap["title"]?.stringValue
            ?? "未命名资源"
        site = rawMap["ui_site"]?.stringValue
            ?? rawMap["site_name"]?.stringValue
            ?? rawMap["site"]?.stringValue
            ?? "未知站点"
        sizeBytes = rawMap["ui_size"]?.doubleValue
            ?? rawMap["size"]?.doubleValue
            ?? rawMap["enclosure_size"]?.doubleValue
            ?? 0
        seeders = rawMap["ui_seeders"]?.intValue
            ?? rawMap["seeders"]?.intValue
            ?? rawMap["seeder"]?.intValue
            ?? 0
        matchScore = rawMap["match_score"]?.intValue ?? 0
        isPack = rawMap["is_pack"]?.boolValue ?? false
        if case .array(let values) = rawMap["extracted_tags"] {
            tags = values.compactMap { $0.stringValue }
        } else {
            tags = []
        }

        id = "\(title)-\(site)-\(Int(sizeBytes))-\(matchScore)-\(seeders)"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}
