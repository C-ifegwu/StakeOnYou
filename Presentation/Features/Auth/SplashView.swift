import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    @StateObject private var viewModel = SplashViewModel()
    @Environment(\.router) private var router
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: AppSpacing.lg) {
                    // Logo Animation
                    ZStack {
                        Circle()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(viewModel.logoScale)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.logoScale)
                        
                        Image(systemName: "target")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(AppColors.primary)
                            .scaleEffect(viewModel.logoScale)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: viewModel.logoScale)
                    }
                    
                    // App Title
                    Text("StakeOnYou")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.textPrimary)
                        .opacity(viewModel.titleOpacity)
                        .animation(.easeIn(duration: 1.0), value: viewModel.titleOpacity)
                    
                    // Subtitle
                    Text("Achieve your goals with accountability")
                        .font(.title3)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(viewModel.subtitleOpacity)
                        .animation(.easeIn(duration: 1.0).delay(0.5), value: viewModel.subtitleOpacity)
                }
                
                Spacer()
                
                // Loading Indicator
                if viewModel.isLoading {
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primary))
                            .scaleEffect(1.2)
                        
                        Text("Setting up your experience...")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .opacity(viewModel.loadingTextOpacity)
                            .animation(.easeIn(duration: 0.5).delay(1.0), value: viewModel.loadingTextOpacity)
                    }
                }
                
                Spacer()
                
                // Version Info
                VStack(spacing: AppSpacing.xs) {
                    Text("Version \(viewModel.appVersion)")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("© 2024 StakeOnYou. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
                .opacity(viewModel.footerOpacity)
                .animation(.easeIn(duration: 0.5).delay(1.5), value: viewModel.footerOpacity)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .onAppear {
            viewModel.startSplashAnimation()
        }
        .onChange(of: viewModel.shouldNavigateToAuth) { shouldNavigate in
            if shouldNavigate {
                navigateToAuth()
            }
        }
        .onChange(of: viewModel.shouldNavigateToMain) { shouldNavigate in
            if shouldNavigate {
                navigateToMain()
            }
        }
    }
    
    // MARK: - Navigation Methods
    private func navigateToAuth() {
        // Navigate to authentication flow
        router.presentFullScreenCover(.auth)
    }
    
    private func navigateToMain() {
        // Navigate to main app
        router.navigateToRoot()
    }
}

// MARK: - Splash View Model
@MainActor
class SplashViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var shouldNavigateToAuth = false
    @Published var shouldNavigateToMain = false
    
    // Animation States
    @Published var logoScale: CGFloat = 0.8
    @Published var titleOpacity: Double = 0.0
    @Published var subtitleOpacity: Double = 0.0
    @Published var loadingTextOpacity: Double = 0.0
    @Published var footerOpacity: Double = 0.0
    
    // MARK: - Properties
    private let authService: AuthenticationService
    private let keychainService: KeychainService
    
    // MARK: - Computed Properties
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Initialization
    init(
        authService: AuthenticationService = DIContainer.shared.resolve(AuthenticationService.self),
        keychainService: KeychainService = DIContainer.shared.resolve(KeychainService.self)
    ) {
        self.authService = authService
        self.keychainService = keychainService
    }
    
    // MARK: - Public Methods
    func startSplashAnimation() {
        // Start loading
        isLoading = true
        
        // Animate logo and title
        animateLogoAndTitle()
        
        // Check authentication state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.checkAuthenticationState()
        }
    }
    
    // MARK: - Private Methods
    private func animateLogoAndTitle() {
        // Logo animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            logoScale = 1.0
        }
        
        // Title animation
        withAnimation(.easeIn(duration: 1.0)) {
            titleOpacity = 1.0
        }
        
        // Subtitle animation
        withAnimation(.easeIn(duration: 1.0).delay(0.5)) {
            subtitleOpacity = 1.0
        }
        
        // Loading text animation
        withAnimation(.easeIn(duration: 0.5).delay(1.0)) {
            loadingTextOpacity = 1.0
        }
        
        // Footer animation
        withAnimation(.easeIn(duration: 0.5).delay(1.5)) {
            footerOpacity = 1.0
        }
    }
    
    private func checkAuthenticationState() {
        Task {
            // Check if user has valid authentication
            if await checkIfUserIsAuthenticated() {
                // User is authenticated, navigate to main app
                shouldNavigateToMain = true
            } else {
                // User is not authenticated, navigate to auth flow
                shouldNavigateToAuth = true
            }
        }
    }
    
    private func checkIfUserIsAuthenticated() async -> Bool {
        do {
            // Check if we have stored authentication tokens
            let hasAccessToken = try keychainService.exists(for: KeychainConstants.accessTokenKey)
            let hasRefreshToken = try keychainService.exists(for: KeychainConstants.refreshTokenKey)
            
            guard hasAccessToken && hasRefreshToken else {
                return false
            }
            
            // Check if tokens are still valid
            if let sessionExpiry = try keychainService.loadString(for: KeychainConstants.sessionExpiryKey),
               let expiryDate = ISO8601DateFormatter().date(from: sessionExpiry) {
                
                // Check if session has expired (with buffer)
                let bufferTime = Date().addingTimeInterval(KeychainConstants.tokenExpiryBuffer)
                if expiryDate > bufferTime {
                    // Session is still valid
                    return true
                } else {
                    // Session has expired, try to refresh
                    return await refreshAuthenticationSession()
                }
            }
            
            // No expiry date, assume valid for now
            return true
            
        } catch {
            logError("Failed to check authentication state: \(error)", category: "SplashView")
            return false
        }
    }
    
    private func refreshAuthenticationSession() async -> Bool {
        do {
            // Try to refresh the session
            try await authService.refreshSession()
            return true
        } catch {
            logError("Failed to refresh authentication session: \(error)", category: "SplashView")
            
            // Clear invalid tokens
            try? keychainService.delete(for: KeychainConstants.accessTokenKey)
            try? keychainService.delete(for: KeychainConstants.refreshTokenKey)
            try? keychainService.delete(for: KeychainConstants.sessionExpiryKey)
            
            return false
        }
    }
}

// MARK: - Splash View Extensions
extension SplashView {
    // MARK: - Loading States
    var isInitializing: Bool {
        viewModel.isLoading && !viewModel.shouldNavigateToAuth && !viewModel.shouldNavigateToMain
    }
    
    var isCheckingAuth: Bool {
        viewModel.isLoading && (viewModel.shouldNavigateToAuth || viewModel.shouldNavigateToMain)
    }
}

// MARK: - Preview
#Preview {
    SplashView()
        .environment(\.router, AppRouter())
}
