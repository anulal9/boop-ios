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

### Directory Structure

```
boop-ios/                              # Source root
├── boop_iosApp.swift                  # App entry point, ModelContainer setup
├── RootView.swift                     # Auth routing (profile check)
├── MainTabView.swift                  # 3-tab navigation
├── BoopTimelineView.swift             # Timeline feed
├── BoopRangingView.swift              # BLE scanning UI
├── ContactsView.swift                 # Contacts list
├── ContactDetailView.swift            # Contact detail sheet
├── ProfileView.swift                  # Profile display/edit
├── ProfileSetupView.swift             # Onboarding flow
├── AddManualBoopView.swift            # Manual boop entry sheet
├── BoopManager.swift                  # Orchestration layer
├── StorageCoordinator.swift           # Async storage init
├── Bluetooth/
│   ├── BluetoothManager.swift         # BLE coordinator
│   ├── BluetoothManagerService.swift  # Central + Peripheral implementation
│   ├── UWBManager.swift               # UWB ranging (per-device NISession)
│   └── UWBService.swift               # Distance threshold logic
├── DataStore/
│   └── DataStore.swift                # UserDefaults actor with caching
├── DesignSystem/
│   ├── Colors+DesignSystem.swift
│   ├── Typography+DesignSystem.swift
│   ├── Spacing+DesignSystem.swift
│   ├── Sizes+DesignSystem.swift
│   ├── Radius+DesignSystem.swift
│   └── ViewModifiers+DesignSystem.swift
├── Components/
│   ├── BoopInteractionCard.swift      # Timeline card
│   ├── ContactInteractionCard.swift   # Contact list card
│   ├── ProfileDisplayCard.swift
│   └── Gradient/
│       ├── AnimatedMeshGradient.swift  # 3x3 MeshGradient animation
│       ├── StyledTextField.swift
│       ├── DatePickerField.swift
│       └── ProfilePhotoSelector.swift
├── model/
│   ├── Contact.swift                  # @Model
│   ├── UserProfile.swift              # @Model
│   ├── BoopInteraction.swift          # @Model
│   ├── Boop.swift                     # Value type for boop data
│   ├── BoopEvent.swift                # Boop + timestamp wrapper
│   ├── BluetoothMessage.swift         # Binary BLE protocol
│   ├── NearbyDevice.swift
│   ├── ConnectionRequest.swift
│   ├── ConnectionResponse.swift
│   ├── AvatarImage.swift
│   └── BoopLiveActivityAttributes.swift
├── UserDefaults/
│   ├── UserDefaultsKeys.swift
│   └── UserDefaultsUtility.swift
└── Utilities/
    ├── LiveActivityManager.swift
    └── StringSanitization.swift
```

### Persisted Data Store

The app uses **two persistence layers**: SwiftData for relational data and UserDefaults for user profile quick-access.

#### SwiftData Models

**`Contact`** (`model/Contact.swift`)
- `uuid: UUID` — remote device's UUID
- `displayName: String`, `avatarData: Data?`, `birthday: Date?`, `bio: String?`
- `gradientColorsData: [String]` — colors stored as strings, converted via `colorToString()`/`stringToColor()`
- `@Relationship(deleteRule: .cascade, inverse: \BoopInteraction.contact) var interactions: [BoopInteraction]` — one-to-many, cascade delete

**`BoopInteraction`** (`model/BoopInteraction.swift`)
- `id: UUID`, `title: String`, `location: String`, `timestamp: Date`
- `imageData: [Data]` — photo attachments
- `contact: Contact?` — inverse relationship back to Contact

**`UserProfile`** (`model/UserProfile.swift`)
- `name: String`, `createdAt: Date`, `avatarData: Data?`, `birthday: Date?`, `bio: String?`
- `gradientColorsData: [String]` — same color storage pattern as Contact

**Critical rule:** All `@Model` stored properties must be `var` (not `let`) for Swift 6 compatibility.

#### ModelContainer Setup (`boop_iosApp.swift`)

```
Schema: [Contact, UserProfile, BoopInteraction]
```

The app entry point creates the `ModelContainer` asynchronously after `StorageCoordinator` finishes directory setup. A loading screen shows until the container is ready, then `RootView` receives it via `.modelContainer()`.

#### DataStore Actor (`DataStore/DataStore.swift`)

A Swift `actor` providing thread-safe UserDefaults access with in-memory caching for user profile data. Key methods:
- `warmup()` — preloads profile data on app init
- `getUserProfile()` → `UserProfileData` DTO
- `setUserProfile(_ profile: UserProfile)` — writes to both cache and UserDefaults
- `isProfileComplete()` / `setProfileComplete()`

#### StorageCoordinator (`StorageCoordinator.swift`)

An `actor` that coordinates async initialization of the SwiftData directory. Uses checked continuations to block ModelContainer creation until the storage directory exists, preventing race conditions.

### Bluetooth

#### BluetoothManager (`Bluetooth/BluetoothManager.swift`, `@MainActor`)

Top-level BLE coordinator. Owns the `BluetoothManagerServiceImpl` (central + peripheral) and `UWBManager`.

- `start()` / `stop()` — starts/stops BLE advertising, scanning, and UWB
- `getNearbyDevices()` → `[UUID: DevicePositionCategory]`
- `sendMessage()` / `sendPresence()` — sends BLE messages to specific devices
- `localDeviceUUID` — persisted in UserDefaults, stable across sessions
- Publishes `nearbyDevices` from UWBManager's Combine publisher

#### BluetoothManagerService (`Bluetooth/BluetoothManagerService.swift`, `@MainActor`)

Implements **dual-mode BLE** — the device acts as both peripheral (advertising) and central (scanning) simultaneously.

**Service UUIDs:**
```
Service:     D3A42A7C-DA0E-4D2C-AAB1-88C77E018A5F
Message:     D3A42A7D-... (.write, .notify)
UWB Token:   D3A42A7E-... (.read, .write)
Token ACK:   D3A42A7F-... (.notify)
```

**Binary Protocol (`BluetoothMessage`):**
```
[UUID: 16 bytes][MessageType: 1 byte][DisplayNameLength: 1 byte]
[DisplayName: variable][PayloadLength: 2 bytes][Payload: variable]
```

**Message Types:**
- `0x01` connectionRequest, `0x02` accept, `0x03` reject, `0x05` disconnect
- `0x06` boop (mutual boop confirmed)
- `0x07` boopRequest (user selected device)
- `0x08` presence (name/profile announcement)

**Delegates:**
- `BluetoothServiceDelegate` — connection events, UWB token exchange
- `BoopDelegate` — boop/request/presence received callbacks

#### UWBManager (`Bluetooth/UWBManager.swift`, `@MainActor`)

**Per-device NISession architecture** — each connected peer gets its own `NISession` instance.

**Distance Thresholds:**
- ≤ 5cm → `ApproxTouching` (boop range)
- ≤ 50cm → `InRange` (nearby)
- \> 50cm → `OutOfRange`

**Flow:** Discovery tokens are exchanged via BLE characteristics. Once both peers have each other's token, ranging begins via `NINearbyPeerConfiguration`. Distance updates publish to `nearbyDevices: [UUID: DevicePositionCategory]` via Combine.

### BoopManager — Orchestration (`BoopManager.swift`, `@MainActor`)

Central orchestrator tying BLE + UWB + UI together. Injected as `@StateObject` at the app root and passed via `@EnvironmentObject`.

**Key Published State:**
- `latestBoopEvent: BoopEvent?` — triggers timeline overlay animation on new boops
- `mySelections: Set<UUID>` / `theirSelections: Set<UUID>` — mutual selection tracking
- `displayNames: [UUID: String]` — maps peer UUIDs to display names

**Mutual Boop Flow:**
1. User taps a device → `selectDevice(deviceID)` adds to `mySelections`, sends `.boopRequest`
2. Remote peer does the same → `didReceiveBoopRequest` adds to `theirSelections`
3. `checkForMutualSelection()` detects both sets contain the peer
4. Sends `.boop` message, clears selections, creates `BoopEvent`
5. `latestBoopEvent` triggers UI overlay + SwiftData persistence in `BoopTimelineView`

**Observer Pattern:** Subscribes to `bluetoothManager.nearbyDevices` publisher. On device discovery, sends presence. On disconnect, cleans up selections.

### View + Model Pattern

#### Navigation Structure

```
boop_iosApp (ModelContainer + BoopManager)
  └─ RootView (checks if profile exists)
       ├─ ProfileSetupView (onboarding, requireAllFields=true)
       └─ MainTabView
            ├─ Tab 1: BoopTimelineView
            │    ├─ Toolbar: "+" → AddManualBoopView (sheet)
            │    ├─ @Query BoopInteraction (sorted by timestamp desc)
            │    └─ NavigationLink → interaction detail
            ├─ Tab 2: ContactsView
            │    ├─ Toolbar: "+" → BoopRangingView (sheet)
            │    ├─ @Query Contact
            │    └─ Tap → ContactDetailView (sheet)
            └─ Tab 3: ProfileView
                 ├─ Display mode (gradient bg + profile card)
                 ├─ Edit mode (ProfileSetupView, requireAllFields=false)
                 └─ Customize mode (color picker)
```

#### State Management Patterns

- **`@Query`** — Views subscribe to SwiftData queries for automatic UI updates when models change
- **`@Environment(\.modelContext)`** — Used for inserts and deletes
- **`@EnvironmentObject`** — `BoopManager` injected at app root, available in all views
- **`@StateObject`** — `BoopManager` lifecycle owned by `boop_iosApp`
- **`@Published`** — Manager properties that drive UI (selections, display names, events)
- **`@State`** — Local UI state (sheet presentation, editing mode, form fields)

#### Data Flow: Boop → Timeline

1. UWB detects touching distance → BLE exchanges mutual boop messages
2. `BoopManager.didReceiveBoop()` creates `BoopEvent`, sets `latestBoopEvent`
3. `BoopTimelineView.onChange(of: latestBoopEvent)` fires `handleNewBoop()`
4. `handleNewBoop()` finds/creates `Contact`, creates `BoopInteraction`, inserts into `modelContext`
5. `@Query` automatically picks up the new interaction → UI updates

#### Card Components

- **`BoopInteractionCard`** — timeline items with title, location, relative time, overlapping thumbnails. Uses `TimelineView(.periodic(by: 60))` for auto-refreshing timestamps.
- **`ContactInteractionCard`** — contact list items with name, boop count, last boop time
- **`AnimatedMeshGradient`** — 3x3 MeshGradient with configurable wave animation (vertical/horizontal), used for profile backgrounds

### Design System

All design tokens live in `DesignSystem/`. Never hardcode visual values — always use the token enums.

#### Colors (`Colors+DesignSystem.swift`)

| Token | Value | Usage |
|-------|-------|-------|
| `backgroundPrimary` | #130914 | Page backgrounds |
| `backgroundSecondary` | #1d0f22 | Card backgrounds |
| `formBackgroundInactive` | #342d39 | Form field backgrounds |
| `textPrimary` | #ffffff | Primary text |
| `textSecondary` | #f4d9f2 | Card titles, subtitles |
| `textMuted` | #b28bb8 | Section headers, captions |
| `textOnAccent` | #130914 | Text on accent buttons |
| `accentPrimary` | #ff7aa2 | Buttons, links, tint |
| `accentSecondary` | #3a1e3f | Selected/highlighted state |
| `accentTertiary` | #4ec8f4 | Secondary accent |

#### Typography (`Typography+DesignSystem.swift`)

| Font | Weight | Size | Line Height |
|------|--------|------|-------------|
| `.primary` | Bold | 32pt | 1.1 |
| `.heading1` | Semibold | 28pt | 1.13 |
| `.heading2` | Semibold | 24pt | 1.1 |
| `.subtitle` | Regular | 14pt | 1.43 |

#### Spacing, Radius, Sizes

See [Spacing Values](#spacing-values) above. Corner radii: `sm` 4pt, `md` 8pt, `lg` 12pt, `xl` 16pt.

#### View Modifiers (`ViewModifiers+DesignSystem.swift`)

**Typography:** `.primaryTextStyle()`, `.heading1Style()`, `.heading2Style()`, `.subtitleStyle()`, `.errorTextStyle()`, `.successTextStyle()`

**Containers:** `.cardStyle()` (backgroundSecondary + cornerRadius.md), `.pageBackground()` (backgroundPrimary), `.sectionContainer()` (standard padding)

**Interactive:** `.iconButtonStyle()` (44pt circle), `.primaryButtonStyle()` (full-width accent button)

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
