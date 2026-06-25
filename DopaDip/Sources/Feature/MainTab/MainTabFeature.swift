import ComposableArchitecture

/// 권한 승인 후의 루트 — Home / Settings 탭.
@Reducer
struct MainTabFeature {
    @ObservableState
    struct State: Equatable {
        var home = HomeFeature.State()
        var settings = SettingsFeature.State()
        var selectedTab: Tab = .home

        enum Tab: Equatable {
            case home, settings
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case home(HomeFeature.Action)
        case settings(SettingsFeature.Action)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
        Scope(state: \.home, action: \.home) { HomeFeature() }
        Scope(state: \.settings, action: \.settings) { SettingsFeature() }
    }
}
