# Bread.ai

BreadAI is an interactive React Native application designed to guide users through the bread-making process. Leveraging AI-driven feedback, gamification elements, and intuitive UI components, BreadAI aims to make baking bread an engaging and educational experience.

## Features

- **AI-Powered Q&A**: Ask any bread-related question and get expert answers from Claude AI
- **AI-Generated Recipes**: Dynamic recipe generation for any bread type
- **Gamification System**: Earn badges and track your baking progress with 21 unique achievements
- **User Feedback**: Rate responses to help improve the AI experience
- **Offline Fallback**: Basic functionality available without internet connection
- **Clean SwiftUI Interface**: Modern iOS design built for iOS 14+

---

## Project Structure

```
Bread.ai/
├── BreadAI/
│   └── BreadAI/
│       ├── Assets.xcassets/              # Asset catalog (App icons, images, colors)
│       ├── Preview Content/              # Preview assets for SwiftUI
│       ├── BadgeCardView.swift           # UI component to display earned badges
│       ├── BadgeModels.swift             # Badge data models (types, properties)
│       ├── BreadAIApp.swift              # App entry point (@main)
│       ├── BreadCardView.swift           # UI component for bread recipe cards
│       ├── BreadRecipes.swift            # Data/model for bread recipes
│       ├── BreadService.swift            # API service layer (async/await actor)
│       ├── ColorExtensions.swift         # Custom color definitions for app theme
│       ├── ContentView.swift             # Primary Q&A view with feedback buttons
│       ├── GamificationManager.swift     # Badge/achievement tracking engine
│       ├── Info.plist                    # App configuration and metadata
│       ├── LoginView.swift               # Login screen UI
│       ├── MainTabView.swift             # TabView navigation setup
│       └── RecipeDetailView.swift        # Recipe detail with AI generation
├── BreadAITests/                         # Unit tests
├── backend/
│   ├── main.py                           # FastAPI server with all endpoints
│   ├── requirements.txt                  # Python dependencies
│   ├── .env.example                      # Environment variable template
│   └── render.yaml                       # Render.com deployment config
└── README.md
```

---

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   iOS App           │────▶│   FastAPI Backend    │────▶│   Anthropic Claude  │
│   (SwiftUI)         │     │   (Python/Render)    │     │   (claude-3-5-haiku)│
└─────────────────────┘     └──────────────────────┘     └─────────────────────┘
         │                           │
         │                           ├── SQLite Database
         │                           │   ├── Feedback storage
         │                           │   ├── Response caching
         │                           │   └── A/B test variants
         │                           │
         └── UserDefaults            └── Analytics & Metrics
             (Gamification data)
```

---

## Backend API

### Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/ask` | POST | Ask a bread-related question |
| `/recipe` | POST | Generate a recipe for any bread type |
| `/feedback` | POST | Submit user feedback on responses |
| `/analytics` | GET | View feedback analytics and trends |
| `/prompts` | GET | List all A/B test prompt variants |
| `/prompts/{name}/toggle` | POST | Enable/disable a prompt variant |
| `/cache/stats` | GET | View cache statistics and savings |
| `/cache/cleanup` | POST | Remove expired cache entries |
| `/cache/clear` | POST | Clear all cached responses |
| `/health` | GET | Health check endpoint |

### Features

- **A/B Testing**: Three prompt variants (concise, detailed, friendly) for optimization
- **Response Caching**: Reduces API costs with configurable TTL (1hr for Q&A, 24hr for recipes)
- **Input Sanitization**: Protection against prompt injection attacks
- **Analytics Dashboard**: Track feedback trends and variant performance

---

## Gamification System

### Badge Categories

| Category | Badges | Description |
|----------|--------|-------------|
| **Skill-Based** | 5 | Rise Master, Crust King/Queen, Knead for Speed, Proof Positive, Precision Baker |
| **Consistency** | 4 | Daily Dough (7-day streak), Weekend Warrior, Starter Guardian, Streak Saver |
| **Creativity** | 4 | Bread Explorer, Freestyle Flour, Pan Artist, Seasonal Star |
| **Community** | 4 | First Share, Feedback Friend, Challenge Accepted, Curious Baker |
| **Milestone** | 4 | Rookie Baker, 10 Bakes, Master Mixer, Flour Fanatic |

### Points & Leveling

- Earn points by unlocking badges (5-1000 points each)
- Level up as you accumulate points
- Progress persisted locally via UserDefaults

---

## Development Setup

### Prerequisites

- **iOS App**: Xcode 12.0+, iOS 14.0+, Swift 5.3+
- **Backend**: Python 3.9+, pip

### iOS App

1. Clone the repository
2. Open `BreadAI/BreadAI.xcodeproj` in Xcode
3. Build and run on simulator or device

### Backend

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Set up environment variables
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY

# Run development server
uvicorn main:app --reload --port 8000
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | Your Anthropic API key | Required |
| `DATABASE_PATH` | SQLite database file path | `feedback.db` |
| `CACHE_ENABLED` | Enable/disable response caching | `true` |
| `CACHE_TTL_ASK` | Cache TTL for Q&A (seconds) | `3600` |
| `CACHE_TTL_RECIPE` | Cache TTL for recipes (seconds) | `86400` |

---

## Deployment

### Backend (Render.com)

1. Push code to GitHub
2. Connect repo to [Render.com](https://render.com)
3. Add `ANTHROPIC_API_KEY` environment variable
4. Deploy - get URL like `https://breadai-api.onrender.com`
5. Update `BreadService.swift` baseURL with production URL

### iOS App (TestFlight)

1. Update `BreadService.swift` with production backend URL
2. Archive app in Xcode (Product > Archive)
3. Upload to App Store Connect
4. Submit for TestFlight review

---

## Changelog (January 3, 2026)

### LLM Backend Integration
- Created Python FastAPI backend with Anthropic Claude integration
- Model: `claude-3-5-haiku-20241022` (optimized for low cost and latency)
- Endpoints for Q&A (`/ask`) and recipe generation (`/recipe`)
- CORS enabled for iOS app access

### AI-Generated Recipes
- All bread types now display AI-generated recipes
- Dynamic recipe view with ingredients, instructions, and baker's tips
- "I Made This!" button to log completed bakes

### Gamification System
- Implemented `GamificationManager` with 21 badges across 5 categories
- Points and leveling system with persistent storage
- Badge unlock notifications with custom alerts
- Integrated throughout app (ContentView, RecipeDetailView, MainTabView)

### Feedback & A/B Testing System
- User feedback buttons (thumbs up/down) on all AI responses
- SQLite database for feedback storage
- Three prompt variants for A/B testing optimization
- Analytics endpoint for performance insights
- Prompt management endpoints for enabling/disabling variants

### Request Caching
- Response caching to reduce API costs (~$0.0003 savings per cache hit)
- Configurable TTL: 1 hour for Q&A, 24 hours for recipes
- Cache statistics and management endpoints
- Visual indicator for cached responses in iOS app

### Security: Input Sanitization
- Prompt injection prevention with pattern matching
- Input length limits (500 chars for queries, 100 chars for bread names)
- Control character removal and whitespace normalization
- Bread-related keyword validation

### Swift Async/Await Modernization
- Converted `BreadService` from class to actor for thread safety
- Replaced completion handlers with async/await pattern
- Updated all views to use `Task {}` blocks
- Replaced `DispatchQueue.asyncAfter` with `Task.sleep`

### Unit Tests
- Added comprehensive backend tests with pytest
- iOS unit tests for core functionality

---

## Cost Estimates

| Component | Cost |
|-----------|------|
| **Render.com** | Free tier (750 hours/month) |
| **Claude Haiku** | ~$0.001 per typical bread question |
| **Monthly estimate** | Under $5 for moderate usage |

---

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+
- Python 3.9+ (for backend)
- Anthropic API key

---

## License

See the LICENSE file for details.
