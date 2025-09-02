import SwiftUI

// MARK: - Typography System
struct AppTypography {
    // MARK: - Font Sizes
    static let displayLarge: CGFloat = 57
    static let displayMedium: CGFloat = 45
    static let displaySmall: CGFloat = 36
    
    static let headlineLarge: CGFloat = 32
    static let headlineMedium: CGFloat = 28
    static let headlineSmall: CGFloat = 24
    
    static let titleLarge: CGFloat = 22
    static let titleMedium: CGFloat = 16
    static let titleSmall: CGFloat = 14
    
    static let bodyLarge: CGFloat = 16
    static let bodyMedium: CGFloat = 14
    static let bodySmall: CGFloat = 12
    
    static let labelLarge: CGFloat = 14
    static let labelMedium: CGFloat = 12
    static let labelSmall: CGFloat = 11
    
    // MARK: - Font Weights
    static let regular = Font.Weight.regular
    static let medium = Font.Weight.medium
    static let semibold = Font.Weight.semibold
    static let bold = Font.Weight.bold
    
    // MARK: - Font Styles
    static func displayLarge(_ weight: Font.Weight = .regular) -> Font {
        .system(size: displayLarge, weight: weight, design: .default)
    }
    
    static func displayMedium(_ weight: Font.Weight = .regular) -> Font {
        .system(size: displayMedium, weight: weight, design: .default)
    }
    
    static func displaySmall(_ weight: Font.Weight = .regular) -> Font {
        .system(size: displaySmall, weight: weight, design: .default)
    }
    
    static func headlineLarge(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: headlineLarge, weight: weight, design: .default)
    }
    
    static func headlineMedium(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: headlineMedium, weight: weight, design: .default)
    }
    
    static func headlineSmall(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: headlineSmall, weight: weight, design: .default)
    }
    
    static func titleLarge(_ weight: Font.Weight = .medium) -> Font {
        .system(size: titleLarge, weight: weight, design: .default)
    }
    
    static func titleMedium(_ weight: Font.Weight = .medium) -> Font {
        .system(size: titleMedium, weight: weight, design: .default)
    }
    
    static func titleSmall(_ weight: Font.Weight = .medium) -> Font {
        .system(size: titleSmall, weight: weight, design: .default)
    }
    
    static func bodyLarge(_ weight: Font.Weight = .regular) -> Font {
        .system(size: bodyLarge, weight: weight, design: .default)
    }
    
    static func bodyMedium(_ weight: Font.Weight = .regular) -> Font {
        .system(size: bodyMedium, weight: weight, design: .default)
    }
    
    static func bodySmall(_ weight: Font.Weight = .regular) -> Font {
        .system(size: bodySmall, weight: weight, design: .default)
    }
    
    static func labelLarge(_ weight: Font.Weight = .medium) -> Font {
        .system(size: labelLarge, weight: weight, design: .default)
    }
    
    static func labelMedium(_ weight: Font.Weight = .medium) -> Font {
        .system(size: labelMedium, weight: weight, design: .default)
    }
    
    static func labelSmall(_ weight: Font.Weight = .medium) -> Font {
        .system(size: labelSmall, weight: weight, design: .default)
    }
}

// MARK: - Text Style Extensions
extension Text {
    func displayLarge(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.displayLarge(weight))
    }
    
    func displayMedium(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.displayMedium(weight))
    }
    
    func displaySmall(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.displaySmall(weight))
    }
    
    func headlineLarge(_ weight: Font.Weight = .semibold) -> Text {
        self.font(AppTypography.headlineLarge(weight))
    }
    
    func headlineMedium(_ weight: Font.Weight = .semibold) -> Text {
        self.font(AppTypography.headlineMedium(weight))
    }
    
    func headlineSmall(_ weight: Font.Weight = .semibold) -> Text {
        self.font(AppTypography.headlineSmall(weight))
    }
    
    func titleLarge(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.titleLarge(weight))
    }
    
    func titleMedium(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.titleMedium(weight))
    }
    
    func titleSmall(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.titleSmall(weight))
    }
    
    func bodyLarge(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.bodyLarge(weight))
    }
    
    func bodyMedium(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.bodyMedium(weight))
    }
    
    func bodySmall(_ weight: Font.Weight = .regular) -> Text {
        self.font(AppTypography.bodySmall(weight))
    }
    
    func labelLarge(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.labelLarge(weight))
    }
    
    func labelMedium(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.labelMedium(weight))
    }
    
    func labelSmall(_ weight: Font.Weight = .medium) -> Text {
        self.font(AppTypography.labelSmall(weight))
    }
}
