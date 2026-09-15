/// Profile Screen
///
/// User profile with settings and account information

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/simple_auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    // Unwrap — treat loading/error as logged-out guest
    final user = userAsync.whenOrNull(data: (u) => u);
    final authNotifier = ref.read(authProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              _showTextDialog(context, l10n.editProfile,
                  'Update your profile details from your account settings.');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 50, color: AppColors.primary),
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                Text(user?.email ?? l10n.guestUser, style: AppTextStyles.h3),
                const SizedBox(height: AppDimensions.paddingSM),
                Text(
                  l10n.farmer,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Account Section
          _buildSectionTitle(l10n.account),
          _buildListTile(
            icon: Icons.person_outline,
            title: l10n.personalInformation,
            subtitle: l10n.managePersonalDetails,
            onTap: () {
              _showTextDialog(context, l10n.personalInformation,
                  'Your signed-in email is ${user?.email ?? l10n.guestUser}.');
            },
          ),
          _buildListTile(
            icon: Icons.agriculture_outlined,
            title: l10n.farmDetails,
            subtitle: l10n.updateFarmInformation,
            onTap: () {
              _showTextDialog(context, l10n.farmDetails,
                  'Add your crop, acreage, and location details when requesting an advisory.');
            },
          ),
          const SizedBox(height: AppDimensions.paddingMD),

          // Preferences Section
          _buildSectionTitle(l10n.preferences),
          _buildListTile(
            icon: Icons.language_outlined,
            title: l10n.language,
            subtitle: l10n.changeAppLanguage,
            onTap: () {
              Navigator.of(context).pushNamed(Routes.languageSelection);
            },
          ),
          _buildListTile(
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            subtitle: l10n.manageNotificationPreferences,
            onTap: () {
              _showNotificationPreferences(context);
            },
          ),
          _buildListTile(
            icon: Icons.dark_mode_outlined,
            title: l10n.theme,
            subtitle: l10n.chooseAppAppearance,
            onTap: () {
              ref.read(themeMode$Provider.notifier).toggle();
            },
          ),
          const SizedBox(height: AppDimensions.paddingMD),

          // Support Section
          _buildSectionTitle(l10n.support),
          _buildListTile(
            icon: Icons.help_outline,
            title: l10n.helpSupport,
            subtitle: l10n.getHelpWithApp,
            onTap: () {
              _showTextDialog(context, l10n.helpSupport,
                  'Use AI Chat for farming questions or contact your local agriculture office for urgent field support.');
            },
          ),
          _buildListTile(
            icon: Icons.info_outline,
            title: l10n.about,
            subtitle: '${l10n.appVersion} ${AppConstants.appVersion}',
            onTap: () {
              _showAboutDialog(context, l10n);
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            subtitle: l10n.readPrivacyPolicy,
            onTap: () {
              _showTextDialog(context, l10n.privacyPolicy,
                  'Your account data is stored securely by Supabase. AI requests include only the information you submit for that request.');
            },
          ),
          const SizedBox(height: AppDimensions.paddingMD),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingMD,
            ),
            child: ElevatedButton.icon(
              onPressed: () =>
                  _showLogoutConfirmation(context, authNotifier, l10n),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.paddingSM,
        top: AppDimensions.paddingSM,
      ),
      child: Text(title, style: AppTextStyles.h4),
    );
  }

  void _showTextDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationPreferences(BuildContext context) {
    var weatherAlerts = true;
    var cropReminders = true;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification preferences'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Weather alerts'),
                value: weatherAlerts,
                onChanged: (value) =>
                    setState(() => weatherAlerts = value ?? false),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Crop reminders'),
                value: cropReminders,
                onChanged: (value) =>
                    setState(() => cropReminders = value ?? false),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingSM),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.bodyLarge),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    authNotifier,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await authNotifier.signOut();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(Routes.login, (route) => false);
              }
            },
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aboutCropAdvisory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.version}: ${AppConstants.appVersion}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            Text(l10n.aboutDescription, style: AppTextStyles.body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
