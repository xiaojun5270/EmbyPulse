import Foundation

struct PosterDataResponse: Decodable {
    let status: String
    let data: PosterData?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct PosterData: Decodable {
    let plays: Int
    let hours: Double
    let serverPlays: Int
    let topList: [PosterTopItem]
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case plays
        case hours
        case serverPlays = "server_plays"
        case topList = "top_list"
        case tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        plays = Self.decodeInt(container, key: .plays)
        if let value = try? container.decode(Double.self, forKey: .hours) {
            hours = value
        } else if let value = try? container.decode(Int.self, forKey: .hours) {
            hours = Double(value)
        } else if let value = try? container.decode(String.self, forKey: .hours), let double = Double(value) {
            hours = double
        } else {
            hours = 0
        }
        serverPlays = Self.decodeInt(container, key: .serverPlays)
        topList = (try? container.decode([PosterTopItem].self, forKey: .topList)) ?? []
        tags = (try? container.decode([String].self, forKey: .tags)) ?? []
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

struct PosterTopItem: Decodable, Identifiable {
    let itemName: String
    let itemID: String
    let count: Int
    let duration: Int

    var id: String { "\(itemID)-\(itemName)" }

    enum CodingKeys: String, CodingKey {
        case itemName = "ItemName"
        case itemID = "ItemId"
        case count = "Count"
        case duration = "Duration"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemName = (try? container.decode(String.self, forKey: .itemName)) ?? "未知内容"
        itemID = (try? container.decode(String.self, forKey: .itemID)) ?? UUID().uuidString
        count = Self.decodeInt(container, key: .count)
        duration = Self.decodeInt(container, key: .duration)
    }

    var durationHours: Double {
        Double(duration) / 3600.0
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

enum ReportPeriod: String, CaseIterable, Identifiable {
    case all
    case year
    case month
    case week
    case day
    case yesterday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "全量"
        case .year:
            return "年度"
        case .month:
            return "本月"
        case .week:
            return "本周"
        case .day:
            return "今日"
        case .yesterday:
            return "昨日"
        }
    }
}

enum ReportTheme: String, CaseIterable, Identifiable {
    case blackGold = "black_gold"
    case cyber
    case ocean
    case aurora
    case magma
    case sunset
    case concrete
    case white

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blackGold:
            return "黑金"
        case .cyber:
            return "赛博"
        case .ocean:
            return "深海"
        case .aurora:
            return "极光"
        case .magma:
            return "熔岩"
        case .sunset:
            return "落日"
        case .concrete:
            return "水泥"
        case .white:
            return "纯白"
        }
    }
}
