import Foundation

struct SystemSettingsResponse: Decodable {
    let status: String
    let data: SystemSettingsData?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct SystemSettingsData: Decodable {
    let embyHost: String
    let embyAPIKey: String
    let tmdbAPIKey: String
    let proxyURL: String
    let webhookToken: String
    let hiddenUsers: [String]

    let embyPublicURL: String
    let welcomeMessage: String
    let clientDownloadURL: String

    let moviepilotURL: String
    let moviepilotToken: String
    let pulseURL: String

    enum CodingKeys: String, CodingKey {
        case embyHost = "emby_host"
        case embyAPIKey = "emby_api_key"
        case tmdbAPIKey = "tmdb_api_key"
        case proxyURL = "proxy_url"
        case webhookToken = "webhook_token"
        case hiddenUsers = "hidden_users"
        case embyPublicURL = "emby_public_url"
        case welcomeMessage = "welcome_message"
        case clientDownloadURL = "client_download_url"
        case moviepilotURL = "moviepilot_url"
        case moviepilotToken = "moviepilot_token"
        case pulseURL = "pulse_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        embyHost = Self.decodeString(container, key: .embyHost)
        embyAPIKey = Self.decodeString(container, key: .embyAPIKey)
        tmdbAPIKey = Self.decodeString(container, key: .tmdbAPIKey)
        proxyURL = Self.decodeString(container, key: .proxyURL)
        webhookToken = Self.decodeString(container, key: .webhookToken, defaultValue: "embypulse")

        if let values = try? container.decode([String].self, forKey: .hiddenUsers) {
            hiddenUsers = values
        } else if let values = try? container.decode([Int].self, forKey: .hiddenUsers) {
            hiddenUsers = values.map(String.init)
        } else {
            hiddenUsers = []
        }

        embyPublicURL = Self.decodeString(container, key: .embyPublicURL)
        welcomeMessage = Self.decodeString(container, key: .welcomeMessage)
        clientDownloadURL = Self.decodeString(container, key: .clientDownloadURL)
        moviepilotURL = Self.decodeString(container, key: .moviepilotURL)
        moviepilotToken = Self.decodeString(container, key: .moviepilotToken)
        pulseURL = Self.decodeString(container, key: .pulseURL)
    }

    private static func decodeString(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys,
        defaultValue: String = ""
    ) -> String {
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return String(value)
        }
        return defaultValue
    }
}

struct SystemSettingsDraft: Equatable {
    var embyHost: String = ""
    var embyAPIKey: String = ""
    var tmdbAPIKey: String = ""
    var proxyURL: String = ""
    var webhookToken: String = "embypulse"
    var hiddenUsers: [String] = []

    var embyPublicURL: String = ""
    var welcomeMessage: String = ""
    var clientDownloadURL: String = ""

    var moviepilotURL: String = ""
    var moviepilotToken: String = ""
    var pulseURL: String = ""

    init() {}

    init(from data: SystemSettingsData) {
        embyHost = data.embyHost
        embyAPIKey = data.embyAPIKey
        tmdbAPIKey = data.tmdbAPIKey
        proxyURL = data.proxyURL
        webhookToken = data.webhookToken
        hiddenUsers = data.hiddenUsers
        embyPublicURL = data.embyPublicURL
        welcomeMessage = data.welcomeMessage
        clientDownloadURL = data.clientDownloadURL
        moviepilotURL = data.moviepilotURL
        moviepilotToken = data.moviepilotToken
        pulseURL = data.pulseURL
    }
}
