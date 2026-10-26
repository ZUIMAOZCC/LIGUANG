import Foundation
import UIKit

// MARK: - 画幅
enum CaptureRatio: String, CaseIterable, Identifiable, Codable {
    case r3x2, r4x3, r1x1, r16x9
    var id: String { rawValue }

    /// 宽高比（宽/高）
    var value: CGFloat {
        switch self {
        case .r3x2: return 3.0 / 2.0
        case .r4x3: return 4.0 / 3.0
        case .r1x1: return 1.0
        case .r16x9: return 16.0 / 9.0
        }
    }

    var label: String {
        switch self {
        case .r3x2: return "3:2"
        case .r4x3: return "4:3"
        case .r1x1: return "1:1"
        case .r16x9: return "16:9"
        }
    }

    /// GR 原生为 3:2
    var isGRNative: Bool { self == .r3x2 }
}
