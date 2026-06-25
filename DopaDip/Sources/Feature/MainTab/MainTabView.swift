import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
    @Bindable var store: StoreOf<MainTabFeature>

    var body: some View {
        TabView(selection: $store.selectedTab) {
            HomeView(store: store.scope(state: \.home, action: \.home))
                .tabItem { Label("집중", systemImage: "timer") }
                .tag(MainTabFeature.State.Tab.home)

            SettingsView(store: store.scope(state: \.settings, action: \.settings))
                .tabItem { Label("설정", systemImage: "gearshape") }
                .tag(MainTabFeature.State.Tab.settings)
        }
        .tint(Palette.accentBrand)
    }
}
