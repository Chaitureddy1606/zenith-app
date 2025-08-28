//
//  FinanceAdvancedSheets.swift
//  app-ai
//
//  Created by chaitu on 27/08/25.
//

import SwiftUI
import Charts

// MARK: - Generate Tax Report Sheet

/// Sheet for generating tax reports
struct GenerateTaxReportSheet: View {
    let financeManager: FinanceManager
    let selectedYear: Int
    @Environment(\.dismiss) private var dismiss
    @State private var isGenerating = false
    @State private var generatedReport: TaxReport?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Report preview
                    reportPreviewSection
                    
                    // Generation options
                    generationOptionsSection
                    
                    // Data summary
                    dataSummarySection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Generate Tax Report")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        generateReport()
                    }
                    .disabled(isGenerating)
                }
            }
        }
    }
    
    /// Report preview section
    private var reportPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Tax Year:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(selectedYear)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Report Type:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Annual Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Generated Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(Date(), style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Generation options section
    private var generationOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generation Options")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Toggle("Include all transactions", isOn: .constant(true))
                Toggle("Include category breakdowns", isOn: .constant(true))
                Toggle("Include deductible expenses", isOn: .constant(true))
                Toggle("Include income summaries", isOn: .constant(true))
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Data summary section
    private var dataSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Summary")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            let yearTransactions = financeManager.transactions.filter { 
                Calendar.current.component(.year, from: $0.date) == selectedYear 
            }
            let totalIncome = yearTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let totalExpenses = yearTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            let deductibleExpenses = yearTransactions.filter { $0.type == .expense && $0.category.name == "Business" }.reduce(0) { $0 + $1.amount }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Transactions:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(yearTransactions.count)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Income:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(totalIncome.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Total Expenses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(totalExpenses.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Deductible Expenses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(deductibleExpenses.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Generate the tax report
    private func generateReport() {
        isGenerating = true
        
        // Simulate report generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            generatedReport = financeManager.generateTaxReport(for: selectedYear)
            isGenerating = false
            dismiss()
        }
    }
}

// MARK: - Tax Report Detail View

/// Detailed view for tax reports
struct TaxReportDetailView: View {
    let report: TaxReport
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Report overview
                    reportOverviewSection
                    
                    // Income breakdown
                    incomeBreakdownSection
                    
                    // Expense breakdown
                    expenseBreakdownSection
                    
                    // Tax calculations
                    taxCalculationsSection
                    
                    // Export options
                    exportOptionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Tax Report \(report.year)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportOptionsSheet(report: report)
            }
        }
    }
    
    /// Report overview section
    private var reportOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Text("Tax Year:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(report.year)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Generated:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.generatedDate, style: .date)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.isExported ? "Exported" : "Generated")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(report.isExported ? .green : .blue)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Income breakdown section
    private var incomeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Income Breakdown")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Income:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.totalIncome.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                // Income categories chart
                Chart {
                    ForEach(report.categories.filter { !$0.isDeductible }, id: \.category) { category in
                        BarMark(
                            x: .value("Category", category.category),
                            y: .value("Amount", category.totalAmount)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .frame(height: 150)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    /// Expense breakdown section
    private var expenseBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Expense Breakdown")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Total Expenses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.totalExpenses.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Text("Deductible Expenses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.deductibleExpenses.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                // Expense categories chart
                Chart {
                    ForEach(report.categories, id: \.category) { category in
                        BarMark(
                            x: .value("Category", category.category),
                            y: .value("Amount", category.totalAmount)
                        )
                        .foregroundStyle(category.isDeductible ? .blue : .red)
                    }
                }
                .frame(height: 150)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    /// Tax calculations section
    private var taxCalculationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Calculations")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Net Income:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.netIncome.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Estimated Tax Rate:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(NSDecimalNumber(decimal: report.estimatedTaxRate).doubleValue * 100))%")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Text("Estimated Taxes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(report.estimatedTaxes.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Export options section
    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Options")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button {
                showingExportOptions = true
            } label: {
                Label("Export Report", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Export Options Sheet

/// Sheet for export options
struct ExportOptionsSheet: View {
    let report: TaxReport
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .pdf
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Format selection
                formatSelectionSection
                
                // Export preview
                exportPreviewSection
                
                // Export button
                exportButtonSection
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    /// Format selection section
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Format")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    ExportFormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        selectedFormat = format
                    }
                }
            }
        }
    }
    
    /// Export preview section
    private var exportPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export Preview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Format:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(selectedFormat.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("File Extension:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(".\(selectedFormat.fileExtension)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Estimated Size:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("~2.5 MB")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Export button section
    private var exportButtonSection: some View {
        Button {
            exportReport()
        } label: {
            if isExporting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Label("Export \(selectedFormat.displayName)", systemImage: "square.and.arrow.up")
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .disabled(isExporting)
    }
    
    /// Export the report
    private func exportReport() {
        isExporting = true
        
        // Simulate export
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

// MARK: - Export Format Card

/// Card for export format selection
struct ExportFormatCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: format.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : format.color)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? format.color : format.color.opacity(0.1))
                    .clipShape(Circle())
                
                Text(format.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                
                Text(".\(format.fileExtension)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .padding(16)
            .background(isSelected ? format.color : Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .clear : format.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Invite User Sheet

/// Sheet for inviting users to shared accounts
struct InviteUserSheet: View {
    let financeManager: FinanceManager
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var selectedAccount: Account?
    @State private var selectedPermissions: Set<PermissionType> = [.view]
    @State private var message = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    TextField("Email address", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Account Selection") {
                    Picker("Select Account", selection: $selectedAccount) {
                        Text("Choose an account").tag(nil as Account?)
                        ForEach(financeManager.accounts) { account in
                            Text(account.name).tag(account as Account?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Permissions") {
                    ForEach(PermissionType.allCases, id: \.self) { permission in
                        Toggle(permission.displayName, isOn: Binding(
                            get: { selectedPermissions.contains(permission) },
                            set: { isSelected in
                                if isSelected {
                                    selectedPermissions.insert(permission)
                                } else {
                                    selectedPermissions.remove(permission)
                                }
                            }
                        ))
                    }
                }
                
                Section("Message (Optional)") {
                    TextField("Personal message", text: $message, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Invite User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invite") {
                        sendInvite()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && selectedAccount != nil && !selectedPermissions.isEmpty
    }
    
    private func sendInvite() {
        guard let account = selectedAccount else { return }
        
        financeManager.inviteUserToAccount(
            accountId: account.id.uuidString,
            email: email,
            permissions: Array(selectedPermissions)
        )
        
        dismiss()
    }
}

// MARK: - Shared Account Detail View

/// Detailed view for shared accounts
struct SharedAccountDetailView: View {
    let account: Account
    let financeManager: FinanceManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingInviteUser = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Account overview
                    accountOverviewSection
                    
                    // Shared users
                    sharedUsersSection
                    
                    // Recent activity
                    recentActivitySection
                    
                    // Settings
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle(account.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInviteUser) {
                InviteUserSheet(financeManager: financeManager)
            }
        }
    }
    
    /// Account overview section
    private var accountOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Overview")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: account.type.iconName)
                        .font(.title)
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(account.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(account.formattedBalance)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(account.balance >= 0 ? .green : .red)
                        
                        Text("Balance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Shared with:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(account.sharedWith?.count ?? 0) users")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// Shared users section
    private var sharedUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shared Users")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let sharedWith = account.sharedWith, !sharedWith.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(sharedWith, id: \.self) { userId in
                        SharedUserCard(userId: userId)
                    }
                }
            } else {
                Text("No users shared with this account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            
            Button {
                showingInviteUser = true
            } label: {
                Label("Invite User", systemImage: "person.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    /// Recent activity section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Recent transactions and changes would appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Settings section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button {
                    // Edit account
                } label: {
                    Label("Edit Account", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // Manage permissions
                } label: {
                    Label("Manage Permissions", systemImage: "person.badge.key")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // Remove sharing
                } label: {
                    Label("Remove Sharing", systemImage: "person.badge.minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Shared User Card

/// Card for displaying shared user information
struct SharedUserCard: View {
    let userId: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(userId)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("View & Edit")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // Manage user
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Receipt Detail View

/// Detailed view for receipts
struct ReceiptDetailView: View {
    let receipt: Transaction
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditReceipt = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Receipt image
                    receiptImageSection
                    
                    // Receipt details
                    receiptDetailsSection
                    
                    // OCR data
                    if receipt.ocrData != nil {
                        ocrDataSection
                    }
                    
                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Receipt Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditReceipt) {
                // Edit receipt sheet would go here
                Text("Edit Receipt")
            }
        }
    }
    
    /// Receipt image section
    private var receiptImageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Image")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let imageData = receipt.receiptImageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No image available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }
        }
    }
    
    /// Receipt details section
    private var receiptDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Receipt Details")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRow(title: "Merchant", value: receipt.merchant)
                DetailRow(title: "Amount", value: receipt.formattedAmount)
                DetailRow(title: "Category", value: receipt.category.name)
                DetailRow(title: "Date", value: receipt.formattedDate)
                DetailRow(title: "Account", value: receipt.account.name)
                
                if let notes = receipt.notes, !notes.isEmpty {
                    DetailRow(title: "Notes", value: notes)
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    /// OCR data section
    private var ocrDataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OCR Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if let ocrData = receipt.ocrData {
                VStack(spacing: 12) {
                    if let merchantName = ocrData.merchantName {
                        DetailRow(title: "Merchant", value: merchantName)
                    }
                    
                    if let amount = ocrData.amount {
                        DetailRow(title: "Amount", value: amount.formatted(.currency(code: "USD")))
                    }
                    
                    if let date = ocrData.date {
                        DetailRow(title: "Date", value: date.formatted(date: .long, time: .omitted))
                    }
                    
                    if let category = ocrData.category {
                        DetailRow(title: "Category", value: category)
                    }
                    
                    DetailRow(title: "Confidence", value: "\(Int(ocrData.confidence * 100))%")
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    /// Actions section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                Button {
                    showingEditReceipt = true
                } label: {
                    Label("Edit Receipt", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button {
                    // Share receipt
                } label: {
                    Label("Share Receipt", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // Delete receipt
                } label: {
                    Label("Delete Receipt", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    GenerateTaxReportSheet(financeManager: FinanceManager(), selectedYear: 2024)
        .preferredColorScheme(.light)
} 