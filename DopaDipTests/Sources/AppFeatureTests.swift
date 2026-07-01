import ComposableArchitecture
import XCTest

@testable import DopaDip

final class AppFeatureTests: XCTestCase {
    private func authStream(_ value: ScreenTimeAuthStatus) -> ScreenTimeAuthClient {
        var client = ScreenTimeAuthClient.testValue
        client.statusUpdates = { AsyncStream { $0.yield(value); $0.finish() } }
        return client
    }

    /// 승인된 유저: 스트림이 approved를 흘리고, Lottie 재생이 끝나면 main으로 라우팅한다.
    @MainActor
    func testApprovedRoutesToMainAfterLoading() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.screenTimeAuth = authStream(.approved)
        }

        await store.send(.task)
        await store.receive(\.authStatusChanged, .approved) { $0.authStatus = .approved }
        await store.send(.loadingFinished) { $0.main = MainTabFeature.State() }
    }

    /// 진짜 첫 실행(notDetermined): 재생이 끝나면 permission으로 라우팅한다.
    @MainActor
    func testNotDeterminedRoutesToPermissionAfterLoading() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.screenTimeAuth = authStream(.notDetermined)
        }

        await store.send(.task)
        await store.receive(\.authStatusChanged)  // .notDetermined → 상태 변화 없음
        await store.send(.loadingFinished) { $0.permission = PermissionFeature.State() }
    }

    /// 거부된 유저: 재생이 끝나면 permission으로 라우팅한다.
    @MainActor
    func testDeniedRoutesToPermissionAfterLoading() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        } withDependencies: {
            $0.screenTimeAuth = authStream(.denied)
        }

        await store.send(.task)
        await store.receive(\.authStatusChanged, .denied) { $0.authStatus = .denied }
        await store.send(.loadingFinished) { $0.permission = PermissionFeature.State() }
    }

    /// permission 화면에서 승인하면 즉시 main으로 라우팅한다(로딩 게이트와 무관).
    @MainActor
    func testPermissionAuthorizedRoutesToMain() async {
        let store = TestStore(initialState: AppFeature.State(permission: PermissionFeature.State())) {
            AppFeature()
        } withDependencies: {
            $0.screenTimeAuth = authStream(.notDetermined)
        }

        await store.send(.permission(.delegate(.authorized))) {
            $0.main = MainTabFeature.State()
            $0.permission = nil
        }
    }
}
