import Foundation

enum NetworkError: LocalizedError {
    case invalidBaseURL
    case invalidResponse
    case unauthorized
    case server(message: String)
    case transport(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "服务地址无效，请检查 URL。"
        case .invalidResponse:
            return "服务响应格式异常。"
        case .unauthorized:
            return "鉴权失败，请重新登录。"
        case .server(let message):
            return message
        case .transport(let message):
            return message
        }
    }

    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }

        if let networkError = error as? NetworkError {
            switch networkError {
            case .transport(let message), .server(let message):
                return messageLooksCancelled(message)
            default:
                break
            }
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == URLError.cancelled.rawValue {
            return true
        }

        return messageLooksCancelled(error.localizedDescription)
    }

    private static func messageLooksCancelled(_ message: String) -> Bool {
        let normalized = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return normalized.contains("cancelled")
            || normalized.contains("canceled")
            || normalized == "cancel"
    }
}
