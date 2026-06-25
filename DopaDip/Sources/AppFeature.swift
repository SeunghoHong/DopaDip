import ComposableArchitecture

/// 루트 리듀서 — Screen Time 권한 상태로 권한 게이트 ↔ 메인 탭을 라우팅한다.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var permission: PermissionFeature.State?
        var main: MainTabFeature.State?
    }

    enum Action {
        case task
        case authStatusLoaded(isApproved: Bool)
        case permission(PermissionFeature.Action)
        case main(MainTabFeature.Action)
    }

    @Dependency(\.screenTimeAuth) var screenTimeAuth

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    let approved = await screenTimeAuth.status() == .approved
                    await send(.authStatusLoaded(isApproved: approved))
                }

            case let .authStatusLoaded(isApproved):
                route(&state, isApproved: isApproved)
                return .none

            case .permission(.delegate(.authorized)):
                route(&state, isApproved: true)
                return .none

            case .permission, .main:
                return .none
            }
        }
        .ifLet(\.permission, action: \.permission) { PermissionFeature() }
        .ifLet(\.main, action: \.main) { MainTabFeature() }
    }

    private func route(_ state: inout State, isApproved: Bool) {
        if isApproved {
            if state.main == nil { state.main = .init() }
            state.permission = nil
        } else {
            if state.permission == nil { state.permission = .init() }
            state.main = nil
        }
    }
}
