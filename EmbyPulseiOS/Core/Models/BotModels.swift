import Foundation

struct BotSettingsResponse: Decodable {
    let status: String
    let data: BotSettingsData?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct BotSettingsData: Decodable {
    let tgBotToken: String
    let tgChatID: String
    let enableBot: Bool
    let enableNotify: Bool
    let enableLibraryNotify: Bool

    let wecomCorpid: String
    let wecomCorpsecret: String
    let wecomAgentid: String
    let wecomTouser: String
    let wecomProxyURL: String
    let wecomToken: String
    let wecomAESKey: String

    let webhookToken: String

    enum CodingKeys: String, CodingKey {
        case tgBotToken = "tg_bot_token"
        case tgChatID = "tg_chat_id"
        case enableBot = "enable_bot"
        case enableNotify = "enable_notify"
        case enableLibraryNotify = "enable_library_notify"
        case wecomCorpid = "wecom_corpid"
        case wecomCorpsecret = "wecom_corpsecret"
        case wecomAgentid = "wecom_agentid"
        case wecomTouser = "wecom_touser"
        case wecomProxyURL = "wecom_proxy_url"
        case wecomToken = "wecom_token"
        case wecomAESKey = "wecom_aeskey"
        case webhookToken = "webhook_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        tgBotToken = Self.decodeString(container, key: .tgBotToken)
        tgChatID = Self.decodeString(container, key: .tgChatID)
        enableBot = Self.decodeBool(container, key: .enableBot, defaultValue: false)
        enableNotify = Self.decodeBool(container, key: .enableNotify, defaultValue: false)
        enableLibraryNotify = Self.decodeBool(container, key: .enableLibraryNotify, defaultValue: false)

        wecomCorpid = Self.decodeString(container, key: .wecomCorpid)
        wecomCorpsecret = Self.decodeString(container, key: .wecomCorpsecret)
        wecomAgentid = Self.decodeString(container, key: .wecomAgentid)
        wecomTouser = Self.decodeString(container, key: .wecomTouser, defaultValue: "@all")
        wecomProxyURL = Self.decodeString(container, key: .wecomProxyURL, defaultValue: "https://qyapi.weixin.qq.com")
        wecomToken = Self.decodeString(container, key: .wecomToken)
        wecomAESKey = Self.decodeString(container, key: .wecomAESKey)

        webhookToken = Self.decodeString(container, key: .webhookToken, defaultValue: "embypulse")
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
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value ? "true" : "false"
        }
        return defaultValue
    }

    private static func decodeBool(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys,
        defaultValue: Bool
    ) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? container.decode(String.self, forKey: key) {
            let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if ["1", "true", "yes", "on"].contains(normalized) {
                return true
            }
            if ["0", "false", "no", "off", ""].contains(normalized) {
                return false
            }
        }
        return defaultValue
    }
}

struct BotSettingsDraft: Equatable {
    var tgBotToken: String = ""
    var tgChatID: String = ""
    var enableBot: Bool = false
    var enableNotify: Bool = false
    var enableLibraryNotify: Bool = false

    var wecomCorpid: String = ""
    var wecomCorpsecret: String = ""
    var wecomAgentid: String = ""
    var wecomTouser: String = "@all"
    var wecomProxyURL: String = "https://qyapi.weixin.qq.com"
    var wecomToken: String = ""
    var wecomAESKey: String = ""

    var webhookToken: String = "embypulse"

    init() {}

    init(from data: BotSettingsData) {
        tgBotToken = data.tgBotToken
        tgChatID = data.tgChatID
        enableBot = data.enableBot
        enableNotify = data.enableNotify
        enableLibraryNotify = data.enableLibraryNotify
        wecomCorpid = data.wecomCorpid
        wecomCorpsecret = data.wecomCorpsecret
        wecomAgentid = data.wecomAgentid
        wecomTouser = data.wecomTouser
        wecomProxyURL = data.wecomProxyURL
        wecomToken = data.wecomToken
        wecomAESKey = data.wecomAESKey
        webhookToken = data.webhookToken
    }
}
