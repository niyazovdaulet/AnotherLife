//
//  OnboardingModels.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import SwiftUI

// MARK: - Focus Areas
enum FocusArea: String, CaseIterable, Identifiable {
    case health, productivity, mindfulness, learning, fitness, finance, custom
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .health: return "Health"
        case .productivity: return "Productivity"
        case .mindfulness: return "Mindfulness"
        case .learning: return "Learning"
        case .fitness: return "Fitness"
        case .finance: return "Finance"
        case .custom: return "Custom"
        }
    }
    
    var symbol: String {
        switch self {
        case .health: return "heart.fill"
        case .productivity: return "checkmark.circle.fill"
        case .mindfulness: return "sparkles"
        case .learning: return "book.fill"
        case .fitness: return "figure.strengthtraining.traditional"
        case .finance: return "banknote.fill"
        case .custom: return "wand.and.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .health: return .red
        case .productivity: return .blue
        case .mindfulness: return .purple
        case .learning: return .orange
        case .fitness: return .green
        case .finance: return .yellow
        case .custom: return .pink
        }
    }
}

// MARK: - Habit Template
struct HabitTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let suggestedFrequency: HabitFrequency
    let isPositive: Bool
    let colorHex: String
    let area: FocusArea
    
    init(title: String, description: String = "", icon: String, suggestedFrequency: HabitFrequency, isPositive: Bool, colorHex: String, area: FocusArea) {
        self.title = title
        self.description = description
        self.icon = icon
        self.suggestedFrequency = suggestedFrequency
        self.isPositive = isPositive
        self.colorHex = colorHex
        self.area = area
    }
}

// MARK: - Starter Templates
struct StarterHabits {
    static let templates: [HabitTemplate] = [
        // Priority Habits (most commonly requested)
        HabitTemplate(
            title: "Drink Water",
            description: "Stay hydrated throughout the day",
            icon: "drop.fill",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#53C1DE",
            area: .health
        ),
        HabitTemplate(
            title: "Sleep by 23:00",
            description: "Get 8 hours of quality sleep",
            icon: "bed.double.fill",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#8E8CF5",
            area: .health
        ),
        HabitTemplate(
            title: "Read 20 min",
            description: "Read books or articles daily",
            icon: "book.fill",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#F5A623",
            area: .learning
        ),
        HabitTemplate(
            title: "Exercise",
            description: "30 minutes of physical activity",
            icon: "figure.run",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#43B581",
            area: .fitness
        ),
        HabitTemplate(
            title: "No Sugar",
            description: "Avoid added sugars and sweets",
            icon: "xmark.octagon.fill",
            suggestedFrequency: .daily,
            isPositive: false,
            colorHex: "#FF6B6B",
            area: .health
        ),
        HabitTemplate(
            title: "No Phone After 22:00",
            description: "Digital detox before bedtime",
            icon: "iphone.slash",
            suggestedFrequency: .daily,
            isPositive: false,
            colorHex: "#FF8C42",
            area: .productivity
        ),
        
        // Additional Health Habits
        HabitTemplate(
            title: "Meditate 10 min",
            description: "Practice mindfulness and meditation",
            icon: "leaf.fill",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#22B573",
            area: .mindfulness
        ),
        HabitTemplate(
            title: "Take the Stairs",
            description: "Choose stairs over elevators",
            icon: "figure.stairs",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#4ECDC4",
            area: .fitness
        ),
        
        // Productivity Habits
        HabitTemplate(
            title: "Plan Tomorrow",
            description: "Review and plan your next day",
            icon: "calendar.badge.clock",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#6E68F0",
            area: .productivity
        ),
        HabitTemplate(
            title: "Journal Writing",
            description: "Write about your day and thoughts",
            icon: "pencil.and.outline",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#9B59B6",
            area: .mindfulness
        ),
        
        // Finance Habits
        HabitTemplate(
            title: "Track Expenses",
            description: "Log daily spending",
            icon: "dollarsign.circle.fill",
            suggestedFrequency: .daily,
            isPositive: true,
            colorHex: "#FFD93D",
            area: .finance
        ),
        HabitTemplate(
            title: "No Impulse Buys",
            description: "Wait 24 hours before purchasing",
            icon: "cart.badge.minus",
            suggestedFrequency: .daily,
            isPositive: false,
            colorHex: "#FF6B6B",
            area: .finance
        )
    ]
}

