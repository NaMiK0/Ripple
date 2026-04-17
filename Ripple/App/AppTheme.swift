import UIKit

enum AppTheme {

    static func apply() {
        // MARK: - Navigation Bar

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .rippleCard
        navAppearance.shadowColor = UIColor.rippleTextSecondary.withAlphaComponent(0.15)
        navAppearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.rippleTextPrimary
        ]
        navAppearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor.rippleTextPrimary
        ]
        UINavigationBar.appearance().standardAppearance   = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance    = navAppearance
        UINavigationBar.appearance().tintColor = .ripplePrimary
        UINavigationBar.appearance().prefersLargeTitles   = true

        // MARK: - Global Tint

        UIView.appearance(whenContainedInInstancesOf: [UIWindow.self])
            .tintColor = .ripplePrimary

        // MARK: - TableView

        UITableView.appearance().backgroundColor = .rippleBackground
        UITableView.appearance().separatorColor  = UIColor.rippleTextSecondary.withAlphaComponent(0.1)
    }
}
