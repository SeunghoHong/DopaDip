import ComposableArchitecture
import FamilyControls
import SwiftUI

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
