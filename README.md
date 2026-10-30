# Crop Advisory - Smart Farming Assistant

A multilingual, AI-powered mobile application that provides real-time, location-specific crop advisory services to small and marginal farmers in India.

## Problem Statement

Small and marginal farmers in India rely on traditional knowledge, local shopkeepers, or guesswork for crop selection, pest control, and fertilizer use. This leads to:
- Poor crop yield
- Excessive input costs
- Environmental degradation due to chemical overuse
- Language barriers and low digital literacy limiting access to modern agri-tech

## Solution

Crop Advisory empowers farmers with scientific insights in their native language, helping them make informed decisions through:
- AI-based personalized recommendations
- Real-time weather and soil data
- Pest/disease detection via image analysis
- Market price tracking
- Voice support for low-literate users

## Features

### Core Features
- **Multilingual AI Chatbot**: Powered by Google Gemini API for intelligent crop advisory
- **Real-time Crop Advisory**: Location-specific recommendations based on soil type, weather, and crop history
- **Soil Health Analysis**: Personalized fertilizer and soil management guidance
- **Weather Alerts**: Weather-based predictions and alerts
- **Pest/Disease Detection**: Upload images for AI-powered pest and disease identification
- **Market Price Tracking**: Real-time market prices for crops
- **Voice Support**: Voice input/output for low-literate farmers
- **Offline Mode**: Basic features available without internet connectivity

### Technical Features
- **Authentication**: Firebase Authentication with email and phone sign-in
- **Database**: Firebase Cloud Firestore for user profiles
- **AI Integration**: Gemini through Firebase AI Logic
- **Cross-platform**: Built with Flutter for Android and iOS

## Tech Stack

- **Frontend**: Flutter/Dart
- **Backend**: Firebase Authentication, Cloud Firestore, and Firebase AI Logic
- **AI/ML**: Google Gemini API
- **State Management**: Provider/Riverpod
- **Local Storage**: Hive/SharedPreferences
- **Image Processing**: TensorFlow Lite (optional for offline detection)

## Prerequisites

Before running this project, ensure you have:

- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / Xcode (for mobile development)
- Git

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd crop_advisory
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Copy `.env.example` to `.env` and configure external data APIs as needed:

```env
WEATHER_API_KEY=your_openweathermap_api_key
```

Firebase is initialized with `lib/firebase_options.dart`. In the Firebase console, enable Email/Password (and Phone if needed) under Authentication, create a Cloud Firestore database, and enable Gemini in Firebase AI Logic. Apply owner-scoped Firestore security rules before deploying.

### 4. Firebase Setup

1. Create or select the Firebase project configured in `lib/firebase_options.dart`.
2. Register platform apps and regenerate options with FlutterFire CLI when using a different project.
3. Enable Firebase Authentication and Cloud Firestore in the console.
4. Enable Firebase AI Logic and verify the Gemini model is available for the project.

### 6. Run the Application

```bash
# For Android
flutter run

# For iOS
flutter run

# For a specific device
flutter run -d <device-id>
```

## Project Structure

```
crop_advisory/
├── lib/
│   ├── core/
│   │   ├── config/          # App configuration
│   │   ├── constants/       # Constants and enums
│   │   ├── utils/           # Utility functions
│   │   └── theme/           # App theme
│   ├── features/
│   │   ├── auth/            # Authentication
│   │   ├── home/            # Home dashboard
│   │   ├── chatbot/         # AI chatbot
│   │   ├── crop_advisory/   # Crop recommendations
│   │   ├── soil_health/     # Soil analysis
│   │   ├── weather/         # Weather alerts
│   │   ├── pest_detection/  # Pest/disease detection
│   │   ├── market_prices/   # Market price tracking
│   │   └── profile/         # User profile
│   ├── models/              # Data models
│   ├── services/            # API services
│   ├── widgets/             # Reusable widgets
│   └── main.dart            # Entry point
├── assets/
│   ├── images/
│   ├── icons/
│   └── translations/        # Language files
├── test/                    # Unit and widget tests
└── pubspec.yaml
```

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_auth: ^latest
  cloud_firestore: ^latest
  firebase_ai: ^latest
  provider: ^latest
  image_picker: ^latest
  geolocator: ^latest
  permission_handler: ^latest
  speech_to_text: ^latest
  flutter_tts: ^latest
  cached_network_image: ^latest
  intl: ^latest
  shared_preferences: ^latest
```

## Supported Languages

- English
- Hindi (हिंदी)
- Bengali (বাংলা)
- Telugu (తెలుగు)
- Marathi (मराठी)
- Tamil (தமிழ்)
- Gujarati (ગુજરાતી)
- Kannada (ಕನ್ನಡ)
- Malayalam (മലയാളം)
- Punjabi (ਪੰਜਾਬੀ)

## Expected Outcomes

- Increased crop productivity for small farmers
- Reduced input costs through optimized fertilizer use
- Sustainable farming practices
- Improved farmer livelihoods
- Enhanced food security
- Reduced environmental impact

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions, please open an issue on GitHub or contact the development team.

## Roadmap

- [ ] Phase 1: Core app with chatbot and authentication
- [ ] Phase 2: Pest detection and soil analysis
- [ ] Phase 3: Weather integration and market prices
- [ ] Phase 4: Voice support and multilingual expansion
- [ ] Phase 5: Offline mode and advanced analytics
- [ ] Phase 6: Community features and farmer networks

## Acknowledgments

Built to empower small and marginal farmers in India with modern agricultural technology.
