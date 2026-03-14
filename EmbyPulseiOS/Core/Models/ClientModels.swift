import Foundation

struct ClientBlacklistItem: Decodable, Identifiable {
    let appName: String
    let createdAt: String?

    var id: String { appName.lowercased() }

    enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case createdAt = "created_at"
    }
}

struct ClientDeviceItem: Decodable, Identifiable {
    let id: String
    let name: String
    let appName: String
    let lastActive: String
    let lastUser: String
    let isActive: Bool
    let isBlocked: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case appName = "app_name"
        case lastActive = "last_active"
        case lastUser = "last_user"
        case isActive = "is_active"
        case isBlocked = "is_blocked"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未知设备"
        appName = try container.decodeIfPresent(String.self, forKey: .appName) ?? "未知客户端"
        lastActive = try container.decodeIfPresent(String.self, forKey: .lastActive) ?? "从未连接"
        lastUser = try container.decodeIfPresent(String.self, forKey: .lastUser) ?? "未知用户"
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? false
        isBlocked = try container.decodeIfPresent(Bool.self, forKey: .isBlocked) ?? false
    }
}

struct ClientChartSeries: Decodable {
    let labels: [String]
    let data: [Int]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        data = try container.decodeIfPresent([Int].self, forKey: .data) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case labels
        case data
    }

    var points: [ClientChartPoint] {
        var result: [ClientChartPoint] = []
        let count = min(labels.count, data.count)
        if count <= 0 { return result }
        for index in 0..<count {
            result.append(ClientChartPoint(label: labels[index], value: data[index]))
        }
        return result
    }
}

struct ClientChartsData: Decodable {
    let pie: ClientChartSeries
    let bar: ClientChartSeries

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pie = try container.decodeIfPresent(ClientChartSeries.self, forKey: .pie) ?? ClientChartSeries(labels: [], data: [])
        bar = try container.decodeIfPresent(ClientChartSeries.self, forKey: .bar) ?? ClientChartSeries(labels: [], data: [])
    }

    enum CodingKeys: String, CodingKey {
        case pie
        case bar
    }
}

struct ClientDataResponse: Decodable {
    let status: String
    let charts: ClientChartsData?
    let devices: [ClientDeviceItem]
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "error"
        charts = try container.decodeIfPresent(ClientChartsData.self, forKey: .charts)
        devices = try container.decodeIfPresent([ClientDeviceItem].self, forKey: .devices) ?? []
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case charts
        case devices
        case message
    }
}

struct ClientChartPoint: Identifiable {
    let label: String
    let value: Int

    var id: String { label }
}

private extension ClientChartSeries {
    init(labels: [String], data: [Int]) {
        self.labels = labels
        self.data = data
    }
}
