import Foundation

struct LibrarySearchItem: Decodable, Identifiable {
    let id: String
    let name: String
    let year: String
    let overview: String
    let type: String
    let poster: String?
    let embyURL: String?
    let badges: [LibraryBadge]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case year
        case overview
        case type
        case poster
        case embyURL = "emby_url"
        case badges
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未知资源"
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "movie"
        poster = try container.decodeIfPresent(String.self, forKey: .poster)
        embyURL = try container.decodeIfPresent(String.self, forKey: .embyURL)
        badges = try container.decodeIfPresent([LibraryBadge].self, forKey: .badges) ?? []

        if let yearString = try? container.decode(String.self, forKey: .year) {
            year = yearString
        } else if let yearInt = try? container.decode(Int.self, forKey: .year) {
            year = String(yearInt)
        } else {
            year = ""
        }
    }
}

struct LibraryBadge: Decodable, Identifiable {
    let type: String?
    let text: String
    let color: String?

    var id: String { "\(type ?? "unknown")-\(text)" }

    enum CodingKeys: String, CodingKey {
        case type
        case text
        case color
    }
}
