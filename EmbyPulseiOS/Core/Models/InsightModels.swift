import Foundation

struct InsightQualityResponse: Decodable {
    let status: String
    let data: InsightQualityStats?
    let message: String?

    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}

struct InsightQualityStats: Decodable {
    let totalCount: Int
    let scanTime: String?
    let movies: InsightMovieGroups

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case scanTime = "scan_time_str"
        case movies
    }
}

struct InsightMovieGroups: Decodable {
    let fourK: [InsightMovieItem]
    let fullHD: [InsightMovieItem]
    let hd: [InsightMovieItem]
    let sd: [InsightMovieItem]
    let hevc: [InsightMovieItem]
    let h264: [InsightMovieItem]
    let av1: [InsightMovieItem]
    let otherCodec: [InsightMovieItem]
    let dolbyVision: [InsightMovieItem]
    let hdr10: [InsightMovieItem]
    let sdr: [InsightMovieItem]

    enum CodingKeys: String, CodingKey {
        case fourK = "4k"
        case fullHD = "1080p"
        case hd = "720p"
        case sd
        case hevc
        case h264
        case av1
        case otherCodec = "other_codec"
        case dolbyVision = "dolby_vision"
        case hdr10
        case sdr
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fourK = try container.decodeIfPresent([InsightMovieItem].self, forKey: .fourK) ?? []
        fullHD = try container.decodeIfPresent([InsightMovieItem].self, forKey: .fullHD) ?? []
        hd = try container.decodeIfPresent([InsightMovieItem].self, forKey: .hd) ?? []
        sd = try container.decodeIfPresent([InsightMovieItem].self, forKey: .sd) ?? []
        hevc = try container.decodeIfPresent([InsightMovieItem].self, forKey: .hevc) ?? []
        h264 = try container.decodeIfPresent([InsightMovieItem].self, forKey: .h264) ?? []
        av1 = try container.decodeIfPresent([InsightMovieItem].self, forKey: .av1) ?? []
        otherCodec = try container.decodeIfPresent([InsightMovieItem].self, forKey: .otherCodec) ?? []
        dolbyVision = try container.decodeIfPresent([InsightMovieItem].self, forKey: .dolbyVision) ?? []
        hdr10 = try container.decodeIfPresent([InsightMovieItem].self, forKey: .hdr10) ?? []
        sdr = try container.decodeIfPresent([InsightMovieItem].self, forKey: .sdr) ?? []
    }

    func items(for category: InsightCategory) -> [InsightMovieItem] {
        switch category {
        case .fourK:
            return fourK
        case .fullHD:
            return fullHD
        case .hd:
            return hd
        case .sd:
            return sd
        case .dolbyVision:
            return dolbyVision
        case .hdr10:
            return hdr10
        case .sdr:
            return sdr
        case .hevc:
            return hevc
        case .h264:
            return h264
        case .av1:
            return av1
        case .otherCodec:
            return otherCodec
        }
    }

    func count(for category: InsightCategory) -> Int {
        items(for: category).count
    }
}

struct InsightMovieItem: Decodable, Identifiable, Hashable {
    let id: String
    let name: String
    let year: String
    let resolution: String
    let path: String

    enum CodingKeys: String, CodingKey {
        case id = "Id"
        case name = "Name"
        case year = "Year"
        case resolution = "Resolution"
        case path = "Path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未知影片"
        resolution = try container.decodeIfPresent(String.self, forKey: .resolution) ?? "未知"
        path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        if let yearString = try? container.decode(String.self, forKey: .year) {
            year = yearString
        } else if let yearInt = try? container.decode(Int.self, forKey: .year) {
            year = String(yearInt)
        } else {
            year = ""
        }
    }
}

struct InsightIgnoreItem: Decodable, Identifiable, Hashable {
    let itemID: String
    let itemName: String
    let ignoredAt: String?

    var id: String { itemID }

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case itemName = "item_name"
        case ignoredAt = "ignored_at"
    }
}

enum InsightCategory: String, CaseIterable, Identifiable {
    case fourK
    case fullHD
    case hd
    case sd
    case dolbyVision
    case hdr10
    case sdr
    case hevc
    case h264
    case av1
    case otherCodec

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourK:
            return "4K"
        case .fullHD:
            return "1080P"
        case .hd:
            return "720P"
        case .sd:
            return "SD"
        case .dolbyVision:
            return "杜比视界"
        case .hdr10:
            return "HDR10"
        case .sdr:
            return "SDR"
        case .hevc:
            return "HEVC"
        case .h264:
            return "H264"
        case .av1:
            return "AV1"
        case .otherCodec:
            return "其他编码"
        }
    }
}
