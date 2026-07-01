import ComposableArchitecture
import DopaDipKit
import Foundation

/// App Group의 세션 경계(시작·종료 시각)를 읽고 쓰는 클라이언트(DopaDipKit `FocusSessionStore` 래핑).
/// reducer가 직접 UserDefaults에 접근하지 않도록 effect 경계로 감싼다(순수성·테스트성).
/// 진행률 복원을 위해 start·end를 함께 저장한다 — endDate만으론 전체 길이를 알 수 없다.
@DependencyClient
struct FocusSessionClient {
    var loadStartDate: @Sendable () -> Date?
    var loadEndDate: @Sendable () -> Date?
    var saveSession: @Sendable (_ start: Date, _ end: Date) -> Void
    var clearSession: @Sendable () -> Void
}

extension FocusSessionClient: DependencyKey {
    static let liveValue = FocusSessionClient(
        loadStartDate: { FocusSessionStore.startDate },
        loadEndDate: { FocusSessionStore.endDate },
        saveSession: { start, end in
            FocusSessionStore.startDate = start
            FocusSessionStore.endDate = end
        },
        clearSession: {
            FocusSessionStore.startDate = nil
            FocusSessionStore.endDate = nil
        }
    )
    static let testValue = FocusSessionClient()
    static let previewValue = FocusSessionClient(
        loadStartDate: { nil },
        loadEndDate: { nil },
        saveSession: { _, _ in },
        clearSession: {}
    )
}

extension DependencyValues {
    var focusSession: FocusSessionClient {
        get { self[FocusSessionClient.self] }
        set { self[FocusSessionClient.self] = newValue }
    }
}
