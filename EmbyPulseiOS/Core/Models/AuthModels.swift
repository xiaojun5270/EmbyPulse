import Foundation

struct InviteRegisterResponse: Decodable {
    let status: String
    let message: String?
    let serverURL: String?
    let welcomeMessage: String?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case serverURL = "server_url"
        case welcomeMessage = "welcome_message"
    }

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}
