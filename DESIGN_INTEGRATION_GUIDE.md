# FluentDeck Design Integration Guide

**Using actual design from SVG templates**

---

## What You Got

### 1. Design System (`lib/ui_elements/design_system.dart`)

A complete Flutter design system with:
- **Colors**: Purple (#5F33E1), Blue (#0087FF), Gray tones
- **Typography**: Heading, body, caption styles
- **8 Components**: Button, Card, Filter Tabs, Header, List Item, Badge, Progress Bar, Theme

### 2. Example Screens (`lib/screens/design_example_screens.dart`)

3 complete, working screens:
- **Home**: Decks list, progress cards, tasks
- **Tasks**: Today's tasks, progress tracking, completed items
- **Create**: Form to create new deck

---

## How to Use

### Step 1: Import the Design System

```dart
import 'package:fluentdeck/ui_elements/design_system.dart';
```

### Step 2: Apply Theme in main.dart

```dart
void main() {
  runApp(
    MaterialApp(
      theme: designSystemTheme(),  // Apply design system theme
      home: MyApp(),
    ),
  );
}
```

### Step 3: Use Components

#### Button
```dart
DesignButton(
  label: 'Start Learning',
  onPressed: () => print('Tapped'),
)
```

#### Card
```dart
DesignCard(
  title: 'Spanish Vocab',
  subtitle: '24 cards',
  headerColor: AppDesignColors.primary,
  child: DesignProgressBar(value: 0.75),
)
```

#### Filter Tabs
```dart
DesignFilterTabs(
  tabs: ['All', 'Recent', 'Done'],
  selectedIndex: _index,
  onTabChanged: (index) => setState(() => _index = index),
)
```

#### List Item
```dart
DesignListItem(
  title: 'Spanish Vocabulary',
  subtitle: '24 cards • 8 due',
  leading: Icon(Icons.book),
  trailing: DesignBadge(text: '8'),
  onTap: () => navigateToReview(),
)
```

#### Header
```dart
DesignHeader(
  title: 'Welcome Back',
  subtitle: 'Continue your journey',
)
```

#### Badge
```dart
DesignBadge(
  text: '12',
  backgroundColor: AppDesignColors.blue,
  size: 36,
)
```

#### Progress Bar
```dart
DesignProgressBar(
  value: 0.65,  // 0.0 to 1.0
  color: AppDesignColors.primary,
  height: 8,
)
```

---

## Color Palette Reference

```dart
// Use these anywhere:
AppDesignColors.primary           // #5F33E1 (Purple)
AppDesignColors.primaryLight      // #9260F4 (Light Purple)
AppDesignColors.blue              // #0087FF (Blue)
AppDesignColors.textPrimary       // #24252C (Dark text)
AppDesignColors.textSecondary     // #6E6A7C (Gray text)
AppDesignColors.bgLight           // #F4F0FF (Light purple page BG)
AppDesignColors.bgWhite           // #FFFFFF (White cards)
AppDesignColors.bgLightPurple     // #EEE9FF (Borders/dividers)
```

---

## Integration Steps

### 1. Update App Theme

**File:** `lib/main.dart`

```dart
import 'ui_elements/design_system.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'FluentDeck',
      theme: designSystemTheme(),  // ← Add this
      home: MyApp(),
    ),
  );
}
```

### 2. Update Home Screen

Replace your existing home screen with components:

```dart
import 'ui_elements/design_system.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.bgLight,
      body: Column(
        children: [
          DesignHeader(title: 'Welcome Back'),
          Expanded(
            child: ListView(
              children: [
                DesignCard(
                  title: 'Today\'s Task',
                  child: DesignProgressBar(value: 0.65),
                ),
                DesignListItem(
                  title: 'Spanish Vocab',
                  subtitle: '24 cards',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 3. Update Individual Screens

For Learn, Speaking, Activity, Profile screens - follow the same pattern:

1. **Wrap in Scaffold** with `backgroundColor: AppDesignColors.bgLight`
2. **Use DesignHeader** for top section
3. **Use DesignCard** for content sections
4. **Use DesignListItem** for list views
5. **Use DesignButton** for CTAs

---

## Typography Reference

```dart
// Use these for text styling:
AppDesignTypography.headingLarge    // 28px, bold - Main titles
AppDesignTypography.headingMedium   // 20px, semibold - Section headers
AppDesignTypography.bodyLarge       // 16px, medium - Main content
AppDesignTypography.bodySmall       // 14px, regular - Descriptions
AppDesignTypography.caption         // 12px, regular - Labels, hints
AppDesignTypography.label           // 13px, semibold - Form labels
```

Example:
```dart
Text('Hello World', style: AppDesignTypography.headingMedium)
```

---

## Component Examples from Real Screens

### Example 1: Deck Card with Progress

```dart
DesignCard(
  title: 'Spanish Vocabulary',
  subtitle: '24 cards • 8 due today',
  headerColor: AppDesignColors.primary,
  child: Column(
    children: [
      DesignProgressBar(value: 0.75),
      SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('75% Complete', style: AppDesignTypography.caption),
          DesignBadge(text: '+50', size: 28),
        ],
      ),
    ],
  ),
)
```

### Example 2: Deck List with Navigation

```dart
ListView(
  children: [
    DesignListItem(
      title: 'Spanish Vocabulary',
      subtitle: '24 cards • 8 due',
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppDesignColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('📚')),
      ),
      trailing: DesignBadge(text: '8', backgroundColor: AppDesignColors.blue),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckReviewScreen())),
    ),
  ],
)
```

### Example 3: Filter & Search

```dart
Column(
  children: [
    DesignFilterTabs(
      tabs: ['All', 'Beginner', 'Intermediate', 'Advanced'],
      selectedIndex: _selectedLevel,
      onTabChanged: (index) {
        setState(() => _selectedLevel = index);
        filterDecks(index);
      },
    ),
    Expanded(
      child: ListView(children: filteredDecks),
    ),
  ],
)
```

---

## Customization

### Change Primary Color

```dart
// In design_system.dart, change:
static const Color primary = Color(0xFF5F33E1);  // Change to your color
```

### Add New Colors

```dart
// In AppDesignColors:
static const Color newColor = Color(0xFF..);
```

### Update Button Style

```dart
// In DesignButton, modify the BoxDecoration:
decoration: BoxDecoration(
  gradient: LinearGradient(...),  // Change gradient
  borderRadius: BorderRadius.circular(12),  // Change radius
),
```

---

## Quick Checklist

- [ ] Import `design_system.dart` in screens
- [ ] Update `main.dart` theme to `designSystemTheme()`
- [ ] Replace white backgrounds with `AppDesignColors.bgLight`
- [ ] Replace buttons with `DesignButton`
- [ ] Replace cards with `DesignCard`
- [ ] Replace list items with `DesignListItem`
- [ ] Test light mode and dark mode
- [ ] Test on mobile (375px) and tablet (768px+)
- [ ] Verify all text uses design typography

---

## File Locations

```
lib/
├── ui_elements/
│   └── design_system.dart          ← All components & colors
├── screens/
│   └── design_example_screens.dart ← 3 complete example screens
├── main.dart                        ← Apply theme here
└── [other screens - update these]
```

---

## Testing

Run the example screens to see the design system:

```bash
flutter run lib/screens/design_example_screens.dart
```

Then swipe between tabs (Home, Tasks, Create) to see all components in action.

---

## No More Changes Needed

The design system is **complete and ready to use**. Just:
1. Import `design_system.dart`
2. Use the components
3. Apply colors and typography

No mockups, no theoretical designs - just practical, working Flutter code. 🚀
