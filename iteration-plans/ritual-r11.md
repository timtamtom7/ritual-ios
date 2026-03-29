# Ritual R11 — AI Ritual Suggestions, Habit Stacking, Routine Optimization

## Overview
Use AI to suggest personalized rituals based on user's patterns, goals, and life circumstances. Implement habit stacking to help users build new rituals on top of existing habits.

## Features

### 1. AI Ritual Suggestions
- Analyze user's existing ritual completion patterns
- Suggest new rituals based on detected gaps (e.g., "You often miss evening rituals — consider a shorter wind-down ritual")
- Surface seasonal/lifecycle suggestions ("Monday mornings seem challenging — try a brief 5-min morning intention")
- Category-based suggestions aligned with user's stated goals

### 2. Habit Stacking Engine
- Detect existing habits (time of day, location triggers)
- Suggest new rituals that attach to existing habits ("After your morning coffee, set an intention")
- Visual "habit chain" showing how rituals connect
- Identify potential conflict points with existing routines

### 3. Routine Optimization
- Analyze completion rates by time of day, day of week
- Identify optimal times for new rituals based on historical data
- Suggest ritual duration adjustments for better adherence
- Detect and warn about ritual overload

## Technical Approach
- Use local pattern analysis (Round 1) before Apple Intelligence integration
- Store suggestion history to avoid repetition
- Track suggestion acceptance/rejection rates for learning

## Data Model
```swift
struct RitualSuggestion: Identifiable, Codable {
    let id: String
    let suggestedText: String
    let category: String
    let suggestedTime: Date
    let stackingHook: String? // "After your morning coffee"
    let reason: String
    let accepted: Bool?
    let createdAt: Date
}
```

## Success Metrics
- Suggestion acceptance rate > 30%
- Users who adopt habit stacking have 20% higher completion rates
- AI suggestions improve week-over-week adherence
