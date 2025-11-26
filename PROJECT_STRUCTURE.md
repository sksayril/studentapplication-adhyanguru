# Student Application - Project Structure

## Overview
This is a Flutter-based educational application with a modern, clean UI design.

## Folder Structure

```
lib/
├── main.dart                           # Application entry point
├── screens/                            # All screen/pages
│   ├── splash_screen.dart             # Animated splash screen with app branding
│   ├── home_screen.dart               # Main home screen with all sections
│   ├── my_courses_screen.dart         # My courses progress screen
│   ├── course_details_screen.dart     # Course details with preview, tabs, and enrollment
│   ├── all_courses_screen.dart        # View all courses by category (premium/live/free)
│   ├── calendar_screen.dart           # Class calendar with monthly view and schedule
│   ├── chat_screen.dart               # Chat list with all conversations
│   ├── chat_detail_screen.dart        # Individual chat conversation screen
│   ├── games_screen.dart              # Educational games grid view
│   ├── ai_features_screen.dart        # AI-powered learning features
│   ├── subject_selection_screen.dart  # Subject selection for test exam
│   ├── test_level_screen.dart         # Difficulty level selection screen
│   ├── test_declaration_screen.dart   # Test instructions and overview
│   ├── quiz_screen.dart               # Quiz/test questions screen with timer
│   ├── test_report_screen.dart        # Test results with pie chart
│   ├── answer_review_screen.dart      # Review answers (correct/incorrect)
│   └── profile_screen.dart            # User profile with stats and settings
├── widgets/                            # Reusable UI components
│   ├── upcoming_class_card.dart       # Card for upcoming class section
│   ├── live_class_card.dart           # Card for live classes
│   ├── live_course_card.dart          # Card for live courses
│   ├── test_exam_card.dart            # Card for test/exam section
│   ├── premium_course_card.dart       # Card for premium courses
│   ├── free_course_card.dart          # Card for free courses
│   ├── my_course_card.dart            # Card for course progress
│   ├── game_card.dart                 # Card for educational games
│   ├── ai_feature_card.dart           # Card for AI features
│   └── skeleton_loader.dart           # Skeleton loading animations
├── utils/                              # Utility files
│   ├── colors.dart                    # Color constants with dark mode support
│   ├── text_styles.dart               # Text style constants
│   └── theme_provider.dart            # Theme management with provider
└── models/                             # Data models (empty for now)
```

## Features

### Dark Mode / Light Mode
- **Theme Toggle**: Button in home screen header to switch themes
- **Persistent Storage**: Theme preference saved using SharedPreferences
- **Dynamic Colors**: Colors automatically adjust based on theme
- **System Integration**: Respects system theme preference
- **Smooth Transition**: Seamless switching between light and dark modes
- **Icon Changes**: Sun icon for light mode, Moon icon for dark mode
- **Complete Coverage**: All screens support dark mode
- **Professional Design**: Dark mode uses #121212 background

### Splash Screen
- **App Branding**: "Adhyan Guru" name with professional logo
- **Gradient Background**: Purple gradient with decorative circles
- **Logo Animation**: Fade and scale effects with bounce
- **Text Animation**: Slide up animation for app name and tagline
- **Loading Indicator**: Circular progress with "Loading..." text
- **Auto Navigation**: 3-second timer before transitioning to home
- **Smooth Transition**: Fade transition to home screen
- **Tagline**: "Learn Smarter, Achieve Greater"

### Home Screen
- **Welcome Header**: Personalized greeting with search and profile icons
- **Upcoming Class Card**: Shows next class with join button and participant avatars
- **Today's Classes**: Horizontal scrollable list of live classes
- **Test Exam Section**: Quick access to test preparation
- **Premium Courses**: Horizontal scrollable list of premium courses with navigation to details
- **Live Courses**: Professional course offerings with pricing
- **Free Courses**: No-cost educational content
- **Educational Games**: Fun learning games with player counts
- **AI Features**: AI-powered learning tools and assistants
- **Bottom Navigation**: Custom navigation bar with 4 sections

### Course Details Screen
- **Video Preview**: Instructor image with playback controls
- **Course Information**: Title, lessons count, duration
- **Tabs**: Details, Mentors, Subject sections
- **Course Features**: Live classes, expert mentors, tests
- **Enrollment**: Price display and admission/enrollment button
- **Dynamic Pricing**: Shows "Free" or price based on course type

### All Courses Screen
- **Category-Based Listing**: Shows all courses filtered by type (Premium/Live/Free)
- **Live Courses**: Card design with instructor images, lessons, duration, price
- **Premium Courses**: Compact horizontal cards with ratings
- **Free Courses**: Badge-style cards with "Free" label
- **Navigation**: Each course navigates to Course Details Screen
- **Back Navigation**: Returns to home screen

### Chat Screen
- **Chat List**: Shows all conversations with preview messages
- **User Avatars**: Profile pictures with online status indicators
- **Message Preview**: Last message and timestamp
- **Unread Badges**: Notification count for unread messages
- **Search Bar**: Find specific conversations
- **Online Status**: Green dot indicator for active users

### Calendar Screen
- **Monthly Calendar View**: Full month display with week days
- **Date Navigation**: Previous/next month arrows
- **Date Selection**: Click any date to select
- **Today Highlight**: Current date marked with border
- **Selected Date**: Highlighted in purple
- **Class Schedule**: List of classes for selected date
- **Class Cards**: Subject, chapter, time, and icon
- **Interactive**: Tap to view class details
- **Week Layout**: Starting from Saturday

### Games Screen
- **Educational Games**: Grid of interactive learning games
- **Game Categories**: Math, Science, Geography, History, etc.
- **Player Count**: Shows active players for each game
- **Colorful Cards**: Gradient backgrounds with decorative patterns
- **Game Details**: Title, description, and player statistics
- **Interactive Icons**: Subject-specific icons for each game
- **Grid Layout**: 2 columns for better visibility
- **See All**: Access from home screen games section

### AI Features Screen
- **AI-Powered Tools**: Complete list of AI learning features
- **AI Tutor**: 24/7 personalized learning assistance
- **Smart Study Plan**: AI-generated personalized schedules
- **Doubt Solver**: Instant answers with step-by-step solutions
- **Practice Generator**: Unlimited custom practice questions
- **Essay Checker**: AI feedback on writing quality
- **Concept Explainer**: Simplify complex topics
- **Feature Cards**: Gradient backgrounds with AI badges
- **Detailed Descriptions**: Each feature includes full explanation
- **Interactive UI**: Tap to explore each AI feature

### Chat Detail Screen
- **Conversation View**: Full chat interface with message bubbles
- **Message Bubbles**: Different styles for sent/received messages
- **Timestamps**: Message time display
- **User Status**: Online/offline status in header
- **Actions**: Call, video call, and menu options
- **Message Input**: Text field with attachment and send buttons
- **Real-time Updates**: New messages appear instantly

## Design System

### Colors (lib/utils/colors.dart)
- Primary: Purple (#6C5CE7)
- Secondary: Orange (#FF9F43)
- Background: Light gray (#F8F9FA)
- Various card backgrounds for different sections

### Components
All widgets are modular and reusable:
- `UpcomingClassCard`: For displaying upcoming classes
- `LiveClassCard`: For showing live classes
- `TestExamCard`: For test/exam promotions
- `PremiumCourseCard`: For premium course listings

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on available device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run on Android emulator
flutter run -d Pixel_9_Pro_XL_API_35
```

## Customization

### Adding New Screens
1. Create a new file in `lib/screens/`
2. Import required widgets from `lib/widgets/`
3. Use color and text style constants from `lib/utils/`

### Creating New Widgets
1. Create a new file in `lib/widgets/`
2. Make it reusable with required parameters
3. Follow the existing widget structure

### Updating Colors/Styles
- Modify `lib/utils/colors.dart` for color scheme
- Modify `lib/utils/text_styles.dart` for typography

## Next Steps
- Add more screens (Profile, Classes, Chat, etc.)
- Implement navigation between screens
- Add data models in `lib/models/`
- Integrate with backend API
- Add animations and transitions
- Implement state management (Provider, Riverpod, or Bloc)

