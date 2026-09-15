import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/gemini_service.dart';

class SoilHealthScreen extends ConsumerStatefulWidget {
  const SoilHealthScreen({super.key});

  @override
  ConsumerState<SoilHealthScreen> createState() => _SoilHealthScreenState();
}

class _SoilHealthScreenState extends ConsumerState<SoilHealthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _crop = TextEditingController(text: 'Rice');
  final _ph = TextEditingController(text: '6.5');
  final _nitrogen = TextEditingController();
  final _phosphorus = TextEditingController();
  final _potassium = TextEditingController();
  final _organicMatter = TextEditingController();
  String? _result;
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [
      _crop,
      _ph,
      _nitrogen,
      _phosphorus,
      _potassium,
      _organicMatter
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final result = await ref.read(geminiServiceProvider).analyzeSoilHealth(
        soilTestData: {
          'crop': _crop.text.trim(),
          'pH': double.parse(_ph.text),
          'nitrogen_kg_per_acre': _nitrogen.text.trim(),
          'phosphorus_kg_per_acre': _phosphorus.text.trim(),
          'potassium_kg_per_acre': _potassium.text.trim(),
          'organic_matter_percent': _organicMatter.text.trim(),
        },
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to analyze soil: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _number(String? value, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) return 'Enter a value';
    final number = double.tryParse(value);
    if (number == null ||
        (min != null && number < min) ||
        (max != null && number > max)) {
      return 'Enter a valid number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soil Health')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            Text('Soil Health Analysis', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              'Enter your soil test values to receive practical, crop-specific guidance.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            _field(_crop, 'Crop', Icons.eco_outlined),
            _field(_ph, 'pH (0-14)', Icons.balance_outlined,
                validator: (value) => _number(value, min: 0, max: 14)),
            _field(_nitrogen, 'Nitrogen (kg/acre)', Icons.grass_outlined),
            _field(_phosphorus, 'Phosphorus (kg/acre)', Icons.science_outlined),
            _field(_potassium, 'Potassium (kg/acre)', Icons.spa_outlined),
            _field(
                _organicMatter, 'Organic matter (%)', Icons.compost_outlined),
            const SizedBox(height: AppDimensions.paddingMD),
            FilledButton.icon(
              onPressed: _loading ? null : _analyze,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics_outlined),
              label: Text(_loading ? 'Analyzing...' : 'Analyze Soil'),
            ),
            if (_result != null) ...[
              const SizedBox(height: AppDimensions.paddingLG),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: SelectableText(_result!),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.paddingMD),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(
                Routes.fertilizerCalculator,
              ),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('Open Fertilizer Calculator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      child: TextFormField(
        controller: controller,
        validator: validator ??
            (value) => label == 'Crop'
                ? (value == null || value.trim().isEmpty
                    ? 'Enter a crop'
                    : null)
                : _number(value),
        keyboardType: label == 'Crop'
            ? TextInputType.text
            : const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}
