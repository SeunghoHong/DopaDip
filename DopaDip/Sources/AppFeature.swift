import ComposableArchitecture

/// 루트 리듀서 — Screen Time 권한 상태로 권한 게이트 ↔ 메인 탭을 라우팅한다.
@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var permission: PermissionFeature.State?
        var main: MainTabFeature.State?
        /// 로딩 중 스트림으로 관찰한 최신 권한 상태. 라우팅은 Lottie 재생이 끝날 때 이 값으로 결정한다.
        var authStatus: ScreenTimeAuthStatus = .notDetermined
    }

    enum Action {
        case task
        case authStatusChanged(ScreenTimeAuthStatus)
        case loadingFinished
        case permission(PermissionFeature.Action)
        case main(MainTabFeature.Action)
    }

    @Dependency(\.screenTimeAuth) var screenTimeAuth

    private enum CancelID { case authStream }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in
                    for await status in screenTimeAuth.statusUpdates() {
                        await send(.authStatusChanged(status))
                    }
                }
                .cancellable(id: CancelID.authStream)

            // 라우팅은 미루고 최신값만 기록한다 — 결정은 .loadingFinished에서.
            case let .authStatusChanged(status):
                state.authStatus = status
                return .none

            // Lottie 1회 재생 완료 → 그 시점 확정 상태로 라우팅. 콜드런치 race는 재생시간이 흡수한다.
            case .loadingFinished:
                route(&state, isApproved: state.authStatus == .approved)
                return .cancel(id: CancelID.authStream)

            case .permission(.delegate(.authorized)):
                route(&state, isApproved: true)
                return .cancel(id: CancelID.authStream)

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
