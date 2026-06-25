import ComposableArchitecture
import SwiftUI

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
                                Text(permissionButtonTitle)
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
        case .approved: String(localized: "허용됨")
        case .denied: String(localized: "거부됨")
        case .notDetermined: String(localized: "미설정")
        }
    }

    private var permissionButtonTitle: LocalizedStringKey {
        store.authStatus == .approved ? "권한 해제하기" : "권한 허용하기"
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
        _ title: LocalizedStringKey,
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
