import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    let note: HabitNote?
    let selectedHabit: Habit?
    
    @State private var content: String = ""
    @State private var habitId: UUID?
    @State private var showingHabitPicker = false
    
    var isEditing: Bool {
        note != nil
    }
    
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
                    // Premium spacing and layout
                    
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
            .navigationTitle(isEditing ? "Edit Note" : "New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        saveNote()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadNoteData()
        }
        .onChange(of: note) {
            loadNoteData()
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text editor
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
        .sheet(isPresented: $showingHabitPicker) {
            HabitPickerView(selectedHabitId: $habitId)
                .environmentObject(habitManager)
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
                    
                    if !progress.isNaN && !progress.isInfinite {
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
                
                // Text Editor with soft paper-like texture
                DynamicTextEditor(text: $content, maxWords: 150)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                
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
    private func loadNoteData() {
        // Ensure we load data immediately when the view appears
        DispatchQueue.main.async {
            if let note = self.note {
                self.content = note.content
                self.habitId = note.habitId
            } else if let habit = self.selectedHabit {
                self.habitId = habit.id
            }
        }
    }
    
    
    private func saveNote() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        if let existingNote = note {
            var updatedNote = existingNote
            updatedNote.content = trimmedContent
            updatedNote.habitId = habitId
            updatedNote.updatedAt = Date() // Update timestamp
            habitManager.updateNote(updatedNote)
        } else {
            let newNote = HabitNote(
                content: trimmedContent,
                date: Date(), // Always use today
                habitId: habitId,
                tags: [] // No tags
            )
            habitManager.addNote(newNote)
        }
        
        dismiss()
    }
}

// MARK: - Habit Picker View
struct HabitPickerView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedHabitId: UUID?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(habitManager.habits) { habit in
                    Button(action: {
                        selectedHabitId = habit.id
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: habit.icon)
                                    .font(.title3)
                                    .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                            }
                            
                            Text(habit.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            if selectedHabitId == habit.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryBlue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Habit")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Dynamic Text Editor
struct DynamicTextEditor: View {
    @Binding var text: String
    @State private var textHeight: CGFloat = 150
    @State private var isEnforcingLimit = false
    @State private var debounceWorkItem: DispatchWorkItem?
    let maxWords: Int
    
    private let minHeight: CGFloat = 150
    private let maxHeight: CGFloat = 600
    private let lineHeight: CGFloat = 23.5 // Approximate line height for better calculation
    
    init(text: Binding<String>, maxWords: Int) {
        self._text = text
        self.maxWords = maxWords
        // Ensure textHeight starts with a valid value
        self._textHeight = State(initialValue: 150)
    }
    
    // Computed property to ensure textHeight is always valid
    private var safeTextHeight: CGFloat {
        let height = textHeight
        guard height > 0 && !height.isNaN && !height.isInfinite else {
            return minHeight
        }
        return max(minHeight, min(height, maxHeight))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hidden text view to calculate height
            Text(text.isEmpty ? " " : text)
                .font(.body)
                .padding(16)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                calculateHeight(from: geometry)
                            }
                            .onChange(of: text) {
                                calculateHeight(from: geometry)
                            }
                    }
                )
                .opacity(0) // Hidden
            
            // Actual TextEditor with professional styling and word limit
            TextEditor(text: $text)
                .frame(height: safeTextHeight)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .onChange(of: text) { newValue in
                    // Cancel previous work item
                    debounceWorkItem?.cancel()
                    
                    // Create new work item with debounce
                    debounceWorkItem = DispatchWorkItem {
                        enforceWordLimit(newValue: newValue)
                    }
                    
                    // Execute after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: debounceWorkItem!)
                }
                .onDisappear {
                    debounceWorkItem?.cancel()
                }
        }
    }
    
    private func calculateHeight(from geometry: GeometryProxy) {
        let calculatedHeight = geometry.size.height
        
        // Ensure we have valid values
        guard calculatedHeight > 0 && 
              !calculatedHeight.isNaN && 
              !calculatedHeight.isInfinite &&
              calculatedHeight < 10000 else { // Reasonable upper bound
            // If invalid, use the current textHeight or fallback to minHeight
            if textHeight <= 0 || textHeight.isNaN || textHeight.isInfinite {
                textHeight = minHeight
            }
            return
        }
        
        // Use the calculated height but ensure it doesn't exceed maxHeight
        let finalHeight = max(minHeight, min(calculatedHeight, maxHeight))
        
        // Double-check the final height is valid
        guard finalHeight > 0 && 
              !finalHeight.isNaN && 
              !finalHeight.isInfinite &&
              finalHeight <= maxHeight else {
            textHeight = minHeight
            return
        }
        
        // Only update if the change is significant to avoid constant updates
        if abs(textHeight - finalHeight) > 1.0 {
            textHeight = finalHeight
        }
    }
    
    private func enforceWordLimit(newValue: String) {
        // Prevent infinite loops
        guard !isEnforcingLimit else { return }
        
        let wordCount = newValue.split(separator: " ").count
        if wordCount > maxWords {
            isEnforcingLimit = true
            
            // Find the last valid position that keeps us at exactly maxWords
            let words = newValue.split(separator: " ")
            let truncatedWords = Array(words.prefix(maxWords))
            let validContent = truncatedWords.joined(separator: " ")
            
            // Only update if the content is different
            if text != validContent {
                text = validContent
            }
            
            // Reset the flag after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isEnforcingLimit = false
            }
        }
    }
}

#Preview {
    NoteEditorView(note: nil, selectedHabit: nil)
        .environmentObject(HabitManager())
}

