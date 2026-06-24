import ComposableArchitecture
import DopaDipKit
import FamilyControls
import Foundation

/// Focus Session 동안 선택 앱에 Shield를 적용/해제하는 클라이언트(DopaDipKit `FocusShield` 래핑).
/// `FamilyActivitySelection`은 Sendable이 아니라 effect 경계를 못 넘으므로, JSON Data로 주고받는다.
@DependencyClient
struct AppShieldClient {
    var apply: @Sendable (_ selectionData: Data) -> Void
    var clear: @Sendable () -> Void
}

extension AppShieldClient: DependencyKey {
    static let liveValue = AppShieldClient(
        apply: { data in
            guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            else { return }
            FocusShield.apply(selection)
        },
        clear: { FocusShield.clear() }
    )
    static let testValue = AppShieldClient()
    static let previewValue = AppShieldClient(apply: { _ in }, clear: {})
}

extension DependencyValues {
    var appShield: AppShieldClient {
        get { self[AppShieldClient.self] }
        set { self[AppShieldClient.self] = newValue }
    }
}
