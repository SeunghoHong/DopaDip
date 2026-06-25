import ComposableArchitecture
import SwiftUI

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
