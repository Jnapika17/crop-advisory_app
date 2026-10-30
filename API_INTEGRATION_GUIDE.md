# API Integration Guide - Crop Advisory App

## Overview
This document provides information about the app's external APIs and AI features. Gemini requests use **Firebase AI Logic** and the configured Firebase project.

---

## 🔑 Required API Keys

### 1. Firebase AI Logic (Required for AI features)
- **Purpose**: AI-powered recommendations, chat, and pest-image analysis
- **Setup**: Enable Firebase AI Logic for the Firebase project in `lib/firebase_options.dart`
- **Credentials**: Uses the configured Firebase app; no separate Gemini key is loaded from `.env`
- **Usage**: 
  - Chatbot conversations
  - Crop advisory recommendations
  - Pest and disease detection
  - Soil health analysis
  - Fertilizer calculations
  - Water requirement analysis
  - Weather advisory
  - Market price analysis
  - Harvest readiness detection
  - All other intelligent features

### 2. OpenWeatherMap API (Required for Weather Features)
- **Purpose**: Real-time weather data, forecasts, and alerts
- **Get API Key**: [OpenWeatherMap](https://openweathermap.org/api)
- **Environment Variable**: `WEATHER_API_KEY`
- **Free Tier**: 1,000 API calls/day
- **APIs Used**:
  - Current Weather Data API
  - 5-Day Weather Forecast
  - Weather Alerts (paid feature)

### 3. Firebase (Required for account services)
- **Purpose**: User authentication and profile storage
- **Setup**: Enable Firebase Authentication and Cloud Firestore for the configured Firebase project
- **Security**: Restrict profile documents to the authenticated owner using Firestore security rules

---

## 🤖 Gemini AI Integration

### Features Powered by Gemini AI

#### 1. **Chatbot Conversations**
```dart
// Basic chat
final response = await geminiService.sendMessage(
  message: "How do I grow rice?",
  language: "English",
);

// Chat with history
final session = geminiService.startChat();
final response = await geminiService.sendChatMessage(
  session: session,
  message: "What fertilizer should I use?",
  language: "Hindi",
);
```

#### 2. **Crop Advisory**
```dart
final advisory = await geminiService.getCropAdvisory(
  cropType: "Rice",
  soilType: "Clay",
  season: "Monsoon",
  location: "Punjab",
  language: "English",
);
```

#### 3. **Fertilizer Calculator**
```dart
final fertilizerPlan = await geminiService.calculateFertilizerRequirement(
  cropType: "Wheat",
  areaInAcres: 5.0,
  soilData: {
    'nitrogen': 'low',
    'phosphorus': 'medium',
    'potassium': 'high',
    'pH': 6.5,
  },
  language: "English",
);
```

#### 4. **Water Requirement Tracker**
```dart
final waterNeeds = await geminiService.calculateWaterRequirement(
  cropType: "Cotton",
  growthStage: "Flowering",
  areaInAcres: 3.0,
  weatherData: {
    'temperature': 35,
    'humidity': 60,
    'rainfall': 0,
  },
  language: "English",
);
```

#### 5. **Pest Detection (Image Analysis)**
```dart
final pestAnalysis = await geminiService.analyzePestImage(
  imageBytes: imageFile.readAsBytesSync(),
  mimeType: 'image/jpeg',
  language: "English",
);
```

#### 6. **Harvest Readiness Checker**
```dart
final harvestStatus = await geminiService.checkHarvestReadiness(
  imageBytes: cropImage.readAsBytesSync(),
  mimeType: 'image/jpeg',
  cropType: "Tomato",
  language: "English",
);
```

#### 7. **Soil Health Analysis**
```dart
// With test data
final soilAnalysis = await geminiService.analyzeSoilHealth(
  soilTestData: {
    'nitrogen': 45,
    'phosphorus': 20,
    'potassium': 180,
    'pH': 6.8,
    'organicMatter': 2.5,
  },
  language: "English",
);

// With image
final soilAnalysis = await geminiService.analyzeSoilHealth(
  soilImageBytes: soilImage.readAsBytesSync(),
  mimeType: 'image/jpeg',
  language: "English",
);
```

#### 8. **Seasonal Crop Suggestions**
```dart
final suggestions = await geminiService.getSeasonalCropSuggestions(
  location: "Karnataka",
  currentMonth: "June",
  soilType: "Red Soil",
  language: "Kannada",
);
```

#### 9. **Input Cost Estimator**
```dart
final costEstimate = await geminiService.estimateInputCosts(
  cropType: "Sugarcane",
  areaInAcres: 10.0,
  location: "Maharashtra",
  language: "Marathi",
);
```

#### 10. **Weather Advisory**
```dart
final advisory = await geminiService.getWeatherAdvisory(
  weatherData: {
    'temperature': 28,
    'humidity': 85,
    'rainfall': 50,
    'forecast': 'Heavy rain expected',
  },
  cropType: "Paddy",
  growthStage: "Vegetative",
  language: "English",
);
```

#### 11. **Market Price Analysis**
```dart
final analysis = await geminiService.analyzeMarketPrices(
  cropType: "Onion",
  marketPrices: [
    {'market': 'Lasalgaon', 'price': 1500, 'distance': 50},
    {'market': 'Pune', 'price': 1800, 'distance': 120},
  ],
  currentLocation: "Nashik",
  language: "Marathi",
);
```

#### 12. **Crop Calendar Generation**
```dart
final calendar = await geminiService.generateCropCalendar(
  cropType: "Maize",
  sowingDate: DateTime.now(),
  location: "Bihar",
  language: "Hindi",
);
```

#### 13. **Offline FAQ Generation**
```dart
final faq = await geminiService.generateCropFAQ(
  cropType: "Cotton",
  region: "Gujarat",
  language: "Gujarati",
);
// Save FAQ locally for offline access
```

#### 14. **Vernacular Translation**
```dart
final translations = await geminiService.translateToVernacular(
  terms: ['Aphid', 'Whitefly', 'Leaf Curl', 'Blight'],
  targetLanguage: "Telugu",
);
```

---

## 🌦️ Weather API Integration

### Real Weather Data from OpenWeatherMap

#### Get Current Weather
```dart
final weatherService = ref.read(weatherServiceProvider);

// By coordinates
final weather = await weatherService.getCurrentWeather(
  latitude: 28.6139,
  longitude: 77.2090,
  units: 'metric',
);

// By city name
final weather = await weatherService.getCurrentWeatherByCity(
  cityName: "Delhi",
  units: 'metric',
);
```

#### Get 5-Day Forecast
```dart
final forecast = await weatherService.getForecast(
  latitude: 28.6139,
  longitude: 77.2090,
  units: 'metric',
);
```

#### Weather Data Available
- Temperature (current, feels like, min, max)
- Humidity
- Wind speed and direction
- Rainfall amount
- Weather condition and description
- Icon code for weather display
- Sunrise/Sunset times
- Atmospheric pressure
- Visibility

---

## 📍 Location Services

### Get User Location
```dart
final locationService = ref.read(locationServiceProvider);

// Get current position
final position = await locationService.getCurrentPosition();

// Get address from coordinates
final address = await locationService.getFormattedAddress(
  latitude: position.latitude,
  longitude: position.longitude,
);

// Calculate distance between two points
final distance = locationService.getDistanceBetween(
  startLatitude: 28.6139,
  startLongitude: 77.2090,
  endLatitude: 28.5355,
  endLongitude: 77.3910,
);
```

---

## 🔔 Push Notifications

### Daily Weather Notifications
```dart
final notificationService = ref.read(notificationServiceProvider);

// Schedule daily weather alert at 7 AM
await notificationService.scheduleDailyWeatherNotification(
  hour: 7,
  minute: 0,
);
```

### Crop Reminders
```dart
// Irrigation reminder
await notificationService.scheduleIrrigationReminder(
  cropName: "Wheat",
  dateTime: DateTime.now().add(Duration(days: 2)),
);

// Fertilizer application
await notificationService.scheduleFertilizerReminder(
  cropName: "Rice",
  fertilizerType: "Urea",
  dateTime: DateTime.now().add(Duration(days: 7)),
);

// Harvest reminder
await notificationService.scheduleHarvestReminder(
  cropName: "Tomato",
  dateTime: DateTime.now().add(Duration(days: 90)),
);

// Pest control
await notificationService.schedulePestControlReminder(
  cropName: "Cotton",
  dateTime: DateTime.now().add(Duration(days: 3)),
);
```

### Weather Alerts
```dart
await notificationService.sendWeatherAlert(
  alertType: "Heavy Rain",
  message: "Heavy rainfall expected in next 24 hours. Protect your crops!",
);
```

---

## 🎨 Theme & Dark Mode

### Toggle Theme
```dart
final themeNotifier = ref.read(themeMode$Provider.notifier);

// Toggle between light and dark
await themeNotifier.toggleTheme();

// Set specific theme
await themeNotifier.setThemeMode(ThemeMode.dark);

// Check if dark mode is active
final isDark = themeNotifier.isDarkMode;
```

---

## ✨ Animations

### Page Transitions
```dart
// Fade transition
await context.pushWithFade(WeatherScreen());

// Slide transition
await context.pushWithSlide(ChatbotScreen());

// Scale transition
await context.pushWithScale(CropAdvisoryScreen());

// Slide up (bottom sheet style)
await context.pushWithSlideUp(ProfileScreen());
```

### Using flutter_animate
```dart
import 'package:flutter_animate/flutter_animate.dart';

// Animate any widget
Text('Hello')
  .animate()
  .fadeIn(duration: 300.ms)
  .slideX(begin: 0.2, end: 0);

// Chain multiple animations
Container()
  .animate()
  .fadeIn()
  .then()
  .scale()
  .then()
  .shake();
```

---

## 📱 Voice Search in Chatbot

### Using Speech-to-Text
```dart
import 'package:speech_to_text/speech_to_text.dart';

final speech = SpeechToText();

// Initialize
await speech.initialize();

// Start listening
await speech.listen(
  onResult: (result) {
    final spokenText = result.recognizedWords;
    // Send to chatbot
  },
  localeId: 'hi_IN', // Hindi
);

// Stop listening
await speech.stop();
```

---

## 🌐 Setup Instructions

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Environment Variables
Edit `.env` file:
```env
WEATHER_API_KEY=your-openweathermap-api-key
```

### 3. Generate Code
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Run the App
```bash
flutter run
```

---

## 🧪 Testing API Integrations

### Test Gemini AI
```dart
// In a test or debug screen
final geminiService = ref.read(geminiServiceProvider);
try {
  final response = await geminiService.sendMessage(
    message: "Hello, test message",
    language: "English",
  );
  print("Gemini response: $response");
} catch (e) {
  print("Gemini error: $e");
}
```

### Test Weather API
```dart
final weatherService = ref.read(weatherServiceProvider);
try {
  final weather = await weatherService.getCurrentWeatherByCity(
    cityName: "Mumbai",
  );
  print("Temperature: ${weather.temperature}°C");
} catch (e) {
  print("Weather API error: $e");
}
```

---

## 📊 API Usage Limits

### Google Gemini AI
- **Free Tier**: 60 requests per minute
- **Rate limiting**: Implemented with retry logic
- **Image Analysis**: Included in the same limit

### OpenWeatherMap
- **Free Tier**: 1,000 calls/day, 60 calls/minute
- **Recommendation**: Cache weather data for 10-15 minutes

### Optimization Tips
1. **Cache Gemini responses** for common queries
2. **Batch requests** when possible
3. **Use local storage** for offline FAQ data
4. **Implement request queues** to avoid rate limits
5. **Show loading indicators** for longer AI analysis

---

## 🛠️ Troubleshooting

### Common Issues

1. **Gemini API Key Error**
   - Verify API key is correct in `.env`
   - Check API is enabled in Google Cloud Console
   - Ensure billing is enabled (free tier available)

2. **Weather API Not Working**
   - Confirm API key is active
   - Check internet connectivity
   - Verify coordinates are valid

3. **Notifications Not Showing**
   - Request permissions on first launch
   - Check notification settings on device
   - Verify timezone is set correctly

4. **Location Permission Denied**
   - Request permissions properly
   - Guide users to app settings
   - Provide manual location input as fallback

---

## 📝 Additional Resources

- [Gemini AI Documentation](https://ai.google.dev/docs)
- [OpenWeatherMap API Docs](https://openweathermap.org/api)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Speech to Text Package](https://pub.dev/packages/speech_to_text)
- [Flutter Animate Package](https://pub.dev/packages/flutter_animate)

---

## 🚀 Future Enhancements

1. **SMS Fallback** - Integrate SMS gateway for critical alerts
2. **Video Tutorials** - Add video player for regional language tutorials
3. **Mandi Finder** - Integrate Google Maps API for directions
4. **Bookmark System** - Save important advice locally
5. **Community Forum** - Add peer-to-peer farmer discussions

---

## 📞 Support

For issues or questions:
- Create an issue on GitHub
- Check documentation
- Review API usage logs in respective dashboards
