/// Home Screen
///
/// Main dashboard showing all app features and quick access cards

import 'package:crop_advisory/providers/weather_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/animated_page_route.dart';
import '../widgets/feature_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/quick_action_button.dart';
import '../../auth/providers/simple_auth_provider.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../pest_detection/screens/pest_detection_screen.dart';
import '../../crop_advisory/screens/crop_advisory_screen.dart';
import '../../soil_health/screens/soil_health_screen.dart';
import '../../weather/screens/weather_screen.dart';
import '../../market_prices/screens/market_prices_screen.dart';
import '../../fertilizer/screens/fertilizer_calculator_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  void _handleNavigation(int index) {
    if (index == _selectedIndex && index == 0) return;

    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.of(context).pushNamed(Routes.chatbot).then((_) {
          setState(() => _selectedIndex = 0);
        });
        break;
      case 2:
        Navigator.of(context).pushNamed(Routes.cropAdvisory).then((_) {
          setState(() => _selectedIndex = 0);
        });
        break;
      case 3:
        Navigator.of(context).pushNamed(Routes.marketPrices).then((_) {
          setState(() => _selectedIndex = 0);
        });
        break;
      case 4:
        Navigator.of(context).pushNamed(Routes.profile).then((_) {
          setState(() => _selectedIndex = 0);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeMode$Provider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: ref.watch(themeMode$Provider) == ThemeMode.dark
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: () {
              ref.read(themeMode$Provider.notifier).toggle();
            },
          ).animate().fadeIn(duration: 300.ms).scale(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'View notifications',
            onPressed: () {
              _showNotifications(context);
            },
          ).animate().fadeIn(duration: 300.ms, delay: 100.ms).scale(),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildHomeContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _handleNavigation,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'Advisory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart_outlined),
            activeIcon: Icon(Icons.show_chart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    final userAsync = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // We only care if the user is authenticated and has an email for the welcome message
    final bool hasUser = userAsync.when(
      data: (user) => user?.email != null,
      loading: () => false,
      error: (_, __) => false,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(currentWeatherProvider.notifier).refresh();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with animation
            Text(
              hasUser ? l10n.welcomeBackFarmer : l10n.welcomeBack,
              style: AppTextStyles.h2.copyWith(color: textColor),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: AppDimensions.paddingXS),
            Text(
              l10n.howCanWeHelpYou,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms)
                .slideX(begin: -0.2, end: 0),
            const SizedBox(height: AppDimensions.paddingLG),

            // Weather Card with animation
            const WeatherCard()
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            const SizedBox(height: AppDimensions.paddingXL),

            // Quick Actions with animation
            Text(
              l10n.quickActions,
              style: AppTextStyles.h4.copyWith(color: textColor),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideX(begin: -0.2, end: 0),
            const SizedBox(height: AppDimensions.paddingMD),
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.chat,
                    label: l10n.askAI,
                    color: AppColors.primary,
                    onTap: () {
                      context.pushWithSlide(const ChatbotScreen());
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
                ),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: QuickActionButton(
                    icon: Icons.camera_alt,
                    label: l10n.scanPest,
                    color: AppColors.accent,
                    onTap: () {
                      context.pushWithSlide(
                        const PestDetectionScreen(),
                      );
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 500.ms).scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1, 1),
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingXL),

            // Features Section with animation
            Text(
              l10n.features,
              style: AppTextStyles.h4.copyWith(color: textColor),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms)
                .slideX(begin: -0.2, end: 0),
            const SizedBox(height: AppDimensions.paddingMD),

            // Grid Layout for Features
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 320
                        ? 2
                        : 1;
                final features = [
                  FeatureCard(
                    icon: Icons.eco_outlined,
                    title: l10n.cropAdvisory,
                    description: l10n.cropAdvisoryDesc,
                    color: AppColors.primary,
                    onTap: () =>
                        context.pushWithSlide(const CropAdvisoryScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.science_outlined,
                    title: 'Fertilizer Calculator',
                    description: 'Plan nutrient needs for your field',
                    color: AppColors.accentDark,
                    onTap: () => context.pushWithSlide(
                      const FertilizerCalculatorScreen(),
                    ),
                  ),
                  FeatureCard(
                    icon: Icons.grass_outlined,
                    title: l10n.soilHealth,
                    description: l10n.soilHealthDesc,
                    color: AppColors.secondary,
                    onTap: () =>
                        context.pushWithSlide(const SoilHealthScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.cloud_outlined,
                    title: l10n.weatherForecast,
                    description: l10n.weatherForecastDesc,
                    color: AppColors.info,
                    onTap: () => context.pushWithSlide(const WeatherScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.pest_control_outlined,
                    title: l10n.pestDetection,
                    description: l10n.pestDetectionDesc,
                    color: AppColors.error,
                    onTap: () =>
                        context.pushWithSlide(const PestDetectionScreen()),
                  ),
                  FeatureCard(
                    icon: Icons.show_chart,
                    title: l10n.marketPrices,
                    description: l10n.marketPricesDesc,
                    color: AppColors.primaryDark,
                    onTap: () =>
                        context.pushWithSlide(const MarketPricesScreen()),
                  ),
                ];

                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: AppDimensions.paddingMD,
                  mainAxisSpacing: AppDimensions.paddingMD,
                  childAspectRatio: 1.18,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var index = 0; index < features.length; index++)
                      features[index]
                          .animate()
                          .fadeIn(
                            duration: 450.ms,
                            delay: (100 * index).ms,
                          )
                          .slideY(begin: 0.08, end: 0),
                  ],
                );
              },
            ),
            const SizedBox(height: AppDimensions.paddingLG),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.wb_sunny_outlined),
                title: Text('Daily weather updates'),
                subtitle:
                    Text('Weather alerts and farming reminders appear here.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline),
                title: Text('You are all caught up'),
                subtitle: Text('No new notifications right now.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
