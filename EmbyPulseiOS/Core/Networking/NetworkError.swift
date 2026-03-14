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
}
