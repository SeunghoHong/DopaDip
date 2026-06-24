import ComposableArchitecture
import DopaDipKit
import Foundation

/// App Group의 세션 종료 시각(endDate)을 읽고 쓰는 클라이언트(DopaDipKit `FocusSessionStore` 래핑).
/// reducer가 직접 UserDefaults에 접근하지 않도록 effect 경계로 감싼다(순수성·테스트성).
@DependencyClient
struct FocusSessionClient {
    var loadEndDate: @Sendable () -> Date?
    var saveEndDate: @Sendable (Date) -> Void
    var clearEndDate: @Sendable () -> Void
}

extension FocusSessionClient: DependencyKey {
    static let liveValue = FocusSessionClient(
        loadEndDate: { FocusSessionStore.endDate },
        saveEndDate: { FocusSessionStore.endDate = $0 },
        clearEndDate: { FocusSessionStore.endDate = nil }
    )
    static let testValue = FocusSessionClient()
    static let previewValue = FocusSessionClient(
        loadEndDate: { nil },
        saveEndDate: { _ in },
        clearEndDate: {}
    )
}

extension DependencyValues {
    var focusSession: FocusSessionClient {
        get { self[FocusSessionClient.self] }
        set { self[FocusSessionClient.self] = newValue }
    }
}
