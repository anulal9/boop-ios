# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Boop is an offline social iOS app that uses Bluetooth Low Energy (BLE) and Ultra-Wideband (UWB) technology for peer-to-peer proximity-based social interactions. Users can "boop" nearby friends within touching distance, creating a chronological timeline of real-world interactions.

**Key Technologies:**
- **BLE:** Device discovery and messaging (simultaneous peripheral + central mode)
- **UWB:** Precise distance measurement (±5cm accuracy) via Nearby Interaction framework
- **SwiftData:** Local persistence for contacts and interaction history
- **Swift 6:** Latest language features with strict concurrency checking

## Build & Run

### Building from Command Line

**Important:** The Xcode project is located in the parent directory (`boop-ios.xcodeproj`), not in the source folder.

```bash
# Navigate to project root (if in boop-ios/ source directory)
cd ..

# Build for debug configuration
xcodebuild -scheme boop-ios -configuration Debug build

# Build for simulator (specify simulator name)
xcodebuild -scheme boop-ios -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -scheme boop-ios -destination 'generic/platform=iOS' build

# Clean build folder
xcodebuild -scheme boop-ios clean

# Build and run tests
xcodebuild -scheme boop-ios test -destination 'platform=iOS Simulator,name=iPhone 15'
```

**Common Build Issues:**
- **Code signing errors:** Ensure Team ID (P3PR8G7GB9) is configured
- **"No such project" error:** Make sure you're in the directory containing `boop-ios.xcodeproj`
- **Provisioning profile errors:** Use `-allowProvisioningUpdates` flag for automatic profile generation

### Running from Xcode

1. Open `boop-ios.xcodeproj` in Xcode (not the source folder)
2. Select a target device:
   - **Simulator:** For UI development (BLE/UWB features limited)
   - **Physical Device:** Required for full BLE advertising and UWB ranging
3. Ensure automatic code signing is enabled (Team: P3PR8G7GB9)
4. Press Cmd+R to build and run

**Testing Boop Functionality:**
- Requires **two physical devices** with UWB support (iPhone 11+)
- Both devices must have the app installed and open
- Open `BoopRangingView` on both devices to initiate discovery

## Git Workflow

### Branch Naming Convention

Use descriptive, ALL-CAPS prefixes for feature branches:

```
FIX-<issue-description>          # Bug fixes
ADD-<feature-name>                # New features
UPDATE-<component-name>           # Updates to existing features
REFACTOR-<component-name>         # Code refactoring
```

**Examples:**
- `FIX-TIMELINE-HEADER-ERROR`
- `ADD-PHOTO-SHARING`
- `UPDATE-BLUETOOTH-PROTOCOL`
- `REFACTOR-DATA-LAYER`

### Workflow Steps

**1. Create Feature Branch**
```bash
git checkout main
git pull
git checkout -b FIX-YOUR-FEATURE-NAME
```

**2. Make Changes & Commit**
```bash
# Stage specific files (avoid staging .claude settings)
git add boop-ios/BoopTimelineView.swift boop-ios/model/Contact.swift

# Commit with detailed message
git commit -m "$(cat <<'EOF'
Brief summary of change (50 chars or less)

Detailed explanation of what changed and why. Include:
- What problem this solves
- What changes were made
- Any technical details worth noting

Changes:
- Bullet point list of specific changes
- File-level changes if relevant

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**3. Push & Set Upstream**
```bash
# First push - set upstream tracking
git push -u origin FIX-YOUR-FEATURE-NAME

# Subsequent pushes
git push
```

**4. Create Pull Request**
- Use the GitHub URL printed after push
- Review changes in PR before merging
- Merge to main after approval

**5. Sync Main**
```bash
git checkout main
git pull
```

### Commit Best Practices

- **Atomic commits:** Each commit should represent a single logical change
- **Descriptive messages:** Explain the "why" not just the "what"
- **Co-authoring:** Always include Claude co-author line when AI assists
- **File selection:** Don't commit `.claude/settings.local.json` (local config only)
- **Build verification:** Ensure code builds before committing

### Common Commands

```bash
# Check current status
git status

# View recent commits
git log --oneline -5

# View changes before staging
git diff

# View staged changes
git diff --cached

# Unstage files
git restore --staged <file>

# Discard local changes
git restore <file>
```

## Date & Time Formatting

### Timeline Header Implementation

**File:** `BoopTimelineView.swift:23-43`

The timeline uses `RelativeDateTimeFormatter` for dynamic, user-friendly time displays:

```swift
private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full  // "2 hours ago" vs "2 hr. ago"
    return formatter
}()

private func headerText(for date: Date) -> String {
    let headerText = relativeDateFormatter.localizedString(for: date, relativeTo: Date())

    // Group fine-grained timestamps under "Today"
    let sanitized = headerText.trimmingCharacters(in: .whitespaces).lowercased()
    let words = sanitized.components(separatedBy: .whitespaces)

    if words.contains(where: { $0.contains("minute") || $0.contains("hour") }) {
        return "Today"
    }

    return headerText.capitalized
}
```

### Key Principles

**✅ DO:**
- Use `RelativeDateTimeFormatter` for relative time strings ("2 hours ago", "yesterday")
- Calculate headers **per-item** as you iterate through data
- Let the formatter choose appropriate units automatically
- Sanitize output to group fine-grained units if needed
- Show headers only when transitioning between different time periods
- Let SwiftUI re-renders handle updates (no manual timers needed)

**❌ DON'T:**
- Don't pre-group timestamps into fixed buckets/dictionaries (causes stale headers)
- Don't use `Date.RelativeFormatStyle` if you need granularity control (no `allowedUnits` property)
- Don't calculate bucketed timestamps (start-of-day, start-of-week, etc.)
- Don't use manual refresh timers unless absolutely necessary
- Don't use `DateComponentsFormatter` for relative time (it's for durations)

### Why Dynamic Calculation?

**Problem:** If you pre-group "12 minutes ago" and "25 minutes ago" into separate dictionary keys, they'll stay separate even as time passes, creating fragmented headers.

**Solution:** Calculate headers on every render:
1. Iterate through sorted items sequentially
2. Calculate header for current item
3. Compare with previous item's header
4. Show header only if different from previous

This ensures:
- Headers stay current as time passes
- "Just now" transitions to "5 minutes ago" to "Today" naturally
- No stale "17 hours ago" headers for recent items
- Proper grouping as time periods change

### Formatter Options

**`RelativeDateTimeFormatter`** (Recommended for timeline headers)
- **Pros:** Full control, localized, automatic unit selection
- **Cons:** No built-in granularity control (use string matching to group units)
- **Properties:** `unitsStyle`, `dateTimeStyle`, `formattingContext`

**`Date.RelativeFormatStyle`** (Simpler but less flexible)
- **Pros:** Modern Swift API, concise syntax
- **Cons:** No `allowedUnits` property, always shows largest unit only
- **Usage:** `date.formatted(.relative(presentation: .named))`

**`DateComponentsFormatter`** (For durations, not relative time)
- **Pros:** Good for intervals (e.g., "2h 30m")
- **Cons:** Not designed for "ago" formatting
- **Usage:** Countdown timers, elapsed time displays

## Architecture

### Core Services

**BoopManager** (`BoopManager.swift`)
- Orchestrates the entire boop interaction flow
- Maintains queue of devices in boop range (≤10cm)
- Tracks mutual selection state between users
- Implements `BoopDelegate` for event broadcasting
- Publishes `latestBoopEvent` for UI updates

**BluetoothManager** (`Bluetooth/BluetoothManager.swift`)
- Dual-mode BLE (simultaneous peripheral + central)
- Automatic connection management
- UWB token exchange coordination
- Distance categorization (InRange, ApproxTouching, OutOfRange)
- Service UUID: `D3A42A7C-DA0E-4D2C-AAB1-88C77E018A5F`

**UWBManager** (`Bluetooth/UWBManager.swift`)
- Precise distance measurement via NISession
- Thresholds: 5cm (touching), 50cm (max range)
- Direction measurement when supported

### UI Architecture

**Main Navigation Flow:**
```
RootView → checks profile → MainTabView
                           ├── BoopTimelineView (chronological feed)
                           ├── ContactsView (saved contacts)
                           └── ProfileSetupView (user profile)
```

**Timeline View** (`BoopTimelineView.swift`)
- Displays all boop interactions chronologically
- Dynamic time-based section headers
- Auto-updating timestamps
- Animated boop notifications via `BoopManager` events
- Vertical spacing: `Spacing.md` (12pt) between cards
- Horizontal padding: `Spacing.lg` (16pt) from edges

### Data Layer

**SwiftData Models:**
- `Contact`: Stores contact info and relationship to interactions
- `UserProfile`: User's name and avatar
- `BoopInteraction`: Individual boop records with timestamp, location, photos

**Important:** All stored properties in `@Model` classes must use `var` (not `let`) for Swift 6 compatibility, even if logically immutable.

## Swift 6 & Language Features

### Strict Concurrency

The project uses Swift 6 language mode with strict concurrency checking.

**Key Patterns:**
- `@MainActor` for UI-related classes (`BoopManager`, `BluetoothManager`)
- Swift `actor` for thread-safe data access (`DataStore`, `StorageCoordinator`)
- `@MainActor` closures for UI updates from background threads

### SwiftData with @Model Macro

**Critical Rule:** All stored properties in `@Model` classes must be `var`, never `let`.

**Why:** The `@Model` macro generates property wrappers for observation and persistence tracking, which requires mutable properties even if values never change at runtime.

**Common Error:**
```
Cannot expand accessor macro on variable declared with 'let';
this is an error in the Swift 6 language mode
```

**Fix:**
```swift
@Model
final class Contact {
    var uuid: UUID  // ✅ Use var, even though UUID won't change
    var displayName: String

    // NOT: let uuid: UUID  ❌
}
```

### Unused Parameter Warnings

When using `onChange(of:)` modifiers, replace unused parameters with `_`:

```swift
// ❌ Lint warning
.onChange(of: someValue) { oldValue, newValue in
    handleChange(newValue)
}

// ✅ No warning
.onChange(of: someValue) { _, newValue in
    handleChange(newValue)
}
```

## Design System

### Spacing Values

**File:** `DesignSystem/Spacing+DesignSystem.swift`

```swift
Spacing.none  // 0pt
Spacing.xs    // 4pt
Spacing.sm    // 8pt
Spacing.md    // 12pt
Spacing.lg    // 16pt
Spacing.xl    // 20pt
```

**Usage Guidelines:**
- Card padding: `Spacing.lg` (16pt)
- Vertical spacing between cards: `Spacing.md` (12pt)
- Section header padding: `.horizontal(Spacing.lg)` + `.vertical(Spacing.md)`
- Always use design system values, never hardcoded numbers

### View Modifiers

**File:** `DesignSystem/ViewModifiers+DesignSystem.swift`

```swift
.heading1Style()        // Large section headers
.heading2Style()        // Subsection headers
.primaryTextStyle()     // Main page titles
.cardStyle()            // Card backgrounds and styling
.pageBackground()       // Page-level background color
```

### Component Patterns

**Cards:**
- Use `BoopInteractionCard` for timeline items
- Use `ContactInteractionCard` for contact list items
- Always apply `.padding(.horizontal, Spacing.lg)` to cards in lists
- Add vertical spacing via `LazyVStack(spacing: Spacing.md)`

**Lists:**
- Use `LazyVStack` for large scrollable lists
- Set `spacing` parameter for vertical gaps
- Apply horizontal padding to individual items, not the stack

## Permissions

Declared in `Info.plist`:
- `NSBluetoothAlwaysUsageDescription`: Required for BLE advertising and scanning
- `NSBluetoothPeripheralUsageDescription`: Required for acting as BLE peripheral
- UWB permissions are automatically handled by Nearby Interaction framework

## Project Configuration

- **Deployment Target**: iOS 18.2
- **Swift Version**: Swift 6.0 (language mode)
- **Devices**: iPhone and iPad (universal)
- **Bundle ID**: `com.boop.boop-ios.aparna`
- **Team ID**: P3PR8G7GB9
- **Code Signing**: Automatic (requires Xcode configuration)

## Common Development Tasks

### Adding a New View

1. Create SwiftUI view file in appropriate location
2. Use design system spacing/colors (never hardcode values)
3. Add `@Query` for SwiftData models if needed
4. Apply standard view modifiers (`.pageBackground()`, etc.)
5. Add to navigation structure (tab, sheet, or NavigationLink)

### Working with SwiftData

1. Define models with `@Model` macro
2. Use `var` for all stored properties (even UUIDs)
3. Set up relationships with `@Relationship` attribute
4. Use `@Query` in views for automatic updates
5. Access `@Environment(\.modelContext)` for inserts/deletes

### Handling Boop Events

1. Listen to `BoopManager.latestBoopEvent` via `.onChange(of:)`
2. Create `BoopInteraction` and `Contact` models
3. Insert into `modelContext`
4. SwiftData automatically updates all `@Query` views
5. Show UI feedback (animations, overlays)

## Debugging Tips

### Build Errors

**"Cannot expand accessor macro":**
- Check all `@Model` classes for `let` declarations
- Change to `var` even if value is logically immutable

**"No such file or directory":**
- Ensure you're running `xcodebuild` from the directory containing `.xcodeproj`
- Use `cd ..` if you're in the `boop-ios/` source folder

**Code signing errors:**
- Check Team ID in Xcode project settings
- Ensure automatic signing is enabled
- Use `-allowProvisioningUpdates` flag for command-line builds

### Runtime Issues

**SwiftData not updating:**
- Verify `@Query` is used in view
- Check that models are inserted via `modelContext.insert()`
- Ensure container includes all model types in schema

**BLE not discovering:**
- Must use physical device (simulator has limited BLE)
- Check Bluetooth permissions in Settings
- Verify both devices are running the app
- Ensure `BluetoothManager` is properly initialized

**UWB ranging not working:**
- Requires two iPhone 11+ devices
- Devices must be connected via BLE first
- Check that UWB tokens are exchanged
- Verify `NISession` delegate is set
