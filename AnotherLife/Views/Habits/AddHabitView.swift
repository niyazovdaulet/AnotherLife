
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
            Group {
                if !isCreatingCustom && selectedTemplates.isEmpty && !showingHabitForm {
                    templateSelectionView
                } else {
                    customHabitFormView
                }
            }
            .navigationTitle(isCreatingCustom ? "Custom Habit" : (showingHabitForm ? "Create Habit" : "New Habit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showingHabitForm && !isCreatingCustom {
                        Button("Back") {
                            showingHabitForm = false
                            selectedTemplate = nil
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
                    }
                }
            }
        }
    }
    
    // MARK: - Template Selection View
    private var templateSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                    
                    Text("Choose a Habit Template")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)
                    
                    Text("Start with a proven template or create your own")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Create Custom Button
                Button(action: { isCreatingCustom = true }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .font(.title3)
                        
                        Text("Create Custom Habit")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryBlue)
                    )
                }
                .padding(.horizontal, 20)
                
                // Selected Templates Count
                if !selectedTemplates.isEmpty {
                    HStack {
                        Text("\(selectedTemplates.count) template\(selectedTemplates.count == 1 ? "" : "s") selected")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Button("Continue") {
                            // Move to form view with first selected template
                            if let firstTemplate = selectedTemplates.first {
                                selectTemplate(firstTemplate)
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryBlue)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Templates Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(StarterHabits.templates.prefix(8), id: \.id) { template in
                        TemplateCardView(
                            template: template,
                            isSelected: selectedTemplates.contains(template)
                        ) {
                            toggleTemplateSelection(template)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Custom Habit Form View
    private var customHabitFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Form
                VStack(spacing: 20) {
                    // Basic Info
                    basicInfoSection
                    
                    // Frequency Selection
                    frequencySection
                    
                    // Custom Days (if weekly)
                    if frequency == .custom {
                        customDaysSection
                    }
                    
                    // Duration Selection
                    durationSection
                    
                    // Target Completions (if more than 1)
                    if targetCompletionsPerDay > 1 {
                        targetCompletionsSection
                    }
                    
                    // Habit Type
                    habitTypeSection
                    
                    // Customization
                    customizationSection
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.primaryBlue)
            
            Text("Create a New Habit")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            Text("Build better habits, one day at a time")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 16) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("Habit Title")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("e.g., Exercise for 30 minutes", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    TextField("Add a note about this habit", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
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
    
    // MARK: - Frequency Section
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequency")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(spacing: 12) {
                ForEach(HabitFrequency.allCases, id: \.self) { freq in
                    Button(action: { frequency = freq }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(freq.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.textPrimary)
                                
                                Text(frequencyDescription(freq))
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: frequency == freq ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(frequency == freq ? .primaryBlue : .textSecondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(frequency == freq ? Color.primaryBlue.opacity(0.1) : Color.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(frequency == freq ? Color.primaryBlue : Color.clear, lineWidth: 2)
                                )
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
    
    // MARK: - Custom Days Section
    private var customDaysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Days")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(0..<7, id: \.self) { day in
                    Button(action: { toggleDay(day) }) {
                        Text(dayName(day))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(customDays.contains(day) ? .white : .textPrimary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(customDays.contains(day) ? Color.primaryBlue : Color.background)
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
    
    // MARK: - Habit Type Section
    private var habitTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Habit Type")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            HStack(spacing: 16) {
                // Positive Habit
                Button(action: { isPositive = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(isPositive ? .primaryGreen : .textSecondary)
                        
                        Text("Positive")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Good habit to build")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isPositive ? Color.primaryGreen.opacity(0.1) : Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isPositive ? Color.primaryGreen : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Negative Habit
                Button(action: { isPositive = false }) {
                    VStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(!isPositive ? .primaryRed : .textSecondary)
                        
                        Text("Negative")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.textPrimary)
                        
                        Text("Bad habit to break")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!isPositive ? Color.primaryRed.opacity(0.1) : Color.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(!isPositive ? Color.primaryRed : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Duration Section
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            // Fixed Duration - Single Option
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fixed Duration")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text("Set a specific number of days")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.primaryBlue)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primaryBlue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primaryBlue, lineWidth: 2)
                    )
            )
            
            // Duration Details
            VStack(alignment: .leading, spacing: 12) {
                Text("Duration: \(customDurationDays) days")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text("21")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Slider(value: Binding(
                        get: { Double(customDurationDays) },
                        set: { customDurationDays = Int($0) }
                    ), in: 21...365, step: 1)
                    .accentColor(.primaryBlue)
                    
                    Text("365")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
            )
            
            // Target Completions Per Day
            VStack(alignment: .leading, spacing: 12) {
                Text("Target Completions Per Day")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                HStack {
                    Text("1")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    
                    Slider(value: Binding(
                        get: { Double(targetCompletionsPerDay) },
                        set: { targetCompletionsPerDay = Int($0) }
                    ), in: 1...10, step: 1)
                    .accentColor(.primaryBlue)
                    
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
                    .fill(Color.background)
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Target Completions Section
    private var targetCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Multi-Completion Setup")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("This habit requires \(targetCompletionsPerDay) completion\(targetCompletionsPerDay == 1 ? "" : "s") per day.")
                    .font(.body)
                    .foregroundColor(.textPrimary)
                
                Text("Examples:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Prayer 5 times per day")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("• Drink 8 glasses of water")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("• Exercise twice daily")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primaryBlue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primaryBlue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Customization Section
    private var customizationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Customization")
                .font(.headline)
                .foregroundColor(.textPrimary)
            
            // Color Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Color")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                    ForEach(availableColors, id: \.self) { color in
                        Button(action: { selectedColor = color }) {
                            Circle()
                                .fill(Color(hex: color) ?? .primaryBlue)
                                .frame(width: 35, height: 35)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.primaryBlue : Color.clear, lineWidth: 1)
                                )
                                .scaleEffect(selectedColor == color ? 1.1 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Icon Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(availableIcons, id: \.self) { icon in
                        Button(action: { selectedIcon = icon }) {
                            Image(systemName: icon)
                                .font(.title3)
                                .foregroundColor(selectedIcon == icon ? .white : .textPrimary)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.primaryBlue : Color.background)
                                )
                                .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
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
    
    // MARK: - Helper Methods
    private var isUnlimitedDuration: Bool {
        if case .unlimited = duration {
            return true
        }
        return false
    }
    
    
    private func toggleTemplateSelection(_ template: HabitTemplate) {
        // Open the habit form with the selected template data
        selectedTemplate = template
        selectTemplate(template)
        showingHabitForm = true
    }
    
    private func selectTemplate(_ template: HabitTemplate) {
        title = template.title
        description = template.description
//        frequency = template.suggestedFrequency
        isPositive = template.isPositive
        selectedColor = template.colorHex
        selectedIcon = template.icon
    }
    
    private func frequencyDescription(_ frequency: HabitFrequency) -> String {
        switch frequency {
        case .daily:
            return "Every day"
        case .weekly:
            return "Once per week"
        case .custom:
            return "Custom schedule"
        }
    }
    
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
        if isCreatingCustom {
            // Save custom habit
            let habit = Habit(
                title: title,
                description: description,
                frequency: frequency,
                customDays: customDays,
                isPositive: isPositive,
                color: selectedColor,
                icon: selectedIcon,
                duration: duration,
                targetCompletionsPerDay: targetCompletionsPerDay,
                startDate: Date()
            )
            habitManager.addHabit(habit)
        } else if showingHabitForm && selectedTemplate != nil {
            // Save single template-based habit (from form)
            let habit = Habit(
                title: title,
                description: description,
                frequency: frequency,
                customDays: customDays,
                isPositive: isPositive,
                color: selectedColor,
                icon: selectedIcon,
                duration: duration,
                targetCompletionsPerDay: targetCompletionsPerDay,
                startDate: Date()
            )
            habitManager.addHabit(habit)
        } else {
            // Save selected templates as habits (batch mode)
            for template in selectedTemplates {
                let habit = Habit(
                    title: template.title,
                    description: template.description,
                    frequency: template.suggestedFrequency,
                    customDays: [],
                    isPositive: template.isPositive,
                    color: template.colorHex,
                    icon: template.icon,
                    duration: .fixed(days: 21), // Templates default to 21 days
                    targetCompletionsPerDay: 1, // Templates default to single completion
                    startDate: Date()
                )
                habitManager.addHabit(habit)
            }
        }
        dismiss()
    }
}

// MARK: - Template Card View
struct TemplateCardView: View {
    let template: HabitTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Card Content
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(templateColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundColor(templateColor)
                }
                
                // Title
                Text(template.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 44)
                
                // Description
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32)
                
//                // Frequency Badge
//                Text(template.suggestedFrequency.displayName)
//                    .font(.caption2)
//                    .fontWeight(.medium)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 4)
//                    .background(
//                        Capsule()
//                            .fill(templateColor.opacity(0.2))
//                    )
                    .foregroundColor(templateColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? templateColor.opacity(0.1) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? templateColor : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            
            // Selection Button - Top Right Corner
            Button(action: onTap) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(isSelected ? .primaryGreen : .textSecondary)
                    .background(
                        Circle()
                            .fill(Color.cardBackground)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(8)
        }
    }
    
    private var templateColor: Color {
        Color(hex: template.colorHex) ?? .primaryBlue
    }
}

#Preview {
    AddHabitView() 
        .environmentObject(HabitManager())
}
