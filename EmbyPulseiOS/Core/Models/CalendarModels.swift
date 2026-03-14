import Foundation

struct CalendarWeeklyResponse: Decodable {
    let days: [CalendarDay]
    let embyURL: String?
    let serverID: String?
    let dateRange: String?
    let currentTTL: Int?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case days
        case embyURL = "emby_url"
        case serverID = "server_id"
        case dateRange = "date_range"
        case currentTTL = "current_ttl"
        case error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.days = try container.decodeIfPresent([CalendarDay].self, forKey: .days) ?? []
        self.embyURL = try container.decodeIfPresent(String.self, forKey: .embyURL)
        self.serverID = try container.decodeIfPresent(String.self, forKey: .serverID)
        self.dateRange = try container.decodeIfPresent(String.self, forKey: .dateRange)
        self.currentTTL = try container.decodeIfPresent(Int.self, forKey: .currentTTL)
        self.error = try container.decodeIfPresent(String.self, forKey: .error)
    }
}

struct CalendarDay: Decodable, Identifiable {
    let date: String
    let weekdayCN: String
    let isToday: Bool
    let items: [CalendarItem]

    var id: String { date }

    enum CodingKeys: String, CodingKey {
        case date
        case weekdayCN = "weekday_cn"
        case isToday = "is_today"
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try container.decode(String.self, forKey: .date)
        self.weekdayCN = try container.decode(String.self, forKey: .weekdayCN)
        self.isToday = try container.decode(Bool.self, forKey: .isToday)
        self.items = try container.decodeIfPresent([CalendarItem].self, forKey: .items) ?? []
    }
}

struct CalendarItem: Decodable, Identifiable {
    let seriesName: String
    let seriesID: String
    let season: Int
    let episodeDisplay: String
    let airDate: String
    let posterPath: String?
    let status: String
    let overview: String?

    var id: String { "\(seriesID)-\(season)-\(episodeDisplay)-\(airDate)" }

    enum CodingKeys: String, CodingKey {
        case seriesName = "series_name"
        case seriesID = "series_id"
        case season
        case episode
        case airDate = "air_date"
        case posterPath = "poster_path"
        case status
        case overview
        case seriesOverview = "series_overview"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.seriesName = try container.decode(String.self, forKey: .seriesName)
        self.seriesID = try container.decode(String.self, forKey: .seriesID)
        self.season = try container.decodeIfPresent(Int.self, forKey: .season) ?? 0
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.status = (try container.decodeIfPresent(String.self, forKey: .status) ?? "upcoming").lowercased()

        if let value = try? container.decode(String.self, forKey: .episode) {
            self.episodeDisplay = value
        } else if let value = try? container.decode(Int.self, forKey: .episode) {
            self.episodeDisplay = String(value)
        } else {
            self.episodeDisplay = "?"
        }

        let episodeOverview = try container.decodeIfPresent(String.self, forKey: .overview)
        let seriesOverview = try container.decodeIfPresent(String.self, forKey: .seriesOverview)
        self.overview = episodeOverview?.isEmpty == false ? episodeOverview : seriesOverview
    }
}
