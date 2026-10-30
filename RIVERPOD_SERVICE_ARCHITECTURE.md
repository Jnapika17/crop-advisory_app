# Riverpod Service Architecture Guide

## Current Service Provider Implementation

### ✅ **Already Using Riverpod Code Generation**

All services are already using `@Riverpod` annotation with code generation pattern for optimal performance and type safety.

---

## 📐 Current Architecture

### **Service Provider Pattern**

```dart
// Example from gemini_service.dart
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  final model = ref.watch(geminiModelProvider);
  final visionModel = ref.watch(geminiVisionModelProvider);
  return GeminiService(model, visionModel);
}
```

### **Benefits of Current Implementation:**

1. ✅ **Type Safety** - Auto-generated providers with compile-time checks
2. ✅ **Dependency Injection** - Services automatically inject dependencies
3. ✅ **Lifecycle Management** - `keepAlive: true` ensures singleton behavior
4. ✅ **Hot Reload Support** - Code generation supports Flutter hot reload
5. ✅ **Tree Shakeable** - Unused providers removed in release builds
6. ✅ **Testing Friendly** - Easy to mock providers in tests

---

## 🎯 Service Provider Overview

### **1. Gemini AI Service**

```dart
@Riverpod(keepAlive: true)
GeminiService geminiService(GeminiServiceRef ref) {
  // Dependencies injected via ref.watch()
  final model = ref.watch(geminiModelProvider);
  final visionModel = ref.watch(geminiVisionModelProvider);
  return GeminiService(model, visionModel);
}
```

**Features:**
- Singleton instance (keepAlive: true)
- Two model providers (text & vision)
- 15+ AI-powered methods
- Multi-language support
- Image analysis capabilities

---

### **2. Weather Service**

```dart
@Riverpod(keepAlive: true)
WeatherService weatherService(WeatherServiceRef ref) {
  final config = ref.watch(envConfigProvider);
  return WeatherService(config.weatherApiKey ?? '');
}
```

**Features:**
- OpenWeatherMap API integration
- Current weather by coordinates/city
- 5-day forecast
- Weather parsing & caching
- Error handling & retry logic

---

### **3. Location Service**

```dart
@Riverpod(keepAlive: true)
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}
```

**Features:**
- GPS positioning
- Geocoding (forward & reverse)
- Distance calculations
- Permission handling
- Real-time location updates

---

### **4. Notification Service**

```dart
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}
```

**Features:**
- Local notifications
- Scheduled reminders
- Crop calendar alerts
- Weather notifications
- Timezone support

---

### **5. Firebase Services**

```dart
FirebaseAuth.instance
FirebaseFirestore.instance
FirebaseAI.googleAI()
```

**Features:**
- Firebase Authentication for account sessions
- Cloud Firestore for user profile documents
- Firebase AI Logic for text and image generation

---

## 🚀 Advanced Patterns for Complex Integrations

### **Pattern 1: AsyncNotifierProvider for Async State**

For services that need to manage async state:

```dart
@riverpod
class WeatherState extends _$WeatherState {
  @override
  Future<WeatherModel?> build() async {
    // Initialize with null or default value
    return null;
  }

  Future<void> fetchCurrentWeather(double lat, double lon) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final weatherService = ref.read(weatherServiceProvider);
      return await weatherService.getCurrentWeather(
        latitude: lat,
        longitude: lon,
      );
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
```

**Usage:**
```dart
// In widget
final weatherState = ref.watch(weatherStateProvider);

weatherState.when(
  data: (weather) => Text('${weather?.temperature}°C'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

---

### **Pattern 2: StreamProvider for Real-time Data**

For location tracking or real-time updates:

```dart
@riverpod
Stream<Position> locationStream(LocationStreamRef ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPositionStream(distanceFilter: 100);
}
```

**Usage:**
```dart
final locationStream = ref.watch(locationStreamProvider);

locationStream.when(
  data: (position) => Text('${position.latitude}, ${position.longitude}'),
  loading: () => Text('Getting location...'),
  error: (err, stack) => Text('Error: $err'),
);
```

---

### **Pattern 3: Family Providers for Parameterized Services**

For services that need parameters:

```dart
@riverpod
Future<String> cropAdvisory(
  CropAdvisoryRef ref,
  String cropType,
  String location,
) async {
  final geminiService = ref.watch(geminiServiceProvider);
  return await geminiService.getCropAdvisory(
    cropType: cropType,
    soilType: 'Clay',
    season: 'Monsoon',
    location: location,
  );
}
```

**Usage:**
```dart
final advisory = ref.watch(cropAdvisoryProvider('Rice', 'Punjab'));

advisory.when(
  data: (text) => Text(text),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

---

### **Pattern 4: Notifier with Side Effects**

For services that need to trigger side effects:

```dart
@riverpod
class NotificationManager extends _$NotificationManager {
  @override
  List<String> build() {
    return []; // List of scheduled notification IDs
  }

  Future<void> scheduleWeatherNotification() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.scheduleDailyWeatherNotification(
      hour: 7,
      minute: 0,
    );
    
    state = [...state, 'weather_daily'];
  }

  Future<void> cancelAll() async {
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.cancelAllNotifications();
    state = [];
  }
}
```

---

### **Pattern 5: Computed Providers**

For derived state:

```dart
@riverpod
String weatherDescription(WeatherDescriptionRef ref) {
  final weather = ref.watch(weatherStateProvider).valueOrNull;
  
  if (weather == null) return 'No data';
  
  return '${weather.condition} - ${weather.temperature}°C';
}
```

---

## 🔄 Migration Examples for Complex Use Cases

### **Example 1: Cached Weather with Auto-Refresh**

```dart
@riverpod
class CachedWeather extends _$CachedWeather {
  Timer? _refreshTimer;

  @override
  Future<WeatherModel?> build(double lat, double lon) async {
    // Cancel timer when provider is disposed
    ref.onDispose(() => _refreshTimer?.cancel());
    
    // Auto-refresh every 15 minutes
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => refresh(),
    );
    
    return await _fetchWeather(lat, lon);
  }

  Future<WeatherModel> _fetchWeather(double lat, double lon) async {
    final weatherService = ref.read(weatherServiceProvider);
    return await weatherService.getCurrentWeather(
      latitude: lat,
      longitude: lon,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWeather(
      // Get params from state or elsewhere
      0.0, 0.0,
    ));
  }
}
```

---

### **Example 2: Multi-Service Orchestration**

```dart
@riverpod
Future<CropRecommendation> smartCropRecommendation(
  SmartCropRecommendationRef ref,
) async {
  // Get location
  final locationService = ref.watch(locationServiceProvider);
  final position = await locationService.getCurrentPosition();
  
  // Get weather
  final weatherService = ref.watch(weatherServiceProvider);
  final weather = await weatherService.getCurrentWeather(
    latitude: position.latitude,
    longitude: position.longitude,
  );
  
  // Get AI recommendation
  final geminiService = ref.watch(geminiServiceProvider);
  final suggestion = await geminiService.getSeasonalCropSuggestions(
    location: 'Auto-detected',
    currentMonth: DateTime.now().month.toString(),
    soilType: 'Unknown', // Can be detected separately
  );
  
  return CropRecommendation(
    location: position,
    weather: weather,
    suggestions: suggestion,
  );
}
```

---

### **Example 3: State Management with Persistence**

```dart
@riverpod
class UserPreferences extends _$UserPreferences {
  @override
  Future<UserPrefs> build() async {
    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    return UserPrefs(
      language: prefs.getString('language') ?? 'English',
      notifications: prefs.getBool('notifications') ?? true,
    );
  }

  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
    
    state = AsyncValue.data(
      state.requireValue.copyWith(language: language),
    );
  }

  Future<void> toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final current = state.requireValue.notifications;
    await prefs.setBool('notifications', !current);
    
    state = AsyncValue.data(
      state.requireValue.copyWith(notifications: !current),
    );
  }
}
```

---

## 📦 Dependency Graph

```
envConfigProvider
    ├── geminiModelProvider
    │       └── geminiServiceProvider
    ├── geminiVisionModelProvider
    │       └── geminiServiceProvider
    ├── weatherServiceProvider
        ├── currentUserProvider
        │       └── FirebaseAuth.instance
        ├── AuthNotifier
        │       └── FirebaseFirestore.instance
        └── geminiServiceProvider
          └── FirebaseAI.googleAI()

locationServiceProvider (independent)
notificationServiceProvider (independent)
themeMode$Provider (independent with persistence)
```

---

## 🧪 Testing Patterns

### **Override Providers in Tests**

```dart
void main() {
  testWidgets('Weather displays correctly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherServiceProvider.overrideWith((ref) {
            return MockWeatherService();
          }),
        ],
        child: MyApp(),
      ),
    );
    
    // Test widget...
  });
}
```

---

## 🎯 Best Practices

### **1. Use `keepAlive: true` for Singletons**
```dart
@Riverpod(keepAlive: true)
MyService myService(MyServiceRef ref) {
  return MyService();
}
```

### **2. Use AsyncNotifier for Async State**
```dart
@riverpod
class DataFetcher extends _$DataFetcher {
  @override
  Future<Data> build() async {
    return await fetchData();
  }
}
```

### **3. Use StreamProvider for Real-time Data**
```dart
@riverpod
Stream<Location> locationUpdates(LocationUpdatesRef ref) {
  return locationService.positionStream;
}
```

### **4. Use Family for Parameterized Providers**
```dart
@riverpod
Future<User> user(UserRef ref, String userId) async {
  return await fetchUser(userId);
}
```

### **5. Dispose Resources Properly**
```dart
@riverpod
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() {
    ref.onDispose(() {
      // Clean up resources
    });
    return MyState();
  }
}
```

---

## 🚀 Future Enhancements

### **Ready for:**

1. ✅ **Background Sync** - Use WorkManager with providers
2. ✅ **Offline-First** - Combine with Hive/Isar
3. ✅ **Real-time Updates** - Firebase listeners can be added for shared data
4. ✅ **Advanced Caching** - HTTP interceptors with providers
5. ✅ **State Persistence** - riverpod_persistence package
6. ✅ **Analytics Integration** - Track state changes
7. ✅ **Error Recovery** - Automatic retry with AsyncValue
8. ✅ **Performance Monitoring** - Provider lifecycle hooks

---

## 📝 Summary

### **Current Status: ✅ EXCELLENT**

Your service architecture is already using Riverpod code generation with best practices:

- ✅ Type-safe providers
- ✅ Dependency injection
- ✅ Singleton pattern
- ✅ Lifecycle management
- ✅ Hot reload support
- ✅ Testing friendly

### **No Migration Needed!**

The current implementation is production-ready and follows Riverpod best practices. The architecture is scalable and ready for complex integrations.

### **Optional Enhancements:**

Only add patterns like AsyncNotifier, StreamProvider, or Family providers when you need:
- Complex async state management
- Real-time data streams
- Parameterized services
- Advanced caching strategies

**Your service layer is already optimized! 🎉**
