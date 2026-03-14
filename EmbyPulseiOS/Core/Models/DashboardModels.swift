import Foundation

struct DashboardData: Decodable {
    let totalPlays: Int
    let activeUsers: Int
    let totalDuration: Int
    let library: LibraryCounts

    enum CodingKeys: String, CodingKey {
        case totalPlays = "total_plays"
        case activeUsers = "active_users"
        case totalDuration = "total_duration"
        case library
    }
}

struct LibraryCounts: Decodable {
    let movie: Int
    let series: Int
    let episode: Int
}
