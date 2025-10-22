import SwiftUI

struct NewNoteView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var content: String = ""
    @State private var habitId: UUID?
    @State private var showingHabitPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Premium background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.background.opacity(0.95),
                        Color.background.opacity(0.98)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    // Habit Selector (Optional)
                    habitSelectorSection
                    
                    // Text Editor
                    textEditorSection
                    
                    // Word count and progress
                    wordCountSection
                    
                    // Motivational Footer
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 50)
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingHabitPicker) {
            HabitPickerView(selectedHabitId: $habitId)
                .environmentObject(habitManager)
        }
    }
    
    // MARK: - Habit Selector Section
    private var habitSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link to Habit (Optional)")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            Button(action: { showingHabitPicker = true }) {
                HStack(spacing: 12) {
                    if let currentHabitId = habitId,
                       let habit = habitManager.habits.first(where: { $0.id == currentHabitId }) {
                        // Selected habit
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: habit.icon)
                                .font(.title3)
                                .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Tap to change")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button(action: { habitId = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textSecondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // No habit selected
                        Image(systemName: "link.circle")
                            .font(.title2)
                            .foregroundColor(.primaryBlue)
                        
                        Text("Select a habit")
                            .font(.subheadline)
                            .foregroundColor(.primaryBlue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Word Count Section
    private var wordCountSection: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.word.spacing")
                            .font(.caption)
                            .foregroundColor(wordCountColor)
                        
                        Text("\(content.split(separator: " ").count)/150 words")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(wordCountColor)
                    }
                    
                    // Progress bar for word count
                    let wordCount = content.split(separator: " ").count
                    let progress = min(max(Double(wordCount) / 150.0, 0.0), 1.0)
                    
                    // Use isFinite for more robust validation
                    if progress.isFinite {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressBarColor))
                            .scaleEffect(y: 0.5)
                            .frame(width: 120)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.cardBackground)
                        .overlay(
                            Capsule()
                                .stroke(wordCountColor.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Limit reached warning
            if content.split(separator: " ").count >= 150 {
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text("Word limit reached! Delete some text to continue.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: content.split(separator: " ").count)
    }
    
    // MARK: - Computed Properties for Colors
    private var wordCount: Int {
        content.split(separator: " ").count
    }
    
    private var wordCountColor: Color {
        if wordCount >= 150 {
            return .red
        } else if wordCount >= 140 {
            return .orange
        } else {
            return .primaryBlue
        }
    }
    
    private var progressBarColor: Color {
        if wordCount >= 150 {
            return .red
        } else if wordCount >= 140 {
            return .orange
        } else {
            return .primaryBlue
        }
    }
    
    // MARK: - Text Editor Section
    private var textEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Thoughts")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Simple TextEditor without dynamic height calculation
                TextEditor(text: $content)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 200, maxHeight: 400)
                
                // Placeholder
                if content.isEmpty {
                    Text("Write your thoughts, observations, or reflections here...")
                        .font(.body)
                        .foregroundColor(.textSecondary.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .allowsHitTesting(false)
                }
            }
        }
    }
    
    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf.fill")
                .font(.title3)
                .foregroundColor(.primaryGreen)
            
            Text("Keep journaling your growth 🌱")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Methods
    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let newNote = HabitNote(
            content: trimmedContent,
            date: Date(),
            habitId: habitId,
            tags: []
        )
        habitManager.addNote(newNote)
        
        dismiss()
    }
}

#Preview {
    NewNoteView()
        .environmentObject(HabitManager())
}
