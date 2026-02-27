# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

This is an iOS SwiftUI app using Xcode. There is no CLI build toolchain — open `CookingApp.xcodeproj` in Xcode, let SPM resolve Firebase dependencies, then build (Cmd+B) and run.

**Required before first build:** Replace `CookingApp/GoogleService-Info.plist` with a real one from Firebase Console (the file contains setup instructions). The app crashes on launch without it.

## Architecture

MVVM with three singleton services. All ViewModels are `@MainActor ObservableObject` classes using async/await.

**Data flow:** Firestore → `FirestoreService` → ViewModels (`@Published` properties) → SwiftUI Views

**Routing:** `ContentView` checks `UserPreferencesManager.shared.hasCompletedOnboarding` to show either `OnboardingContainerView` (4-page TabView pager) or `MainTabView` (Home/Shopping/Settings tabs). Setting `hasCompletedOnboarding = true` triggers the route change reactively.

**Services (all singletons):**
- `UserPreferencesManager.shared` — Wraps UserDefaults. Persists `DietaryProfile` and `NotificationPreferences` as Codable JSON. `@Published` properties auto-save via `didSet`. Generates and stores a stable device UUID.
- `FirestoreService.shared` — Reads `recipes` collection, writes to `dietaryProfiles` collection. Recipe filtering is **client-side**: fetches all recipes then filters by allergens (recipe must be free of all user allergies) and dietary tags (recipe must match ALL selected user diets).
- `NotificationService.shared` — Schedules 3 repeating daily local notifications via `UNCalendarNotificationTrigger`. Each has a unique identifier (`com.cookingapp.morning/shopping/cooking`) so they update independently. Notifications are rescheduled whenever the recipe changes or settings are saved.

**Today's recipe selection:** Deterministic per calendar day — uses `Calendar.current.ordinality(of: .day, in: .era)` mod recipe count. The "Skip" button picks a random alternative.

## Firestore Schema

**`recipes` collection:** Documents decoded into `Recipe` model using `@DocumentID`. Key fields: `dietaryTags: [String]` (diet types present), `allergenFree: [String]` (allergens NOT present), `ingredients: [{name, amount, unit}]`.

**`dietaryProfiles` collection:** Document ID = device UUID. Written anonymously on onboarding completion and settings save. Contains `allergies`, `diets`, and `createdAt` server timestamp.

## Key Enums

`Allergy` (8 cases): nuts, dairy, gluten, shellfish, eggs, soy, fish, sesame
`Diet` (9 cases): vegetarian, vegan, pescatarian, keto, glutenFree, halal, kosher, dairyFree, lowCarb

Both are `String`-rawValue `Codable CaseIterable` enums. Their `rawValue` strings are used as Firestore field values, so changing them is a breaking schema change.

## Dependencies

Single SPM dependency: `firebase-ios-sdk` (>= 10.0.0). Only `FirebaseCore` and `FirebaseFirestore` modules are used.
