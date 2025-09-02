import SwiftUI

// MARK: - Placeholder Views for Full Screen Destinations

struct CameraView: View {
    var body: some View {
        PlaceholderView(
            title: "Camera",
            icon: "camera.fill",
            description: "Camera functionality will be implemented here"
        )
    }
}

struct PhotoLibraryView: View {
    var body: some View {
        PlaceholderView(
            title: "Photo Library",
            icon: "photo.on.rectangle",
            description: "Photo library functionality will be implemented here"
        )
    }
}

struct DocumentPickerView: View {
    var body: some View {
        PlaceholderView(
            title: "Document Picker",
            icon: "doc.fill",
            description: "Document picker functionality will be implemented here"
        )
    }
}

struct WebView: View {
    let url: URL
    
    var body: some View {
        PlaceholderView(
            title: "Web View",
            icon: "globe",
            description: "Web view for: \(url.absoluteString)"
        )
    }
}

struct VideoPlayerView: View {
    let url: URL
    
    var body: some View {
        PlaceholderView(
            title: "Video Player",
            icon: "play.rectangle.fill",
            description: "Video player for: \(url.absoluteString)"
        )
    }
}

struct AudioPlayerView: View {
    let url: URL
    
    var body: some View {
        PlaceholderView(
            title: "Audio Player",
            icon: "speaker.wave.3.fill",
            description: "Audio player for: \(url.absoluteString)"
        )
    }
}

struct MapView: View {
    var body: some View {
        PlaceholderView(
            title: "Map",
            icon: "map.fill",
            description: "Map functionality will be implemented here"
        )
    }
}

struct CalendarView: View {
    var body: some View {
        PlaceholderView(
            title: "Calendar",
            icon: "calendar",
            description: "Calendar functionality will be implemented here"
        )
    }
}

struct ContactsView: View {
    var body: some View {
        PlaceholderView(
            title: "Contacts",
            icon: "person.2.fill",
            description: "Contacts functionality will be implemented here"
        )
    }
}

struct HealthKitView: View {
    var body: some View {
        PlaceholderView(
            title: "Health Kit",
            icon: "heart.fill",
            description: "Health Kit integration will be implemented here"
        )
    }
}

struct ScreenTimeView: View {
    var body: some View {
        PlaceholderView(
            title: "Screen Time",
            icon: "clock.fill",
            description: "Screen Time functionality will be implemented here"
        )
    }
}

// MARK: - Generic Placeholder View
struct PlaceholderView: View {
    let title: String
    let icon: String
    let description: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.primary)
                
                // Title
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(description)
                    .font(.body)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
                
                Spacer()
                
                // Close Button
                Button("Close") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primary)
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.lg)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PlaceholderView(
        title: "Example",
        icon: "star.fill",
        description: "This is an example placeholder view"
    )
}
