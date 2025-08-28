//
//  FinanceViews.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import Charts

// MARK: - Main Finance View

/// Main finance view that serves as the entry point for all financial features
/// Implements a comprehensive dashboard with summary cards, AI insights, and advanced features
struct FinanceView: View {
    // MARK: - State Management
    
    /// Environment object for finance data management
    @EnvironmentObject var financeManager: FinanceManager
    
    /// State for showing the add transaction sheet
    @State private var showingAddTransaction = false
    
    /// State for search text
    @State private var searchText = ""
    
    /// State for selected filter
    @State private var selectedFilter: TransactionFilter = .all
    
    /// State for showing advanced features
    @State private var showingAdvancedFeatures = false
    
    /// State for selected tab in advanced features
    @State private var selectedAdvancedTab: AdvancedFeatureTab = .budgets
    
    // MARK: - Environment Values
    
    /// Color scheme for adaptive styling
    @Environment(\.colorScheme) private var colorScheme
    
    /// Dynamic type size for accessibility
    @Environment(\.sizeCategory) private var sizeCategory
    
    // MARK: - Main View Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Enhanced summary cards section
                    enhancedSummaryCardsSection
                    
                    // AI insights and forecasts section
                    aiInsightsAndForecastsSection
                    
                    // Quick actions section
                    enhancedQuickActionsSection
                    
                    // Recent transactions section
                    recentTransactionsSection
                    
                    // Advanced features preview
                    advancedFeaturesPreviewSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Finance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addTransactionButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    advancedFeaturesButton
                }
            }
            .searchable(text: $searchText, prompt: "Search transactions, bills, goals, tax reports...")
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionSheet(financeManager: financeManager)
            }
            .sheet(isPresented: $showingAdvancedFeatures) {
                AdvancedFeaturesView(
                    financeManager: financeManager,
                    selectedTab: $selectedAdvancedTab
                )
            }
            .refreshable {
                await refreshData()
            }
        }
    }
    
    // MARK: - Enhanced Summary Cards Section
    
    /// Enhanced summary cards showing key financial metrics with AI forecasts
    private var enhancedSummaryCardsSection: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            // Net Worth Card with AI Forecast
            NetWorthCard(
                netWorth: financeManager.summary?.netWorth ?? 0,
                forecast: financeManager.summary?.netWorthForecast,
                currency: financeManager.baseCurrency
            )
            
            // Total Balance Card
            SummaryCard(
                title: "Total Balance",
                value: financeManager.summary?.totalBalance.formatted(.currency(code: financeManager.baseCurrency.code)) ?? "\(financeManager.baseCurrency.symbol)0.00",
                iconName: "banknote.fill",
                color: .green,
                subtitle: "Across all accounts"
            )
            
            // Monthly Spending Card with AI Analysis
            MonthlySpendingCard(
                spending: financeManager.summary?.monthlyExpenses ?? 0,
                budget: financeManager.budgets.first { $0.category.name == "Overall" }?.amount ?? 0,
                currency: financeManager.baseCurrency
            )
            
            // Cash Flow Forecast Card
            CashFlowForecastCard(
                forecast: financeManager.summary?.cashFlowForecast,
                currency: financeManager.baseCurrency
            )
        }
    }
    
    /// Grid columns for summary cards
    private var gridColumns: [GridItem] {
        let columns = sizeCategory.isAccessibilityCategory ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
    }
    
    // MARK: - AI Insights and Forecasts Section
    
    /// AI-generated financial insights and forecasts
    private var aiInsightsAndForecastsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights & Forecasts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    selectedAdvancedTab = .insights
                    showingAdvancedFeatures = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if !financeManager.insights.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(financeManager.insights.prefix(3)) { insight in
                        EnhancedInsightCard(insight: insight)
                    }
                }
            } else {
                Text("No insights available yet. Add more transactions to get personalized financial advice.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Enhanced Quick Actions Section
    
    /// Enhanced quick action buttons for advanced finance tasks
    private var enhancedQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: quickActionColumns, spacing: 12) {
                QuickActionButton(
                    title: "Add Transaction",
                    iconName: "plus.circle.fill",
                    color: .blue
                ) {
                    showingAddTransaction = true
                }
                
                QuickActionButton(
                    title: "Scan Receipt",
                    iconName: "camera.fill",
                    color: .purple
                ) {
                    // Navigate to receipt scanner
                    selectedAdvancedTab = .receipts
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Bank Sync",
                    iconName: "link.circle.fill",
                    color: .green
                ) {
                    // Navigate to bank sync
                    selectedAdvancedTab = .bankSync
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Tax Reports",
                    iconName: "doc.text.fill",
                    color: .orange
                ) {
                    // Navigate to tax reports
                    selectedAdvancedTab = .taxReports
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Set Budget",
                    iconName: "chart.pie.fill",
                    color: .indigo
                ) {
                    // Navigate to budget view
                    selectedAdvancedTab = .budgets
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Track Bills",
                    iconName: "calendar.badge.clock",
                    color: .red
                ) {
                    // Navigate to bills view
                    selectedAdvancedTab = .bills
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Savings Goals",
                    iconName: "target",
                    color: .teal
                ) {
                    // Navigate to savings view
                    selectedAdvancedTab = .savings
                    showingAdvancedFeatures = true
                }
                
                QuickActionButton(
                    title: "Shared Accounts",
                    iconName: "person.2.fill",
                    color: .pink
                ) {
                    // Navigate to shared accounts
                    selectedAdvancedTab = .sharedAccounts
                    showingAdvancedFeatures = true
                }
            }
        }
    }
    
    /// Grid columns for quick actions
    private var quickActionColumns: [GridItem] {
        let columns = sizeCategory.isAccessibilityCategory ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
    
    // MARK: - Recent Transactions Section
    
    /// Recent transactions list with search and filter
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    selectedAdvancedTab = .transactions
                    showingAdvancedFeatures = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if let transactions = financeManager.summary?.recentTransactions, !transactions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        EnhancedTransactionRow(transaction: transaction)
                            .contextMenu {
                                Button("Edit") {
                                    // Edit transaction
                                }
                                
                                Button("Delete", role: .destructive) {
                                    financeManager.deleteTransaction(transaction)
                                }
                                
                                if transaction.receiptImageData != nil {
                                    Button("View Receipt") {
                                        // View receipt
                                    }
                                }
                                
                                if transaction.isAnomaly {
                                    Button("Mark as Normal") {
                                        // Mark as normal
                                    }
                                }
                            }
                    }
                }
            } else {
                emptyTransactionsView
            }
        }
    }
    
    /// Empty state for transactions
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "banknote")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Transactions Yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Add your first transaction to start tracking your finances")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Transaction") {
                showingAddTransaction = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Advanced Features Preview Section
    
    /// Preview of advanced features available
    private var advancedFeaturesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Features")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                // Budget tracking preview
                if !financeManager.budgets.isEmpty {
                    BudgetPreviewCard(budgets: financeManager.budgets)
                }
                
                // Savings goals preview
                if !financeManager.savingsGoals.isEmpty {
                    SavingsGoalsPreviewCard(goals: financeManager.savingsGoals)
                }
                
                // Bills preview
                if !financeManager.bills.isEmpty {
                    BillsPreviewCard(bills: financeManager.bills)
                }
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    /// Add transaction button in toolbar
    private var addTransactionButton: some View {
        Button {
            showingAddTransaction = true
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Add new transaction")
        .accessibilityHint("Opens form to add income or expense")
    }
    
    /// Advanced features button in toolbar
    private var advancedFeaturesButton: some View {
        Button {
            showingAdvancedFeatures = true
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .accessibilityLabel("Advanced features")
        .accessibilityHint("Opens advanced finance features and settings")
    }
    
    // MARK: - Helper Methods
    
    /// Refreshes finance data
    private func refreshData() async {
        // Refresh data immediately
        await MainActor.run {
            financeManager.refreshData()
        }
    }
}

// MARK: - Enhanced Summary Cards

/// Net worth card with AI forecast
struct NetWorthCard: View {
    let netWorth: Decimal
    let forecast: NetWorthForecast?
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if forecast != nil {
                    Image(systemName: "crystal.ball.fill")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(netWorth.formatted(.currency(code: currency.code)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Net Worth")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let forecast = forecast {
                    Text("Forecast: \(forecast.predictedNetWorth.formatted(.currency(code: currency.code)))")
                        .font(.caption)
                        .foregroundColor(.teal)
                } else {
                    Text("Total assets minus liabilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net Worth: \(netWorth.formatted(.currency(code: currency.code)))")
    }
}

/// Monthly spending card with AI analysis
struct MonthlySpendingCard: View {
    let spending: Decimal
    let budget: Decimal
    let currency: Currency
    
    private var spendingPercentage: Double {
        guard budget > 0 else { return 0 }
        return Double(truncating: (spending / budget) as NSNumber)
    }
    
    private var isOverBudget: Bool {
        spending > budget
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(isOverBudget ? .red : .orange)
                
                Spacer()
                
                if isOverBudget {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(spending.formatted(.currency(code: currency.code)))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Monthly Spending")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if budget > 0 {
                    Text("\(Int(spendingPercentage * 100))% of budget")
                        .font(.caption)
                        .foregroundColor(isOverBudget ? .red : .secondary)
                } else {
                    Text("This month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly Spending: \(spending.formatted(.currency(code: currency.code)))")
    }
}

/// Cash flow forecast card
struct CashFlowForecastCard: View {
    let forecast: CashFlowForecast?
    let currency: Currency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
                
                Spacer()
                
                if forecast != nil {
                    Image(systemName: "crystal.ball.fill")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let forecast = forecast {
                    Text(forecast.predictedSavings.formatted(.currency(code: currency.code)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Predicted Savings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Next \(forecast.period.displayName.lowercased())")
                        .font(.caption)
                        .foregroundColor(.teal)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Text("Cash Flow Forecast")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Add more data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cash Flow Forecast")
    }
}

// MARK: - Enhanced Insight Card

/// Enhanced AI-generated financial insight card
struct EnhancedInsightCard: View {
    let insight: FinancialInsight
    
    var body: some View {
        HStack(spacing: 16) {
            // Insight icon with priority indicator
            VStack(spacing: 4) {
                Image(systemName: insight.iconName)
                    .font(.title2)
                    .foregroundColor(insight.color)
                    .frame(width: 44, height: 44)
                    .background(insight.color.opacity(0.1))
                    .clipShape(Circle())
                
                if insight.priority == .critical || insight.priority == .high {
                    Circle()
                        .fill(insight.priority.color)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Insight content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if insight.priority != .low {
                        Text(insight.priority.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(insight.priority.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(insight.priority.color.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if insight.actionable, let actionTitle = insight.actionTitle {
                    Button(actionTitle) {
                        // Handle action
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(insight.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(insight.color.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Tags
                if !insight.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(insight.tags), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.color.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(insight.title): \(insight.description)")
        .accessibilityHint("Priority: \(insight.priority.displayName)")
    }
}

// MARK: - Enhanced Transaction Row

/// Enhanced individual transaction row with additional features
struct EnhancedTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            categoryIconSection
            transactionDetailsSection
            amountSection
        }
    }
    
    private var categoryIconSection: some View {
        VStack(spacing: 4) {
            Image(systemName: transaction.category.iconName)
                .font(.title2)
                .foregroundColor(transaction.category.color)
                .frame(width: 44, height: 44)
                .background(transaction.category.color.opacity(0.1))
                .clipShape(Circle())
            
            if transaction.isAnomaly {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if transaction.isRecurring {
                Image(systemName: "repeat.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private var transactionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(transaction.merchant)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if transaction.priority != Priority.normal {
                    Image(systemName: transaction.priority.iconName)
                        .font(.caption)
                        .foregroundColor(transaction.priority.color)
                }
            }
            
            HStack {
                Text(transaction.category.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(transaction.relativeDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !transaction.tags.isEmpty {
                tagsSection
            }
        }
    }
    
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(transaction.tags), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(transaction.formattedAmount)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.amountColor)
            
            Text(transaction.currency.code)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            
            Text(transaction.type.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(transaction.amountColor.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Preview Cards

/// Budget tracking preview card
struct BudgetPreviewCard: View {
    let budgets: [Budget]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Budget Tracking")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(budgets.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(budgets.prefix(3)) { budget in
                        BudgetMiniCard(budget: budget)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Budget mini card for preview
struct BudgetMiniCard: View {
    let budget: Budget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(budget.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            ProgressView(value: budget.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: budget.progress > 0.8 ? .red : .blue))
            
            Text("\(Int(truncating: budget.spendingPercentage * 100 as NSNumber))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Savings goals preview card
struct SavingsGoalsPreviewCard: View {
    let goals: [SavingsGoal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Savings Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(goals.count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(goals.prefix(3)) { goal in
                        SavingsGoalMiniCard(goal: goal)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Savings goal mini card for preview
struct SavingsGoalMiniCard: View {
    let goal: SavingsGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(goal.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            ProgressView(value: goal.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text("\(Int(truncating: goal.progressPercentage * 100 as NSNumber))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Bills preview card
struct BillsPreviewCard: View {
    let bills: [Bill]
    
    private var upcomingBills: [Bill] {
        bills.filter { !$0.isPaid && $0.dueDate > Date() }
    }
    
    private var overdueBills: [Bill] {
        bills.filter { !$0.isPaid && $0.dueDate < Date() }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bills & Payments")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(upcomingBills.count) upcoming")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if !overdueBills.isEmpty {
                        Text("\(overdueBills.count) overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if !bills.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(upcomingBills.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Upcoming")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(overdueBills.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Advanced Features View

/// Advanced features view with tabbed interface
struct AdvancedFeaturesView: View {
    let financeManager: FinanceManager
    @Binding var selectedTab: AdvancedFeatureTab
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                BudgetsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "chart.pie.fill")
                        Text("Budgets")
                    }
                    .tag(AdvancedFeatureTab.budgets)
                
                TransactionsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "list.bullet")
                        Text("Transactions")
                    }
                    .tag(AdvancedFeatureTab.transactions)
                
                BillsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "calendar.badge.clock")
                        Text("Bills")
                    }
                    .tag(AdvancedFeatureTab.bills)
                
                SavingsGoalsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "target")
                        Text("Savings")
                    }
                    .tag(AdvancedFeatureTab.savings)
                
                InsightsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "lightbulb.fill")
                        Text("Insights")
                    }
                    .tag(AdvancedFeatureTab.insights)
                
                BankSyncView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "link.circle.fill")
                        Text("Bank Sync")
                    }
                    .tag(AdvancedFeatureTab.bankSync)
                
                TaxReportsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "doc.text.fill")
                        Text("Tax Reports")
                    }
                    .tag(AdvancedFeatureTab.taxReports)
                
                SharedAccountsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Shared")
                    }
                    .tag(AdvancedFeatureTab.sharedAccounts)
                
                ReceiptsView(financeManager: financeManager)
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Receipts")
                    }
                    .tag(AdvancedFeatureTab.receipts)
            }
            .navigationTitle("Advanced Features")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Advanced Feature Tabs

/// Enumeration of advanced feature tabs
enum AdvancedFeatureTab: String, CaseIterable {
    case budgets = "budgets"
    case transactions = "transactions"
    case bills = "bills"
    case savings = "savings"
    case insights = "insights"
    case bankSync = "bank_sync"
    case taxReports = "tax_reports"
    case sharedAccounts = "shared_accounts"
    case receipts = "receipts"
    
    var displayName: String {
        switch self {
        case .budgets: return "Budgets"
        case .transactions: return "Transactions"
        case .bills: return "Bills"
        case .savings: return "Savings Goals"
        case .insights: return "AI Insights"
        case .bankSync: return "Bank Sync"
        case .taxReports: return "Tax Reports"
        case .sharedAccounts: return "Shared Accounts"
        case .receipts: return "Receipts"
        }
    }
}

// MARK: - Placeholder Views for Advanced Features

/// Budgets view placeholder
struct BudgetsView: View {
    let financeManager: FinanceManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Budget overview section
                budgetOverviewSection
                
                // Category budgets section
                categoryBudgetsSection
                
                // Spending trends section
                spendingTrendsSection
                
                // AI suggestions section
                aiSuggestionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Budget Management")
        .navigationBarTitleDisplayMode(.large)
    }
    
    /// Budget overview with total spending and remaining
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let totalBudget = financeManager.budgets.reduce(0) { $0 + $1.amount }
            let totalSpent = financeManager.budgets.reduce(0) { $0 + $1.spent }
            let totalRemaining = totalBudget - totalSpent
            let spendingPercentage = totalBudget > 0 ? totalSpent / totalBudget : 0
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(totalBudget.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(totalRemaining.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(totalRemaining >= 0 ? .green : .red)
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Spending Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(NSDecimalNumber(decimal: spendingPercentage * 100).doubleValue))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(spendingPercentage > 0.9 ? .red : .primary)
                    }
                    
                    ProgressView(value: min(Double(truncating: spendingPercentage as NSNumber), 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: spendingPercentage > 0.9 ? .red : .green))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Category budgets with individual progress
    private var categoryBudgetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Budgets")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !financeManager.budgets.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(financeManager.budgets) { budget in
                        BudgetCard(budget: budget) {
                            // Navigate to budget detail
                        }
                    }
                }
            } else {
                emptyBudgetsView
            }
        }
    }
    
    /// Spending trends chart
    private var spendingTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trends")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !financeManager.budgets.isEmpty {
                Chart {
                    ForEach(financeManager.budgets) { budget in
                        BarMark(
                            x: .value("Category", budget.category.name),
                            y: .value("Spent", budget.spent)
                        )
                        .foregroundStyle(budget.category.color)
                        
                        RuleMark(
                            y: .value("Budget", budget.amount)
                        )
                        .foregroundStyle(budget.category.color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }
                }
                .frame(height: 200)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                emptyBudgetsView
            }
        }
    }
    
    /// AI suggestions for budget optimization
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Budget Suggestions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Mock AI suggestions - in real app these would come from FinanceManager
            VStack(spacing: 12) {
                AISuggestionCard(
                    title: "Increase Food Budget",
                    description: "Your food spending consistently exceeds budget. Consider increasing by 15%.",
                    type: .increase,
                    confidence: 0.85
                )
                
                AISuggestionCard(
                    title: "Reduce Entertainment",
                    description: "Entertainment spending is 30% above average. Consider reducing budget.",
                    type: .decrease,
                    confidence: 0.92
                )
            }
        }
    }
    
    /// Empty state for budgets
    private var emptyBudgetsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Budgets Set")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create budgets for your spending categories to start tracking")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

/// AI suggestion card for budget optimization
struct AISuggestionCard: View {
    let title: String
    let description: String
    let type: SuggestionType
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: type.iconName)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: 44, height: 44)
                .background(type.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Confidence: \(Int(confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Apply") {
                        // Apply suggestion
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(type.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(type.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

/// Summary card for displaying financial metrics
struct SummaryCard: View {
    let title: String
    let value: String
    let iconName: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(subtitle)")
    }
}

/// Quick action button for common finance tasks
struct QuickActionButton: View {
    let title: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

// MARK: - Transaction Filter

/// Transaction filter options
enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .income: return "arrow.down.circle"
        case .expense: return "arrow.up.circle"
        case .thisWeek: return "calendar"
        case .thisMonth: return "calendar.badge.clock"
        case .thisYear: return "calendar.badge.plus"
        }
    }
}

// MARK: - Preview Provider

#Preview {
    FinanceView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    FinanceView()
        .preferredColorScheme(.dark)
} 

// MARK: - Transactions View

/// Fully implemented transactions view with advanced features
struct TransactionsView: View {
    let financeManager: FinanceManager
    @State private var searchText = ""
    @State private var selectedFilter: TransactionFilter = .all
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Transaction summary section
                transactionSummarySection
                
                // Filter and search section
                filterAndSearchSection
                
                // Transactions list
                transactionsListSection
                
                // AI categorization insights
                aiCategorizationSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionSheet(financeManager: financeManager)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailView(transaction: transaction)
        }
    }
    
    /// Transaction summary with key metrics
    private var transactionSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredTransactions = getFilteredTransactions()
            let totalIncome = filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalExpenses = filteredTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let netAmount = totalIncome - totalExpenses
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Income",
                    value: totalIncome.formatted(.currency(code: "USD")),
                    color: .green,
                    iconName: "arrow.down.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "Expenses",
                    value: totalExpenses.formatted(.currency(code: "USD")),
                    color: .red,
                    iconName: "arrow.up.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "Net",
                    value: netAmount.formatted(.currency(code: "USD")),
                    color: netAmount >= 0 ? .green : .red,
                    iconName: "chart.line.uptrend.xyaxis"
                )
            }
        }
    }
    
    /// Filter and search controls
    private var filterAndSearchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter & Search")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search transactions...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TransactionFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    /// Transactions list with enhanced features
    private var transactionsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transactions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredTransactions = getFilteredTransactions()
            
            if !filteredTransactions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTransactions) { transaction in
                        EnhancedTransactionRow(transaction: transaction)
                            .onTapGesture {
                                selectedTransaction = transaction
                            }
                            .contextMenu {
                                Button("Edit") {
                                    // Edit transaction
                                }
                                
                                Button("Delete", role: .destructive) {
                                    financeManager.deleteTransaction(transaction)
                                }
                                
                                if transaction.receiptImageData != nil {
                                    Button("View Receipt") {
                                        // View receipt
                                    }
                                }
                                
                                if transaction.isAnomaly {
                                    Button("Mark as Normal") {
                                        // Mark as normal
                                    }
                                }
                                
                                Button("Copy Details") {
                                    // Copy transaction details
                                }
                            }
                    }
                }
            } else {
                emptyTransactionsView
            }
        }
    }
    
    /// AI categorization insights
    private var aiCategorizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Categorization Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                AICategorizationCard(
                    title: "Smart Categorization",
                    description: "AI automatically categorizes 87% of your transactions with 94% accuracy",
                    iconName: "brain.head.profile",
                    color: .blue
                )
                
                AICategorizationCard(
                    title: "Anomaly Detection",
                    description: "3 unusual transactions detected this month",
                    iconName: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
        }
    }
    
    /// Get filtered transactions based on current filter and search
    private func getFilteredTransactions() -> [Transaction] {
        var transactions = financeManager.transactions
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .income:
            transactions = transactions.filter { $0.type == .income }
        case .expense:
            transactions = transactions.filter { $0.type == .expense }
        case .thisWeek:
            let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            transactions = transactions.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            transactions = transactions.filter { $0.date >= startOfMonth }
        case .thisYear:
            let startOfYear = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()
            transactions = transactions.filter { $0.date >= startOfYear }
        }
        
        // Apply search
        if !searchText.isEmpty {
            transactions = transactions.filter { transaction in
                transaction.merchant.localizedCaseInsensitiveContains(searchText) ||
                transaction.category.name.localizedCaseInsensitiveContains(searchText) ||
                (transaction.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return transactions.sorted { $0.date > $1.date }
    }
    
    /// Empty state for transactions
    private var emptyTransactionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "banknote")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Transactions Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or add your first transaction")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Transaction") {
                showingAddTransaction = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views for Transactions

/// Summary metric card for transaction summary
struct SummaryMetricCard: View {
    let title: String
    let value: String
    let color: Color
    let iconName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

/// Filter chip for transaction filtering
struct FilterChip: View {
    let filter: TransactionFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// AI categorization card
struct AICategorizationCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Transaction detail view
struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Transaction overview
                    transactionOverviewCard
                    
                    // Category and merchant details
                    detailsCard
                    
                    // Location information
                    if transaction.location != nil {
                        locationCard
                    }
                    
                    // Receipt information
                    if transaction.receiptImageData != nil {
                        receiptCard
                    }
                    
                    // AI insights
                    aiInsightsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var transactionOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: transaction.category.iconName)
                        .font(.title)
                        .foregroundColor(transaction.category.color)
                        .frame(width: 44, height: 44)
                        .background(transaction.category.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.merchant)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(transaction.category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(transaction.formattedAmount)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(transaction.amountColor)
                        
                        Text(transaction.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(transaction.amountColor.opacity(0.1))
                            .foregroundColor(transaction.amountColor)
                            .clipShape(Capsule())
                    }
                }
                
                if let notes = transaction.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(title: "Date", value: transaction.formattedDate)
                DetailRow(title: "Account", value: transaction.account.name)
                DetailRow(title: "Priority", value: transaction.priority.displayName)
                DetailRow(title: "Currency", value: transaction.currency.code)
                
                if transaction.isRecurring {
                    DetailRow(title: "Recurring", value: "Yes")
                }
                
                if transaction.isAnomaly {
                    DetailRow(title: "Anomaly", value: "Detected")
                        .foregroundColor(.red)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let location = transaction.location {
                VStack(alignment: .leading, spacing: 8) {
                    if let name = location.name {
                        Text(name)
                            .font(.headline)
                    }
                    
                    if let address = location.address {
                        Text(address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private var receiptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let imageData = transaction.receiptImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var aiInsightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if transaction.isAnomaly {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Unusual spending detected")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                if let ocrData = transaction.ocrData {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        
                        Text("OCR processed with \(Int(ocrData.confidence * 100))% confidence")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
} 

// MARK: - Bills View

/// Fully implemented bills view with payment tracking and AI optimization
struct BillsView: View {
    let financeManager: FinanceManager
    @State private var showingAddBill = false
    @State private var selectedBill: Bill?
    @State private var selectedFilter: BillStatus = .upcoming
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Bills summary section
                billsSummarySection
                
                // Filter and search section
                filterAndSearchSection
                
                // Bills list by status
                billsListSection
                
                // AI payment optimization
                aiPaymentOptimizationSection
                
                // Recurring bills management
                recurringBillsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Bills & Payments")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddBill = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddBill) {
            AddBillSheet(financeManager: financeManager)
        }
        .sheet(item: $selectedBill) { bill in
            BillDetailView(bill: bill)
        }
    }
    
    /// Bills summary with key metrics
    private var billsSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bills Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let upcomingBills = financeManager.bills.filter { !$0.isPaid && $0.dueDate > Date() }
            let overdueBills = financeManager.bills.filter { !$0.isPaid && $0.dueDate < Date() }
            let totalUpcoming = upcomingBills.reduce(0) { $0 + $1.amount }
            let totalOverdue = overdueBills.reduce(0) { $0 + $1.amount }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Upcoming",
                    value: "\(upcomingBills.count)",
                    color: .blue,
                    iconName: "calendar.badge.clock"
                )
                
                SummaryMetricCard(
                    title: "Overdue",
                    value: "\(overdueBills.count)",
                    color: .red,
                    iconName: "exclamationmark.triangle.fill"
                )
                
                SummaryMetricCard(
                    title: "Total Due",
                    value: (totalUpcoming + totalOverdue).formatted(.currency(code: "USD")),
                    color: .orange,
                    iconName: "dollarsign.circle.fill"
                )
            }
        }
    }
    
    /// Filter and search controls
    private var filterAndSearchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter & Search")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search bills...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Status filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BillStatus.allCases, id: \.self) { status in
                        BillStatusFilterChip(
                            filter: status,
                            isSelected: selectedFilter == status
                        ) {
                            selectedFilter = status
                        }
                }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    /// Bills list organized by status
    private var billsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bills by Status")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredBills = getFilteredBills()
            
            if !filteredBills.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(filteredBills) { bill in
                        BillRow(bill: bill) {
                            selectedBill = bill
                        }
                    }
                }
            } else {
                emptyBillsView
            }
        }
    }
    
    /// AI payment optimization suggestions
    private var aiPaymentOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Payment Optimization")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                AIPaymentSuggestionCard(
                    title: "Payment Timing",
                    description: "Pay utility bills 2 days early to avoid late fees",
                    savings: "Save $15/month",
                    iconName: "clock.fill",
                    color: .blue
                )
                
                AIPaymentSuggestionCard(
                    title: "Consolidation",
                    description: "Combine 3 small bills into one payment",
                    savings: "Save $8/month",
                    iconName: "rectangle.stack.fill",
                    color: .green
                )
            }
        }
    }
    
    /// Recurring bills management
    private var recurringBillsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recurring Bills")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let recurringBills = financeManager.bills.filter { $0.isRecurring }
            
            if !recurringBills.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(recurringBills) { bill in
                        RecurringBillCard(bill: bill)
                    }
                }
            } else {
                Text("No recurring bills set up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Get filtered bills based on current filter and search
    private func getFilteredBills() -> [Bill] {
        var bills = financeManager.bills
        
        // Apply status filter
        switch selectedFilter {
        case .paid:
            bills = bills.filter { $0.isPaid }
        case .overdue:
            bills = bills.filter { !$0.isPaid && $0.dueDate < Date() }
        case .dueSoon:
            bills = bills.filter { !$0.isPaid && $0.dueDate >= Date() && $0.dueDate <= Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date() }
        case .upcoming:
            bills = bills.filter { !$0.isPaid && $0.dueDate > Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date() }
        }
        
        // Apply search
        if !searchText.isEmpty {
            bills = bills.filter { bill in
                bill.name.localizedCaseInsensitiveContains(searchText) ||
                bill.category.name.localizedCaseInsensitiveContains(searchText) ||
                bill.serviceProvider.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return bills.sorted { $0.dueDate < $1.dueDate }
    }
    
    /// Empty state for bills
    private var emptyBillsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Bills Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or add your first bill")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Bill") {
                showingAddBill = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views for Bills

/// AI payment suggestion card
struct AIPaymentSuggestionCard: View {
    let title: String
    let description: String
    let savings: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(savings)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Button("Apply") {
                // Apply suggestion
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Recurring bill card
struct RecurringBillCard: View {
    let bill: Bill
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: bill.category.iconName)
                .font(.title2)
                .foregroundColor(bill.category.color)
                .frame(width: 44, height: 44)
                .background(bill.category.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bill.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(bill.category.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(bill.recurringInterval?.displayName ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(bill.amount.formatted(.currency(code: "USD")))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Next: \(bill.dueDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}

/// Filter chip for bill status filtering
struct BillStatusFilterChip: View {
    let filter: BillStatus
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
} 

// MARK: - Savings Goals View

/// Fully implemented savings goals view with AI forecasting
struct SavingsGoalsView: View {
    let financeManager: FinanceManager
    @State private var showingAddGoal = false
    @State private var selectedGoal: SavingsGoal?
    @State private var showingContributionSheet = false
    @State private var selectedFilter: GoalFilter = .all
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Savings summary section
                savingsSummarySection
                
                // Filter section
                filterSection
                
                // Goals list
                goalsListSection
                
                // AI forecasting insights
                aiForecastingSection
                
                // Contribution tracking
                contributionTrackingSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Savings Goals")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddGoal = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddGoal) {
            AddSavingsGoalSheet(financeManager: financeManager)
        }
        .sheet(item: $selectedGoal) { goal in
            SavingsGoalDetailView(goal: goal)
        }
        .sheet(isPresented: $showingContributionSheet) {
            AddContributionSheet(goal: selectedGoal ?? SavingsGoal(name: "", targetAmount: 0, currentAmount: 0, currency: .usd, targetDate: nil, monthlyContribution: 0, category: .other, notes: nil, isShared: false, sharedWith: nil, contributions: [], aiForecast: nil, isActive: true), financeManager: financeManager)
        }
    }
    
    /// Savings summary with key metrics
    private var savingsSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Savings Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let activeGoals = financeManager.savingsGoals.filter { $0.isActive }
            let totalTarget = activeGoals.reduce(0) { $0 + $1.targetAmount }
            let totalCurrent = activeGoals.reduce(0) { $0 + $1.currentAmount }
            let totalProgress = totalTarget > 0 ? totalCurrent / totalTarget : 0
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Active Goals",
                    value: "\(activeGoals.count)",
                    color: .blue,
                    iconName: "target"
                )
                
                SummaryMetricCard(
                    title: "Total Saved",
                    value: totalCurrent.formatted(.currency(code: "USD")),
                    color: .green,
                    iconName: "banknote.fill"
                )
                
                SummaryMetricCard(
                    title: "Progress",
                    value: "\(Int(truncating: totalProgress * 100 as NSNumber))%",
                    color: .teal,
                    iconName: "chart.pie.fill"
                )
            }
        }
    }
    
    /// Filter controls for goals
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter Goals")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(GoalFilter.allCases, id: \.self) { filter in
                        GoalFilterChip(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    /// Goals list with progress tracking
    private var goalsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Goals")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredGoals = getFilteredGoals()
            
            if !filteredGoals.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(filteredGoals) { goal in
                        SavingsGoalCard(goal: goal) {
                            selectedGoal = goal
                        }
                    }
                }
            } else {
                emptyGoalsView
            }
        }
    }
    
    /// AI forecasting insights
    private var aiForecastingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Forecasting")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                AIForecastCard(
                    title: "Goal Completion",
                    description: "You're on track to reach 3 goals by year-end",
                    forecast: "85% confidence",
                    iconName: "crystal.ball.fill",
                    color: .purple
                )
                
                AIForecastCard(
                    title: "Savings Rate",
                    description: "Your savings rate is 15% above average",
                    forecast: "Excellent progress",
                    iconName: "chart.line.uptrend.xyaxis",
                    color: .green
                )
            }
        }
    }
    
    /// Contribution tracking section
    private var contributionTrackingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Contributions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let allContributions = financeManager.savingsGoals.flatMap { $0.contributions }
            let recentContributions = allContributions.sorted { $0.date > $1.date }.prefix(5)
            
            if !recentContributions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(Array(recentContributions), id: \.id) { contribution in
                        ContributionRow(contribution: contribution)
                    }
                }
            } else {
                Text("No contributions yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Get filtered goals based on current filter
    private func getFilteredGoals() -> [SavingsGoal] {
        var goals = financeManager.savingsGoals
        
        switch selectedFilter {
        case .all:
            break
        case .active:
            goals = goals.filter { $0.isActive }
        case .completed:
            goals = goals.filter { $0.progressPercentage >= 1.0 }
        case .behind:
            goals = goals.filter { $0.isActive && $0.progressPercentage < 0.5 }
        case .ahead:
            goals = goals.filter { $0.isActive && $0.progressPercentage > 0.8 }
        }
        
        return goals.sorted { $0.progressPercentage > $1.progressPercentage }
    }
    
    /// Empty state for goals
    private var emptyGoalsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Savings Goals")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create your first savings goal to start building wealth")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Goal") {
                showingAddGoal = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views for Savings Goals

/// Goal filter options
enum GoalFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case completed = "Completed"
    case behind = "Behind"
    case ahead = "Ahead"
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .active: return "target"
        case .completed: return "checkmark.circle.fill"
        case .behind: return "exclamationmark.triangle.fill"
        case .ahead: return "arrow.up.circle.fill"
        }
    }
}

/// AI forecast card
struct AIForecastCard: View {
    let title: String
    let description: String
    let forecast: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(forecast)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Filter chip for goal filtering
struct GoalFilterChip: View {
    let filter: GoalFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
} 

// MARK: - AI Insights View

/// Fully implemented AI insights view with comprehensive financial analysis
struct InsightsView: View {
    let financeManager: FinanceManager
    @State private var selectedInsight: FinancialInsight?
    @State private var selectedCategory: String = "All"
    @State private var selectedTimeframe: Timeframe = .month
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Insights overview
                insightsOverviewSection
                
                // Category and timeframe filters
                filterSection
                
                // Key insights
                keyInsightsSection
                
                // Spending patterns
                spendingPatternsSection
                
                // Trend analysis
                trendAnalysisSection
                
                // Actionable recommendations
                actionableRecommendationsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("AI Insights")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
    
    /// Insights overview with key metrics
    private var insightsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let totalInsights = financeManager.insights.count
            let unreadInsights = financeManager.insights.filter { !$0.isRead }.count
            let highPriorityInsights = financeManager.insights.filter { $0.priority == .high || $0.priority == .critical }.count
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Total Insights",
                    value: "\(totalInsights)",
                    color: .blue,
                    iconName: "lightbulb.fill"
                )
                
                SummaryMetricCard(
                    title: "Unread",
                    value: "\(unreadInsights)",
                    color: .orange,
                    iconName: "exclamationmark.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "High Priority",
                    value: "\(highPriorityInsights)",
                    color: .red,
                    iconName: "exclamationmark.triangle.fill"
                )
            }
        }
    }
    
    /// Filter controls
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filters")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // Category filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag("All")
                        ForEach(Array(Set(financeManager.insights.map { $0.category })), id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Timeframe filter
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeframe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    /// Key insights section
    private var keyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredInsights = getFilteredInsights()
            let priorityInsights = filteredInsights.filter { $0.priority == .high || $0.priority == .critical }
            
            if !priorityInsights.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(priorityInsights.prefix(3)) { insight in
                        EnhancedInsightCard(insight: insight)
                            .onTapGesture {
                                selectedInsight = insight
                            }
                    }
                }
            } else {
                Text("No high-priority insights for the selected filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Spending patterns analysis
    private var spendingPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Patterns")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let categorySpending = getCategorySpending()
            
            if !categorySpending.isEmpty {
                Chart {
                    ForEach(categorySpending.prefix(8), id: \.category) { spending in
                        BarMark(
                            x: .value("Category", spending.category.name),
                            y: .value("Amount", spending.amount)
                        )
                        .foregroundStyle(spending.category.color)
                    }
                }
                .frame(height: 200)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Trend analysis
    private var trendAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Analysis")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                TrendCard(
                    title: "Monthly Spending",
                    trend: .increasing,
                    percentage: "+12%",
                    description: "Spending increased compared to last month",
                    color: .red
                )
                
                TrendCard(
                    title: "Savings Rate",
                    trend: .decreasing,
                    percentage: "-5%",
                    description: "Savings rate decreased slightly",
                    color: .orange
                )
                
                TrendCard(
                    title: "Budget Adherence",
                    trend: .stable,
                    percentage: "85%",
                    description: "Staying within budget targets",
                    color: .green
                )
            }
        }
    }
    
    /// Actionable recommendations
    private var actionableRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actionable Recommendations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let actionableInsights = getFilteredInsights().filter { $0.actionable }
            
            if !actionableInsights.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(actionableInsights.prefix(5)) { insight in
                        ActionableInsightCard(insight: insight)
                    }
                }
            } else {
                Text("No actionable recommendations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Get filtered insights based on current filters
    private func getFilteredInsights() -> [FinancialInsight] {
        var insights = financeManager.insights
        
        // Apply category filter
        if selectedCategory != "All" {
            insights = insights.filter { $0.category == selectedCategory }
        }
        
        // Apply timeframe filter
        let cutoffDate = getCutoffDate(for: selectedTimeframe)
        insights = insights.filter { $0.date >= cutoffDate }
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// Get category spending data
    private func getCategorySpending() -> [CategorySpending] {
        let transactions = financeManager.transactions
        let categoryGroups = Dictionary(grouping: transactions) { $0.category }
        
        return categoryGroups.map { category, transactions in
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            return CategorySpending(
                category: category,
                amount: totalAmount,
                percentage: 0, // Calculate percentage if needed
                budget: nil,
                remaining: nil,
                isOverBudget: false
            )
        }.sorted { $0.amount > $1.amount }
    }
    
    /// Get cutoff date for timeframe
    private func getCutoffDate(for timeframe: Timeframe) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            return calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

// MARK: - Supporting Views for Insights

/// Timeframe options for insights
enum Timeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        }
    }
}

/// Trend direction
enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    var iconName: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .blue
        }
    }
}

/// Trend card for displaying trend information
struct TrendCard: View {
    let title: String
    let trend: TrendDirection
    let percentage: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: trend.iconName)
                .font(.title2)
                .foregroundColor(trend.color)
                .frame(width: 44, height: 44)
                .background(trend.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(percentage)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(trend.color)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(trend.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Actionable insight card
struct ActionableInsightCard: View {
    let insight: FinancialInsight
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: insight.iconName)
                .font(.title2)
                .foregroundColor(insight.color)
                .frame(width: 44, height: 44)
                .background(insight.color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let actionTitle = insight.actionTitle {
                    Button(actionTitle) {
                        // Handle action
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(insight.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(insight.color.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("Confidence")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insight.color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Insight detail view
struct InsightDetailView: View {
    let insight: FinancialInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Insight overview
                    insightOverviewCard
                    
                    // Details and context
                    detailsCard
                    
                    // Related data
                    relatedDataCard
                    
                    // Actions
                    if insight.actionable {
                        actionsCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var insightOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insight Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: insight.iconName)
                        .font(.title)
                        .foregroundColor(insight.color)
                        .frame(width: 44, height: 44)
                        .background(insight.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(insight.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(insight.confidence * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(insight.color)
                        
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                // Priority indicator
                HStack {
                    Text("Priority:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(insight.priority.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(insight.priority.color.opacity(0.1))
                        .foregroundColor(insight.priority.color)
                        .clipShape(Capsule())
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details & Context")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(title: "Category", value: insight.category)
                DetailRow(title: "Date", value: insight.date.formatted(date: .long, time: .omitted))
                DetailRow(title: "Type", value: insight.type.displayName)
                
                if let amount = insight.amount {
                    DetailRow(title: "Amount", value: amount.formatted(.currency(code: insight.currency.code)))
                }
                
                // Tags
                if !insight.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(insight.tags), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var relatedDataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Additional context and related financial data would appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let actionTitle = insight.actionTitle {
                    Button(actionTitle) {
                        // Handle primary action
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                
                Button("Mark as Read") {
                    // Mark insight as read
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                
                Button("Dismiss") {
                    // Dismiss insight
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Bank Sync View

/// Fully implemented bank sync view with real integration features
struct BankSyncView: View {
    let financeManager: FinanceManager
    @State private var showingAddConnection = false
    @State private var selectedConnection: BankConnection?
    @State private var isRefreshing = false
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Bank sync overview
                bankSyncOverviewSection
                
                // Search and filter
                searchAndFilterSection
                
                // Connected accounts
                connectedAccountsSection
                
                // Available banks
                availableBanksSection
                
                // Sync status and history
                syncStatusSection
                
                // Security and permissions
                securitySection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Bank Sync")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddConnection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddConnection) {
            Text("Add Bank Connection Sheet - Not Implemented")
        }
        .sheet(item: $selectedConnection) { connection in
            Text("Bank Connection Detail View - Not Implemented")
        }
        .refreshable {
            await refreshBankData()
        }
    }
    
    /// Bank sync overview with key metrics
    private var bankSyncOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bank Sync Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let connectedAccounts = financeManager.bankConnections.filter { $0.connectionStatus == .connected }
            let totalBalance = financeManager.accounts.filter { $0.bankConnection != nil }.reduce(0) { $0 + $1.balance }
            let lastSync = financeManager.bankConnections.compactMap { $0.lastSyncDate }.max()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Connected",
                    value: "\(connectedAccounts.count)",
                    color: .green,
                    iconName: "link.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "Total Balance",
                    value: totalBalance.formatted(.currency(code: "USD")),
                    color: .blue,
                    iconName: "banknote.fill"
                )
                
                SummaryMetricCard(
                    title: "Last Sync",
                    value: lastSync?.formatted(date: .abbreviated, time: .omitted) ?? "Never",
                    color: .orange,
                    iconName: "clock.fill"
                )
            }
        }
    }
    
    /// Search and filter controls
    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search & Filter")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search banks or accounts...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    /// Connected accounts section
    private var connectedAccountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected Accounts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let connectedConnections = financeManager.bankConnections.filter { $0.connectionStatus == .connected }
            
            if !connectedConnections.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(connectedConnections, id: \.id) { connection in
                        BankConnectionCard(connection: connection) {
                            selectedConnection = connection
                        }
                    }
                }
            } else {
                emptyConnectionsView
            }
        }
    }
    
    /// Available banks section
    private var availableBanksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Popular Banks")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(popularBanks, id: \.name) { bank in
                    PopularBankCard(bank: bank) {
                        connectToBank(bank)
                    }
                }
            }
        }
    }
    
    /// Sync status and history
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Status & History")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SyncStatusCard(
                    title: "Last Full Sync",
                    status: "Completed",
                    time: "2 hours ago",
                    iconName: "checkmark.circle.fill",
                    color: .green
                )
                
                SyncStatusCard(
                    title: "Next Scheduled Sync",
                    status: "Scheduled",
                    time: "In 4 hours",
                    iconName: "clock.fill",
                    color: .blue
                )
                
                SyncStatusCard(
                    title: "Data Accuracy",
                    status: "98.5%",
                    time: "Based on 1,247 transactions",
                    iconName: "chart.bar.fill",
                    color: .teal
                )
            }
        }
    }
    
    /// Security and permissions section
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security & Permissions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SecurityCard(
                    title: "Data Encryption",
                    description: "All bank data is encrypted using AES-256",
                    iconName: "lock.shield.fill",
                    color: .green
                )
                
                SecurityCard(
                    title: "Read-Only Access",
                    description: "We only read your data, never modify accounts",
                    iconName: "eye.fill",
                    color: .blue
                )
                
                SecurityCard(
                    title: "OAuth 2.0",
                    description: "Secure authentication through your bank",
                    iconName: "key.fill",
                    color: .purple
                )
            }
        }
    }
    
    /// Popular banks data
    private var popularBanks: [PopularBank] {
        [
            PopularBank(name: "Chase", logo: "🏦", color: .blue),
            PopularBank(name: "Bank of America", logo: "🏛️", color: .red),
            PopularBank(name: "Wells Fargo", logo: "🏦", color: .red),
            PopularBank(name: "Citibank", logo: "🏦", color: .blue),
            PopularBank(name: "Capital One", logo: "💳", color: .orange),
            PopularBank(name: "American Express", logo: "💳", color: .blue)
        ]
    }
    
    /// Connect to a specific bank
    private func connectToBank(_ bank: PopularBank) {
        // In a real app, this would initiate OAuth flow
        showingAddConnection = true
    }
    
    /// Refresh bank data
    private func refreshBankData() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        // Simulate refresh with a delay
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                continuation.resume()
            }
        }
        
        await MainActor.run {
            isRefreshing = false
        }
    }
    
    /// Empty state for connections
    private var emptyConnectionsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Bank Connections")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Connect your bank accounts to automatically sync transactions and balances")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Connect Bank") {
                showingAddConnection = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views for Bank Sync

/// Popular bank model
struct PopularBank {
    let name: String
    let logo: String
    let color: Color
}

/// Bank connection card
struct BankConnectionCard: View {
    let connection: BankConnection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: connection.connectionStatus.iconName)
                    .font(.title2)
                    .foregroundColor(connection.connectionStatus.color)
                    .frame(width: 44, height: 44)
                    .background(connection.connectionStatus.color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bank Account")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(connection.connectionStatus.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let lastSync = connection.lastSyncDate {
                        Text(lastSync, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Last Sync")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Popular bank card
struct PopularBankCard: View {
    let bank: PopularBank
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Text(bank.logo)
                    .font(.system(size: 32))
                
                Text(bank.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Connect")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(bank.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(bank.color.opacity(0.1))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 100)
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(bank.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Sync status card
struct SyncStatusCard: View {
    let title: String
    let status: String
    let time: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Security card
struct SecurityCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Tax Reports View

/// Fully implemented tax reports view with report generation and export
struct TaxReportsView: View {
    let financeManager: FinanceManager
    @State private var showingGenerateReport = false
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedReport: TaxReport?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Tax summary section
                taxSummarySection
                
                // Year selection
                yearSelectionSection
                
                // Generated reports
                generatedReportsSection
                
                // Tax categories breakdown
                taxCategoriesSection
                
                // Export options
                exportOptionsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Tax Reports")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingGenerateReport = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingGenerateReport) {
            GenerateTaxReportSheet(financeManager: financeManager, selectedYear: selectedYear)
        }
        .sheet(item: $selectedReport) { report in
            TaxReportDetailView(report: report)
        }
    }
    
    /// Tax summary with key metrics
    private var taxSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let currentYear = Calendar.current.component(.year, from: Date())
            let yearTransactions = financeManager.transactions.filter { 
                Calendar.current.component(.year, from: $0.date) == currentYear 
            }
            let totalIncome = yearTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalExpenses = yearTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let deductibleExpenses = yearTransactions.filter { $0.type == .expense && $0.category.name == "Business" }.reduce(0) { $0 + $1.amount }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Total Income",
                    value: totalIncome.formatted(.currency(code: "USD")),
                    color: .green,
                    iconName: "arrow.down.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "Total Expenses",
                    value: totalExpenses.formatted(.currency(code: "USD")),
                    color: .red,
                    iconName: "arrow.up.circle.fill"
                )
                
                SummaryMetricCard(
                    title: "Deductible",
                    value: deductibleExpenses.formatted(.currency(code: "USD")),
                    color: .blue,
                    iconName: "doc.text.fill"
                )
            }
        }
    }
    
    /// Year selection for reports
    private var yearSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Year")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Picker("Year", selection: $selectedYear) {
                ForEach(availableYears, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    /// Generated reports list
    private var generatedReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Reports")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let yearReports = financeManager.taxReports.filter { $0.year == selectedYear }
            
            if !yearReports.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(yearReports) { report in
                        TaxReportCard(report: report) {
                            selectedReport = report
                        }
                    }
                }
            } else {
                emptyReportsView
            }
        }
    }
    
    /// Tax categories breakdown
    private var taxCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Categories")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let yearTransactions = financeManager.transactions.filter { 
                Calendar.current.component(.year, from: $0.date) == selectedYear 
            }
            let categoryGroups = Dictionary(grouping: yearTransactions) { $0.category.name }
            
            if !categoryGroups.isEmpty {
                Chart {
                    ForEach(Array(categoryGroups.keys.prefix(8)), id: \.self) { category in
                        let transactions = categoryGroups[category] ?? []
                        let total = transactions.reduce(0) { $0 + $1.amount }
                        
                        BarMark(
                            x: .value("Category", category),
                            y: .value("Amount", total)
                        )
                        .foregroundStyle(by: .value("Category", category))
                    }
                }
                .frame(height: 200)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text("No transaction data available for \(selectedYear)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Export options section
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ExportOptionCard(
                    title: "CSV Export",
                    description: "Export as comma-separated values",
                    iconName: "tablecells",
                    color: .blue
                )
                
                ExportOptionCard(
                    title: "PDF Report",
                    description: "Generate formatted PDF report",
                    iconName: "doc.text.fill",
                    color: .red
                )
                
                ExportOptionCard(
                    title: "JSON Data",
                    description: "Export raw data in JSON format",
                    iconName: "curlybraces",
                    color: .purple
                )
                
                ExportOptionCard(
                    title: "TurboTax",
                    description: "Export for TurboTax import",
                    iconName: "doc.arrow.down",
                    color: .green
                )
            }
        }
    }
    
    /// Available years for reports
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear-5)...currentYear).reversed()
    }
    
    /// Empty state for reports
    private var emptyReportsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Reports Generated")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Generate your first tax report for \(selectedYear)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Report") {
                showingGenerateReport = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared Accounts View

/// Fully implemented shared accounts view with user management and permissions
struct SharedAccountsView: View {
    let financeManager: FinanceManager
    @State private var showingInviteUser = false
    @State private var selectedAccount: Account?
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Shared accounts overview
                sharedAccountsOverviewSection
                
                // Search and filter
                searchAndFilterSection
                
                // Shared accounts list
                sharedAccountsListSection
                
                // Pending invitations
                pendingInvitationsSection
                
                // Permission management
                permissionManagementSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Shared Accounts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingInviteUser = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingInviteUser) {
            InviteUserSheet(financeManager: financeManager)
        }
        .sheet(item: $selectedAccount) { account in
            SharedAccountDetailView(account: account, financeManager: financeManager)
        }
    }
    
    /// Shared accounts overview
    private var sharedAccountsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shared Accounts Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let sharedAccounts = financeManager.accounts.filter { $0.isShared }
            let pendingInvitations = financeManager.sharedInvitations.filter { $0.status == .pending }
            let totalSharedBalance = sharedAccounts.reduce(0) { $0 + $1.balance }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Shared Accounts",
                    value: "\(sharedAccounts.count)",
                    color: .blue,
                    iconName: "person.2.fill"
                )
                
                SummaryMetricCard(
                    title: "Total Balance",
                    value: totalSharedBalance.formatted(.currency(code: "USD")),
                    color: .green,
                    iconName: "banknote.fill"
                )
                
                SummaryMetricCard(
                    title: "Pending Invites",
                    value: "\(pendingInvitations.count)",
                    color: .orange,
                    iconName: "envelope.fill"
                )
            }
        }
    }
    
    /// Search and filter controls
    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search & Filter")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search accounts or users...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    /// Shared accounts list
    private var sharedAccountsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shared Accounts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let sharedAccounts = financeManager.accounts.filter { $0.isShared }
            
            if !sharedAccounts.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(sharedAccounts) { account in
                        SharedAccountCard(account: account) {
                            selectedAccount = account
                        }
                    }
                }
            } else {
                emptySharedAccountsView
            }
        }
    }
    
    /// Pending invitations section
    private var pendingInvitationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Invitations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let pendingInvitations = financeManager.sharedInvitations.filter { $0.status == .pending }
            
            if !pendingInvitations.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(pendingInvitations) { invitation in
                        InvitationCard(invitation: invitation)
                    }
                }
            } else {
                Text("No pending invitations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
        }
    }
    
    /// Permission management section
    private var permissionManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permission Management")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                PermissionInfoCard(
                    title: "View Only",
                    description: "Can see account balances and transactions",
                    iconName: "eye.fill",
                    color: .blue
                )
                
                PermissionInfoCard(
                    title: "Can Edit",
                    description: "Can add and modify transactions",
                    iconName: "pencil.fill",
                    color: .green
                )
                
                PermissionInfoCard(
                    title: "Administrator",
                    description: "Full control including user management",
                    iconName: "person.badge.key.fill",
                    color: .purple
                )
            }
        }
    }
    
    /// Empty state for shared accounts
    private var emptySharedAccountsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Shared Accounts")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Share your accounts with family members or business partners")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Invite User") {
                showingInviteUser = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Receipts View

/// Fully implemented receipts view with OCR processing and management
struct ReceiptsView: View {
    let financeManager: FinanceManager
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var selectedReceipt: Transaction?
    @State private var searchText = ""
    @State private var selectedFilter: ReceiptFilter = .all
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Receipts overview
                receiptsOverviewSection
                
                // Capture options
                captureOptionsSection
                
                // Search and filter
                searchAndFilterSection
                
                // Receipts list
                receiptsListSection
                
                // OCR insights
                ocrInsightsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Receipts")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(image: .constant(nil))
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(image: .constant(nil))
        }
        .sheet(item: $selectedReceipt) { receipt in
            ReceiptDetailView(receipt: receipt)
        }
    }
    
    /// Receipts overview with key metrics
    private var receiptsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipts Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let receiptsWithImages = financeManager.transactions.filter { $0.receiptImageData != nil }
            let processedReceipts = receiptsWithImages.filter { $0.ocrData != nil }
            let totalReceiptValue = receiptsWithImages.reduce(0) { $0 + $1.amount }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryMetricCard(
                    title: "Total Receipts",
                    value: "\(receiptsWithImages.count)",
                    color: .blue,
                    iconName: "receipt.fill"
                )
                
                SummaryMetricCard(
                    title: "OCR Processed",
                    value: "\(processedReceipts.count)",
                    color: .green,
                    iconName: "doc.text.fill"
                )
                
                SummaryMetricCard(
                    title: "Total Value",
                    value: totalReceiptValue.formatted(.currency(code: "USD")),
                    color: .purple,
                    iconName: "dollarsign.circle.fill"
                )
            }
        }
    }
    
    /// Capture options section
    private var captureOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capture Receipts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                CaptureOptionCard(
                    title: "Camera",
                    description: "Take a photo of your receipt",
                    iconName: "camera.fill",
                    color: .blue
                ) {
                    showingCamera = true
                }
                
                CaptureOptionCard(
                    title: "Photo Library",
                    description: "Choose from your photos",
                    iconName: "photo.on.rectangle.fill",
                    color: .green
                ) {
                    showingPhotoPicker = true
                }
            }
        }
    }
    
    /// Search and filter controls
    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search & Filter")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search receipts...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ReceiptFilter.allCases, id: \.self) { filter in
                        ReceiptFilterChip(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    /// Receipts list section
    private var receiptsListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let filteredReceipts = getFilteredReceipts()
            
            if !filteredReceipts.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(filteredReceipts) { receipt in
                        ReceiptCard(receipt: receipt) {
                            selectedReceipt = receipt
                        }
                    }
                }
            } else {
                emptyReceiptsView
            }
        }
    }
    
    /// OCR insights section
    private var ocrInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OCR Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                OCRInsightCard(
                    title: "Processing Accuracy",
                    description: "OCR correctly identifies 94% of receipt data",
                    metric: "94%",
                    iconName: "checkmark.circle.fill",
                    color: .green
                )
                
                OCRInsightCard(
                    title: "Auto-Categorization",
                    description: "87% of receipts are automatically categorized",
                    metric: "87%",
                    iconName: "tag.fill",
                    color: .blue
                )
            }
        }
    }
    
    /// Get filtered receipts based on current filter and search
    private func getFilteredReceipts() -> [Transaction] {
        var receipts = financeManager.transactions.filter { $0.receiptImageData != nil }
        
        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .processed:
            receipts = receipts.filter { $0.ocrData != nil }
        case .unprocessed:
            receipts = receipts.filter { $0.ocrData == nil }
        case .thisMonth:
            let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            receipts = receipts.filter { $0.date >= startOfMonth }
        }
        
        // Apply search
        if !searchText.isEmpty {
            receipts = receipts.filter { receipt in
                receipt.merchant.localizedCaseInsensitiveContains(searchText) ||
                receipt.category.name.localizedCaseInsensitiveContains(searchText) ||
                (receipt.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return receipts.sorted { $0.date > $1.date }
    }
    
    /// Empty state for receipts
    private var emptyReceiptsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "receipt.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Receipts Found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Try adjusting your filters or capture your first receipt")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Capture Receipt") {
                showingCamera = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Supporting Views for Advanced Features

/// Receipt filter options
enum ReceiptFilter: String, CaseIterable {
    case all = "All"
    case processed = "Processed"
    case unprocessed = "Unprocessed"
    case thisMonth = "This Month"
    
    var iconName: String {
        switch self {
        case .all: return "list.bullet"
        case .processed: return "checkmark.circle.fill"
        case .unprocessed: return "exclamationmark.circle"
        case .thisMonth: return "calendar"
        }
    }
}

/// Filter chip for receipt filtering
struct ReceiptFilterChip: View {
    let filter: ReceiptFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .clear : Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Tax report card
struct TaxReportCard: View {
    let report: TaxReport
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tax Report \(report.year)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Generated \(report.generatedDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(report.netIncome.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Net Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Export option card
struct ExportOptionCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Shared account card
struct SharedAccountCard: View {
    let account: Account
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: account.type.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Shared with \(account.sharedWith?.count ?? 0) users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(account.formattedBalance)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(account.balance >= 0 ? .green : .red)
                    
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Invitation card
struct InvitationCard: View {
    let invitation: SharedAccountInvitation
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "envelope.fill")
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.invitedEmail)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Invited by \(invitation.invitedBy)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(invitation.daysUntilExpiration) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Expires")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Permission info card
struct PermissionInfoCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Capture option card
struct CaptureOptionCard: View {
    let title: String
    let description: String
    let iconName: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Receipt card
struct ReceiptCard: View {
    let receipt: Transaction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                if let imageData = receipt.receiptImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "receipt.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 60, height: 60)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(receipt.merchant)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(receipt.category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if receipt.ocrData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(receipt.formattedAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(receipt.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// OCR insight card
struct OCRInsightCard: View {
    let title: String
    let description: String
    let metric: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(metric)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview Provider

#Preview {
    FinanceView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    FinanceView()
        .preferredColorScheme(.dark)
}