import ComposableArchitecture
import FamilyControls
import Foundation

/// 집중 세션 메인 화면. idle(앱선택·휠·시작) ↔ active(카운트다운·포기) 상태머신.
@Reducer
struct HomeFeature {
    /// 세션 길이 범위. 하한 1분(테스트), 상한 60분(DeviceActivity 신뢰 구간).
    static let minDuration: TimeInterval = 60
    static let maxDuration: TimeInterval = 60 * 60

    @ObservableState
    struct State: Equatable {
        var selection = FamilyActivitySelection()
        var duration: TimeInterval = 25 * 60
        var isPickerPresented = false

        /// 진행 중 세션의 시작 시각. 진행률(경과/전체) 계산에 필요.
        var sessionStartDate: Date?
        /// 진행 중 세션의 종료 시각. nil이면 idle.
        var sessionEndDate: Date?
        /// 카운트다운 계산용 현재 시각(타이머가 갱신).
        var now = Date(timeIntervalSinceReferenceDate: 0)

        var isActive: Bool { sessionEndDate != nil }

        var blockedCount: Int {
            selection.applicationTokens.count + selection.categoryTokens.count
        }

        var canStart: Bool {
            blockedCount > 0
                && duration >= HomeFeature.minDuration
                && duration <= HomeFeature.maxDuration
        }

        /// 남은 시간(초). idle이면 0.
        var remaining: TimeInterval {
            guard let end = sessionEndDate else { return 0 }
            return max(0, end.timeIntervalSince(now))
        }

        /// 진행률 0~1 (FocusRing용). 전체 길이는 start~end 실제 간격으로 — 복원 시에도 정확.
        var progress: Double {
            guard let start = sessionStartDate, let end = sessionEndDate, end > start else { return 0 }
            let total = end.timeIntervalSince(start)
            return min(1, max(0, now.timeIntervalSince(start) / total))
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case restore(startDate: Date?, endDate: Date?)
        case selectAppsTapped
        case startTapped
        case giveUpTapped
        case timerTicked(Date)
    }

    @Dependency(\.appShield) var appShield
    @Dependency(\.deviceActivity) var deviceActivity
    @Dependency(\.focusSession) var focusSession
    @Dependency(\.date) var date
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case timer }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.now = date.now
                // 백그라운드/재실행 중 살아있는 세션을 App Group에서 복원(effect 경계).
                return .run { send in
                    await send(.restore(startDate: focusSession.loadStartDate(), endDate: focusSession.loadEndDate()))
                }

            case let .restore(startDate, endDate):
                let current = date.now
                state.now = current
                if let start = startDate, let end = endDate, end > current {
                    state.sessionStartDate = start
                    state.sessionEndDate = end
                    return startTimer()
                }
                state.sessionStartDate = nil
                state.sessionEndDate = nil
                return .run { _ in focusSession.clearSession() }

            case .selectAppsTapped:
                state.isPickerPresented = true
                return .none

            case .startTapped:
                guard state.canStart, !state.isActive else { return .none }
                let start = date.now
                let end = start.addingTimeInterval(state.duration)
                state.now = start
                state.sessionStartDate = start
                state.sessionEndDate = end
                let selectionData = (try? JSONEncoder().encode(state.selection)) ?? Data()
                return .merge(
                    .run { [duration = state.duration] _ in
                        appShield.apply(selectionData)
                        _ = deviceActivity.start(start, duration)
                        focusSession.saveSession(start, end)
                    },
                    startTimer()
                )

            case .giveUpTapped:
                return endSession(&state)

            case let .timerTicked(current):
                state.now = current
                if let end = state.sessionEndDate, current >= end {
                    return endSession(&state)
                }
                return .none

            case .binding:
                return .none
            }
        }
    }

    private func startTimer() -> Effect<Action> {
        .run { send in
            for await _ in clock.timer(interval: .seconds(1)) {
                await send(.timerTicked(date.now))
            }
        }
        .cancellable(id: CancelID.timer, cancelInFlight: true)
    }

    private func endSession(_ state: inout State) -> Effect<Action> {
        state.sessionStartDate = nil
        state.sessionEndDate = nil
        return .merge(
            .cancel(id: CancelID.timer),
            .run { _ in
                appShield.clear()
                deviceActivity.stop()
                focusSession.clearSession()
            }
        )
    }
}
