//
//  FinanceFeatureViews.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import Charts

// MARK: - Budget Tracking View

/// Comprehensive budget tracking view with category budgets and spending analysis
struct BudgetTrackingView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingAddBudget = false
    @State private var selectedBudget: Budget?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Budget overview section
                    budgetOverviewSection
                    
                    // Category budgets section
                    categoryBudgetsSection
                    
                    // Spending trends section
                    spendingTrendsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddBudgetSheet(financeManager: financeManager)
            }
            .sheet(item: $selectedBudget) { budget in
                BudgetDetailView(budget: budget)
            }
        }
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
                        
                        Text("\(Int(truncating: (spendingPercentage * 100) as NSNumber))%")
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
            
            LazyVStack(spacing: 12) {
                ForEach(financeManager.budgets) { budget in
                    BudgetCard(budget: budget) {
                        selectedBudget = budget
                    }
                }
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
            
            Button("Add Budget") {
                showingAddBudget = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Budget Card

/// Individual budget card showing category spending
struct BudgetCard: View {
    let budget: Budget
    let onTap: () -> Void
    
    private var budgetAccessibilityLabel: String {
        let percentage = Int(NSDecimalNumber(decimal: budget.spendingPercentage * 100).doubleValue)
        return "\(budget.category.name) budget: \(percentage)% spent"
    }
    
    var body: some View {
        Button(action: onTap) {
            budgetContent
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(budgetAccessibilityLabel)
        .accessibilityHint("Tap to view budget details")
    }
    
    private var budgetContent: some View {
        HStack(spacing: 16) {
            categoryIcon
            budgetDetails
            Spacer()
            amountSpent
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private var categoryIcon: some View {
        Image(systemName: budget.category.iconName)
            .font(.title2)
            .foregroundColor(budget.category.color)
            .frame(width: 44, height: 44)
            .background(budget.category.color.opacity(0.1))
            .clipShape(Circle())
    }
    
    private var budgetDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(budget.category.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Text("Budget: \(budget.amount.formatted(.currency(code: "USD")))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                                        Text("\(Int(NSDecimalNumber(decimal: budget.spendingPercentage * 100).doubleValue))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(budget.progressColor)
            }
            
            // Progress bar
            ProgressView(value: min(NSDecimalNumber(decimal: budget.spendingPercentage).doubleValue, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: budget.progressColor))
        }
    }
    
    private var amountSpent: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(budget.spent.formatted(.currency(code: "USD")))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Spent")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Bills Management View

/// Bills and subscriptions tracking view
struct BillsManagementView: View {
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingAddBill = false
    @State private var selectedBill: Bill?
    
    var body: some View {
        NavigationStack {
            List {
                // Upcoming bills section
                Section("Upcoming Bills") {
                    let upcomingBills = financeManager.bills.filter { !$0.isPaid && $0.dueDate > Date() }
                    
                    if upcomingBills.isEmpty {
                        Text("No upcoming bills")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(upcomingBills.sorted { $0.dueDate < $1.dueDate }) { bill in
                            BillRow(bill: bill) {
                                selectedBill = bill
                            }
                        }
                    }
                }
                
                // Overdue bills section
                Section("Overdue Bills") {
                    let overdueBills = financeManager.bills.filter { !$0.isPaid && $0.dueDate < Date() }
                    
                    if overdueBills.isEmpty {
                        Text("No overdue bills")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(overdueBills.sorted { $0.dueDate < $1.dueDate }) { bill in
                            BillRow(bill: bill) {
                                selectedBill = bill
                            }
                        }
                    }
                }
                
                // Paid bills section
                Section("Recently Paid") {
                    let paidBills = financeManager.bills.filter { $0.isPaid }.prefix(5)
                    
                    if paidBills.isEmpty {
                        Text("No recently paid bills")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(paidBills)) { bill in
                            BillRow(bill: bill) {
                                selectedBill = bill
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bills & Subscriptions")
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
    }
}

// MARK: - Bill Row

/// Individual bill row in the bills list
struct BillRow: View {
    let bill: Bill
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Bill icon
                Image(systemName: bill.category.iconName)
                    .font(.title2)
                    .foregroundColor(bill.category.color)
                    .frame(width: 44, height: 44)
                    .background(bill.category.color.opacity(0.1))
                    .clipShape(Circle())
                
                // Bill details
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(bill.category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(bill.statusText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(bill.statusColor.opacity(0.1))
                            .foregroundColor(bill.statusColor)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Amount and due date
                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.amount.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(bill.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(bill.name), \(bill.amount.formatted(.currency(code: "USD"))), \(bill.statusText)")
        .accessibilityHint("Tap to view bill details")
    }
}

// SavingsGoalsView is defined in FinanceViews.swift

// MARK: - Savings Goal Card

/// Individual savings goal card
struct SavingsGoalCard: View {
    let goal: SavingsGoal
    let onTap: () -> Void
    
    private var goalAccessibilityLabel: String {
        let percentage = Int(NSDecimalNumber(decimal: goal.progressPercentage * 100).doubleValue)
        return "\(goal.name): \(percentage)% complete"
    }
    
    var body: some View {
        Button(action: onTap) {
            goalContent
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(goalAccessibilityLabel)
        .accessibilityHint("Tap to view goal details")
    }
    
    private var goalContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            goalHeader
            goalName
            progressSection
            amountDetails
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
    
    private var goalHeader: some View {
        HStack {
            Image(systemName: goal.category.iconName)
                .font(.title2)
                .foregroundColor(goal.category.color)
            
            Spacer()
            
            Text(goal.isActive ? "Active" : "Paused")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(goal.isActive ? .green.opacity(0.1) : .gray.opacity(0.1))
                .foregroundColor(goal.isActive ? .green : .gray)
                .clipShape(Capsule())
        }
    }
    
    private var goalName: some View {
        Text(goal.name)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .lineLimit(2)
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                                        Text("\(Int(NSDecimalNumber(decimal: goal.progressPercentage * 100).doubleValue))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            ProgressView(value: NSDecimalNumber(decimal: goal.progressPercentage).doubleValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
    }
    
    private var amountDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Saved:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(goal.currentAmount.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            HStack {
                Text("Target:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(goal.targetAmount.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    BudgetTrackingView()
        .environmentObject(FinanceManager())
        .preferredColorScheme(.light)
} 