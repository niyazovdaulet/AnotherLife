import SwiftUI

// MARK: - Main Notes Tab View
struct NotesTabView: View {
    @EnvironmentObject var habitManager: HabitManager
    @State private var selectedSegment: NotesSegment = .byHabit
    @State private var showingNewNote = false
    @State private var editingNote: HabitNote?
    @State private var swipedNoteId: UUID? = nil
    
    enum NotesSegment: String, CaseIterable {
        case allNotes = "All Notes"
        case byHabit = "By Habit"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.background,
                        Color.background.opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced header with premium styling
                    enhancedHeaderView
                    
                    // Content with smooth animations
                    if filteredNotes.isEmpty {
                        emptyStateView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                byHabitView
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 20)
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { 
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        showingNewNote = true
                    }) {
                        ZStack {
                            // Enhanced button with glow effect
                            Circle()
                                .fill(Color.primaryGradient)
                                .frame(width: 40, height: 40)
                                .shadow(
                                    color: .primaryBlue.opacity(0.4),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                            
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .fullScreenCover(isPresented: $showingNewNote) {
            NewNoteView()
                .environmentObject(habitManager)
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { editingNote != nil },
            set: { if !$0 { editingNote = nil } }
        )) {
            if let note = editingNote {
                EditNoteView(note: note)
                    .environmentObject(habitManager)
            }
        }
    }
    
    // MARK: - Enhanced Header View
    private var enhancedHeaderView: some View {
        VStack(spacing: 20) {
            // Premium stats section with glass morphism
            HStack(spacing: 0) {
                // Total notes card
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryBlue.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "note.text")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primaryBlue)
                        }
                        
                        Text("Total Notes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Text("\(filteredNotes.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                )
                
                Spacer(minLength: 16)
                
                // Recent activity card
                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("This Week")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textSecondary)
                        
                        ZStack {
                            Circle()
                                .fill(Color.primaryPurple.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "calendar")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primaryPurple)
                        }
                    }
                    
                    Text("\(recentNotesCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryPurple)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: .black.opacity(0.1),
                            radius: 15,
                            x: 0,
                            y: 8
                        )
                )
            }
            .padding(.horizontal, 20)
            
            // Today's date section (without Quick Note button)
            if !filteredNotes.isEmpty {
                HStack {
                    // Today's date label
                    Text(todayDateString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .animation(.easeInOut(duration: 0.3), value: filteredNotes.isEmpty)
    }
    
    // MARK: - Computed Properties
    private var recentNotesCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return filteredNotes.filter { $0.createdAt >= weekAgo }.count
    }
    
    private var habitsWithNotesCount: Int {
        let habitsWithNotes = Set(filteredNotes.compactMap { $0.habitId })
        return habitsWithNotes.count
    }
    
    private var averageNotesPerHabit: Int {
        guard habitsWithNotesCount > 0 else { return 0 }
        return Int(Double(recentNotesCount) / Double(habitsWithNotesCount))
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    // MARK: - All Notes View
    private var allNotesView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredNotes) { note in
                NoteCardView(
                    note: note,
                    habit: getHabit(for: note),
                    isSwipedOpen: swipedNoteId == note.id,
                    onDelete: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            habitManager.deleteNote(note)
                            swipedNoteId = nil
                        }
                    },
                    onSwipeChanged: { isOpen in
                        swipedNoteId = isOpen ? note.id : nil
                    },
                    onCardTapped: {
                        // Handle card tap
                        if swipedNoteId == note.id {
                            // Close swipe
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                swipedNoteId = nil
                            }
                        } else if swipedNoteId == nil {
                            // Edit note
                            editingNote = note
                        } else {
                            // Close other open swipe first
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                swipedNoteId = nil
                            }
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - By Habit View
    private var byHabitView: some View {
        LazyVStack(spacing: 24) {
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
                VStack(alignment: .leading, spacing: 16) {
                    // Enhanced Habit Header
                    if let habitId = habitId, let habit = habitManager.habits.first(where: { $0.id == habitId }) {
                        HStack(spacing: 16) {
                            // Enhanced habit icon with glow effect
                            ZStack {
                                // Glow effect
                                Circle()
                                    .fill(Color(hex: habit.color)?.opacity(0.2) ?? Color.primaryBlue.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                    .blur(radius: 6)
                                
                                // Main icon container
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: habit.color)?.opacity(0.15) ?? Color.primaryBlue.opacity(0.15),
                                                    Color(hex: habit.color)?.opacity(0.05) ?? Color.primaryBlue.opacity(0.05)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                    
                                    Circle()
                                        .stroke(Color(hex: habit.color)?.opacity(0.3) ?? Color.primaryBlue.opacity(0.3), lineWidth: 2)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: habit.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(habit.title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("\(groupedByHabit[habitId]?.count ?? 0) notes")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Notes count badge
                            Text("\(groupedByHabit[habitId]?.count ?? 0)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color(hex: habit.color) ?? .primaryBlue)
                                        .shadow(
                                            color: Color(hex: habit.color)?.opacity(0.4) ?? .primaryBlue.opacity(0.4),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                        }
                    } else {
                        HStack(spacing: 16) {
                            // General notes icon
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "note.text")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("General Notes")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.textPrimary)
                                
                                Text("\(groupedByHabit[habitId]?.count ?? 0) notes")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Notes count badge
                            Text("\(groupedByHabit[habitId]?.count ?? 0)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.gray)
                                        .shadow(
                                            color: .gray.opacity(0.4),
                                            radius: 8,
                                            x: 0,
                                            y: 4
                                        )
                                )
                        }
                    }
                    
                    // Notes for this habit with enhanced spacing
                    if let notes = groupedByHabit[habitId] {
                        LazyVStack(spacing: 12) {
                            ForEach(notes) { note in
                                NoteCardView(
                                    note: note,
                                    habit: getHabit(for: note),
                                    isCompact: true,
                                    isSwipedOpen: swipedNoteId == note.id,
                                    onDelete: {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                            habitManager.deleteNote(note)
                                            swipedNoteId = nil
                                        }
                                    },
                                    onSwipeChanged: { isOpen in
                                        swipedNoteId = isOpen ? note.id : nil
                                    },
                                    onCardTapped: {
                                        // Handle card tap
                                        if swipedNoteId == note.id {
                                            // Close swipe
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                swipedNoteId = nil
                                            }
                                        } else if swipedNoteId == nil {
                                            // Edit note
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            editingNote = note
                                        } else {
                                            // Close other open swipe first
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                swipedNoteId = nil
                                            }
                                        }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .bottom))
                                ))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: notes.map(\.id))
                    }
                }
                .padding(20)
                .background(
                    ZStack {
                        // Glass-like background with gradient
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Material.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.2),
                                                Color.white.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        
                        // Subtle accent border
                        if let habitId = habitId, let habit = habitManager.habits.first(where: { $0.id == habitId }) {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: habit.color)?.opacity(0.3) ?? Color.primaryBlue.opacity(0.3),
                                            Color(hex: habit.color)?.opacity(0.1) ?? Color.primaryBlue.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    }
                )
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 16,
                    x: 0,
                    y: 8
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .bottom))
                ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: groupedByHabit.keys.map { $0 })
    }
    
    // MARK: - Enhanced Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Enhanced empty state illustration with animations
            ZStack {
                // Animated background circles
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.08),
                                Color.primaryPurple.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.primaryBlue.opacity(0.12),
                                Color.primaryPurple.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 15)
                
                // Main icon with enhanced styling
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color.primaryGradient)
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                        .opacity(0.6)
                    
                    // Main icon container
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.primaryBlue.opacity(0.2),
                                        Color.primaryPurple.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)
                        
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.primaryBlue.opacity(0.4),
                                        Color.primaryPurple.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 90, height: 90)
                        
                        Image(systemName: "note.text")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            VStack(spacing: 20) {
                Text("Start Your Journey")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text("Capture your thoughts, track your progress, and reflect on your habit-building journey with personal notes.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 24)
            }
            
            // Enhanced CTA button
            Button(action: { 
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                showingNewNote = true
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Create Your First Note")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 18)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.primaryGradient)
                            .shadow(
                                color: .primaryBlue.opacity(0.4),
                                radius: 16,
                                x: 0,
                                y: 8
                            )
                        
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingNewNote)
            
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

// MARK: - Enhanced Note Card View
struct NoteCardView: View {
    let note: HabitNote
    let habit: Habit?
    var isCompact: Bool = false
    var isSwipedOpen: Bool = false
    var onDelete: (() -> Void)? = nil
    var onSwipeChanged: ((Bool) -> Void)? = nil
    var onCardTapped: (() -> Void)? = nil
    
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    @State private var isPressed = false
    @State private var isDragging = false // Track if currently dragging to prevent animation conflicts
    
    var body: some View {
        ZStack {
            // Enhanced delete button background
            if showingDeleteButton {
                HStack {
                    Spacer()
                    // Delete button is now just visual - deletion happens via full swipe
                    Button(action: {
                        // Visual feedback only - actual delete happens on full swipe
                        // User can tap to close the swipe
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                            showingDeleteButton = false
                            onSwipeChanged?(false)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Delete")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(
                                    color: .red.opacity(0.4),
                                    radius: 8,
                                    x: 0,
                                    y: 4
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                    .zIndex(10) // High z-index to ensure delete button is on top
                }
            }
            
            // Enhanced main card content
            VStack(alignment: .leading, spacing: 14) {
                // Enhanced header
                HStack(spacing: 12) {
                    if !isCompact, let habit = habit {
                        // Enhanced habit icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: habit.color)?.opacity(0.2) ?? Color.primaryBlue.opacity(0.2),
                                            Color(hex: habit.color)?.opacity(0.1) ?? Color.primaryBlue.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Circle()
                                .stroke(Color(hex: habit.color)?.opacity(0.3) ?? Color.primaryBlue.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: habit.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: habit.color) ?? .primaryBlue)
                        }
                        
                        Text(habit.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("•")
                            .foregroundColor(.textSecondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    // Enhanced last edited indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 7, height: 7)
                        
                        Text(lastEditedDateFormatter.string(from: note.updatedAt))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                // Enhanced note content preview
                Text(note.preview)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                
                // Word count indicator
                HStack {
                    Spacer()
                    
                    Text("\(note.content.split(separator: " ").count) words")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                }
            }
            .padding(isCompact ? 16 : 20)
            .background(
                ZStack {
                    // Enhanced background with glass morphism
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isCompact ? Material.ultraThinMaterial : Material.thinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(isCompact ? 0.2 : 0.1),
                                            Color.white.opacity(isCompact ? 0.05 : 0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    
                    // Subtle accent for habit-linked notes
                    if let habit = habit {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: habit.color)?.opacity(0.2) ?? Color.primaryBlue.opacity(0.2),
                                        Color(hex: habit.color)?.opacity(0.05) ?? Color.primaryBlue.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
            )
            .shadow(
                color: .black.opacity(isCompact ? 0.05 : 0.08),
                radius: isCompact ? 8 : 12,
                x: 0,
                y: isCompact ? 2 : 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(x: offset)
            .zIndex(1) // Card content is below delete button
            .animation(isDragging ? nil : .default, value: offset) // Disable animation during drag
            .onChange(of: isSwipedOpen) { oldValue, newValue in
                // Sync with external state changes (e.g., when another card is swiped)
                // Only update if we're not currently dragging to avoid animation conflicts
                guard !isDragging else { return }
                
                DispatchQueue.main.async {
                    if !newValue && showingDeleteButton {
                        // Close swipe
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                            showingDeleteButton = false
                        }
                    } else if newValue && !showingDeleteButton {
                        // Open swipe
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = -60
                            showingDeleteButton = true
                        }
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Mark that we're dragging to prevent other animations
                        isDragging = true
                        
                        // Disable all animations during drag to prevent conflicts
                        var transaction = Transaction(animation: nil)
                        transaction.disablesAnimations = true
                        
                        withTransaction(transaction) {
                            if value.translation.width < 0 {
                                // Swiping left to reveal delete
                                // Allow swiping up to -120 to show delete fully and indicate deletion threshold
                                offset = max(value.translation.width, -120)
                                showingDeleteButton = offset < -20
                            } else if value.translation.width > 0 && showingDeleteButton {
                                // Swiping right to hide delete
                                offset = min(value.translation.width - 60, 0)
                                showingDeleteButton = offset < -20
                            }
                        }
                    }
                    .onEnded { value in
                        // Mark that dragging has ended
                        isDragging = false
                        
                        let swipeDistance = value.translation.width
                        let deleteThreshold: CGFloat = -100 // Swipe past this to delete
                        
                        // Check if swiped far enough to delete
                        if swipeDistance < deleteThreshold {
                            // Delete the note
                            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                            impactFeedback.impactOccurred()
                            
                            // Animate off screen, then delete
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = -200
                            }
                            
                            // Delete after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDelete?()
                            }
                        } else {
                            // Determine final state (show/hide delete button or snap back)
                            let shouldShowDelete = swipeDistance < -40
                            let shouldHideDelete = swipeDistance > 20 && showingDeleteButton
                            
                            // Animate to final state (only after drag ends)
                            DispatchQueue.main.async {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if shouldShowDelete {
                                        // Snap to open position (delete button visible)
                                        offset = -60
                                        showingDeleteButton = true
                                        onSwipeChanged?(true)
                                    } else if shouldHideDelete {
                                        // Snap to closed position when swiping right
                                        offset = 0
                                        showingDeleteButton = false
                                        onSwipeChanged?(false)
                                    } else {
                                        // Snap back to current state
                                        if showingDeleteButton {
                                            offset = -60
                                        } else {
                                            offset = 0
                                        }
                                    }
                                }
                            }
                        }
                    }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if showingDeleteButton {
                    // Close swipe when tapping card
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                        showingDeleteButton = false
                        onSwipeChanged?(false)
                    }
                } else {
                    // Normal tap - edit note
                    onCardTapped?()
                }
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            } perform: {
                // Long press action if needed
            }
        }
        .clipped() // Ensure content doesn't overflow
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
