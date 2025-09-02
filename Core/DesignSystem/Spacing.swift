import SwiftUI

// MARK: - Spacing System
struct AppSpacing {
    // MARK: - Base Spacing Units
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
    
    // MARK: - Component Spacing
    static let buttonPadding: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 32
    static let listItemSpacing: CGFloat = 12
    
    // MARK: - Layout Spacing
    static let screenPadding: CGFloat = 20
    static let tabBarHeight: CGFloat = 83
    static let navigationBarHeight: CGFloat = 44
    static let statusBarHeight: CGFloat = 47
    
    // MARK: - Border Radius
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusXLarge: CGFloat = 24
    
    // MARK: - Shadow
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Float = 0.1
    static let shadowOffset = CGSize(width: 0, height: 2)
}

// MARK: - Spacing Extensions
extension View {
    func padding(_ spacing: CGFloat) -> some View {
        self.padding(.all, spacing)
    }
    
    func paddingHorizontal(_ spacing: CGFloat) -> some View {
        self.padding(.horizontal, spacing)
    }
    
    func paddingVertical(_ spacing: CGFloat) -> some View {
        self.padding(.vertical, spacing)
    }
    
    func paddingTop(_ spacing: CGFloat) -> some View {
        self.padding(.top, spacing)
    }
    
    func paddingBottom(_ spacing: CGFloat) -> some View {
        self.padding(.bottom, spacing)
    }
    
    func paddingLeading(_ spacing: CGFloat) -> some View {
        self.padding(.leading, spacing)
    }
    
    func paddingTrailing(_ spacing: CGFloat) -> some View {
        self.padding(.trailing, spacing)
    }
}

// MARK: - Spacing Modifiers
extension View {
    func spacing(_ spacing: CGFloat) -> some View {
        self.padding(spacing)
    }
    
    func spacingHorizontal(_ spacing: CGFloat) -> some View {
        self.padding(.horizontal, spacing)
    }
    
    func spacingVertical(_ spacing: CGFloat) -> some View {
        self.padding(.vertical, spacing)
    }
}

// MARK: - Layout Helpers
struct SpacerView: View {
    let height: CGFloat
    
    init(_ height: CGFloat) {
        self.height = height
    }
    
    var body: some View {
        Spacer()
            .frame(height: height)
    }
}

struct HorizontalSpacer: View {
    let width: CGFloat
    
    init(_ width: CGFloat) {
        self.width = width
    }
    
    var body: some View {
        Spacer()
            .frame(width: width)
    }
}
