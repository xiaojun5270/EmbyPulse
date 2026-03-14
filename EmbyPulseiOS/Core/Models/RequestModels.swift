import Foundation

struct ManagedRequest: Decodable, Identifiable {
    let tmdbID: Int
    let mediaType: String
    let title: String
    let year: String
    let posterPath: String?
    let status: Int
    let season: Int
    let createdAt: String?
    let requestCount: Int
    let requestedBy: String?
    let rejectReason: String?

    var id: String { "\(tmdbID)-\(season)" }

    enum CodingKeys: String, CodingKey {
        case tmdbID = "tmdb_id"
        case mediaType = "media_type"
        case title
        case year
        case posterPath = "poster_path"
        case status
        case season
        case createdAt = "created_at"
        case requestCount = "request_count"
        case requestedBy = "requested_by"
        case rejectReason = "reject_reason"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.tmdbID = try container.decode(Int.self, forKey: .tmdbID)
        self.mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType) ?? "movie"
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未知标题"
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        self.season = try container.decodeIfPresent(Int.self, forKey: .season) ?? 0
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.requestCount = try container.decodeIfPresent(Int.self, forKey: .requestCount) ?? 0
        self.requestedBy = try container.decodeIfPresent(String.self, forKey: .requestedBy)
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

struct ManagedRequestBatchItem: Encodable {
    let tmdbID: Int
    let season: Int
}

enum ManageRequestAction: String {
    case approve
    case manual
    case finish
    case reject
    case delete

    var title: String {
        switch self {
        case .approve:
            return "推送 MP"
        case .manual:
            return "手动接单"
        case .finish:
            return "标记完成"
        case .reject:
            return "拒绝"
        case .delete:
            return "删除"
        }
    }
}

enum ManagedRequestStatus: Int {
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
