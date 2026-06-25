import ComposableArchitecture

/// 설정 탭 — Screen Time 권한 상태·재요청·해제, 앱 정보.
@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var authStatus: ScreenTimeAuthStatus = .notDetermined
        var isWorking = false
    }

    enum Action {
        case onAppear
        case statusLoaded(ScreenTimeAuthStatus)
        case requestTapped
        case revokeTapped
        case finished(ScreenTimeAuthStatus)
    }

    @Dependency(\.screenTimeAuth) var screenTimeAuth

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in await send(.statusLoaded(await screenTimeAuth.status())) }

            case let .statusLoaded(status):
                state.authStatus = status
                return .none

            case .requestTapped:
                guard !state.isWorking else { return .none }
                state.isWorking = true
                return .run { send in
                    try? await screenTimeAuth.requestAuthorization()
                    await send(.finished(await screenTimeAuth.status()))
                }

            case .revokeTapped:
                guard !state.isWorking else { return .none }
                state.isWorking = true
                return .run { send in
                    try? await screenTimeAuth.revokeAuthorization()
                    await send(.finished(await screenTimeAuth.status()))
                }

            case let .finished(status):
                state.isWorking = false
                state.authStatus = status
                return .none
            }
        }
    }
}
