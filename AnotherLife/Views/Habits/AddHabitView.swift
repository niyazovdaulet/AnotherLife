
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
    @State private var selectedTemplate: HabitTemplate?
    @State private var isCreatingCustom = false
    
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
                if !isCreatingCustom && selectedTemplate == nil {
                    templateSelectionView
                } else {
                    customHabitFormView
                }
            }
            .navigationTitle(isCreatingCustom ? "Custom Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if isCreatingCustom || selectedTemplate != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveHabit()
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
                        .foregroundColor(.primaryBlue)
                    
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
                
                // Templates Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(StarterHabits.templates.prefix(8), id: \.id) { template in
                        TemplateCardView(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id
                        ) {
                            selectTemplate(template)
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
                                    .fill(customDays.contains(day) ? Color.primaryBlue : Color.backgroundGray)
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
                                        .fill(selectedIcon == icon ? Color.primaryBlue : Color.backgroundGray)
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
    private func selectTemplate(_ template: HabitTemplate) {
        selectedTemplate = template
        title = template.title
        description = template.description
        frequency = template.suggestedFrequency
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
    
    private func saveHabit() {
        let habit = Habit(
            title: title,
            description: description,
            frequency: frequency,
            customDays: customDays,
            isPositive: isPositive,
            color: selectedColor,
            icon: selectedIcon
        )
        
        habitManager.addHabit(habit)
        dismiss()
    }
}

// MARK: - Template Card View
struct TemplateCardView: View {
    let template: HabitTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    .frame(height: 44) // Fixed height for title
                
                // Description
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32) // Fixed height for description
                
                // Frequency Badge
                Text(template.suggestedFrequency.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(templateColor.opacity(0.2))
                    )
                    .foregroundColor(templateColor)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 160) // Fixed height instead of minHeight
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? templateColor.opacity(0.1) : Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? templateColor : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var templateColor: Color {
        Color(hex: template.colorHex) ?? .primaryBlue
    }
}

#Preview {
    AddHabitView()
        .environmentObject(HabitManager())
}
