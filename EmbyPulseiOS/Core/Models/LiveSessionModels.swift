import Foundation

struct LiveSession: Decodable, Identifiable {
    let id: String
    let userName: String?
    let client: String?
    let deviceName: String?
    let nowPlayingItem: LiveNowPlayingItem?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case userName = "UserName"
        case client = "Client"
        case deviceName = "DeviceName"
        case nowPlayingItem = "NowPlayingItem"
    }
}

struct LiveNowPlayingItem: Decodable {
    let name: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case type = "Type"
    }
}
