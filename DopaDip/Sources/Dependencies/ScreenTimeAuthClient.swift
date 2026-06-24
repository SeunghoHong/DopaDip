import ComposableArchitecture
import FamilyControls

/// FamilyControls `AuthorizationStatus`의 Sendable 미러(@Sendable 클로저 경계를 넘기 위함).
enum ScreenTimeAuthStatus: Equatable, Sendable {
    case notDetermined, denied, approved

    init(_ status: AuthorizationStatus) {
        switch status {
        case .approved: self = .approved
        case .denied: self = .denied
        default: self = .notDetermined
        }
    }
}

/// FamilyControls `AuthorizationCenter`를 감싸는 얇은 클라이언트.
/// Screen Time은 시뮬레이터에서 동작하지 않으므로 시뮬레이터·프리뷰는 목으로 돌린다.
@DependencyClient
struct ScreenTimeAuthClient {
    var status: @Sendable () async -> ScreenTimeAuthStatus = { .notDetermined }
    var requestAuthorization: @Sendable () async throws -> Void
    var revokeAuthorization: @Sendable () async throws -> Void
}

extension ScreenTimeAuthClient: DependencyKey {
    static let liveValue = ScreenTimeAuthClient(
        status: {
            await MainActor.run { ScreenTimeAuthStatus(AuthorizationCenter.shared.authorizationStatus) }
        },
        requestAuthorization: {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        },
        revokeAuthorization: {
            try await withCheckedThrowingContinuation { continuation in
                AuthorizationCenter.shared.revokeAuthorization { result in
                    continuation.resume(with: result)
                }
            }
        }
    )

    static let testValue = ScreenTimeAuthClient()

    static let previewValue = ScreenTimeAuthClient(
        status: { .approved },
        requestAuthorization: {},
        revokeAuthorization: {}
    )
}

extension DependencyValues {
    var screenTimeAuth: ScreenTimeAuthClient {
        get { self[ScreenTimeAuthClient.self] }
        set { self[ScreenTimeAuthClient.self] = newValue }
    }
}
