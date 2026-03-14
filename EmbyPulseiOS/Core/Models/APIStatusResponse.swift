import Foundation

func isSuccessStatus(_ status: String) -> Bool {
    let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return normalized == "success" || normalized == "ok" || normalized == "true" || normalized == "1"
}

func decodeStatusString<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K
) -> String {
    if let value = try? container.decode(String.self, forKey: key) {
        return value
    }
    if let value = try? container.decode(Bool.self, forKey: key) {
        return value ? "success" : "error"
    }
    if let value = try? container.decode(Int.self, forKey: key) {
        switch value {
        case 1:
            return "success"
        case 0:
            return "error"
        default:
            return String(value)
        }
    }
    if let value = try? container.decode(Double.self, forKey: key) {
        if value == 1 { return "success" }
        if value == 0 { return "error" }
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }
    return "error"
}

func decodeOptionalString<K: CodingKey>(
    from container: KeyedDecodingContainer<K>,
    forKey key: K
) -> String? {
    if let value = try? container.decodeIfPresent(String.self, forKey: key) {
        return value
    }
    if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
        return String(value)
    }
    if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(value)
    }
    if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
        return value ? "true" : "false"
    }
    return nil
}

struct APIStatusResponse: Decodable {
    let status: String
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}

struct APIWrappedResponse<T: Decodable>: Decodable {
    let status: String
    let data: T?
    let message: String?

    var isSuccess: Bool {
        isSuccessStatus(status)
    }

    enum CodingKeys: String, CodingKey {
        case status
        case data
        case message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = decodeStatusString(from: container, forKey: .status)
        data = try? container.decodeIfPresent(T.self, forKey: .data)
        message = decodeOptionalString(from: container, forKey: .message)
    }
}
