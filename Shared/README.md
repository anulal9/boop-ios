# Shared Code

This folder contains code shared between the main Boop app and the Live Activity widget extension.

## Files

### BoopLiveActivityAttributes.swift
Defines the data model for Live Activities, including:
- Contact information (name, UUID, gradient colors)
- Interaction ID for deep linking
- Boop timestamp

## Configuration

These files are added to multiple Xcode targets via target membership:
- **boop-ios** (main app target)
- **BoopLiveActivityExtension** (widget extension target)

The files are NOT a Swift Package. They're regular Swift files with shared target membership.

## Adding New Shared Files

To add new shared files:
1. Create the file in this `Shared/` folder
2. In Xcode, select the file in the navigator
3. Open the File Inspector (right sidebar)
4. Under "Target Membership", check both:
   - boop-ios
   - BoopLiveActivityExtension

## Deep Linking

Live Activities use the `boop://` URL scheme:
- `boop://timeline` - Opens the timeline tab
- `boop://timeline/{interactionID}` - Opens timeline and scrolls to specific interaction

## Gradient Color Encoding

Note that there are two different gradient color encoding schemes in the codebase:

- **`BoopLiveActivityAttributes.gradientColors: [String]`** — stores colors as **hex strings** (e.g. `"#ff7aa2"`)
- **`Contact.gradientColorsData: [String]`** / **`UserProfile.gradientColorsData: [String]`** — stores colors using a custom named/serialized format via `colorToString()`/`stringToColor()` helpers

When passing gradient colors from a `Contact` to a Live Activity, convert the format accordingly.
