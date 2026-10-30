# Crop Advisory App Recreation Guide

This guide provides a step-by-step breakdown of how to recreate the Crop Advisory app. It's designed to be followed in order, but you can also use it as a reference for specific features.

## Part 1: Project Setup & Core Infrastructure

### Step 1: Initialize Flutter Project & Basic Setup

*   **1.1: Initialize a new Flutter project:**
    ```bash
    flutter create crop_advisory
    ```
*   **1.2: Clean up the default boilerplate code:**
    *   Remove the `MyHomePage` widget and related code from `lib/main.dart`.
*   **1.3: Define the project structure:**
    *   Create the following directories in the `lib` folder:
        *   `core`: For shared code like configuration, constants, providers, themes, and utils.
        *   `features`: For individual app features (e.g., auth, home, chatbot).
        *   `models`: For data models.
        *   `services`: For business logic and API interactions.
        *   `widgets`: For reusable UI components.
*   **1.4: Set up linting rules:**
    *   Review and customize the `analysis_options.yaml` file to enforce your preferred coding style.

### Step 2: Environment & Configuration

*   **2.1: Create `.env.example` and `.env` files:**
    *   Create a `.env.example` file in the project root to list all required environment variables with placeholder values.
    *   Create a `.env` file (which should be in `.gitignore`) to store your actual secret keys.
*   **2.2: Set up `flutter_dotenv`:**
    *   Add `flutter_dotenv` to your `pubspec.yaml`.
    *   Load the environment variables in `main.dart` before the app starts.
*   **2.3: Create `EnvConfig` class:**
    *   Create a class in `lib/core/config/env_config.dart` to hold your environment variables.
    *   Add a factory constructor to create an instance of the class from the loaded environment variables.
    *   Add a `isValid` getter to check if all required environment variables are present.

### Step 3: Firebase Backend Integration

*   **3.1: Configure Firebase:** Register each platform app and generate `lib/firebase_options.dart` with FlutterFire CLI.
*   **3.2: Enable services:** Turn on Firebase Authentication, Cloud Firestore, and Firebase AI Logic in the Firebase console.
*   **3.3: Secure Firestore:** Add owner-scoped security rules for user profile documents before deployment.
*   **3.4: Initialize Firebase:** Initialize Firebase in `main.dart` with `DefaultFirebaseOptions.currentPlatform`.

### Step 4: State Management - Riverpod

*   **4.1: Add Riverpod packages to `pubspec.yaml`:**
    *   Add `flutter_riverpod` and `riverpod_annotation` to your `pubspec.yaml`.
*   **4.2: Set up the `ProviderScope`:**
    *   Wrap your root widget in `main.dart` with a `ProviderScope`.
*   **4.3: Create providers for core services:**
    *   Create providers for Firebase-backed services and `envConfigProvider` to make them accessible throughout the app.

## Part 2: UI/UX & Onboarding

### Step 5: App Theme & Styling

*   **5.1: Define the color palette, typography, and theme data:**
    *   Create files in `lib/core/theme` to define your app's colors, text styles, and `ThemeData` for both light and dark modes.
*   **5.2: Create a theme provider:**
    *   Create a Riverpod provider to manage the current theme mode (light/dark).
*   **5.3: Implement the theme in the `MaterialApp`:**
    *   Use the theme provider to set the `theme` and `darkTheme` properties of your `MaterialApp` widget.

### Step 6: Onboarding & Language Selection

*   **6.1: Create a language selection screen:**
    *   Build a UI that allows users to select their preferred language.
*   **6.2: Implement logic to save the selected language:**
    *   Use the `shared_preferences` package to persist the user's language choice.
*   **6.3: Create a splash screen:**
    *   The splash screen should be the initial route of the app.
    *   It should check if the user has completed onboarding and navigate to the appropriate screen (language selection or login).

### Step 7: User Authentication

*   **7.1: Design and build the login/signup screen UI:**
    *   Create the UI for your login and signup screens.
*   **7.2: Implement authentication logic:**
    *   Use `firebase_auth` to implement email/password and phone login.
*   **7.3: Create an authentication service and provider:**
    *   Create a service to handle all authentication-related logic.
    *   Create a Riverpod provider for the authentication service.
*   **7.4: Handle user sessions:**
    *   Listen to authentication state changes from Firebase Auth and navigate the user to the home screen on successful login.

## Part 3: Core Features

### Step 8: Home Screen

*   **8.1: Design and build the home screen UI:**
    *   Create a dashboard-style UI that provides an overview of the app's features.
*   **8.2: Create a bottom navigation bar:**
    *   Implement a bottom navigation bar to switch between the main features of the app.
*   **8.3: Display summary information:**
    *   Show widgets for weather, recent advisories, etc.

### Step 9: AI Chatbot - Gemini

*   **9.1: Create the chatbot screen UI:**
    *   Build a familiar chat interface with a text input field and a message list.
*   **9.2: Implement the Gemini service:**
    *   If you have a Gemini API key, create a service to send prompts to the Gemini API and get responses.
*   **9.3: Manage chat history:**
    *   Store and display the conversation history.

### Step 10: Weather Feature

*   **10.1: Integrate a weather API:**
    *   If you have a weather API key, create a service to fetch weather data.
*   **10.2: Create a weather service and model:**
    *   Create a service to handle the API calls and a model to represent the weather data.
*   **10.3: Display weather information:**
    *   Create a dedicated screen to display the current weather and forecast.

### Step 11: Crop Advisory Feature

*   **11.1: Design the UI for displaying crop advisories:**
    *   Create a list or card-based UI to display advisories.
*   **11.2: Fetch advisory data:**
    *   Fetch profile data from Cloud Firestore.

### Step 12: Pest Detection Feature

*   **12.1: Implement image picker:**
    *   Use the `image_picker` package to allow users to take a photo or select one from their gallery.
*   **12.2: Use a placeholder for the pest detection model:**
    *   Since a real pest detection model is complex, you can start with a placeholder that returns a dummy result.
*   **12.3: Display the results:**
    *   Show the pest detection results to the user.

### Step 13: Market Prices Feature

*   **13.1: Design the UI to display market prices:**
    *   Create a UI to show a list of crops and their market prices.
*   **13.2: Fetch market price data:**
    *   Fetch data from Cloud Firestore or an external API.

### Step 14: Soil Health Feature

*   **14.1: Design the UI for soil health information:**
    *   Create a UI to display soil health data.
*   **14.2: Fetch soil health data:**
    *   Fetch profile data from Cloud Firestore.

### Step 15: Profile Screen

*   **15.1: Design the UI for the profile screen:**
    *   Create a screen where users can see their profile information.
*   **15.2: Allow users to view and edit their profile information:**
    *   Implement forms to allow users to update their Firestore profile data.
*   **15.3: Implement logout functionality:**
    *   Add a logout button that calls Firebase Auth `signOut`.

## Part 4: Final Touches

### Step 16: Testing

*   **16.1: Write unit tests:**
    *   Write tests for your services and providers to ensure they work as expected.
*   **16.2: Write widget tests:**
    *   Write tests for your most important UI widgets.
*   **16.3: Write integration tests:**
    *   Write tests that simulate user flows through the app.

### Step 17: Deployment

*   **17.1: Prepare the app for release:**
    *   Follow the Flutter documentation to prepare your app for release (app icons, signing, etc.).
*   **17.2: Build the app:**
    *   Build the release version of your app for Android and iOS.
*   **17.3: Publish to the app stores:**
    *   Follow the instructions for the Google Play Store and Apple App Store to publish your app.
