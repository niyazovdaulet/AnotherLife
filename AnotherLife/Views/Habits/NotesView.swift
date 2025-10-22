import SwiftUI

// MARK: - Main Notes Tab View
struct NotesTabView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var selectedSegment: NotesSegment = .byHabit
    @State private var showingNoteEditor = false
    @State private var selectedHabit: Habit?
    @State private var editingNote: HabitNote?
    
    enum NotesSegment: String, CaseIterable {
        case allNotes = "All Notes"
        case byHabit = "By Habit"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern background
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern header
                    modernHeaderView
                    
                    // Content
                    if filteredNotes.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                byHabitView
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingNoteEditor = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryGradient)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNoteEditor) {
            NoteEditorView(note: editingNote, selectedHabit: selectedHabit)
                .environmentObject(habitManager)
                .onDisappear {
                    // Only reset when the sheet is actually dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        editingNote = nil
                        selectedHabit = nil
                    }
                }
        }
    }
    
    // MARK: - Modern Header View
    private var modernHeaderView: some View {
        VStack(spacing: 16) {
            // Stats card
            HStack(spacing: 20) {
                // Total notes count
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(filteredNotes.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Total Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Recent activity
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(recentNotesCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryBlue)
                    
                    Text("This Week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(
                        color: .black.opacity(0.05),
                        radius: 10,
                        x: 0,
                        y: 4
                    )
            )
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Computed Properties
    private var recentNotesCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filteredNotes.filter { $0.createdAt >= weekAgo }.count
    }
    
    // MARK: - All Notes View
    private var allNotesView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredNotes) { note in
                NoteCardView(note: note, habit: getHabit(for: note), onDelete: {
                    habitManager.deleteNote(note)
                })
                    .onTapGesture {
                        editingNote = note
                        selectedHabit = getHabit(for: note)
                        showingNoteEditor = true
                    }
            }
        }
    }
    
    // MARK: - By Habit View
    private var byHabitView: some View {
        LazyVStack(spacing: 20) {
            // Group notes by habit
            ForEach(groupedByHabit.keys.sorted(by: { h1, h2 in
                // Sort by habit title
                if let habit1 = habitManager.habits.first(where: { $0.id == h1 }),
                   let habit2 = habitManager.habits.first(where: { $0.id == h2 }) {
                    return habit1.title < habit2.title
                }
                // Put "General Notes" last
                return h1 != nil && h2 == nil
            }), id: \.self) { habitId in
                VStack(alignment: .leading, spacing: 12) {
                    // Habit Header
                    if let habitId = habitId, let habit = habitManager.habits.first(where: { $0.id == habitId }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: habit.icon)
                                    .font(.title3)
                                    .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                            }
                            
                            Text(habit.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(groupedByHabit[habitId]?.count ?? 0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "note.text")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("General Notes")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(groupedByHabit[habitId]?.count ?? 0)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Notes for this habit
                    if let notes = groupedByHabit[habitId] {
                        ForEach(notes) { note in
                            NoteCardView(note: note, habit: getHabit(for: note), isCompact: true, onDelete: {
                                habitManager.deleteNote(note)
                            })
                                .onTapGesture {
                                    editingNote = note
                                    selectedHabit = getHabit(for: note)
                                    showingNoteEditor = true
                                }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Modern empty state illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(Color.primaryBlue.opacity(0.05))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(Color.primaryBlue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: .primaryBlue.opacity(0.3),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 16) {
                Text("Start Your Journey")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Capture your thoughts, track your progress, and reflect on your habit-building journey with personal notes.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }
            
            Button(action: { 
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showingNoteEditor = true
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Create Your First Note")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.primaryGradient)
                        .shadow(
                            color: .primaryBlue.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingNoteEditor)
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Computed Properties
    private var filteredNotes: [HabitNote] {
        return habitManager.getAllNotes()
    }
    
    private var groupedByHabit: [UUID?: [HabitNote]] {
        Dictionary(grouping: filteredNotes) { $0.habitId }
    }
    
    private func getHabit(for note: HabitNote) -> Habit? {
        guard let habitId = note.habitId else { return nil }
        return habitManager.habits.first { $0.id == habitId }
    }
}

// MARK: - Note Card View
struct NoteCardView: View {
    let note: HabitNote
    let habit: Habit?
    var isCompact: Bool = false
    var onDelete: (() -> Void)? = nil
    
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    var body: some View {
        ZStack {
            // Delete button background
            if showingDeleteButton {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            onDelete?()
                        }
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
            }
            
            // Main card content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    if !isCompact, let habit = habit {
                        // Habit icon and name
                        ZStack {
                            Circle()
                                .fill(Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: habit.icon)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                        }
                        
                        Text(habit.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
                        Text("•")
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
                    Spacer()
                    
                    // Last edited date
                    Text(lastEditedDateFormatter.string(from: note.updatedAt))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                // Note content preview
                Text(note.preview)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(isCompact ? 12 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                    .fill(isCompact ? Color.background : Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isCompact ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: isCompact ? .clear : .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                            showingDeleteButton = offset < -20
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            if offset < -40 {
                                offset = -60
                                showingDeleteButton = true
                            } else {
                                offset = 0
                                showingDeleteButton = false
                            }
                        }
                    }
            )
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(note.date) {
            return "Today"
        } else if calendar.isDateInYesterday(note.date) {
            return "Yesterday"
        } else if calendar.isDate(note.date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: note.date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: note.date)
        }
    }
    
    private var lastEditedDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy"
        return formatter
    }
}

#Preview {
    NotesTabView()
        .environmentObject(HabitManager())
}
