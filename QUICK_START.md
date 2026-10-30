# Quick Start Guide - Crop Advisory App

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

---

## 📦 Step 1: Install Dependencies

```bash
# Get all packages
flutter pub get
```

---

## 🔑 Step 2: Get API Keys

### **Firebase** (Required)
1. Select the Firebase project configured in `lib/firebase_options.dart`.
2. Enable Email/Password authentication and create a Cloud Firestore database.
3. Enable Gemini in Firebase AI Logic.

### **OpenWeatherMap API Key** (Required for Weather)
1. Go to [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for free account
3. Navigate to "API keys" section
4. Copy your API key (or generate new one)

---

## ⚙️ Step 3: Configure Environment Variables

Edit the `.env` file in the project root:

```env
# Replace with your actual key if weather data is needed
WEATHER_API_KEY=your_openweathermap_key_here
```

**⚠️ Important**: Never commit the `.env` file with real keys to Git!

---

## 🔨 Step 4: Generate Code

Run build_runner to generate required provider code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates:
- `*.g.dart` files for all Riverpod providers
- `*.freezed.dart` files (if using Freezed)
- JSON serialization code

---

## ▶️ Step 5: Run the App

```bash
# Run on connected device/emulator
flutter run

# Or run in debug mode with hot reload
flutter run --debug

# Run in release mode
flutter run --release
```

---

## 🧪 Step 6: Test Core Features

### Test Gemini AI Integration
1. Open the app
2. Navigate to Chatbot
3. Send a message: "How do I grow rice?"
4. Verify AI response is generated

### Test Weather API
1. Allow location permission
2. Navigate to Weather screen
3. Verify current weather displays
4. Check 5-day forecast

### Test Notifications
1. Allow notification permission
2. Go to Settings
3. Enable daily weather notifications
4. Schedule a test reminder

### Test Theme Switching
1. Go to Settings/Profile
2. Toggle dark mode switch
3. Verify theme changes
4. Restart app - theme should persist

---

## 🎨 Step 7: Customize (Optional)

### Change App Colors
Edit `lib/core/theme/app_theme.dart`:
```dart
static const Color primary = Color(0xFF2E7D32); // Your color
```

### Add New Feature
1. Create screen in `lib/features/your_feature/screens/`
2. Create provider in `lib/features/your_feature/providers/`
3. Use Gemini service for AI features:
```dart
final geminiService = ref.read(geminiServiceProvider);
final response = await geminiService.sendMessage(
  message: "Your query",
  language: "English",
);
```

---

## 📱 Available Features

### ✅ **Working Out of the Box**
- Chatbot with Gemini AI
- Weather forecasts (OpenWeatherMap)
- Location services
- Push notifications
- Theme switching (light/dark)
- Page animations
- Voice-to-text ready

### 🔨 **Need UI Implementation** (Services Ready)
- Fertilizer calculator
- Water requirement tracker
- Pest detection (image-based)
- Harvest readiness checker
- Soil health analysis
- Seasonal crop suggestions
- Input cost estimator
- Market price analysis
- Crop calendar
- Offline FAQs
- Mandi distance finder

---

## 🐛 Troubleshooting

### "Environment variables not found"
- Check `.env` file exists in root
- Verify keys are correct
- Restart app after changes

### "Provider not found" errors
- Run code generation: `flutter pub run build_runner build`
- Clean and rebuild: `flutter clean && flutter pub get`

### Weather API returns error
- Verify API key is active
- Check internet connection
- Confirm coordinates are valid (-90 to 90 lat, -180 to 180 lon)

### Gemini API rate limit
- Free tier: 60 requests/minute
- Wait or upgrade to paid plan
- Implement caching for common queries

### Notifications not showing
- Check device permissions (Settings → Apps → Crop Advisory → Notifications)
- For Android 13+, runtime permission required
- Verify notification service is initialized

---

## 📚 Project Structure

```
lib/
├── core/
│   ├── config/         # Environment config
│   ├── constants/      # App constants
│   ├── theme/          # Theme & colors
│   ├── providers/      # Global providers (theme)
│   └── utils/          # Utilities (animations, etc.)
├── features/
│   ├── auth/           # Login/Register
│   ├── chatbot/        # AI Chatbot
│   ├── crop_advisory/  # Crop recommendations
│   ├── home/           # Main dashboard
│   ├── pest_detection/ # Pest identification
│   ├── soil_health/    # Soil analysis
│   ├── weather/        # Weather forecasts
│   └── ...
├── models/             # Data models
├── services/           # API services (Gemini, Weather, Location, Notifications)
└── main.dart           # App entry point
```

---

## 🎯 Next Development Steps

1. **UI Redesign** - Update screens with modern glassmorphism and gradients
2. **Add Feature Screens** - Build UI for fertilizer calculator, water tracker, etc.
3. **Voice Integration** - Connect speech-to-text to chatbot
4. **Offline Support** - Store FAQ data locally with Hive
5. **Tutorial Videos** - Add video player for farming tutorials
6. **Bookmark System** - Let users save important advice
7. **SMS Fallback** - Send critical alerts via SMS

---

## 📖 Documentation

- **Full API Guide**: `API_INTEGRATION_GUIDE.md`
- **Features Summary**: `FEATURES_SUMMARY.md`
- **This Guide**: `QUICK_START.md`

---

## 🆘 Need Help?

1. Check documentation files
2. Review code comments
3. Test API keys in respective dashboards
4. Enable verbose logging in services
5. Check Flutter doctor: `flutter doctor -v`

---

## 🎉 You're Ready!

Everything is set up. Now you can:
- Build beautiful UI screens
- Connect Gemini AI to your features
- Add smooth animations
- Test on real devices
- Deploy to Play Store / App Store

**Happy Coding! 🚀**
