import SwiftUI

/// DESIGN.md의 컬러 토큰. iOS Clock 앱 다크 테마 기반. 액센트는 셋만(오렌지·그린·그레이).
enum Palette {
    static let canvas = Color.black
    static let surfaceRaised = Color(red: 0x1C / 255, green: 0x1C / 255, blue: 0x1E / 255)
    static let surfaceRaisedHigh = Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255)
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0x8E / 255, green: 0x8E / 255, blue: 0x93 / 255)
    static let textTertiary = Color(red: 0x48 / 255, green: 0x48 / 255, blue: 0x4A / 255)
    static let accentBrand = Color(red: 0xFF / 255, green: 0x9F / 255, blue: 0x0A / 255)
    static let actionStart = Color(red: 0x34 / 255, green: 0xC7 / 255, blue: 0x59 / 255)
    static let ringTrack = Color.white.opacity(0.12)
}
