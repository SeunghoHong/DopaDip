import ComposableArchitecture
import Foundation

/// Screen Time 권한 게이트. 미승인 시 전체 앱을 가리고 권한 허용을 요청한다.
@Reducer
struct PermissionFeature {
    @ObservableState
    struct State: Equatable {
        var isRequesting = false
        var deniedMessage: String?
    }

    enum Action {
        case requestTapped
        case requestSucceeded
        case requestFailed(String)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authorized
        }
    }

    @Dependency(\.screenTimeAuth) var screenTimeAuth

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .requestTapped:
                guard !state.isRequesting else { return .none }
                state.isRequesting = true
                state.deniedMessage = nil
                return .run { send in
                    do {
                        try await screenTimeAuth.requestAuthorization()
                        await send(.requestSucceeded)
                    } catch {
                        await send(.requestFailed(error.localizedDescription))
                    }
                }

            case .requestSucceeded:
                state.isRequesting = false
                return .send(.delegate(.authorized))

            case let .requestFailed(message):
                state.isRequesting = false
                state.deniedMessage = message
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
