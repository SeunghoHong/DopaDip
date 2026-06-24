import SwiftUI

/// DESIGN.md의 타이포 토큰. SF Pro. 히어로 숫자는 얇게 + monospacedDigit(깜빡임 방지).
enum Typo {
    static let largeTitle = Font.system(size: 34, weight: .bold)
    static let heroNumeral = Font.system(size: 80, weight: .light).monospacedDigit()
    static let sectionHeader = Font.system(size: 20, weight: .bold)
    static let rowTitle = Font.system(size: 17, weight: .regular)
    static let rowValue = Font.system(size: 17, weight: .regular)
    static let buttonLabel = Font.system(size: 17, weight: .semibold)
    static let caption = Font.system(size: 13, weight: .regular)
}
