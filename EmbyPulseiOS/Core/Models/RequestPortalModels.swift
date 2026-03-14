import Foundation

struct RequestPortalUser: Decodable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
    }
}

struct RequestPortalSessionResponse: Decodable {
    let status: String
    let user: RequestPortalUser?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct RequestMediaItem: Decodable, Identifiable {
    let tmdbID: Int
    let mediaType: String
    let title: String
    let year: String
    let posterPath: String?
    let overview: String?
    let voteAverage: Double?
    let localStatus: Int?

    var id: String { "\(mediaType)-\(tmdbID)" }

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case mediaType = "media_type"
        case title
        case year
        case posterPath = "poster_path"
        case overview
        case voteAverage = "vote_average"
        case localStatus = "local_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tmdbID = try container.decode(Int.self, forKey: .tmdbID)
        self.mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType) ?? "movie"
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未知标题"
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage)
        self.localStatus = try container.decodeIfPresent(Int.self, forKey: .localStatus)

        if let yearString = try? container.decode(String.self, forKey: .year) {
            self.year = yearString
        } else if let yearInt = try? container.decode(Int.self, forKey: .year) {
            self.year = String(yearInt)
        } else {
            self.year = ""
        }
    }
}

struct RequestTrendingGroups: Decodable {
    let movies: [RequestMediaItem]
    let tv: [RequestMediaItem]
    let topMovies: [RequestMediaItem]
    let topTV: [RequestMediaItem]

    enum CodingKeys: String, CodingKey {
        case movies
        case tv
        case topMovies = "top_movies"
        case topTV = "top_tv"
    }
}

struct TVSeasonInfo: Decodable, Identifiable {
    let seasonNumber: Int
    let name: String
    let episodeCount: Int
    let existsLocally: Bool

    var id: Int { seasonNumber }

    enum CodingKeys: String, CodingKey {
        case seasonNumber = "season_number"
        case name
        case episodeCount = "episode_count"
        case existsLocally = "exists_locally"
    }
}

struct TVSeasonResponse: Decodable {
    let status: String
    let seasons: [TVSeasonInfo]
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }

    enum CodingKeys: String, CodingKey {
        case status
        case seasons
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "error"
        self.seasons = try container.decodeIfPresent([TVSeasonInfo].self, forKey: .seasons) ?? []
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}

struct UserRequestItem: Decodable, Identifiable {
    let tmdbID: Int
    let title: String
    let year: String
    let posterPath: String?
    let status: Int
    let season: Int
    let requestedAt: String?
    let rejectReason: String?

    var id: String { "\(tmdbID)-\(season)" }

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case title
        case year
        case posterPath = "poster_path"
        case status
        case season
        case requestedAt = "requested_at"
        case rejectReason = "reject_reason"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tmdbID = try container.decode(Int.self, forKey: .tmdbID)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未知标题"
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        self.season = try container.decodeIfPresent(Int.self, forKey: .season) ?? 0
        self.requestedAt = try container.decodeIfPresent(String.self, forKey: .requestedAt)
        self.rejectReason = try container.decodeIfPresent(String.self, forKey: .rejectReason)

        if let yearString = try? container.decode(String.self, forKey: .year) {
            self.year = yearString
        } else if let yearInt = try? container.decode(Int.self, forKey: .year) {
            self.year = String(yearInt)
        } else {
            self.year = ""
        }
    }
}

enum UserRequestStatus: Int {
    case pending = 0
    case approved = 1
    case done = 2
    case rejected = 3
    case manual = 4

    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .approved
        case 2: self = .done
        case 3: self = .rejected
        case 4: self = .manual
        default: self = .pending
        }
    }

    var title: String {
        switch self {
        case .pending:
            return "待处理"
        case .approved:
            return "已推送"
        case .done:
            return "已完成"
        case .rejected:
            return "已拒绝"
        case .manual:
            return "手动处理中"
        }
    }
}
