import ComposableArchitecture
import XCTest

@testable import DopaDip

final class HomeFeatureTests: XCTestCase {
    private func noopShield() -> AppShieldClient {
        AppShieldClient(apply: { _ in }, clear: {})
    }

    private func noopActivity() -> DeviceActivityClient {
        DeviceActivityClient(start: { _, _ in true }, stop: {})
    }

    private func session(start: Date? = nil, end: Date? = nil) -> FocusSessionClient {
        FocusSessionClient(
            loadStartDate: { start },
            loadEndDate: { end },
            saveSession: { _, _ in },
            clearSession: {}
        )
    }

    /// 차단 앱을 안 골랐으면 시작이 무시된다(canStart false).
    @MainActor
    func testStartIgnoredWhenNothingSelected() async {
        let store = TestStore(initialState: HomeFeature.State(duration: 1500)) {
            HomeFeature()
        }
        await store.send(.startTapped)
    }

    /// active 세션에서 포기하면 idle로 돌아가고 shield/스케줄을 해제한다.
    @MainActor
    func testGiveUpEndsActiveSession() async {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let end = now.addingTimeInterval(1500)
        let store = TestStore(initialState: HomeFeature.State(sessionEndDate: end, now: now)) {
            HomeFeature()
        } withDependencies: {
            $0.appShield = noopShield()
            $0.deviceActivity = noopActivity()
            $0.focusSession = session()
        }

        await store.send(.giveUpTapped) {
            $0.sessionEndDate = nil
        }
    }

    /// 타이머가 종료 시각에 도달하면 세션이 자동 종료된다.
    @MainActor
    func testTimerEndsSessionWhenReachingEnd() async {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let end = now.addingTimeInterval(60)
        let store = TestStore(initialState: HomeFeature.State(sessionEndDate: end, now: now)) {
            HomeFeature()
        } withDependencies: {
            $0.appShield = noopShield()
            $0.deviceActivity = noopActivity()
            $0.focusSession = session()
        }

        await store.send(.timerTicked(end)) {
            $0.now = end
            $0.sessionEndDate = nil
        }
    }

    /// 종료 전 틱은 now만 갱신하고 세션을 유지한다.
    @MainActor
    func testTimerTickBeforeEndKeepsSession() async {
        let now = Date(timeIntervalSinceReferenceDate: 0)
        let end = now.addingTimeInterval(120)
        let mid = now.addingTimeInterval(60)
        let store = TestStore(initialState: HomeFeature.State(sessionEndDate: end, now: now)) {
            HomeFeature()
        }

        await store.send(.timerTicked(mid)) {
            $0.now = mid
        }
    }

    /// 진행 중 세션이 없으면 onAppear 복원은 idle을 유지한다.
    @MainActor
    func testRestoreNoActiveSession() async {
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.focusSession = session()
        }

        await store.send(.onAppear) { $0.now = now }
        await store.receive(\.restore)
    }

    /// 살아있는 세션이 App Group에 있으면 onAppear가 active로 복원한다.
    @MainActor
    func testRestoreActiveSession() async {
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        let start = now.addingTimeInterval(-300)
        let end = now.addingTimeInterval(600)
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.continuousClock = TestClock()
            $0.appShield = noopShield()
            $0.deviceActivity = noopActivity()
            $0.focusSession = session(start: start, end: end)
        }

        await store.send(.onAppear) { $0.now = now }
        await store.receive(\.restore) {
            $0.now = now
            $0.sessionStartDate = start
            $0.sessionEndDate = end
        }
        // 복원이 타이머를 시작했으므로 정리한다.
        await store.send(.giveUpTapped) {
            $0.sessionStartDate = nil
            $0.sessionEndDate = nil
        }
    }

    /// 복원 시 진행률은 실제 start~end 간격 기준 — 기본 duration(25분)이 아니라.
    /// (라벨은 맞고 링만 어긋나던 버그 회귀 방지: 600초 세션 절반 경과 → 0.5)
    @MainActor
    func testProgressAfterRestoreUsesActualSpan() async {
        let now = Date(timeIntervalSinceReferenceDate: 1000)
        let start = now.addingTimeInterval(-300)
        let end = now.addingTimeInterval(300)
        let store = TestStore(initialState: HomeFeature.State()) {
            HomeFeature()
        } withDependencies: {
            $0.date = .constant(now)
            $0.continuousClock = TestClock()
            $0.appShield = noopShield()
            $0.deviceActivity = noopActivity()
            $0.focusSession = session(start: start, end: end)
        }

        await store.send(.onAppear) { $0.now = now }
        await store.receive(\.restore) {
            $0.now = now
            $0.sessionStartDate = start
            $0.sessionEndDate = end
        }
        XCTAssertEqual(store.state.progress, 0.5, accuracy: 0.001)

        await store.send(.giveUpTapped) {
            $0.sessionStartDate = nil
            $0.sessionEndDate = nil
        }
    }
}
