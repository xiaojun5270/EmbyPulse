import Foundation

struct EmbyUserOption: Decodable, Identifiable {
    let userID: String
    let userName: String
    let isHidden: Bool

    var id: String { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "UserId"
        case userName = "UserName"
        case isHidden = "IsHidden"
    }
}

struct PlaybackHistoryListResponse: Decodable {
    let status: String
    let data: [PlaybackHistoryItem]
    let pagination: HistoryPagination?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case pagination
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "error"
        self.data = try container.decodeIfPresent([PlaybackHistoryItem].self, forKey: .data) ?? []
        self.pagination = try container.decodeIfPresent(HistoryPagination.self, forKey: .pagination)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}

struct HistoryPagination: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case totalPages = "total_pages"
    }
}

struct PlaybackHistoryItem: Decodable, Identifiable {
    let dateCreated: String
    let userID: String
    let itemID: String
    let itemName: String
    let itemType: String
    let playDuration: Int
    let deviceName: String?
    let clientName: String?
    let userName: String?
    let durationStr: String?
    let dateStr: String?

    var id: String { "\(dateCreated)-\(itemID)-\(userID)" }

    enum CodingKeys: String, CodingKey {
        case dateCreated = "DateCreated"
        case userID = "UserId"
        case itemID = "ItemId"
        case itemName = "ItemName"
        case itemType = "ItemType"
        case playDuration = "PlayDuration"
        case deviceName = "DeviceName"
        case clientName = "ClientName"
        case userName = "UserName"
        case durationStr = "DurationStr"
        case dateStr = "DateStr"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateCreated = try container.decodeIfPresent(String.self, forKey: .dateCreated) ?? ""
        self.userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? ""
        self.itemID = try container.decodeIfPresent(String.self, forKey: .itemID) ?? ""
        self.itemName = try container.decodeIfPresent(String.self, forKey: .itemName) ?? "未知内容"
        self.itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? "Unknown"
        self.deviceName = try container.decodeIfPresent(String.self, forKey: .deviceName)
        self.clientName = try container.decodeIfPresent(String.self, forKey: .clientName)
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
        self.durationStr = try container.decodeIfPresent(String.self, forKey: .durationStr)
        self.dateStr = try container.decodeIfPresent(String.self, forKey: .dateStr)

        if let durationInt = try? container.decode(Int.self, forKey: .playDuration) {
            self.playDuration = durationInt
        } else if let durationString = try? container.decode(String.self, forKey: .playDuration),
                  let durationInt = Int(durationString) {
            self.playDuration = durationInt
        } else {
            self.playDuration = 0
        }
    }
}

enum TrendDimension: String, CaseIterable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "日"
        case .week:
            return "周"
        case .month:
            return "月"
        }
    }
}

struct TrendPoint: Identifiable {
    let label: String
    let durationSeconds: Int

    var id: String { label }

    var hours: Double {
        Double(durationSeconds) / 3600.0
    }
}
