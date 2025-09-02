import SwiftUI

// MARK: - Color System
struct AppColors {
    // MARK: - Primary Colors
    static let primary = Color("Primary")
    static let primaryLight = Color("PrimaryLight")
    static let primaryDark = Color("PrimaryDark")
    
    // MARK: - Secondary Colors
    static let secondary = Color("Secondary")
    static let secondaryLight = Color("SecondaryLight")
    static let secondaryDark = Color("SecondaryDark")
    
    // MARK: - Semantic Colors
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")
    static let info = Color("Info")
    
    // MARK: - Neutral Colors
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let text = Color("Text")
    static let textSecondary = Color("TextSecondary")
    static let border = Color("Border")
    static let divider = Color("Divider")
    
    // MARK: - Staking Specific Colors
    static let stakeActive = Color("StakeActive")
    static let stakePending = Color("StakePending")
    static let stakeCompleted = Color("StakeCompleted")
    static let stakeFailed = Color("StakeFailed")
    
    // MARK: - Goal Category Colors
    static let fitness = Color("Fitness")
    static let learning = Color("Learning")
    static let career = Color("Career")
    static let health = Color("Health")
    static let finance = Color("Finance")
    static let social = Color("Social")
}

// MARK: - Color Extensions
extension Color {
    static let appPrimary = AppColors.primary
    static let appSecondary = AppColors.secondary
    static let appSuccess = AppColors.success
    static let appWarning = AppColors.warning
    static let appError = AppColors.error
    static let appBackground = AppColors.background
    static let appSurface = AppColors.surface
    static let appText = AppColors.text
    static let appTextSecondary = AppColors.textSecondary
}
