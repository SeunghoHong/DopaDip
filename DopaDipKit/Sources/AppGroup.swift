import Foundation

/// App과 익스텐션이 공유하는 App Group 식별자 및 컨테이너 접근점.
public enum AppGroup {
    public static let identifier = "group.com.dopadip"

    public static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}
