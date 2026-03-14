import Foundation

struct ManagedUser: Decodable, Identifiable {
    let id: String
    let name: String
    let lastLoginDate: String?
    let isDisabled: Bool
    let isAdmin: Bool
    let expireDate: String?
    let note: String?
    let primaryImageTag: String?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case lastLoginDate = "LastLoginDate"
        case isDisabled = "IsDisabled"
        case isAdmin = "IsAdmin"
        case expireDate = "ExpireDate"
        case note = "Note"
        case primaryImageTag = "PrimaryImageTag"
    }
}

struct ManagedUsersResponse: Decodable {
    let status: String
    let data: [ManagedUser]
    let embyURL: String?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case embyURL = "emby_url"
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "error"
        self.data = try container.decodeIfPresent([ManagedUser].self, forKey: .data) ?? []
        self.embyURL = try container.decodeIfPresent(String.self, forKey: .embyURL)
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}

struct InviteCodeItem: Decodable, Identifiable {
    let code: String
    let days: Int
    let usedCount: Int
    let maxUses: Int
    let createdAt: String?
    let usedAt: String?
    let usedBy: String?
    let status: Int
    let templateUserID: String?

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case code
        case days
        case usedCount = "used_count"
        case maxUses = "max_uses"
        case createdAt = "created_at"
        case usedAt = "used_at"
        case usedBy = "used_by"
        case status
        case templateUserID = "template_user_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.code = try container.decode(String.self, forKey: .code)
        self.days = try container.decodeIfPresent(Int.self, forKey: .days) ?? 0
        self.usedCount = try container.decodeIfPresent(Int.self, forKey: .usedCount) ?? 0
        self.maxUses = try container.decodeIfPresent(Int.self, forKey: .maxUses) ?? 1
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.usedAt = try container.decodeIfPresent(String.self, forKey: .usedAt)
        self.usedBy = try container.decodeIfPresent(String.self, forKey: .usedBy)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        self.templateUserID = try container.decodeIfPresent(String.self, forKey: .templateUserID)
    }
}

struct InviteListResponse: Decodable {
    let status: String
    let data: [InviteCodeItem]
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "error"
        self.data = try container.decodeIfPresent([InviteCodeItem].self, forKey: .data) ?? []
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
    }
}
