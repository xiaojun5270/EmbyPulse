import Foundation

struct TopMoviesResponse: Decodable {
    let status: String
    let data: [TopMovieItem]?
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
        data = try? container.decodeIfPresent([TopMovieItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct TopMovieItem: Decodable, Identifiable {
    let itemName: String
    let itemID: String
    let playCount: Int
    let totalTime: Int
    let smartPoster: String?

    var id: String { "\(itemID)-\(itemName)" }

    enum CodingKeys: String, CodingKey {
        case itemName = "ItemName"
        case itemID = "ItemId"
        case playCount = "PlayCount"
        case totalTime = "TotalTime"
        case smartPoster = "smart_poster"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemName = try container.decodeIfPresent(String.self, forKey: .itemName) ?? "未知内容"
        itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? UUID().uuidString
        playCount = Self.decodeInt(container, key: .playCount)
        totalTime = Self.decodeInt(container, key: .totalTime)
        smartPoster = try container.decodeIfPresent(String.self, forKey: .smartPoster)
    }

    var totalHours: Double {
        Double(totalTime) / 3600.0
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

struct TopUsersListResponse: Decodable {
    let status: String
    let data: [TopUserItem]?
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
        data = try? container.decodeIfPresent([TopUserItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct TopUserItem: Decodable, Identifiable {
    let userID: String
    let userName: String
    let plays: Int
    let totalTime: Int

    var id: String { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "UserId"
        case userName = "UserName"
        case plays = "Plays"
        case totalTime = "TotalTime"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? UUID().uuidString
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? "未知用户"
        plays = Self.decodeInt(container, key: .plays)
        totalTime = Self.decodeInt(container, key: .totalTime)
    }

    var totalHours: Double {
        Double(totalTime) / 3600.0
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

struct BadgesResponse: Decodable {
    let status: String
    let data: [StatBadge]?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent([StatBadge].self, forKey: .data)
    }
}

struct StatBadge: Decodable, Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let background: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case color
        case background = "bg"
        case description = "desc"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未知勋章"
        icon = try container.decodeIfPresent(String.self, forKey: .icon) ?? "fa-star"
        color = try container.decodeIfPresent(String.self, forKey: .color) ?? ""
        background = try container.decodeIfPresent(String.self, forKey: .background) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }
}

struct UserDetailsResponse: Decodable {
    let status: String
    let data: UserDetailData?
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
        data = try? container.decodeIfPresent(UserDetailData.self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct UserDetailData: Decodable {
    let hourly: [String: Int]
    let devices: [StatsKeyValue]
    let clients: [StatsKeyValue]
    let logs: [RecentPlaybackLog]
    let overview: UserOverview
    let preference: UserPreference
    let topFavorite: TopFavoriteItem?

    enum CodingKeys: String, CodingKey {
        case hourly
        case devices
        case clients
        case logs
        case overview
        case preference
        case topFavorite = "top_fav"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intMap = try? container.decodeIfPresent([String: Int].self, forKey: .hourly) {
            hourly = intMap
        } else if let stringMap = try? container.decodeIfPresent([String: String].self, forKey: .hourly) {
            hourly = stringMap.reduce(into: [:]) { partialResult, element in
                partialResult[element.key] = Int(element.value) ?? 0
            }
        } else if let doubleMap = try? container.decodeIfPresent([String: Double].self, forKey: .hourly) {
            hourly = doubleMap.reduce(into: [:]) { partialResult, element in
                partialResult[element.key] = Int(element.value)
            }
        } else {
            hourly = [:]
        }
        devices = try container.decodeIfPresent([StatsKeyValue].self, forKey: .devices) ?? []
        clients = try container.decodeIfPresent([StatsKeyValue].self, forKey: .clients) ?? []
        logs = try container.decodeIfPresent([RecentPlaybackLog].self, forKey: .logs) ?? []
        overview = try container.decodeIfPresent(UserOverview.self, forKey: .overview) ?? UserOverview()
        preference = try container.decodeIfPresent(UserPreference.self, forKey: .preference) ?? UserPreference()
        topFavorite = try container.decodeIfPresent(TopFavoriteItem.self, forKey: .topFavorite)
    }
}

struct StatsKeyValue: Decodable, Identifiable {
    let label: String
    let plays: Int

    var id: String { label }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let playsKey = DynamicCodingKey(stringValue: "Plays")
        if let playsKey {
            if let int = try container.decodeIfPresent(Int.self, forKey: playsKey) {
                plays = int
            } else if let double = try container.decodeIfPresent(Double.self, forKey: playsKey) {
                plays = Int(double)
            } else if let string = try container.decodeIfPresent(String.self, forKey: playsKey), let int = Int(string) {
                plays = int
            } else {
                plays = 0
            }
        } else {
            plays = 0
        }

        if let deviceKey = DynamicCodingKey(stringValue: "Device"),
           let value = try container.decodeIfPresent(String.self, forKey: deviceKey) {
            label = value
        } else if let clientKey = DynamicCodingKey(stringValue: "Client"),
                  let value = try container.decodeIfPresent(String.self, forKey: clientKey) {
            label = value
        } else {
            label = "未知"
        }
    }
}

struct RecentPlaybackLog: Decodable, Identifiable {
    let dateCreated: String
    let itemName: String
    let itemID: String
    let itemType: String
    let playDuration: Int
    let device: String
    let userID: String
    let userName: String
    let smartPoster: String?

    var id: String { "\(dateCreated)-\(itemID)-\(userID)" }

    enum CodingKeys: String, CodingKey {
        case dateCreated = "DateCreated"
        case itemName = "ItemName"
        case itemID = "ItemId"
        case itemType = "ItemType"
        case playDuration = "PlayDuration"
        case device = "Device"
        case userID = "UserId"
        case userName = "UserName"
        case smartPoster = "smart_poster"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated) ?? ""
        itemName = try container.decodeIfPresent(String.self, forKey: .itemName) ?? "未知内容"
        itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? UUID().uuidString
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? ""
        device = try container.decodeIfPresent(String.self, forKey: .device) ?? "未知设备"
        userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? ""
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? "未知用户"
        smartPoster = try container.decodeIfPresent(String.self, forKey: .smartPoster)

        if let int = try? container.decode(Int.self, forKey: .playDuration) {
            playDuration = int
        } else if let string = try? container.decode(String.self, forKey: .playDuration), let int = Int(string) {
            playDuration = int
        } else {
            playDuration = 0
        }
    }
}

struct UserOverview: Decodable {
    let totalPlays: Int
    let totalDuration: Int
    let avgDuration: Int
    let accountAgeDays: Int

    enum CodingKeys: String, CodingKey {
        case totalPlays = "total_plays"
        case totalDuration = "total_duration"
        case avgDuration = "avg_duration"
        case accountAgeDays = "account_age_days"
    }

    init(
        totalPlays: Int = 0,
        totalDuration: Int = 0,
        avgDuration: Int = 0,
        accountAgeDays: Int = 0
    ) {
        self.totalPlays = totalPlays
        self.totalDuration = totalDuration
        self.avgDuration = avgDuration
        self.accountAgeDays = accountAgeDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalPlays = Self.decodeInt(container, key: .totalPlays)
        totalDuration = Self.decodeInt(container, key: .totalDuration)
        avgDuration = Self.decodeInt(container, key: .avgDuration)
        accountAgeDays = Self.decodeInt(container, key: .accountAgeDays)
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

struct UserPreference: Decodable {
    let moviePlays: Int
    let episodePlays: Int

    enum CodingKeys: String, CodingKey {
        case moviePlays = "movie_plays"
        case episodePlays = "episode_plays"
    }

    init(moviePlays: Int = 0, episodePlays: Int = 0) {
        self.moviePlays = moviePlays
        self.episodePlays = episodePlays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        moviePlays = (try? container.decode(Int.self, forKey: .moviePlays)) ?? 0
        episodePlays = (try? container.decode(Int.self, forKey: .episodePlays)) ?? 0
    }
}

struct TopFavoriteItem: Decodable {
    let itemName: String
    let itemID: String
    let playCount: Int
    let totalDuration: Int
    let smartPoster: String?

    enum CodingKeys: String, CodingKey {
        case itemName = "ItemName"
        case itemID = "ItemId"
        case playCount = "c"
        case totalDuration = "d"
        case smartPoster = "smart_poster"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemName = try container.decodeIfPresent(String.self, forKey: .itemName) ?? ""
        itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? ""
        playCount = (try? container.decode(Int.self, forKey: .playCount)) ?? 0
        totalDuration = (try? container.decode(Int.self, forKey: .totalDuration)) ?? 0
        smartPoster = try container.decodeIfPresent(String.self, forKey: .smartPoster)
    }
}

struct LatestMediaResponse: Decodable {
    let status: String
    let data: [LatestMediaItem]?
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
        data = try? container.decodeIfPresent([LatestMediaItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct LatestMediaItem: Decodable, Identifiable {
    let id: String
    let name: String
    let seriesName: String
    let year: Int?
    let rating: Double?
    let type: String
    let dateCreated: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case seriesName = "SeriesName"
        case year = "Year"
        case rating = "Rating"
        case type = "Type"
        case dateCreated = "DateCreated"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未知资源"
        seriesName = try container.decodeIfPresent(String.self, forKey: .seriesName) ?? ""
        year = try? container.decodeIfPresent(Int.self, forKey: .year)
        if let double = try? container.decodeIfPresent(Double.self, forKey: .rating) {
            rating = double
        } else if let int = try? container.decodeIfPresent(Int.self, forKey: .rating) {
            rating = Double(int)
        } else if let string = try? container.decode(String.self, forKey: .rating), let double = Double(string) {
            rating = double
        } else {
            rating = nil
        }
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated)
    }
}

struct RecentActivityResponse: Decodable {
    let status: String
    let data: [RecentActivityItem]?
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
        data = try? container.decodeIfPresent([RecentActivityItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct RecentActivityItem: Decodable, Identifiable {
    let dateCreated: String
    let userID: String
    let userName: String
    let itemID: String
    let itemName: String
    let itemType: String
    let displayName: String

    var id: String { "\(dateCreated)-\(itemID)-\(userID)" }

    enum CodingKeys: String, CodingKey {
        case dateCreated = "DateCreated"
        case userID = "UserId"
        case userName = "UserName"
        case itemID = "ItemId"
        case itemName = "ItemName"
        case itemType = "ItemType"
        case displayName = "DisplayName"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated) ?? ""
        userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? ""
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? "未知用户"
        itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? UUID().uuidString
        itemName = try container.decodeIfPresent(String.self, forKey: .itemName) ?? "未知内容"
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? itemName
    }
}

struct LibrariesResponse: Decodable {
    let status: String
    let data: [LibraryViewItem]?
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
        data = try? container.decodeIfPresent([LibraryViewItem].self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct LibraryViewItem: Decodable, Identifiable {
    let id: String
    let name: String
    let collectionType: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case collectionType = "CollectionType"
        case type = "Type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名库"
        collectionType = try container.decodeIfPresent(String.self, forKey: .collectionType) ?? "unknown"
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
    }
}

struct MonthlyStatsResponse: Decodable {
    let status: String
    let data: [String: Int]?
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
        message = decodeOptionalString(from: container, forKey: .message)

        if let intMap = try? container.decode([String: Int].self, forKey: .data) {
            data = intMap
            return
        }
        if let stringMap = try? container.decode([String: String].self, forKey: .data) {
            var normalized: [String: Int] = [:]
            for (key, value) in stringMap {
                normalized[key] = Int(value) ?? 0
            }
            data = normalized
            return
        }
        if let doubleMap = try? container.decode([String: Double].self, forKey: .data) {
            var normalized: [String: Int] = [:]
            for (key, value) in doubleMap {
                normalized[key] = Int(value)
            }
            data = normalized
            return
        }
        data = [:]
    }
}

struct MonthlyDurationPoint: Identifiable {
    let month: String
    let durationSeconds: Int

    var id: String { month }

    var hours: Double {
        Double(durationSeconds) / 3600.0
    }
}

enum TopMoviesCategory: String, CaseIterable, Identifiable {
    case all
    case movie = "Movie"
    case episode = "Episode"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全部"
        case .movie:
            return "电影"
        case .episode:
            return "剧集"
        }
    }
}

enum TopMoviesSort: String, CaseIterable, Identifiable {
    case count
    case time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .count:
            return "按次数"
        case .time:
            return "按时长"
        }
    }
}

enum TopMoviesPeriod: String, CaseIterable, Identifiable {
    case all
    case year
    case month
    case week
    case day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "总榜"
        case .year:
            return "年度"
        case .month:
            return "本月"
        case .week:
            return "本周"
        case .day:
            return "今日"
        }
    }
}

enum TopUsersPeriod: String, CaseIterable, Identifiable {
    case all
    case day
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全量"
        case .day:
            return "今日"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .year:
            return "年度"
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
