/// Market Price Providers
///
/// Riverpod state management for market price data.
/// Provides reactive access to commodity prices, trends, and filtered results.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../core/config/env_config.dart';
import '../models/market_price_model.dart';
import '../services/market_price_service.dart';
import '../services/gemini_service.dart';

final _logger = Logger();

// ============================================================================
// STATE CLASSES
// ============================================================================

/// State class for market prices screen
class MarketPricesState {
  /// Currently selected commodity
  final String selectedCommodity;

  /// Currently selected state filter
  final String? selectedState;

  /// List of fetched market prices
  final List<MarketPriceModel> prices;

  /// Price trend data for selected commodity
  final PriceTrend? priceTrend;

  /// Whether data is currently loading
  final bool isLoading;

  /// Error message if fetch failed
  final String? errorMessage;

  /// AI-generated market advice
  final String? aiAdvice;

  /// Whether AI advice is being generated
  final bool isAdviceLoading;

  const MarketPricesState({
    this.selectedCommodity = 'Rice',
    this.selectedState,
    this.prices = const [],
    this.priceTrend,
    this.isLoading = false,
    this.errorMessage,
    this.aiAdvice,
    this.isAdviceLoading = false,
  });

  MarketPricesState copyWith({
    String? selectedCommodity,
    String? selectedState,
    List<MarketPriceModel>? prices,
    PriceTrend? priceTrend,
    bool? isLoading,
    String? errorMessage,
    String? aiAdvice,
    bool? isAdviceLoading,
    bool clearAdvice = false,
    bool clearError = false,
    bool clearTrend = false,
  }) {
    return MarketPricesState(
      selectedCommodity: selectedCommodity ?? this.selectedCommodity,
      selectedState: selectedState ?? this.selectedState,
      prices: prices ?? this.prices,
      priceTrend: clearTrend ? null : (priceTrend ?? this.priceTrend),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      aiAdvice: clearAdvice ? null : (aiAdvice ?? this.aiAdvice),
      isAdviceLoading: isAdviceLoading ?? this.isAdviceLoading,
    );
  }
}

// ============================================================================
// NOTIFIER
// ============================================================================

/// StateNotifier that manages market prices state
class MarketPricesNotifier extends StateNotifier<MarketPricesState> {
  final MarketPriceService _marketService;
  final GeminiService? _geminiService;

  MarketPricesNotifier(this._marketService, [this._geminiService])
    : super(const MarketPricesState());

  /// Fetch prices for the currently selected commodity
  Future<void> fetchPrices() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final prices = await _marketService.getCurrentPrices(
        commodity: state.selectedCommodity,
        state: state.selectedState,
        limit: 30,
      );

      if (prices.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No prices found for ${state.selectedCommodity}. Try a different crop.',
        );
      } else {
        state = state.copyWith(isLoading: false, prices: prices);
      }
    } catch (e) {
      _logger.e('Error fetching prices: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch prices. Please try again.',
      );
    }
  }

  /// Fetch price trend for the selected commodity
  Future<void> fetchPriceTrend() async {
    try {
      final trend = await _marketService.getPriceTrend(
        commodity: state.selectedCommodity,
        state: state.selectedState,
      );
      state = state.copyWith(priceTrend: trend);
    } catch (e) {
      _logger.e('Error fetching price trend: $e');
    }
  }

  /// Change the selected commodity and refetch data
  Future<void> selectCommodity(String commodity) async {
    state = state.copyWith(
      selectedCommodity: commodity,
      clearTrend: true,
      clearAdvice: true,
    );
    await fetchPrices();
    await fetchPriceTrend();
  }

  /// Change the selected state filter and refetch data
  Future<void> selectState(String? selectedState) async {
    state = state.copyWith(
      selectedState: selectedState,
      clearTrend: true,
      clearAdvice: true,
    );
    await fetchPrices();
    await fetchPriceTrend();
  }

  /// Clear the state filter
  Future<void> clearStateFilter() async {
    await selectState(null);
  }

  /// Get AI-powered market advice using Gemini
  Future<void> fetchAiAdvice() async {
    if (_geminiService == null) {
      state = state.copyWith(
        aiAdvice:
            'Local market insight: compare nearby mandis, check price movement over the last 3 days, and sell when prices are stable or rising. This fallback advice is shown because the AI backend is not connected in the current environment.',
      );
      return;
    }

    state = state.copyWith(isAdviceLoading: true);

    try {
      final priceData = state.prices
          .take(10)
          .map(
            (p) => {
              'Market': p.market,
              'State': p.state,
              'Modal Price': '₹${p.modalPrice.toStringAsFixed(0)}',
              'Min': '₹${p.minPrice.toStringAsFixed(0)}',
              'Max': '₹${p.maxPrice.toStringAsFixed(0)}',
            },
          )
          .toList();

      final advice = await _geminiService!.analyzeMarketPrices(
        cropType: state.selectedCommodity,
        marketPrices: priceData,
        currentLocation: state.selectedState ?? 'India',
      );

      state = state.copyWith(aiAdvice: advice, isAdviceLoading: false);
    } catch (e) {
      _logger.e('Error fetching AI advice: $e');
      state = state.copyWith(
        isAdviceLoading: false,
        aiAdvice:
            'Local market insight: prioritize nearby mandi prices, compare transport cost, and sell when the trend is stable or rising. The AI backend is unavailable right now, so this guidance is generated locally.',
      );
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await fetchPrices();
    await fetchPriceTrend();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for MarketPriceService — creates the service directly using env config.
final marketPriceServiceProvider = Provider<MarketPriceService>((ref) {
  final config = ref.watch(envConfigProvider);
  return MarketPriceService(config.marketApiKey ?? '');
});

/// Provider for GeminiService (for AI market analysis)
// final geminiServiceProvider = Provider<GeminiService?>((ref) {
//   try {
//     return ref.watch(geminiServiceProvider);
//   } catch (_) {
//     return null;
//   }
// });

/// Main provider for market prices state
final marketPricesProvider =
    StateNotifierProvider<MarketPricesNotifier, MarketPricesState>((ref) {
      final marketService = ref.watch(marketPriceServiceProvider);
      final geminiService = ref.watch(geminiServiceProvider);
      return MarketPricesNotifier(marketService, geminiService);
    });

/// Provider for the list of supported commodities
final commodityListProvider = Provider<List<Map<String, String>>>((ref) {
  return MarketPriceService.supportedCommodities;
});

/// Provider for the list of supported states
final stateListProvider = Provider<List<String>>((ref) {
  return MarketPriceService.supportedStates;
});
