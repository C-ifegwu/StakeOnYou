import SwiftUI

// MARK: - Root View
struct RootView: View {
    @StateObject private var router = AppRouter()
    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var selectedTab = 0
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .onAppear {
                        // Show splash for minimum duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showSplash = false
                            }
                        }
                    }
            } else if appEnvironment.isInitialized {
                mainTabView
            } else {
                loadingView
            }
        }
        .environmentObject(router)
        .fullScreenCover(item: $router.presentedFullScreenCover) { destination in
            switch destination {
            case .auth:
                AuthView()
            case .camera:
                CameraView()
            case .photoLibrary:
                PhotoLibraryView()
            case .documentPicker:
                DocumentPickerView()
            case .webView(let url):
                WebView(url: url)
            case .videoPlayer(let url):
                VideoPlayerView(url: url)
            case .audioPlayer(let url):
                AudioPlayerView(url: url)
            case .map:
                MapView()
            case .calendar:
                CalendarView()
            case .contacts:
                ContactsView()
            case .healthKit:
                HealthKitView()
            case .screenTime:
                ScreenTimeView()
            }
        }
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Goals")
                }
                .tag(1)
            
            GroupsView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Groups")
                }
                .tag(2)
            
            CorporateView()
                .tabItem {
                    Image(systemName: "building.2.fill")
                    Text("Corporate")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.appPrimary)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: selectedTab) { newValue in
            handleTabChange(newValue)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Setting up StakeOnYou...")
                .font(AppTypography.bodyLarge())
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
    
    // MARK: - Private Methods
    private func setupTabBarAppearance() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func handleTabChange(_ newTab: Int) {
        // Track tab navigation for analytics
        let tabNames = ["Home", "Goals", "Groups", "Corporate", "Profile"]
        if newTab < tabNames.count {
            AnalyticsService.shared.trackEvent(
                AnalyticsEvent(
                    name: "tab_navigation",
                    properties: ["tab": tabNames[newTab]]
                )
            )
        }
        
        // Handle any tab-specific logic
        switch newTab {
        case 0: // Home
            logInfo("User navigated to Home tab", category: "Navigation")
        case 1: // Goals
            logInfo("User navigated to Goals tab", category: "Navigation")
        case 2: // Groups
            logInfo("User navigated to Groups tab", category: "Navigation")
        case 3: // Corporate
            logInfo("User navigated to Corporate tab", category: "Navigation")
        case 4: // Profile
            logInfo("User navigated to Profile tab", category: "Navigation")
        default:
            break
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Welcome Section
                    welcomeSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Active Goals
                    activeGoalsSection
                    
                    // Recent Activity
                    recentActivitySection
                }
                .padding(AppSpacing.screenPadding)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshData()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Welcome back!")
                .font(AppTypography.headlineLarge())
                .foregroundColor(.appText)
            
            Text("Ready to achieve your goals today?")
                .font(AppTypography.bodyLarge())
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.cardPadding)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Actions")
                .font(AppTypography.titleLarge())
                .foregroundColor(.appText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.md) {
                QuickActionButton(
                    title: "Create Goal",
                    icon: "plus.circle.fill",
                    color: .appPrimary
                ) {
                    // TODO: Navigate to create goal
                }
                
                QuickActionButton(
                    title: "Start Stake",
                    icon: "dollarsign.circle.fill",
                    color: .appSuccess
                ) {
                    // TODO: Navigate to start stake
                }
                
                QuickActionButton(
                    title: "Join Group",
                    icon: "person.3.fill",
                    color: .appInfo
                ) {
                    // TODO: Navigate to join group
                }
                
                QuickActionButton(
                    title: "View Progress",
                    icon: "chart.bar.fill",
                    color: .appWarning
                ) {
                    // TODO: Navigate to progress view
                }
            }
        }
    }
    
    // MARK: - Active Goals Section
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Active Goals")
                    .font(AppTypography.titleLarge())
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to all goals
                }
                .font(AppTypography.bodyMedium())
                .foregroundColor(.appPrimary)
            }
            
            if viewModel.activeGoals.isEmpty {
                emptyGoalsView
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.activeGoals.prefix(3)) { goal in
                        GoalCardView(goal: goal)
                    }
                }
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Activity")
                    .font(AppTypography.titleLarge())
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button("View All") {
                    // TODO: Navigate to activity view
                }
                .font(AppTypography.bodyMedium())
                .foregroundColor(.appPrimary)
            }
            
            if viewModel.recentActivity.isEmpty {
                emptyActivityView
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.recentActivity.prefix(5)) { activity in
                        ActivityRowView(activity: activity)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty States
    private var emptyGoalsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.appTextSecondary)
            
            Text("No active goals")
                .font(AppTypography.titleMedium())
                .foregroundColor(.appText)
            
            Text("Create your first goal to get started")
                .font(AppTypography.bodyMedium())
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("Create Goal") {
                // TODO: Navigate to create goal
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundColor(.appTextSecondary)
            
            Text("No recent activity")
                .font(AppTypography.titleMedium())
                .foregroundColor(.appText)
            
            Text("Your activity will appear here as you use the app")
                .font(AppTypography.bodyMedium())
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTypography.bodyMedium())
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(Color.appSurface)
            .cornerRadius(AppSpacing.cornerRadiusMedium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Goal Card View
struct GoalCardView: View {
    let goal: Goal
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: goal.category.iconName)
                    .foregroundColor(Color(goal.category.color))
                
                Text(goal.title)
                    .font(AppTypography.titleMedium())
                    .foregroundColor(.appText)
                    .lineLimit(2)
                
                Spacer()
                
                Text(goal.status.displayName)
                    .font(AppTypography.labelSmall())
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(statusColor)
                    .cornerRadius(AppSpacing.cornerRadiusSmall)
            }
            
            Text(goal.description)
                .font(AppTypography.bodySmall())
                .foregroundColor(.appTextSecondary)
                .lineLimit(2)
            
            HStack {
                Text("\(goal.daysRemaining) days left")
                    .font(AppTypography.labelMedium())
                    .foregroundColor(.appTextSecondary)
                
                Spacer()
                
                ProgressView(value: goal.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .appPrimary))
                    .frame(width: 60)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.cornerRadiusMedium)
    }
    
    private var statusColor: Color {
        switch goal.status {
        case .active: return .appSuccess
        case .paused: return .appWarning
        case .completed: return .appInfo
        case .failed: return .appError
        default: return .appSecondary
        }
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    let activity: String // Placeholder for now
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 8, height: 8)
            
            Text(activity)
                .font(AppTypography.bodyMedium())
                .foregroundColor(.appText)
            
            Spacer()
            
            Text("2h ago") // Placeholder
                .font(AppTypography.labelSmall())
                .foregroundColor(.appTextSecondary)
        }
        .padding(AppSpacing.sm)
        .background(Color.appSurface)
        .cornerRadius(AppSpacing.cornerRadiusSmall)
    }
}

// MARK: - Home View Model
class HomeViewModel: ObservableObject {
    @Published var activeGoals: [Goal] = []
    @Published var recentActivity: [String] = []
    @Published var isLoading = false
    
    func loadData() async {
        await MainActor.run {
            isLoading = true
        }
        
        // TODO: Load actual data from repositories
        await loadActiveGoals()
        await loadRecentActivity()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func refreshData() async {
        await loadData()
    }
    
    private func loadActiveGoals() async {
        // TODO: Load active goals from repository
        await MainActor.run {
            activeGoals = [] // Placeholder
        }
    }
    
    private func loadRecentActivity() async {
        // TODO: Load recent activity from repository
        await MainActor.run {
            recentActivity = [] // Placeholder
        }
    }
}

// MARK: - Placeholder Views
struct GoalsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Goals View")
                    .font(AppTypography.headlineLarge())
                Text("Coming soon...")
                    .font(AppTypography.bodyLarge())
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Goals")
        }
    }
}

struct GroupsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Groups View")
                    .font(AppTypography.headlineLarge())
                Text("Coming soon...")
                    .font(AppTypography.bodyLarge())
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Groups")
        }
    }
}

struct CorporateView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Corporate View")
                    .font(AppTypography.headlineLarge())
                Text("Coming soon...")
                    .font(AppTypography.bodyLarge())
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Corporate")
        }
    }
}

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile View")
                    .font(AppTypography.headlineLarge())
                Text("Coming soon...")
                    .font(AppTypography.bodyLarge())
                    .foregroundColor(.appTextSecondary)
            }
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AppEnvironment())
    }
}
