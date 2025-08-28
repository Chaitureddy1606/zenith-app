//
//  MainTabView.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI

/// Main navigation container implementing a custom TabView with glassmorphic styling
/// and enhanced accessibility features following Apple Human Interface Guidelines
struct MainTabView: View {
    // MARK: - State Management
    
    /// Currently selected tab index - drives the tab selection state
    @State private var selectedTab: TabItem = .home
    
    /// Animation namespace for smooth tab transitions
    @Namespace private var tabAnimation
    
    /// Finance manager state with onAppear initialization
    @State private var financeManager: FinanceManager?
    
    // MARK: - Tab Configuration
    
    /// Tab item enumeration defining all available tabs
    enum TabItem: Int, CaseIterable {
        case home = 0
        case tasks = 1
        case notes = 2
        case finance = 3
        case habits = 4
        case calendar = 5
        
        /// SF Symbol icon name for each tab
        var iconName: String {
            switch self {
            case .home: return "house.fill"
            case .tasks: return "checkmark.circle.fill"
            case .notes: return "note.text"
            case .finance: return "banknote.fill"
            case .habits: return "flame.fill"
            case .calendar: return "calendar"
            }
        }
        
        /// Display title for each tab
        var title: String {
            switch self {
            case .home: return "Home"
            case .tasks: return "Tasks"
            case .notes: return "Notes"
            case .finance: return "Finance"
            case .habits: return "Habits"
            case .calendar: return "Calendar"
            }
        }
        
        /// Accessibility label for VoiceOver support
        var accessibilityLabel: String {
            "Switch to \(title) tab"
        }
        
        /// Accessibility hint providing additional context
        var accessibilityHint: String {
            switch self {
            case .home: return "Navigate to home screen with calendar view"
            case .tasks: return "View and manage your tasks"
            case .notes: return "Access your notes and create new ones"
            case .finance: return "Track your financial information"
            case .habits: return "Monitor and build your habits"
            case .calendar: return "View full calendar and manage events"
            }
        }
    }
    
    // MARK: - Main View Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area with tab-specific views
            if let financeManager = financeManager {
                mainContentView
                    .environmentObject(financeManager)
                
                // Custom tab bar with glassmorphic styling
                customTabBar
            } else {
                // ProgressView fallback while FinanceManager initializes
                VStack {
                    ProgressView("Initializing...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                    
                    Text("Setting up your financial dashboard")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            // Initialize FinanceManager on first appearance
            if financeManager == nil {
                financeManager = FinanceManager()
            }
        }
    }
    
    // MARK: - Main Content View
    
    /// Content view that displays the appropriate screen based on selected tab
    @ViewBuilder
    private var mainContentView: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView()
            case .tasks:
                EnhancedTasksView()
            case .notes:
                NotesView()
            case .finance:
                FinanceView()
            case .habits:
                HabitsView()
            case .calendar:
                AppleCalendarView()
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }
    
    // MARK: - Custom Tab Bar
    
    /// Glassmorphic tab bar with rounded corners and adaptive styling
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(tabBarBackground)
        .overlay(tabBarBorder)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Tab Button
    
    /// Individual tab button with scaling animation and haptic feedback
    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        Button(action: {
            selectTab(tab)
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(tab == selectedTab ? .accentColor : .secondary)
                    .scaleEffect(tab == selectedTab ? 1.2 : 1.0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0),
                        value: selectedTab
                    )
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(tab == selectedTab ? .accentColor : .secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44) // Ensures minimum tappable area per Apple HIG
        .contentShape(Rectangle()) // Expands tappable area
        .accessibilityLabel(tab.accessibilityLabel)
        .accessibilityHint(tab.accessibilityHint)
        .accessibilityAddTraits(tab == selectedTab ? .isSelected : [])
    }
    
    // MARK: - Tab Bar Styling
    
    /// Glassmorphic background with ultra thin material and adaptive overlay
    private var tabBarBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(
                        Color.primary.opacity(
                            colorScheme == .dark ? 0.05 : 0.02
                        )
                    )
            )
    }
    
    /// Adaptive border that responds to light and dark modes
    private var tabBarBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                Color.primary.opacity(
                    colorScheme == .dark ? 0.2 : 0.1
                ),
                lineWidth: 0.5
            )
    }
    
    // MARK: - Environment Values
    
    /// Color scheme for adaptive styling
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Helper Methods
    
    /// Handles tab selection with haptic feedback
    private func selectTab(_ tab: TabItem) {
        guard tab != selectedTab else { return }
        
        // Provide light haptic feedback on tab change
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Update selected tab with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
}

// MARK: - Tab Content Views

/// Home view - empty placeholder
struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "house.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Home")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Welcome to your home screen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// Habits tracking view
struct HabitsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
                
                Text("Habits")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("Build and track your daily habits")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview Provider

#Preview {
    MainTabView()
        .environmentObject(FinanceManager.mock)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    MainTabView()
        .environmentObject(FinanceManager.mock)
        .preferredColorScheme(.dark)
} 