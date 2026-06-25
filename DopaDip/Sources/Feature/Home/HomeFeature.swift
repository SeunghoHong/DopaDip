import ComposableArchitecture
import FamilyControls
import SwiftUI

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

        /// 진행률 0~1 (FocusRing용).
        var progress: Double {
            guard let end = sessionEndDate, duration > 0 else { return 0 }
            let elapsed = duration - max(0, end.timeIntervalSince(now))
            return min(1, max(0, elapsed / duration))
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case restore(endDate: Date?)
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
                    await send(.restore(endDate: focusSession.loadEndDate()))
                }

            case let .restore(endDate):
                let current = date.now
                state.now = current
                if let end = endDate, end > current {
                    state.sessionEndDate = end
                    return startTimer()
                }
                state.sessionEndDate = nil
                return .run { _ in focusSession.clearEndDate() }

            case .selectAppsTapped:
                state.isPickerPresented = true
                return .none

            case .startTapped:
                guard state.canStart, !state.isActive else { return .none }
                let start = date.now
                let end = start.addingTimeInterval(state.duration)
                state.now = start
                state.sessionEndDate = end
                let selectionData = (try? JSONEncoder().encode(state.selection)) ?? Data()
                return .merge(
                    .run { [duration = state.duration] _ in
                        appShield.apply(selectionData)
                        _ = deviceActivity.start(start, duration)
                        focusSession.saveEndDate(end)
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
        state.sessionEndDate = nil
        return .merge(
            .cancel(id: CancelID.timer),
            .run { _ in
                appShield.clear()
                deviceActivity.stop()
                focusSession.clearEndDate()
            }
        )
    }
}

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            if store.isActive {
                activeView
            } else {
                idleView
            }
        }
        .sheet(isPresented: $store.isPickerPresented) {
            NavigationStack {
                FamilyActivityPicker(selection: $store.selection)
                    .navigationTitle("차단할 앱")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("완료") { store.isPickerPresented = false }
                        }
                    }
            }
            .preferredColorScheme(.dark)
        }
        .task { store.send(.onAppear) }
    }

    // MARK: idle

    private var idleView: some View {
        VStack(spacing: 32) {
            HStack {
                Text("집중")
                    .font(Typo.largeTitle)
                    .foregroundStyle(Palette.textPrimary)
                Spacer()
            }

            blockedAppsRow

            DurationWheel(duration: $store.duration)
                .frame(height: 180)

            Spacer()

            CircularActionButton(title: "시작", isEnabled: store.canStart) {
                store.send(.startTapped)
            }

            Spacer().frame(height: 8)
        }
        .padding(24)
    }

    private var blockedAppsRow: some View {
        Button {
            store.send(.selectAppsTapped)
        } label: {
            HStack {
                Text(blockedAppsTitle)
                    .font(Typo.rowTitle)
                    .foregroundStyle(store.blockedCount > 0 ? Palette.textPrimary : Palette.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Palette.surfaceRaised, in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: active

    private var activeView: some View {
        VStack(spacing: 48) {
            Spacer()

            ZStack {
                FocusRing(progress: store.progress)
                    .frame(width: 300, height: 300)

                VStack(spacing: 8) {
                    Text("집중 중")
                        .font(Typo.caption)
                        .foregroundStyle(Palette.textSecondary)
                    Text(formatRemaining(store.remaining))
                        .font(Typo.heroNumeral)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 36)
                }
            }

            Spacer()

            CircularActionButton(
                title: "그만하기",
                fill: Palette.surfaceRaised,
                labelColor: Palette.textPrimary
            ) {
                store.send(.giveUpTapped)
            }

            Spacer().frame(height: 8)
        }
        .padding(24)
    }

    private var blockedAppsTitle: LocalizedStringKey {
        store.blockedCount > 0 ? "차단 앱 \(store.blockedCount)개" : "차단할 앱 고르기"
    }

    private func formatRemaining(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, seconds)
            : String(format: "%02d:%02d", minutes, seconds)
    }
}
