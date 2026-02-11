import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry/models/country_model.dart';
import 'package:laundry/services/api_service.dart';

/// Provider for country code data
/// This is a FutureProvider that fetches the country code once and caches it
class CountryCodeNotifier extends StateNotifier<AsyncValue<CountryCodeModel?>> {
  final ApiService _apiService = ApiService();

  CountryCodeNotifier() : super(const AsyncValue.loading()) {
    loadData();
  }

  Future<void> loadData() async {
    // 1. Load from cache immediately
    try {
      final cachedData = await _apiService.getCachedCountryCode();
      if (cachedData != null) {
        state = AsyncValue.data(cachedData);
      }
    } catch (e) {
      // Ignore cache errors
      print('Cache load error: $e');
    }

    // 2. Fetch fresh data from API
    try {
      final newData = await _apiService.getCountrycode();
      if (mounted) {
        if (newData != null) {
          state = AsyncValue.data(newData);
        } else {
          // API returned null (error), check if we have data
          if (state is! AsyncData || state.value == null) {
             // If no cache, we COULD set error, but since we suppressed the exception, 
             // we might want to just leave it (or set a specific "Offline" error if needed).
             // For now, let's just log it.
             print('API returned null (likely network error)');
             // Optional: state = AsyncValue.error('Failed to load data', StackTrace.current);
          }
        }
      }
    } catch (e, stack) {
      print('API Fetch error (unexpected): $e');
      if (state is! AsyncData || state.value == null) {
        if (mounted) state = AsyncValue.error(e, stack);
      }
    }
  }
}

final countryCodeProvider =
    StateNotifierProvider<CountryCodeNotifier, AsyncValue<CountryCodeModel?>>(
        (ref) {
  return CountryCodeNotifier();
});
