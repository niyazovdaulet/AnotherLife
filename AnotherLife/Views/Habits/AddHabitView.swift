
import SwiftUI

struct AddHabitView: View {
    @EnvironmentObject var habitManager: HabitManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var frequency: HabitFrequency = .daily
    @State private var isPositive = true
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "star.fill"
    @State private var customDays: [Int] = []
    @State private var selectedTemplates = Set<HabitTemplate>()
    @State private var isCreatingCustom = false
    @State private var showingHabitForm = false
    @State private var selectedTemplate: HabitTemplate?
    
    // New state variables for enhanced functionality
    @State private var duration: HabitDuration = .fixed(days: 21)
    @State private var targetCompletionsPerDay = 1
    @State private var customDurationDays = 21
    
    // Animation states
    @State private var showSuccessAnimation = false
    @State private var addedHabitId: UUID?
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink", "teal", "indigo",
        "mint", "yellow", "brown", "gray", "cyan", "magenta", "lime", "navy"
    ]
    private let availableIcons = [
        // Health & Fitness
        "heart.fill", "flame.fill", "figure.walk", "figure.run", "dumbbell.fill", "bicycle",
        "figure.strengthtraining.traditional", "figure.yoga", "figure.pilates", "figure.core.training",
        
        // Learning & Productivity
        "book.fill", "pencil", "graduationcap.fill", "brain.head.profile", "lightbulb.fill",
        "paintbrush.fill", "music.note", "camera.fill", "paintpalette.fill", "puzzlepiece.fill",
        
        // Lifestyle & Habits
        "moon.fill", "sun.max.fill", "drop.fill", "leaf.fill", "tree.fill", "house.fill",
        "car.fill", "airplane", "train.side.front.car", "scooter", "gamecontroller.fill",
        
        // Work & Study
        "laptopcomputer", "desktopcomputer", "printer.fill", "doc.text.fill", "folder.fill",
        "envelope.fill", "phone.fill", "video.fill", "mic.fill", "speaker.wave.3.fill",
        
        // Food & Drink
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "birthday.cake", "carrot.fill",
        "apple.logo", "fish.fill", "pawprint.fill", "bird.fill",
        
        // Social & Communication
        "person.2.fill", "person.3.fill", "message.fill", "bubble.left.fill", "bubble.right.fill", 
        "hand.raised.fill", "hand.thumbsup.fill",
        
        // Technology & Digital
        "iphone", "ipad", "applewatch", "airpods", "headphones", "wifi", "antenna.radiowaves.left.and.right", 
        "wave.3.right", "wave.3.left",
        
        // Miscellaneous
        "star.fill", "bolt.fill", "sparkles", "wand.and.stars", "crown.fill",
        "gift.fill", "party.popper.fill", "balloon.fill", "party.popper"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content
                Group {
                    if !isCreatingCustom && selectedTemplates.isEmpty && !showingHabitForm {
                        templateSelectionView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    } else {
                        customHabitFormView
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isCreatingCustom)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingHabitForm)
                
                // Success animation overlay
                if showSuccessAnimation {
                    SuccessAnimationView()
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1000)
                }
            }
            .navigationTitle(isCreatingCustom ? "Custom Habit" : (showingHabitForm ? "Create Habit" : "New Habit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showingHabitForm && !isCreatingCustom {
                        Button("Back") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingHabitForm = false
                                selectedTemplate = nil
                            }
                        }
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                if isCreatingCustom || !selectedTemplates.isEmpty || showingHabitForm {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveHabits()
                        }
                        .disabled(title.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Template Selection View
    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Modern Header with Gradient
                VStack(spacing: 16) {
                    // Animated Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBlue.opacity(0.2), Color.primaryPurple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("New Habit")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                        
                        Text("Choose a template or create your own")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.bottom, 32)
                
                // Create Custom Button - Premium Design
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isCreatingCustom = true
                    }
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Create Custom Habit")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color.primaryBlue.opacity(0.4), radius: 20, x: 0, y: 10)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Templates Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Popular Templates")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 24)
                    
                    // Modern Grid Layout
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(StarterHabits.templates.prefix(8), id: \.id) { template in
                            ModernTemplateCard(
                                template: template,
                                isSelected: selectedTemplates.contains(template)
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    toggleTemplateSelection(template)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Custom Habit Form View
    private var customHabitFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Minimal Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.primaryBlue.opacity(0.15), Color.primaryPurple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Create a New Habit")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Build better habits, one day at a time")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                // Form Sections
                VStack(spacing: 20) {
                    modernBasicInfoSection
//                    modernFrequencySection
                    
//                    if frequency == .custom {
//                        modernCustomDaysSection
//                    }
                    
                    modernDurationSection
                    
                    if targetCompletionsPerDay > 1 {
                        modernTargetCompletionsSection
                    }
                    
                    modernHabitTypeSection
                    modernCustomizationSection
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Modern Basic Info Section
    private var modernBasicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 16) {
                // Title Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., Exercise for 30 minutes", text: $title)
                        .textFieldStyle(ModernTextFieldStyle())
                }
                
                // Description Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Add a note about this habit", text: $description)
                        .textFieldStyle(ModernTextFieldStyle())
                }
            }
        }
        .padding(20)
        .background(ModernCardBackground())
    }
    
//    // MARK: - Modern Frequency Section
//    private var modernFrequencySection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Frequency")
//                .font(.system(size: 18, weight: .bold, design: .rounded))
//                .foregroundColor(.textPrimary)
//            
//            VStack(spacing: 12) {
//                ForEach(HabitFrequency.allCases, id: \.self) { freq in
//                    ModernFrequencyButton(
//                        frequency: freq,
//                        isSelected: frequency == freq,
//                        description: frequencyDescription(freq)
//                    ) {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                            frequency = freq
//                        }
//                    }
//                }
//            }
//        }
//        .padding(20)
//        .background(ModernCardBackground())
//    }
    
    // MARK: - Modern Custom Days Section
    private var modernCustomDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Days")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { day in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            toggleDay(day)
                        }
                    }) {
                        Text(dayName(day))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(customDays.contains(day) ? .white : .textPrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Group {
                                    if customDays.contains(day) {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.primaryBlue, Color.primaryPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    } else {
                                        Circle()
                                            .fill(Color.cardBackground)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.separator, lineWidth: 1)
                                            )
                                    }
                                }
                            )
                            .scaleEffect(customDays.contains(day) ? 1.1 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(ModernCardBackground())
    }
    
    // MARK: - Modern Duration Section
    private var modernDurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Duration")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            // Fixed Duration Card
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Fixed Duration")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text("Set a specific number of days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.primaryBlue.opacity(0.1), Color.primaryPurple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.primaryBlue.opacity(0.5), Color.primaryPurple.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            
            // Duration Slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(customDurationDays) days")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                HStack {
                    Text("21")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Slider(value: Binding(
                        get: { Double(customDurationDays) },
                        set: { customDurationDays = Int($0) }
                    ), in: 21...365, step: 1)
                    .tint(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    Text("365")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
            
            // Target Completions Slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Target Per Day")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text("\(targetCompletionsPerDay)x")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Slider(value: Binding(
                        get: { Double(targetCompletionsPerDay) },
                        set: { targetCompletionsPerDay = Int($0) }
                    ), in: 1...10, step: 1)
                    .tint(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    
                    Text("10")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Text("\(targetCompletionsPerDay) completion\(targetCompletionsPerDay == 1 ? "" : "s") per day")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cardBackground)
            )
        }
        .padding(20)
        .background(ModernCardBackground())
    }
    
    // MARK: - Modern Target Completions Section
    private var modernTargetCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.primaryBlue, Color.primaryPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Multi-Completion Setup")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            
            Text("This habit requires \(targetCompletionsPerDay) completion\(targetCompletionsPerDay == 1 ? "" : "s") per day.")
                .font(.subheadline)
                .foregroundColor(.textPrimary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.primaryBlue.opacity(0.1), Color.primaryPurple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.primaryBlue.opacity(0.3), Color.primaryPurple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    // MARK: - Modern Habit Type Section
    private var modernHabitTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Type")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                ModernHabitTypeButton(
                    icon: "checkmark.circle.fill",
                    title: "Positive",
                    subtitle: "Good habit to build",
                    isSelected: isPositive,
                    gradient: [Color.primaryGreen, Color.mint]
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPositive = true
                    }
                }
                
                ModernHabitTypeButton(
                    icon: "xmark.circle.fill",
                    title: "Negative",
                    subtitle: "Bad habit to break",
                    isSelected: !isPositive,
                    gradient: [Color.primaryRed, Color.orange]
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPositive = false
                    }
                }
            }
        }
        .padding(20)
        .background(ModernCardBackground())
    }
    
    // MARK: - Modern Customization Section
    private var modernCustomizationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Customization")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.textPrimary)
            
            // Color Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Color")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(availableColors, id: \.self) { color in
                        ModernColorButton(
                            color: color,
                            isSelected: selectedColor == color
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedColor = color
                            }
                        }
                    }
                }
            }
            
            // Icon Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(availableIcons, id: \.self) { icon in
                        ModernIconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon,
                            color: selectedColor
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedIcon = icon
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(ModernCardBackground())
    }
    
    // MARK: - Helper Methods
    private func toggleTemplateSelection(_ template: HabitTemplate) {
        selectedTemplate = template
        selectTemplate(template)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showingHabitForm = true
        }
    }
    
    private func selectTemplate(_ template: HabitTemplate) {
        title = template.title
        description = template.description
        isPositive = template.isPositive
        selectedColor = template.colorHex
        selectedIcon = template.icon
    }
    
//    private func frequencyDescription(_ frequency: HabitFrequency) -> String {
//        switch frequency {
//        case .daily:
//            return "Every day"
//        case .weekly:
//            return "Once per week"
//        case .custom:
//            return "Custom schedule"
//        }
//    }
    
    private func dayName(_ day: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[day]
    }
    
    private func toggleDay(_ day: Int) {
        if customDays.contains(day) {
            customDays.removeAll { $0 == day }
        } else {
            customDays.append(day)
        }
    }
    
    private func saveHabits() {
        // Show success animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showSuccessAnimation = true
        }
        
        // Create and save habits
        var savedHabitIds: [UUID] = []
        
        if isCreatingCustom {
            let habit = Habit(
                title: title,
                description: description,
//                frequency: frequency,
                customDays: customDays,
                isPositive: isPositive,
                color: selectedColor,
                icon: selectedIcon,
                duration: duration,
                targetCompletionsPerDay: targetCompletionsPerDay,
                startDate: Date()
            )
            habitManager.addHabit(habit)
            savedHabitIds.append(habit.id)
        } else if showingHabitForm && selectedTemplate != nil {
            let habit = Habit(
                title: title,
                description: description,
//                frequency: frequency,
                customDays: customDays,
                isPositive: isPositive,
                color: selectedColor,
                icon: selectedIcon,
                duration: duration,
                targetCompletionsPerDay: targetCompletionsPerDay,
                startDate: Date()
            )
            habitManager.addHabit(habit)
            savedHabitIds.append(habit.id)
        } else {
            for template in selectedTemplates {
                let habit = Habit(
                    title: template.title,
                    description: template.description,
//                    frequency: template.suggestedFrequency,
                    customDays: [],
                    isPositive: template.isPositive,
                    color: template.colorHex,
                    icon: template.icon,
                    duration: .fixed(days: 21),
                    targetCompletionsPerDay: 1,
                    startDate: Date()
                )
                habitManager.addHabit(habit)
                savedHabitIds.append(habit.id)
            }
        }
        
        // Hide animation and dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                showSuccessAnimation = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - Modern Template Card
struct ModernTemplateCard: View {
    let template: HabitTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    templateColor.opacity(0.2),
                                    templateColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: template.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [templateColor, templateColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title
                Text(template.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 40)
                
                // Description
                Text(template.description)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                templateColor.opacity(0.15),
                                templateColor.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.cardBackground, Color.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? templateColor.opacity(0.6) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isSelected ? templateColor.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 8,
                        x: 0,
                        y: isSelected ? 6 : 4
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var templateColor: Color {
        Color(hex: template.colorHex) ?? .primaryBlue
    }
}

// MARK: - Modern Frequency Button
struct ModernFrequencyButton: View {
    let frequency: HabitFrequency
    let isSelected: Bool
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(frequency.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryBlue : Color.clear)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.separator, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color.primaryBlue.opacity(0.1), Color.primaryPurple.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.cardBackground, Color.cardBackground],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(
                                    colors: [Color.primaryBlue.opacity(0.5), Color.primaryPurple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear, Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 1.5 : 0
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Habit Type Button
struct ModernHabitTypeButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                gradient[0].opacity(0.15),
                                gradient[1].opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.cardBackground, Color.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Color Button
struct ModernColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color) ?? .primaryBlue)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.primaryBlue, Color.primaryPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 2 : 0
                        )
                )
                .shadow(
                    color: isSelected ? Color(hex: color)?.opacity(0.4) ?? Color.primaryBlue.opacity(0.4) : Color.clear,
                    radius: isSelected ? 8 : 0
                )
                .scaleEffect(isSelected ? 1.15 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Modern Icon Button
struct ModernIconButton: View {
    let icon: String
    let isSelected: Bool
    let color: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    ZStack {
                        if isSelected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: color) ?? .primaryBlue,
                                            (Color(hex: color) ?? .primaryBlue).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            Circle()
                                .fill(Color.cardBackground)
                                .overlay(
                                    Circle()
                                        .stroke(Color.separator, lineWidth: 1)
                                )
                        }
                    }
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Success Animation View
struct SuccessAnimationView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // Success content
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primaryGreen, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primaryGreen, Color.mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                Text("Habit Added!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

#Preview {
    AddHabitView() 
        .environmentObject(HabitManager())
}

