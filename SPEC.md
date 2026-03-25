# Ritual — Product Specification

## 1. Concept & Vision

**Ritual** is a mindful intention-setting companion that transforms daily intention-setting into a sacred practice. It feels like stepping into a quiet temple — warm, still, unhurried. The app guides users through morning intentions with breathwork, checks in at evening, and over weeks reveals the patterns between what they intend and what they embody.

This is not a productivity app with gamification. It's an instrument for self-discovery.

---

## 2. Design Language

### Aesthetic Direction
**Ceremonial minimalism** — inspired by candlelit temples, meditation halls, and the quiet before dawn. Warmth without brightness, presence without urgency.

### Color Palette
| Role | Hex | Usage |
|---|---|---|
| Background | `#0D0B09` | Primary dark background |
| Surface | `#1A1714` | Cards, elevated surfaces |
| Gold Primary | `#C9A96E` | Primary accent, CTAs |
| Gold Muted | `#8B7355` | Secondary accents, borders |
| Gold Glow | `#E8D5A3` | Highlights, active states |
| Text Primary | `#F5F0E8` | Headings, body text |
| Text Secondary | `#9C9285` | Captions, placeholders |
| Text Muted | `#5C544A` | Disabled states |
| Success | `#7A9E7A` | Completion, positive |
| Warning | `#C4956A` | Caution, neutral |

### Typography
- **Display**: System serif (New York) — large intention text
- **Body**: System sans-serif (SF Pro) — descriptions, UI elements
- **Weights**: Light (300), Regular (400), Medium (500)
- **Sizes**: 48pt (hero), 28pt (title), 20pt (heading), 17pt (body), 13pt (caption)

### Spatial System
- Base unit: 8pt
- Generous padding: 24–48pt on screens
- Card corner radius: 16pt
- Button corner radius: 12pt

### Motion Philosophy
- **Slow and deliberate** — 600–1200ms durations
- **Ease-in-out** breathing curves
- Breathing circle: scale 0.6 → 1.0 → 0.6 with 4s inhale / 4s exhale default
- **Haptics**: soft pulses on breath rhythm, gentle confirmation on actions
- **Transitions**: fade + slight vertical drift (8pt)

### Visual Assets
- SF Symbols for icons (minimal set)
- Gradient overlays: gold-to-transparent radial for glows
- No photography — pure abstract warmth

---

## 3. Layout & Structure

### Navigation
Tab-based navigation with 3 tabs:
1. **Today** — Morning intention + evening check-in (main ritual)
2. **Timeline** — History of intentions and reflections
3. **Insights** — Pattern analysis from Apple Intelligence

### Screen Hierarchy
```
App
├── TodayView (Tab 1)
│   ├── MorningIntentionView (before 12pm)
│   │   ├── BreathingGuideView
│   │   └── IntentionInputView
│   ├── BreathingSessionView (accessible anytime)
│   └── EveningCheckInView (after 6pm)
│       ├── SuccessRatingView
│       └── ReflectionInputView
├── TimelineView (Tab 2)
│   └── IntentionRowView (per day)
└── InsightsView (Tab 3)
    ├── PatternCardView
    └── CategoryInsightView
```

### Responsive Strategy
- Single-column layout optimized for portrait
- Safe area respected on all edges
- Dynamic Type supported (accessibility sizes)

---

## 4. Features & Interactions

### 4.1 Morning Intention

**Flow:**
1. User opens app → sees "Set Today's Intention" prompt
2. Tap begins with 3-breath settling guide (4s in / 4s out each)
3. After settling, text input appears (keyboard or voice dictation)
4. User types/speaks intention (max 140 chars)
5. Confirm button → intention saved with timestamp
6. Success animation: golden glow ripple

**Intention Input:**
- Placeholder: "Today, I intend to..."
- Character counter at 120/140
- Voice input button (SF Symbol: mic.fill)
- Submit button: "Hold This Intention"

**States:**
- Empty: placeholder + muted voice button
- Typing: character count visible, voice button highlighted
- Submitted: success message + celebration ripple

### 4.2 Breathing Session

**Flow:**
1. User taps "Breathe" from Today or standalone
2. Full-screen breathing circle animation
3. Haptic pulses sync with breath phases
4. Default: 4s inhale / 4s hold / 4s exhale / 4s hold (box breathing)
5. Tap to pause, tap again to resume
6. Session complete: gentle fade out

**Customization:**
- Pattern selector: Box (4-4-4-4), Calm (4-7-8), Energize (6-0-6-0)
- Duration selector: 1, 3, 5, 10 minutes
- Haptic toggle

**Haptic Pattern:**
- Inhale: gentle increasing pulse (3 pulses)
- Hold: single sustained soft pulse
- Exhale: decreasing pulse (3 pulses)
- Uses CoreHaptics CHHapticEngine

### 4.3 Evening Check-In

**Flow:**
1. After 6pm, "Check In" prompt appears on Today tab
2. Question: "Did you act on your intention?"
3. Two large buttons: "Yes" / "Not Quite"
4. If "Yes": single tap confirmation, golden celebration
5. If "Not Quite": optional reflection text input ("What got in the way?")
6. Reflection saved, gentle close

**States:**
- Unchecked: prompt visible
- Checked Yes: green checkmark, celebration ripple
- Checked No: textarea appears for reflection

### 4.4 Ritual Timeline

**Layout:**
- Vertical scrolling list, most recent first
- Grouped by week
- Each day shows: date, intention text, check-in result, reflection (if any)

**Intention Row:**
- Date label (e.g., "Monday, March 23")
- Intention text (truncated if long)
- Status indicator: ✓ (acted) / ✗ (didn't) / — (no check-in)
- Tap to expand full detail

**Empty State:**
- Gentle message: "Your ritual begins when you're ready."

### 4.5 Pattern Insights

**Analysis (Apple Intelligence):**
- Categorize intentions by theme (Work, Relationships, Health, Growth, Other)
- Calculate success rate per category
- Identify temporal patterns (morning vs evening check-ins)
- Generate insight cards

**Insight Cards:**
- Headline: "Intentions about Work succeed 70% of the time."
- Subtext: "You've set 10 work intentions this month. 7 led to action."
- Trend: "This is your strongest category."
- Weakest: "Relationships: 30% success rate"

**Minimum Data:**
- Require at least 2 weeks of data before showing insights
- Show placeholder: "Insights emerge with practice. Keep going."

---

## 5. Component Inventory

### BreathingCircleView
- Outer ring: stroke gradient gold, animates scale 0.6→1.0
- Inner glow: radial gradient, opacity pulses with breath
- Center text: current phase ("Breathe In", "Hold", "Breathe Out")
- States: idle, inhaling, holding, exhaling, paused

### IntentionCard
- Background: Surface color with gold border (1pt)
- Corner radius: 16pt
- Padding: 20pt
- Text: serif font, 20pt
- States: default, highlighted (today's active intention)

### CheckInButton
- Size: full-width, 56pt height
- Background: Gold Primary
- Text: "Yes" / "Not Quite" in dark text
- Corner radius: 12pt
- States: default, pressed (scale 0.96), disabled

### ReflectionInput
- Multiline text field, max 280 chars
- Placeholder: "What got in the way?"
- Border: gold muted, 1pt
- Corner radius: 12pt

### InsightCard
- Background: Surface
- Border: Gold Muted, 1pt
- Icon: category-specific SF Symbol
- Headline: 17pt medium
- Subtext: 14pt regular, secondary color
- Corner radius: 16pt

### TimelineRow
- Left: date column (48pt wide)
- Right: intention text + status indicator
- Separator: subtle gold muted line
- Tap: expands to show reflection

---

## 6. Technical Approach

### Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Minimum iOS**: 26.0

### Data Persistence
- **SQLite.swift** for local storage
- Schema:
  ```
  intentions
    - id: TEXT PRIMARY KEY
    - text: TEXT NOT NULL
    - created_at: TEXT NOT NULL (ISO8601)
    - category: TEXT (optional, AI-assigned)

  check_ins
    - id: TEXT PRIMARY KEY
    - intention_id: TEXT REFERENCES intentions(id)
    - acted: INTEGER (0/1)
    - reflection: TEXT (optional)
    - created_at: TEXT NOT NULL

  breathing_sessions
    - id: TEXT PRIMARY KEY
    - pattern: TEXT
    - duration_seconds: INTEGER
    - completed: INTEGER (0/1)
    - created_at: TEXT NOT NULL
  ```

### Services
- `DatabaseService`: SQLite.swift wrapper, CRUD operations
- `BreathingService`: Haptic engine management, timing
- `IntentAnalysisService`: Category assignment (pattern matching for Round 1; Apple Intelligence in future)
- `CloudKitService`: Optional sync (Round 2, not in scope)

### Dependencies (Swift Package Manager)
- `SQLite.swift` — version 0.15.0+
- No other external dependencies for Round 1

### File Structure
```
Ritual/
├── App/
│   └── RitualApp.swift
├── Models/
│   ├── Intention.swift
│   ├── CheckIn.swift
│   └── BreathingSession.swift
├── Services/
│   ├── DatabaseService.swift
│   └── BreathingService.swift
├── ViewModels/
│   ├── TodayViewModel.swift
│   ├── TimelineViewModel.swift
│   └── InsightsViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Today/
│   │   ├── TodayView.swift
│   │   ├── MorningIntentionView.swift
│   │   ├── BreathingGuideView.swift
│   │   ├── IntentionInputView.swift
│   │   └── EveningCheckInView.swift
│   ├── Breathing/
│   │   └── BreathingSessionView.swift
│   ├── Timeline/
│   │   └── TimelineView.swift
│   └── Insights/
│       └── InsightsView.swift
├── Components/
│   ├── BreathingCircleView.swift
│   ├── IntentionCard.swift
│   ├── CheckInButton.swift
│   └── InsightCard.swift
├── Theme/
│   └── Theme.swift
└── Resources/
    └── Assets.xcassets
```

### CloudKit (Future)
- CKContainer: `iCloud.com.ritual.app`
- Private database for user data
- Round 2 feature

---

## 7. Edge Cases & Error Handling

- **No intention set today**: Show morning flow on Today tab
- **Evening without morning**: Check-in still available (forgiven, not punished)
- **App killed during breathing**: Session marked incomplete
- **Empty timeline**: Beautiful empty state, no skeleton loading
- **Database error**: Graceful fallback, log locally, don't crash
- **Voice input unavailable**: Hide voice button silently
