import Combine
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
    /// 권한 상태 변화를 흘려보낸다. 구독 즉시 현재값을 내보내고 이후 변화마다 갱신값을 보낸다.
    /// 콜드런치 시 `AuthorizationCenter`의 비동기 복원으로 늦게 도착하는 `.approved`를 받기 위함.
    var statusUpdates: @Sendable () -> AsyncStream<ScreenTimeAuthStatus> = { .finished }
    var requestAuthorization: @Sendable () async throws -> Void
    var revokeAuthorization: @Sendable () async throws -> Void
}

extension ScreenTimeAuthClient: DependencyKey {
    static let liveValue = ScreenTimeAuthClient(
        status: {
            await MainActor.run { ScreenTimeAuthStatus(AuthorizationCenter.shared.authorizationStatus) }
        },
        statusUpdates: {
            AsyncStream { continuation in
                let task = Task { @MainActor in
                    for await status in AuthorizationCenter.shared.$authorizationStatus.values {
                        continuation.yield(ScreenTimeAuthStatus(status))
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
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
        statusUpdates: { AsyncStream { $0.yield(.approved); $0.finish() } },
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
