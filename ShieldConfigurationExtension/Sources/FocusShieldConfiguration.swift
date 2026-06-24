import DopaDipKit
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// 차단된 앱을 열었을 때 덮어씌우는 Shield 화면.
/// App Group의 endDate를 읽어 "집중 중 · 남은 N분"을 렌더한다(다크·미니멀).
/// ShieldConfiguration은 완전 자유 뷰가 아니라 텍스트/색/아이콘만 커스텀 가능하다.
final class FocusShieldConfiguration: ShieldConfigurationDataSource {
    private static let brandOrange = UIColor(
        red: 0xFF / 255, green: 0x9F / 255, blue: 0x0A / 255, alpha: 1
    )

    private func focusConfiguration() -> ShieldConfiguration {
        let remaining = FocusSessionStore.remaining()
        let minutes = max(1, Int((remaining / 60).rounded(.up)))
        let subtitle = remaining > 0
            ? String(localized: "\(minutes)분 남았어요")
            : String(localized: "거의 다 왔어요")

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .black,
            icon: UIImage(systemName: "moon.zzz.fill"),
            title: ShieldConfiguration.Label(text: String(localized: "집중 중"), color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: Self.brandOrange),
            primaryButtonLabel: ShieldConfiguration.Label(text: String(localized: "닫기"), color: .black),
            primaryButtonBackgroundColor: Self.brandOrange
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        focusConfiguration()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        focusConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        focusConfiguration()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        focusConfiguration()
    }
}
