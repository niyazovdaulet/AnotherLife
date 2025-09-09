
import SwiftUI

struct NotesView: View {
    let habit: Habit
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var notes = ""
    @State private var selectedStatus: HabitStatus = .skipped
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerView
                
                // Status Selection
                statusSelectionView
                
                // Notes Input
                notesInputView
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Habit Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
        }
        .onAppear {
            loadExistingEntry()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 16) {
            // Habit Icon
            ZStack {
                Circle()
                    .fill(Color(hex: habit.color)?.opacity(0.2) ?? Color.primaryBlue.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: habit.icon)
                    .font(.title)
                    .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
            }
            
            // Habit Info
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(habitManager.selectedDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Status Selection View
    private var statusSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How did it go?")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                ForEach(HabitStatus.allCases, id: \.self) { status in
                    Button(action: { selectedStatus = status }) {
                        VStack(spacing: 8) {
                            Image(systemName: status.icon)
                                .font(.title)
                                .foregroundColor(selectedStatus == status ? .white : status.color)
                            
                            Text(status.rawValue.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedStatus == status ? .white : .textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedStatus == status ? status.color : status.color.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Notes Input View
    private var notesInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Notes (Optional)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Text("Record your thoughts, challenges, or insights about this habit")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.backgroundGray)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Methods
    private func loadExistingEntry() {
        if let entry = habitManager.getEntry(for: habit, on: habitManager.selectedDate) {
            selectedStatus = entry.status
            notes = entry.notes
        }
    }
    
    private func saveEntry() {
        habitManager.updateEntry(for: habit, status: selectedStatus, notes: notes)
        dismiss()
    }
}

#Preview {
    NotesView(habit: Habit(title: "Exercise", description: "30 minutes of cardio"))
        .environmentObject(HabitManager())
}
