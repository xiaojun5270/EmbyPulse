import Foundation

struct UserFeedbackItem: Decodable, Identifiable {
    let id: Int
    let itemName: String
    let issueType: String
    let description: String?
    let status: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case itemName = "item_name"
        case issueType = "issue_type"
        case description
        case status
        case createdAt = "created_at"
    }
}

struct ManagedFeedbackItem: Decodable, Identifiable {
    let id: Int
    let itemName: String
    let username: String
    let issueType: String
    let description: String?
    let status: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case itemName = "item_name"
        case username
        case issueType = "issue_type"
        case description
        case status
        case createdAt = "created_at"
    }
}

enum FeedbackStatus: Int {
    case pending = 0
    case fixing = 1
    case done = 2
    case ignored = 3

    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .fixing
        case 2: self = .done
        case 3: self = .ignored
        default: self = .pending
        }
    }

    var title: String {
        switch self {
        case .pending:
            return "待核实"
        case .fixing:
            return "修复中"
        case .done:
            return "已解决"
        case .ignored:
            return "已忽略"
        }
    }
}

enum ManageFeedbackAction: String {
    case fix
    case done
    case reject
    case delete

    var title: String {
        switch self {
        case .fix:
            return "修复中"
        case .done:
            return "已解决"
        case .reject:
            return "忽略"
        case .delete:
            return "删除"
        }
    }
}
