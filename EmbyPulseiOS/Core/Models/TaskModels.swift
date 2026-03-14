import Foundation

struct TaskGroupsResponse: Decodable {
    let status: String
    let data: [TaskGroup]?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct TaskGroup: Decodable, Identifiable {
    let title: String
    let tasks: [ScheduledTask]

    var id: String { title }

    enum CodingKeys: String, CodingKey {
        case title
        case tasks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未分类"
        tasks = try container.decodeIfPresent([ScheduledTask].self, forKey: .tasks) ?? []
    }
}

struct ScheduledTask: Decodable, Identifiable {
    let id: String
    let name: String
    let originalName: String
    let description: String
    let category: String
    let state: String
    let currentProgressPercentage: Double
    let isHidden: Bool
    let lastExecutionResult: TaskExecutionResult?

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case originalName = "OriginalName"
        case description = "Description"
        case category = "Category"
        case state = "State"
        case currentProgressPercentage = "CurrentProgressPercentage"
        case isHidden = "IsHidden"
        case lastExecutionResult = "LastExecutionResult"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = Self.decodeString(container, key: .id, defaultValue: UUID().uuidString)
        name = Self.decodeString(container, key: .name, defaultValue: "未知任务")
        originalName = Self.decodeString(container, key: .originalName, defaultValue: name)
        description = Self.decodeString(container, key: .description)
        category = Self.decodeString(container, key: .category, defaultValue: "未分类")
        state = Self.decodeString(container, key: .state)
        currentProgressPercentage = Self.decodeDouble(container, key: .currentProgressPercentage)
        isHidden = Self.decodeBool(container, key: .isHidden)
        lastExecutionResult = try container.decodeIfPresent(TaskExecutionResult.self, forKey: .lastExecutionResult)
    }

    var isRunning: Bool {
        state.lowercased() == "running"
    }

    var displayProgress: Double {
        max(0.0, min(currentProgressPercentage, 100.0))
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

    private static func decodeDouble(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Double {
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? container.decode(String.self, forKey: key), let double = Double(value) {
            return double
        }
        return 0.0
    }

    private static func decodeBool(
        _ container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Bool {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return ["1", "true", "yes", "on"].contains(value.lowercased())
        }
        return false
    }
}

struct TaskExecutionResult: Decodable {
    let status: String
    let endTimeUTC: String?

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case endTimeUTC = "EndTimeUtc"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        endTimeUTC = try container.decodeIfPresent(String.self, forKey: .endTimeUTC)
    }

    var statusTitle: String {
        switch status.lowercased() {
        case "completed":
            return "成功"
        case "failed":
            return "失败"
        case "cancelled":
            return "取消"
        default:
            return status.isEmpty ? "无记录" : status
        }
    }

    var statusColorHex: String {
        switch status.lowercased() {
        case "completed":
            return "green"
        case "failed":
            return "red"
        case "cancelled":
            return "orange"
        default:
            return "gray"
        }
    }
}
