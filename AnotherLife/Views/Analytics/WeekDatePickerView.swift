import SwiftUI

struct WeekDatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var startDate: Date
    @Binding var endDate: Date
    @State private var tempStartDate: Date
    @State private var tempEndDate: Date
    @State private var selectionMode: SelectionMode = .start
    
    enum SelectionMode {
        case start, end
    }
    
    init(startDate: Binding<Date>, endDate: Binding<Date>) {
        self._startDate = startDate
        self._endDate = endDate
        self._tempStartDate = State(initialValue: startDate.wrappedValue)
        self._tempEndDate = State(initialValue: endDate.wrappedValue)
    }
    
    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Select Date Range")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.textPrimary)
                        .padding(.top, 20)
                    
                    // Date Range Display
                    VStack(spacing: 16) {
                        // Start Date Button
                        Button(action: {
                            selectionMode = .start
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "calendar.badge.plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primaryBlue)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.primaryBlue.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Date")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(formatDate(tempStartDate))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Spacer()
                                
                                if selectionMode == .start {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.primaryBlue)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectionMode == .start ? Color.primaryBlue.opacity(0.1) : Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectionMode == .start ? Color.primaryBlue : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // End Date Button
                        Button(action: {
                            selectionMode = .end
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "calendar.badge.minus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primaryPurple)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(Color.primaryPurple.opacity(0.1))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("End Date")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(formatDate(tempEndDate))
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Spacer()
                                
                                if selectionMode == .end {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.primaryPurple)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectionMode == .end ? Color.primaryPurple.opacity(0.1) : Color.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectionMode == .end ? Color.primaryPurple : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Validation Message
                        if tempStartDate > tempEndDate {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Start date must be before end date")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Date Picker
                    DatePicker(
                        selectionMode == .start ? "Select Start Date" : "Select End Date",
                        selection: selectionMode == .start ? $tempStartDate : $tempEndDate,
                        in: ...today,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(selectionMode == .start ? .primaryBlue : .primaryPurple)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    .onChange(of: tempStartDate) { oldValue, newValue in
                        // Ensure start date is not after end date
                        if newValue > tempEndDate {
                            tempEndDate = newValue
                        }
                    }
                    .onChange(of: tempEndDate) { oldValue, newValue in
                        // Ensure end date is not before start date
                        if newValue < tempStartDate {
                            tempStartDate = newValue
                        }
                    }
                    
                    Spacer()
                    
                    // Confirm Button
                    Button(action: {
                        startDate = tempStartDate
                        endDate = tempEndDate
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Confirm")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    tempStartDate > tempEndDate ?
                                    LinearGradient(
                                        colors: [Color.gray, Color.gray.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.primaryBlue, Color.primaryPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: tempStartDate <= tempEndDate ? .primaryBlue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                        )
                    }
                    .disabled(tempStartDate > tempEndDate)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Select Date Range")
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
