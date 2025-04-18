# Bread.ai

Bread.ai is an iOS app that provides AI-powered knowledge about bread. Ask anything about different types of bread, recipes, baking techniques, or bread history, and get instant expert answers.

## Features

- Simple, intuitive interface for asking bread-related questions
- Quick responses about various bread types
- Information on ingredients, baking techniques, and bread history
- Clean SwiftUI interface built for iOS 14+

## Project Structure

```
BreadAi/
├── BreadAi/
└── Assets.xcassets/                         # Asset catalog (App icons, images, colors)
└── Preview Content/                         # Contains all code, assets, and app config
    ├── Assets.xcassets/                     # Asset catalog (App icons, images, colors)
    ├── BadgeCardView.swift                  # UI component to display earned badges
    ├── BadgeModels.swift                    # Badge data models (types, properties)
    ├── BreadAIApp.swift                     # App entry point (uses @main, sets initial view)
    ├── BreadCardView.swift                  # UI component for showing bread recipe cards
    ├── BreadRecipes.swift                   # Data/model for bread recipes
    ├── BreadService.swift                   # Core logic or services for Bread.ai functionality
    ├── ColorExtensions.swift                # Custom color definitions for app theme
    ├── ContentView.swift                    # Primary container view, includes navigation logic
    ├── Info.plist                           # App configuration and metadata
    ├── LoginView.swift                      # Login screen UI
    ├── MainTabView.swift                    # TabView setup for navigating between major screens
    └── RecipeDetailView.swift               # Detail screen for a selected bread recipe
└── BreadAiTests/              # Unit test directory

```

## Development

1. Clone the repository
2. Open the BreadAi.xcodeproj file in Xcode
3. Build and run the app on a simulator or physical device

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

## Future Enhancements

- Integrate with a real AI service for more comprehensive answers
- Add more bread-specific features like recipe storage
- Create a discovery section with bread categories
- Add sharing capabilities for bread knowledge

## License

See the LICENSE file for details.
