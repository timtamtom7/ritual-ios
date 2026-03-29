# Ritual R12 — Accountability, Shared Rituals, Family Rituals

## Overview
Build accountability mechanisms and shared ritual experiences. Enable users to invite partners, family members, or friends to participate in joint ritual practices.

## Features

### 1. Accountability Partnerships
- Pair with an accountability buddy
- Receive gentle nudges when partner completes/misses rituals
- Weekly accountability check-ins with shared summary
- Privacy-respecting: only share ritual completion, not content

### 2. Shared Rituals
- Create a ritual that multiple people participate in simultaneously
- Synchronized breathing sessions with visual coordination
- Shared evening check-in where partners confirm intentions together
- See partner's streak and support them with encouraging taps

### 3. Family Rituals
- Family group with shared calendar of rituals
- Age-appropriate ritual templates for children
- Family breathing exercises (shorter durations, fun visuals)
- Weekly family ritual summary for parents

### 4. Accountability UI
- Partner status card showing their completion today
- "Send encouragement" quick action
- Gentle notification when partner completes a ritual
- Muted mode for when you need space

## Technical Approach
- Use MultipeerConnectivity for local proximity sharing (Round 1)
- CloudKit private database for cross-device/cross-person sync (Round 2)
- End-to-end encryption for shared data
- Parental controls for family features

## Data Model
```swift
struct AccountabilityPartner: Identifiable, Codable {
    let id: String
    let displayName: String
    let peerId: String
    var currentStreak: Int
    var todayCompleted: Bool
    var relationship: PartnerRelationship
}

enum PartnerRelationship: String, Codable {
    case accountabilityBuddy
    case partner
    case familyMember
    case child
}

struct SharedRitual: Identifiable, Codable {
    let id: String
    let title: String
    let hostId: String
    var participants: [String] // peer IDs
    let scheduledAt: Date
    let ritualType: SharedRitualType
}

enum SharedRitualType {
    case synchronizedBreathing
    case sharedIntentionSetting
    case eveningCheckIn
    case familyBreathing
}
```

## Success Metrics
- 25% of active users have at least one accountability partner
- Shared ritual sessions average 4+ minutes
- Users with accountability partners have 40% higher retention
