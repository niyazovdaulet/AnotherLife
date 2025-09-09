# AnotherLife - Habit Tracking App

AnotherLife is a beautiful and intuitive habit tracking iOS app built with SwiftUI. It helps you build better habits and break bad ones through visual tracking, detailed statistics, and insightful analytics.

## Features

### 🏠 **Main Dashboard**
- Clean, modern interface with habit cards
- Visual progress tracking with completion rates
- Quick stats overview (current streak, total habits)
- Swipe gestures for easy habit logging
- Date navigation to track past/future progress

### 📊 **Statistics & Analytics**
- Comprehensive habit performance metrics
- Completion rate tracking over time
- Streak analysis (current and longest streaks)
- Interactive charts and graphs (iOS 16+)
- Time range filtering (week, month, 3 months, year)

### 🔍 **Insights & Correlations**
- Advanced habit correlation analysis
- Pattern recognition between different habits
- Visual streak graphs for each habit
- Success rate calculations
- Weekly report generation

### ➕ **Habit Management**
- Create custom habits with detailed configuration
- Support for positive and negative habits
- Flexible frequency options (daily, weekly, custom)
- Custom day selection for weekly habits
- Rich customization with colors and icons
- Habit editing and deletion

### 📝 **Notes & Tracking**
- Add notes to habit entries
- Multiple status options (completed, failed, skipped)
- Visual day-by-day tracking grid
- Progress visualization with color-coded tiles

### 🎨 **Theming & Customization**
- Light, dark, and system theme support
- Dynamic color system
- Beautiful gradient backgrounds
- Smooth animations and transitions

## Technical Details

### **Platform Requirements**
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### **Architecture**
- **Framework**: SwiftUI
- **Pattern**: MVVM with ObservableObject
- **Data Persistence**: UserDefaults with JSON encoding
- **Charts**: Swift Charts (iOS 16+) with fallback support

### **Key Components**

#### Models (`Models.swift`)
- `Habit`: Core habit data structure
- `HabitEntry`: Daily habit completion records
- `HabitStatus`: Completion states (completed, failed, skipped)
- `HabitFrequency`: Scheduling options
- `HabitStatistics`: Analytics data
- `AppTheme`: Theme management

#### Core Manager (`HabitManager.swift`)
- Centralized data management
- Habit CRUD operations
- Entry tracking and statistics
- Data persistence
- Theme management

#### Views
- `ContentView`: Main tab-based interface
- `AddHabitView`: Habit creation form
- `StatisticsView`: Analytics dashboard
- `InsightsView`: Advanced insights and correlations
- `NotesView`: Note-taking interface
- `SettingsView`: App configuration

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/AnotherLife.git
   cd AnotherLife
   ```

2. **Open in Xcode**
   ```bash
   open AnotherLife.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## Usage

### Getting Started
1. Launch the app and tap the "+" button to add your first habit
2. Configure your habit with title, description, frequency, and type
3. Choose a color and icon to personalize your habit
4. Start tracking by tapping or swiping on habit cards

### Tracking Habits
- **Tap** habit cards to cycle through statuses
- **Swipe right** to mark as completed
- **Swipe left** to mark as skipped
- **Add notes** for additional context

### Viewing Analytics
- Switch to the **Stats** tab for performance metrics
- Use the **Insights** tab for advanced analytics
- Generate **Weekly Reports** for detailed summaries

## Data Structure

### Habit Model
```swift
struct Habit {
    let id: UUID
    var title: String
    var description: String
    var frequency: HabitFrequency
    var customDays: [Int]
    var isPositive: Bool
    var createdAt: Date
    var color: String
    var icon: String
}
```

### Entry Model
```swift
struct HabitEntry {
    let id: UUID
    let habitId: UUID
    let date: Date
    var status: HabitStatus
    var notes: String
}
```

## Customization

### Adding New Colors
Extend the `Color` extension in `Models.swift`:
```swift
static let customColor = Color(red: 0.5, green: 0.3, blue: 0.8)
```

### Adding New Icons
Update the `availableIcons` array in `AddHabitView.swift` with SF Symbol names.

### Modifying Themes
Adjust color values in the `Color` extension for light/dark theme customization.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Future Enhancements

- [ ] Cloud sync with iCloud
- [ ] Widget support for quick habit logging
- [ ] Apple Watch companion app
- [ ] Habit sharing and social features
- [ ] Advanced analytics and machine learning insights
- [ ] Export data functionality
- [ ] Habit templates and suggestions
- [ ] Push notifications and reminders

## Screenshots

*Screenshots would be added here showing the main interface, habit creation, statistics, and insights views.*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and Swift Charts
- Icons from SF Symbols
- Inspired by modern habit tracking principles
- Designed for iOS Human Interface Guidelines

## Support

For support, feature requests, or bug reports, please open an issue on GitHub or contact [your-email@example.com].

---

**AnotherLife** - Transform your habits, transform your life. 🌟
