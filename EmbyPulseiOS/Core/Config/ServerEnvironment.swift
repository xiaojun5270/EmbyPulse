import Foundation

@MainActor
final class ServerEnvironment: ObservableObject {
    static let shared = ServerEnvironment()

    @Published var baseURL: String {
        didSet {
            defaults.set(baseURL, forKey: key)
        }
    }

    private let defaults: UserDefaults
    private let key = "embypulse.server.base_url"

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.baseURL = defaults.string(forKey: key) ?? ""
    }
}
