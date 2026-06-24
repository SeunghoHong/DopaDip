import ComposableArchitecture
import SwiftUI

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

struct PermissionView: View {
    let store: StoreOf<PermissionFeature>

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                Text("집중을 시작해 볼까요?")
                    .font(Typo.largeTitle)
                    .foregroundStyle(Palette.textPrimary)

                Text("집중하는 동안 고른 앱을 차단하려면 Screen Time 권한이 필요해요.\n권한은 기기 안에서만 쓰여요.")
                    .font(Typo.rowTitle)
                    .foregroundStyle(Palette.textSecondary)

                if let message = store.deniedMessage {
                    Text(message)
                        .font(Typo.caption)
                        .foregroundStyle(Palette.accentBrand)
                }

                Spacer()

                Button {
                    store.send(.requestTapped)
                } label: {
                    HStack {
                        if store.isRequesting {
                            ProgressView().tint(.black)
                        } else {
                            Text("권한 허용하기")
                                .font(Typo.buttonLabel)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Palette.actionStart, in: .capsule)
                    .foregroundStyle(.black)
                }
                .disabled(store.isRequesting)
            }
            .padding(24)
        }
    }
}
