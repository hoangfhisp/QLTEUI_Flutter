# Android Native Accessibility Service & App Restriction Engine

## 1. Overview

To prevent distraction during scheduled study periods, QLTE integrates native Android APIs with Flutter via a custom `MethodChannel`. An Android `AccessibilityService` runs in the background on the child device, monitoring foreground applications and blocking unauthorized packages.

---

## 2. Platform Channel Architecture

Communication between the Dart runtime and the Kotlin Android layer is established over the `com.frontend_qlte/restriction` channel:

```
+-----------------------------------------------------------+
|               Flutter (Dart) Service Layer                |
|             RestrictionService.updateBlockedApps()        |
+-----------------------------------------------------------+
                            |
                     MethodChannel
             'com.frontend_qlte/restriction'
                            |
                            v
+-----------------------------------------------------------+
|              Android (Kotlin) MainActivity                |
|              MethodCallHandler / Argument Parser          |
+-----------------------------------------------------------+
                            |
                 In-Memory Companion State
                            v
+-----------------------------------------------------------+
|                 MyAccessibilityService                    |
|          onAccessibilityEvent(TYPE_WINDOW_STATE_CHANGED)  |
|          -> Check packageName against blockedApps         |
|          -> performGlobalAction(GLOBAL_ACTION_HOME)       |
+-----------------------------------------------------------+
```

---

## 3. Platform Channel Methods

| Method Name | Direction | Arguments | Description |
| :--- | :--- | :--- | :--- |
| `updateBlockedApps` | Dart -> Kotlin | `{'apps': List<String>}` | Updates the active list of restricted package names. |
| `openAccessibilitySettings` | Dart -> Kotlin | `null` | Launches Android system settings so the user can grant Accessibility permissions. |
| `isAccessibilityEnabled` | Dart -> Kotlin | `null` | Returns a boolean indicating whether the service is currently enabled in OS settings. |
| `openOverlaySettings` | Dart -> Kotlin | `null` | Requests system overlay authorization for drawing alerts on top of other applications. |

---

## 4. Kotlin Service Implementation

### 4.1 Accessibility Event Interception
The service registers for `AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED` inside `accessibility_config.xml`:

```kotlin
override fun onAccessibilityEvent(event: AccessibilityEvent?) {
    if (event == null) return
    if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

    val packageName = event.packageName?.toString() ?: return

    if (blockedApps.any { packageName.contains(it, ignoreCase = true) }) {
        Toast.makeText(this, "Application blocked during study hours", Toast.LENGTH_SHORT).show()
        performGlobalAction(GLOBAL_ACTION_HOME)
    }
}
```

### 4.2 Configuration Manifest (`accessibility_config.xml`)
The service is configured with minimal overhead to prevent battery drain:
- **Event Types**: `typeWindowStateChanged`
- **Feedback Type**: `feedbackGeneric`
- **Flags**: `flagDefault`
