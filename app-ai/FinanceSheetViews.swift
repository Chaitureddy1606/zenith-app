//
//  FinanceSheetViews.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import Charts

// MARK: - Add Budget Sheet

/// Sheet for adding and editing budgets
struct AddBudgetSheet: View {
    let financeManager: FinanceManager
    let budget: Budget?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedCategory: TransactionCategory?
    @State private var amount: String = ""
    @State private var period: BudgetPeriod = .monthly
    @State private var startDate = Date()
    
    init(financeManager: FinanceManager, budget: Budget? = nil) {
        self.financeManager = financeManager
        self.budget = budget
        
        if let budget = budget {
            _name = State(initialValue: budget.name)
            _selectedCategory = State(initialValue: budget.category)
            _amount = State(initialValue: String(describing: budget.amount))
            _period = State(initialValue: budget.period)
            _startDate = State(initialValue: budget.startDate)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    // Budget name
                    TextField("Budget name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    // Category selection
                    HStack {
                        Text("Category")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            // Show category picker
                        } label: {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(category.color)
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Category")
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Amount field
                    HStack {
                        Text("Amount")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Period picker
                    Picker("Period", selection: $period) {
                        ForEach(BudgetPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // Start date
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
                
                Section("Budget Preview") {
                    if let amountValue = Decimal(string: amount), amountValue > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Budget Summary")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Amount:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(amountValue.formatted(.currency(code: "USD")))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Period:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(period.displayName)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Start Date:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(startDate, style: .date)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .navigationTitle(budget == nil ? "Add Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && selectedCategory != nil && !amount.isEmpty && Decimal(string: amount) != nil
    }
    
    private func saveBudget() {
        guard let amountValue = Decimal(string: amount),
              let category = selectedCategory else { return }
        
        let newBudget = Budget(
            name: name,
            category: category,
            amount: amountValue,
            currency: .usd,
            period: period,
            startDate: startDate,
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate,
            spent: budget?.spent ?? 0,
            isShared: false,
            sharedWith: nil,
            aiSuggestions: [],
            isActive: true
        )
        
        if budget != nil {
            financeManager.updateBudget(newBudget)
        } else {
            financeManager.addBudget(newBudget)
        }
        
        dismiss()
    }
}

// MARK: - Add Bill Sheet

/// Sheet for adding and editing bills
struct AddBillSheet: View {
    let financeManager: FinanceManager
    let bill: Bill?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var dueDate = Date()
    @State private var frequency: BillFrequency = .monthly
    @State private var selectedCategory: TransactionCategory?
    @State private var selectedAccount: Account?
    @State private var notes: String = ""
    @State private var isRecurring = true
    
    init(financeManager: FinanceManager, bill: Bill? = nil) {
        self.financeManager = financeManager
        self.bill = bill
        
        if let bill = bill {
            _name = State(initialValue: bill.name)
            _amount = State(initialValue: String(describing: bill.amount))
            _dueDate = State(initialValue: bill.dueDate)
            _frequency = State(initialValue: BillFrequency(rawValue: bill.recurringInterval?.rawValue ?? "monthly") ?? .monthly)
            _selectedCategory = State(initialValue: bill.category)
            _selectedAccount = State(initialValue: bill.account)
            _notes = State(initialValue: bill.notes ?? "")
            _isRecurring = State(initialValue: bill.isRecurring)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Bill Information") {
                    // Bill name
                    TextField("Bill name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    // Amount
                    HStack {
                        Text("Amount")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Due date
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    // Category selection
                    HStack {
                        Text("Category")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            // Show category picker
                        } label: {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(category.color)
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Category")
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Account selection
                    HStack {
                        Text("Account")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            // Show account picker
                        } label: {
                            HStack {
                                if let account = selectedAccount {
                                    Image(systemName: account.type.iconName)
                                        .foregroundColor(.accentColor)
                                    Text(account.name)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Account")
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("Recurring Settings") {
                    Toggle("Recurring Bill", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(BillFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Additional Details") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("Bill Preview") {
                    if let amountValue = Decimal(string: amount), amountValue > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bill Summary")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Name:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(name.isEmpty ? "Unnamed Bill" : name)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Amount:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(amountValue.formatted(.currency(code: "USD")))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Due Date:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(dueDate, style: .date)
                                    .fontWeight(.semibold)
                            }
                            
                            if isRecurring {
                                HStack {
                                    Text("Frequency:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(frequency.displayName)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(bill == nil ? "Add Bill" : "Edit Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBill()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !amount.isEmpty && selectedCategory != nil && selectedAccount != nil && Decimal(string: amount) != nil
    }
    
    private func saveBill() {
        guard let amountValue = Decimal(string: amount),
              let category = selectedCategory,
              let account = selectedAccount else { return }
        
        let newBill = Bill(
            name: name,
            amount: amountValue,
            currency: .usd,
            dueDate: dueDate,
            isPaid: false,
            paidDate: nil,
            category: category,
            account: account,
            isRecurring: isRecurring,
            recurringInterval: isRecurring ? RecurringInterval(rawValue: frequency.rawValue) : nil,
            serviceProvider: "Unknown",
            accountNumber: nil,
            notes: notes.isEmpty ? nil : notes,
            attachments: [],
            priority: .normal,
            isShared: false,
            sharedWith: nil,
            aiPaymentSuggestion: nil,
            notifications: []
        )
        
        if let existingBill = bill {
            financeManager.updateBill(newBill)
        } else {
            financeManager.addBill(newBill)
        }
        
        dismiss()
    }
}

// MARK: - Add Savings Goal Sheet

/// Sheet for adding and editing savings goals
struct AddSavingsGoalSheet: View {
    let financeManager: FinanceManager
    let goal: SavingsGoal?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var targetAmount: String = ""
    @State private var targetDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var selectedCategory: SavingsGoalCategory?
    @State private var notes: String = ""
    @State private var hasTargetDate = false
    
    init(financeManager: FinanceManager, goal: SavingsGoal? = nil) {
        self.financeManager = financeManager
        self.goal = goal
        
        if let goal = goal {
            _name = State(initialValue: goal.name)
            _targetAmount = State(initialValue: String(describing: goal.targetAmount))
            _targetDate = State(initialValue: goal.targetDate ?? Date())
            _selectedCategory = State(initialValue: goal.category)
            _notes = State(initialValue: goal.notes ?? "")
            _hasTargetDate = State(initialValue: goal.targetDate != nil)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Information") {
                    // Goal name
                    TextField("Goal name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    // Target amount
                    HStack {
                        Text("Target Amount")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $targetAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    // Category selection
                    HStack {
                        Text("Category")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            // Show category picker
                        } label: {
                            HStack {
                                if let category = selectedCategory {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(category.color)
                                    Text(category.displayName)
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Select Category")
                                        .foregroundColor(.secondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Section("Target Date") {
                    Toggle("Set Target Date", isOn: $hasTargetDate)
                    
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }
                
                Section("Additional Details") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("Goal Preview") {
                    if let targetAmountValue = Decimal(string: targetAmount), targetAmountValue > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal Summary")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Name:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(name.isEmpty ? "Unnamed Goal" : name)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Target Amount:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(targetAmountValue.formatted(.currency(code: "USD")))
                                    .fontWeight(.semibold)
                            }
                            
                            if hasTargetDate {
                                HStack {
                                    Text("Target Date:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(targetDate, style: .date)
                                        .fontWeight(.semibold)
                                }
                                
                                // Calculate estimated monthly contribution
                                let monthsUntilTarget = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 12
                                let monthlyContribution = targetAmountValue / Decimal(monthsUntilTarget)
                                
                                HStack {
                                    Text("Monthly Contribution:")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(monthlyContribution.formatted(.currency(code: "USD")))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(goal == nil ? "Add Savings Goal" : "Edit Savings Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !targetAmount.isEmpty && selectedCategory != nil && Decimal(string: targetAmount) != nil
    }
    
    private func saveGoal() {
        guard let targetAmountValue = Decimal(string: targetAmount),
              let category = selectedCategory else { return }
        
        let newGoal = SavingsGoal(
            name: name,
            targetAmount: targetAmountValue,
            currentAmount: goal?.currentAmount ?? 0,
            currency: .usd,
            targetDate: hasTargetDate ? targetDate : nil,
            monthlyContribution: 0,
            category: selectedCategory ?? .other,
            notes: notes.isEmpty ? nil : notes,
            isShared: false,
            sharedWith: nil,
            contributions: goal?.contributions ?? [],
            aiForecast: nil,
            isActive: true
        )
        
        if goal != nil {
            financeManager.updateSavingsGoal(newGoal)
        } else {
            financeManager.addSavingsGoal(newGoal)
        }
        
        dismiss()
    }
}

// MARK: - Detail Views

/// Budget detail view showing spending analysis
struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Budget overview
                    budgetOverviewCard
                    
                    // Spending chart
                    spendingChartCard
                    
                    // Recent transactions
                    recentTransactionsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(budget.category.name)
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
    
    private var budgetOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget Amount")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(budget.amount.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(budget.spent.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text((budget.amount - budget.spent).formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(truncating: (budget.spendingPercentage * 100) as NSNumber))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(budget.progressColor)
                    }
                }
                
                // Progress bar
                ProgressView(value: min(Double(truncating: budget.spendingPercentage as NSNumber), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: budget.progressColor))
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var spendingChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Placeholder for spending chart
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Spending Chart")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Transaction list would appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        }
    }
}

/// Bill detail view
struct BillDetailView: View {
    let bill: Bill
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Bill overview
                    billOverviewCard
                    
                    // Payment actions
                    paymentActionsCard
                    
                    // Bill details
                    billDetailsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(bill.name)
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
    
    private var billOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bill Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: bill.category.iconName)
                        .font(.title)
                        .foregroundColor(bill.category.color)
                        .frame(width: 44, height: 44)
                        .background(bill.category.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bill.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(bill.category.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(bill.amount.formatted(.currency(code: "USD")))
                            .font(.title2)
                            .fontWeight(.bold)
                        
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
                
                if let notes = bill.notes, !notes.isEmpty {
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
    
    private var paymentActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if !bill.isPaid {
                    Button {
                        financeManager.markBillAsPaid(bill)
                    } label: {
                        Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Button {
                    // Postpone bill
                } label: {
                    Label("Postpone", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // Edit bill
                } label: {
                    Label("Edit Bill", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var billDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bill Details")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(title: "Due Date", value: bill.dueDate.formatted(date: .long, time: .omitted))
                DetailRow(title: "Frequency", value: bill.recurringInterval?.displayName ?? "Not recurring")
                DetailRow(title: "Account", value: bill.account.name)
                DetailRow(title: "Recurring", value: bill.isRecurring ? "Yes" : "No")
                
                if let lastPaid = bill.paidDate {
                    DetailRow(title: "Last Paid", value: lastPaid.formatted(date: .long, time: .omitted))
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

/// Savings goal detail view
struct SavingsGoalDetailView: View {
    let goal: SavingsGoal
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var financeManager: FinanceManager
    @State private var showingContributionSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Goal overview
                    goalOverviewCard
                    
                    // Progress chart
                    progressChartCard
                    
                    // Contribution actions
                    contributionActionsCard
                    
                    // Recent contributions
                    recentContributionsCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(goal.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingContributionSheet) {
                AddContributionSheet(goal: goal, financeManager: financeManager)
            }
        }
    }
    
    private var goalOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(goal.category.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(Int(truncating: (goal.progressPercentage * 100) as NSNumber))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                ProgressView(value: Double(truncating: goal.progressPercentage as NSNumber))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Savings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(goal.currentAmount.formatted(.currency(code: "USD")))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target Amount")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(goal.targetAmount.formatted(.currency(code: "USD")))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                
                if let targetDate = goal.targetDate {
                    HStack {
                        Text("Target Date:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(targetDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var progressChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Chart")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Placeholder for progress chart
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Progress Chart")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
    
    private var contributionActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button {
                    showingContributionSheet = true
                } label: {
                    Label("Add Contribution", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    // Edit goal
                } label: {
                    Label("Edit Goal", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var recentContributionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Contributions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if !goal.contributions.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(goal.contributions.sorted { $0.date > $1.date }.prefix(5), id: \.id) { contribution in
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
}

// MARK: - Supporting Views

/// Detail row for displaying key-value pairs
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

/// Contribution row for displaying individual contributions
struct ContributionRow: View {
    let contribution: Contribution
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contribution.amount.formatted(.currency(code: "USD")))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                if let notes = contribution.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(contribution.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

/// Add contribution sheet
struct AddContributionSheet: View {
    let goal: SavingsGoal
    let financeManager: FinanceManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var amount: String = ""
    @State private var date = Date()
    @State private var notes: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contribution Details") {
                    HStack {
                        Text("Amount")
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("Goal Progress") {
                    let currentProgress = goal.progressPercentage
                    let newAmount = Decimal(string: amount) ?? 0
                    let newTotal = goal.currentAmount + newAmount
                    let newProgress = goal.targetAmount > 0 ? newTotal / goal.targetAmount : 0
                    
                    HStack {
                        Text("Current Progress")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(truncating: (currentProgress * 100) as NSNumber))%")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("After Contribution")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(truncating: (newProgress * 100) as NSNumber))%")
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Add Contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContribution()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !amount.isEmpty && Decimal(string: amount) != nil
    }
    
    private func saveContribution() {
        guard let amountValue = Decimal(string: amount) else { return }
        
        let contribution = Contribution(
            amount: amountValue,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            source: "Manual",
            isRecurring: false
        )
        
        financeManager.addContribution(to: goal, contribution: contribution)
        dismiss()
    }
}

// MARK: - Preview Provider

#Preview {
    AddBudgetSheet(financeManager: FinanceManager())
        .preferredColorScheme(.light)
} 