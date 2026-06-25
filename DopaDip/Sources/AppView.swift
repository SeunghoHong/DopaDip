import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            if let permissionStore = store.scope(state: \.permission, action: \.permission) {
                PermissionView(store: permissionStore)
            } else if let mainStore = store.scope(state: \.main, action: \.main) {
                MainTabView(store: mainStore)
            } else {
                Palette.canvas.ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .task { store.send(.task) }
    }
}
