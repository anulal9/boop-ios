# Boop iOS

An offline social iOS app that enables users to discover, connect, and interact with nearby friends using Ultra-Wideband (UWB) and Bluetooth Low Energy (BLE) technology. When users come within touching distance, they can "boop" each other to create connections and track interactions.

## Overview

Boop is a peer-to-peer proximity app that operates entirely offline. It uses BLE for device discovery and communication, combined with UWB for precise distance measurement (down to centimeter-level accuracy). The app enables spontaneous social interactions through physical proximity rather than traditional networking.

## Architecture

### Key Services

#### 1. **BoopManager** (`BoopManager.swift`)
The core orchestration layer that manages the entire boop interaction flow.

- **Responsibilities:**
  - Maintains queue of devices in "boop" range (≤10cm with aligned angles)
  - Tracks mutual selection state between users
  - Manages display names for discovered devices
  - Coordinates between BluetoothManager and UI layer
  - Implements `BoopDelegate` protocol to receive boop events

- **Key Properties:**
  - `boopQueue`: Set of device UUIDs currently in touching range
  - `mySelections`: Devices the user has selected for booping
  - `theirSelections`: Devices that have selected the user
  - `displayNames`: Maps device UUIDs to user display names
  - `boopsToRender`: Queue of completed boops ready for UI display

- **Location:** `/boop-ios/BoopManager.swift:10`

#### 2. **BluetoothManager** (`BluetoothManager.swift`)
Manages dual-mode BLE operations (peripheral + central) and coordinates UWB ranging.

- **Responsibilities:**
  - Simultaneous BLE advertising (peripheral) and scanning (central)
  - Automatic connection management for discovered devices
  - UWB token exchange between devices
  - Distance categorization (InRange, ApproxTouching, OutOfRange)
  - Device lifecycle management (discovery, connection, disconnection)

- **Key Properties:**
  - `nearbyDevices`: Dictionary of discovered devices with their distance categories
  - `connectedPeripherals`: Active BLE peripheral connections
  - `localDeviceUUID`: Persistent unique identifier for this device

- **Integration:**
  - Delegates to `BluetoothManagerServiceImpl` for BLE operations
  - Coordinates with `UWBManager` for distance measurements
  - Implements `BluetoothServiceDelegate` and `UWBManagerDelegate`

- **Location:** `/boop-ios/Bluetooth/BluetoothManager.swift:8`

#### 3. **BluetoothManagerServiceImpl** (`BluetoothManagerService.swift`)
Low-level BLE service handling both peripheral and central roles.

- **Responsibilities:**
  - Manages `CBCentralManager` (scanning for peripherals)
  - Manages `CBPeripheralManager` (advertising as a peripheral)
  - Handles GATT service/characteristic discovery and operations
  - Processes incoming BLE messages via binary protocol
  - Exchanges UWB tokens between devices

- **BLE Configuration:**
  - Service UUID: `D3A42A7C-DA0E-4D2C-AAB1-88C77E018A5F`
  - Message Characteristic UUID: `D3A42A7D-DA0E-4D2C-AAB1-88C77E018A5F`
  - UWB Token Characteristic UUID: `D3A42A7E-DA0E-4D2C-AAB1-88C77E018A5F`

- **Location:** `/boop-ios/Bluetooth/BluetoothManagerService.swift:42`

#### 4. **UWBManager** (`UWBManager.swift`)
Handles Ultra-Wideband ranging for precise distance measurement.

- **Responsibilities:**
  - Manages `NISession` (Nearby Interaction framework)
  - Tracks nearby objects with distance and direction data
  - Provides distance-based proximity detection
  - Handles UWB discovery token exchange

- **Distance Thresholds:**
  - `touchingDistance`: 5cm (0.05m) - for "boop" interactions
  - `maxDistance`: 50cm (0.5m) - maximum proximity range

- **Key Methods:**
  - `isNearby(deviceID:)`: Checks if device is within 50cm
  - `isApproximatelyTouching(deviceID:)`: Checks if device is within 5cm
  - `startRanging(to:peerToken:)`: Initiates UWB ranging session
  - `stopRanging(to:)`: Terminates ranging session

- **Location:** `/boop-ios/Bluetooth/UWBManager.swift:47`

#### 5. **DataStore** (`DataStore/DataStore.swift`)
Actor-based unified data access layer with in-memory caching.

- **Responsibilities:**
  - Provides async interface to UserDefaults
  - Implements warmup pattern for frequently accessed data
  - Manages user profile data (name, avatar)
  - Thread-safe data access via Swift actor

- **Key Methods:**
  - `warmup()`: Pre-loads data into cache during app initialization
  - `getUserProfile()`: Returns complete user profile data
  - `setUserProfile(_:)`: Saves profile to both cache and UserDefaults
  - `clear()`: Removes all user data (for logout)

- **Location:** `/boop-ios/DataStore/DataStore.swift:5`

#### 6. **StorageCoordinator** (`StorageCoordinator.swift`)
Async storage initialization coordinator to prevent race conditions.

- **Responsibilities:**
  - Ensures storage directories exist before database access
  - Coordinates async initialization with continuation-based waiting
  - Prevents race conditions between directory creation and SwiftData access

- **Location:** `/boop-ios/StorageCoordinator.swift:5`

### Data Storage & Persistence

#### **SwiftData** (Primary Database)

The app uses Apple's SwiftData framework for local persistence with a schema containing two main models:

**Models:**

1. **Contact** (`model/Contact.swift`)
   - `uuid: UUID` - Unique identifier for the contact (matches sender's device UUID)
   - `displayName: String` - User's display name
   - `interactions: [BoopInteraction]` - Array of boop interactions with this contact
   - **Location:** `/boop-ios/model/Contact.swift:13`

2. **UserProfile** (`model/UserProfile.swift`)
   - `name: String` - User's display name
   - `createdAt: Date` - Profile creation timestamp
   - `avatarData: Data?` - Optional profile photo
   - **Location:** `/boop-ios/model/UserProfile.swift:5`

3. **BoopInteraction** (`model/BoopInteraction.swift`)
   - `id: UUID` - Unique interaction identifier
   - `title: String` - Interaction title (contact's name)
   - `location: String` - Location of interaction (currently placeholder)
   - `timestamp: Date` - When the boop occurred
   - `imageData: [Data]` - Optional photos from the interaction
   - **Location:** `/boop-ios/model/BoopInteraction.swift:13`

**Configuration:**
- Container setup: `/boop-ios/boop_iosApp.swift:15`
- Schema: `[Contact.self, UserProfile.self]`
- Storage: Persistent (not in-memory)
- Directory initialization: Handled by `StorageCoordinator`

#### **UserDefaults** (Session & Preferences)

Used for lightweight data and app state:

**Keys** (`UserDefaults/UserDefaultsKeys.swift`):
- `name`: User's display name
- `avatarData`: Profile photo data
- `profileComplete`: Whether profile setup is complete
- `com.boop.localDeviceUUID`: Persistent device UUID for BLE identity

**Access Pattern:**
- All UserDefaults access is routed through `DataStore` for consistency
- In-memory cache layer for performance
- Warmup pattern loads frequently accessed keys on app start

#### **Data Transfer Models**

**Non-persisted models for runtime state:**

1. **BluetoothMessage** (`model/BluetoothMessage.swift`)
   - Binary protocol for BLE communication
   - Message types: connectionRequest, connectionAccept, connectionReject, disconnect, boop, boopRequest, presence
   - Includes sender UUID, message type, display name, and payload
   - Max display name: 50 bytes (UTF-8)

2. **NearbyDevice** (`model/NearbyDevice.swift`)
   - UI representation of discovered devices
   - Contains: id, displayName, distance category, selection state

3. **Boop** (`model/Boop.swift`)
   - Represents a completed boop event
   - Contains: senderUUID, displayName

4. **ConnectionRequest/Response** (`model/ConnectionRequest.swift`, `model/ConnectionResponse.swift`)
   - Connection handshake state models

### Views & Navigation

#### **Entry Point**

**boop_iosApp** (`boop_iosApp.swift:12`)
- App entry point decorated with `@main`
- Initializes SwiftData schema and model container
- Sets up `StorageCoordinator` and `DataStore`
- Creates global `BoopManager` as environment object
- Shows loading screen while container initializes
- Navigates to `RootView` once ready

#### **Root Navigation**

**RootView** (`RootView.swift:3`)
- First view after app initialization
- Checks if user profile exists via `DataStore`
- **Routes:**
  - Profile exists → `MainTabView`
  - No profile → `ProfileSetupView` (setup mode)

#### **Main Interface**

**MainTabView** (`MainTabView.swift:4`)
- Root tab container for authenticated users
- **Tabs:**
  1. **Timeline** (`BoopTimelineView`) - Tab icon: `clock`
  2. **Contacts** (`ContactsView`) - Tab icon: `person.2`
  3. **You** (`ProfileSetupView`) - Tab icon: `person.crop.circle`

#### **Primary Views**

1. **BoopTimelineView** (`BoopTimelineView.swift:11`)
   - **Purpose:** Chronological timeline of all boop interactions
   - **Features:**
     - Dynamic time-based section headers ("Today", "Yesterday", "2 hours ago", etc.)
     - Auto-updating relative timestamps using `RelativeDateTimeFormatter`
     - Grouped interactions with headers that recalculate on every render
     - Animated boop overlay when new interactions occur
     - Navigation to detailed interaction view
   - **Data Source:** SwiftData `@Query` for `BoopInteraction` models (sorted by timestamp, newest first)
   - **Technical Details:**
     - Uses `RelativeDateTimeFormatter` with `.full` units style
     - Groups minute/hour-level timestamps under "Today" to reduce header granularity
     - Headers display only when transitioning between different time periods
     - Real-time event broadcasting from `BoopManager.latestBoopEvent`

2. **ContactsView** (`ContactsView.swift:11`)
   - **Purpose:** Display list of saved contacts
   - **Features:**
     - Scrollable list of contact cards
     - Swipe-to-delete functionality
     - Plus button to trigger new boop ranging
     - Tap contact to view boop history
   - **Navigation:**
     - Sheet: `BoopRangingView` (when + button tapped)
     - Sheet: `BoopHistoryView` (when contact selected)
   - **Data Source:** SwiftData `@Query` for `Contact` models

3. **BoopRangingView** (`BoopRangingView.swift:11`)
   - **Purpose:** Discover and boop nearby users
   - **Features:**
     - Real-time list of nearby devices with distance indicators
     - Distance categories: "Very close" (🤝), "Nearby" (📡), "Far" (📍)
     - Selection interface for initiating boops
     - Mutual selection detection (both users must select each other)
     - Animated boop success overlay
     - Auto-dismiss after successful boop
   - **Data Source:**
     - `BoopManager.nearbyDevices` for discovered devices
     - `BoopManager.displayNames` for user names
     - SwiftData contacts for saved contact lookup
   - **Lifecycle:** Presented as a sheet, dismisses after successful boop

4. **ProfileSetupView** (`ProfileSetupView.swift:4`)
   - **Purpose:** User profile creation and editing
   - **Modes:**
     - Setup mode (first launch): Blocks navigation until complete
     - Edit mode (from tab): Allows saving and dismissing
   - **Features:**
     - Profile photo picker with `PhotosUI` integration
     - Name text field with validation
     - Save/Continue button (enabled when name is not empty)
   - **Data:** Saves to both SwiftData (`UserProfile` model) and `DataStore`

5. **BoopHistoryView** (in `ContactsView.swift:73`)
   - **Purpose:** Display interaction history with a specific contact
   - **Features:**
     - List of all boop interactions
     - Shows timestamp and location for each interaction
   - **Data Source:** `Contact.interactions` array

#### **Reusable Components**

Located in `/boop-ios/Components/`:

- **BoopInteractionCard**: Displays individual boop interaction details
- **ContactInteractionCard**: Displays contact summary with recent interaction info
- **ProfilePhotoSelector**: Avatar image picker component
- **StyledTextField**: Consistent text field styling
- **AnimatedTextFieldMeshGradient**: Animated gradient background for text inputs

#### **Design System**

Located in `/boop-ios/DesignSystem/`:

- **Colors+DesignSystem**: Centralized color palette
- **Typography+DesignSystem**: Text style definitions
- **Spacing+DesignSystem**: Consistent spacing values
- **Sizes+DesignSystem**: Standard size constants
- **Radius+DesignSystem**: Border radius values
- **ViewModifiers+DesignSystem**: Reusable view modifiers (card style, page background, etc.)

## Interaction Flow

### Boop Sequence

1. **Discovery:**
   - User A and User B open `BoopRangingView`
   - `BluetoothManager` advertises and scans simultaneously
   - Both devices discover each other via BLE

2. **Connection:**
   - Devices automatically connect when discovered
   - Exchange UWB tokens via BLE characteristics
   - `UWBManager` starts ranging session

3. **Proximity Detection:**
   - UWB provides real-time distance measurements
   - Devices categorized: InRange (≤50cm), ApproxTouching (≤5cm)
   - UI updates to show nearby users with distance indicators

4. **Selection:**
   - User A selects User B from the list
   - `BoopManager.selectDevice()` called
   - Sends `boopRequest` message via BLE
   - User B's device shows "Wants to boop you!" indicator

5. **Mutual Selection:**
   - User B also selects User A
   - `BoopManager.checkForMutualSelection()` detects mutual selection
   - Both devices send `boop` message
   - Boop is confirmed on both sides

6. **Persistence:**
   - `BoopInteraction` created with timestamp and display name
   - If contact exists, interaction added to their history
   - If new contact, `Contact` model created with initial interaction
   - Saved to SwiftData
   - UI shows animated "Boop!" overlay
   - View auto-dismisses after animation

## Technical Details

### BLE Protocol

**Service Architecture:**
- One primary service: Boop Service (`D3A42A7C-DA0E-4D2C-AAB1-88C77E018A5F`)
- Two characteristics:
  1. Message Characteristic (write): For sending boop messages, connection requests, etc.
  2. UWB Token Characteristic (read/write): For exchanging UWB discovery tokens

**Message Format:**
```
[UUID: 16 bytes][MessageType: 1 byte][DisplayNameLength: 1 byte][DisplayName: variable][PayloadLength: 2 bytes][Payload: variable]
```

**Message Types:**
- `0x01`: connectionRequest
- `0x02`: connectionAccept
- `0x03`: connectionReject
- `0x05`: disconnect
- `0x06`: boop (confirmed interaction)
- `0x07`: boopRequest (user selected this device)
- `0x08`: presence (announce display name when connecting)

### UWB Integration

**Framework:** Apple's Nearby Interaction (NearbyInteraction framework)

**Capabilities:**
- Precise distance measurement (±5cm accuracy)
- Direction measurement (when supported)
- Peer-to-peer ranging via discovery tokens

**Token Exchange:**
1. Device A connects to Device B via BLE
2. Device A reads Device B's UWB token characteristic
3. Device A writes its own UWB token to Device B
4. Both devices call `NISession.run()` with peer token
5. `NISessionDelegate` callbacks provide distance updates

### Date & Time Formatting

**Timeline Headers** (`BoopTimelineView.swift:23-43`)

The app uses `RelativeDateTimeFormatter` for dynamic, human-readable time displays:

```swift
let formatter = RelativeDateTimeFormatter()
formatter.unitsStyle = .full  // "2 hours ago" vs "2 hr. ago"
let text = formatter.localizedString(for: date, relativeTo: Date())
```

**Key Implementation Details:**
- **Dynamic Recalculation:** Headers recalculate on every view render to stay current
- **Granularity Control:** Minutes/hours are grouped under "Today" to prevent excessive header fragmentation
- **Sequential Display:** Headers appear only when transitioning between time periods
- **No Pre-grouping:** Avoid bucketing timestamps into fixed intervals (prevents stale headers)

**Best Practices:**
- Use `RelativeDateTimeFormatter` instead of `Date.RelativeFormatStyle` when you need more control
- For timeline/feed UIs, calculate headers per-item rather than pre-grouping into dictionaries
- Sanitize formatter output to group fine-grained units (e.g., "12 minutes ago" → "Today")
- Let SwiftUI re-render handle updates rather than manual refresh timers

**Alternative Formatters:**
- `Date.RelativeFormatStyle`: Simpler API but no granularity control
- `DateComponentsFormatter`: Good for durations/intervals, not relative times
- `Date.FormatStyle`: For absolute date/time displays

### Thread Safety

- `BoopManager`: `@MainActor` - all UI updates on main thread
- `BluetoothManager`: `@MainActor` - Bluetooth state changes on main thread
- `DataStore`: Swift actor - automatic thread-safe data access
- `StorageCoordinator`: Swift actor - safe async initialization

### Performance Optimizations

1. **In-memory Caching:** DataStore pre-loads frequently accessed data
2. **Async Storage Init:** StorageCoordinator prevents blocking UI during setup
3. **Lazy Loading:** UI components use `LazyVStack` for large lists
4. **Combine Publishers:** Reactive updates for device discovery and distance changes
5. **Stale Device Removal:** Automatic cleanup of disconnected devices

## Build & Run

### Requirements

- Xcode 15.0+
- iOS 18.2+
- Physical device with UWB support (iPhone 11 or later)
- Bluetooth and UWB permissions

### Build Commands

```bash
# Build for debug
xcodebuild -scheme boop-ios -configuration Debug build

# Build for simulator
xcodebuild -scheme boop-ios -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for device
xcodebuild -scheme boop-ios -destination 'generic/platform=iOS' build

# Clean
xcodebuild -scheme boop-ios clean
```

### Running

1. Open `boop-ios.xcodeproj` in Xcode
2. Select a physical device (UWB requires real hardware)
3. Ensure code signing is configured (Team: P3PR8G7GB9)
4. Run with Cmd+R

### Permissions

Declared in `Info.plist`:
- `NSBluetoothAlwaysUsageDescription`: Required for BLE advertising and scanning
- `NSBluetoothPeripheralUsageDescription`: Required for acting as BLE peripheral

## Project Structure

```
boop-ios/
├── boop_iosApp.swift              # App entry point
├── RootView.swift                 # Root navigation
├── MainTabView.swift              # Main tab container
│
├── Bluetooth/                     # BLE & UWB services
│   ├── BluetoothManager.swift
│   ├── BluetoothManagerService.swift
│   └── UWBManager.swift
│
├── DataStore/                     # Data access layer
│   └── DataStore.swift
│
├── model/                         # Data models
│   ├── Contact.swift              # SwiftData
│   ├── UserProfile.swift          # SwiftData
│   ├── BoopInteraction.swift      # SwiftData
│   ├── BluetoothMessage.swift     # Protocol
│   ├── NearbyDevice.swift         # UI model
│   ├── Boop.swift                 # Event model
│   ├── ConnectionRequest.swift
│   └── ConnectionResponse.swift
│
├── Views/
│   ├── BoopTimelineView.swift
│   ├── ContactsView.swift
│   ├── BoopRangingView.swift
│   └── ProfileSetupView.swift
│
├── Components/                    # Reusable UI components
│   ├── BoopInteractionCard.swift
│   ├── ContactInteractionCard.swift
│   ├── ProfilePhotoSelector.swift
│   └── StyledTextField.swift
│
├── DesignSystem/                  # Design tokens & styles
│   ├── Colors+DesignSystem.swift
│   ├── Typography+DesignSystem.swift
│   ├── Spacing+DesignSystem.swift
│   └── ViewModifiers+DesignSystem.swift
│
├── UserDefaults/                  # UserDefaults utilities
│   ├── UserDefaultsKeys.swift
│   └── UserDefaultsUtility.swift
│
├── Utilities/
│   └── StringSanitization.swift
│
├── StorageCoordinator.swift       # Async storage init
└── BoopManager.swift              # Core boop coordinator
```

## Future Enhancements

- Location services integration for automatic location tagging
- Photo sharing during boop interactions
- Boop notifications and haptic feedback
- Group boop functionality
- Privacy controls and blocking
- Export/backup contact data
- Analytics for boop frequency and patterns
