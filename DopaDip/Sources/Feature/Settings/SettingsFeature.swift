import ComposableArchitecture
import SwiftUI

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

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Text("설정")
                            .font(Typo.largeTitle)
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                    }

                    card {
                        row("Screen Time 권한") {
                            Text(statusText)
                                .font(Typo.rowValue)
                                .foregroundStyle(statusColor)
                        }
                        Divider().overlay(Palette.canvas)
                        Button {
                            store.send(store.authStatus == .approved ? .revokeTapped : .requestTapped)
                        } label: {
                            HStack {
                                Text(store.authStatus == .approved ? "권한 해제" : "권한 허용")
                                    .font(Typo.rowTitle)
                                    .foregroundStyle(Palette.accentBrand)
                                Spacer()
                                if store.isWorking { ProgressView().tint(Palette.textSecondary) }
                            }
                            .frame(minHeight: 52)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isWorking)
                    }

                    card {
                        row("버전") {
                            Text(appVersion)
                                .font(Typo.rowValue)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(24)
            }
        }
        .task { store.send(.onAppear) }
    }

    private var statusText: String {
        switch store.authStatus {
        case .approved: "승인됨"
        case .denied: "거부됨"
        case .notDetermined: "미설정"
        }
    }

    private var statusColor: Color {
        switch store.authStatus {
        case .approved: Palette.actionStart
        case .denied: Palette.accentBrand
        case .notDetermined: Palette.textSecondary
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 16)
            .background(Palette.surfaceRaised, in: .rect(cornerRadius: 14))
    }

    private func row<Trailing: View>(
        _ title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack {
            Text(title)
                .font(Typo.rowTitle)
                .foregroundStyle(Palette.textPrimary)
            Spacer()
            trailing()
        }
        .frame(minHeight: 52)
    }
}
