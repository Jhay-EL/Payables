import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class PerformanceUtils {
  // Debounce function to limit frequent calls
  static Timer? _debounceTimer;

  static void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  // Throttle function to limit execution frequency
  static DateTime? _lastExecution;

  static bool throttle({
    Duration duration = const Duration(milliseconds: 100),
  }) {
    final now = DateTime.now();
    if (_lastExecution == null || now.difference(_lastExecution!) > duration) {
      _lastExecution = now;
      return true;
    }
    return false;
  }

  // Optimized list filtering with caching
  static final Map<String, List<dynamic>> _filterCache = {};

  static List<T> filterWithCache<T>(
    List<T> items,
    String cacheKey,
    bool Function(T) predicate,
  ) {
    if (_filterCache.containsKey(cacheKey)) {
      return _filterCache[cacheKey]!.cast<T>();
    }

    final filtered = items.where(predicate).toList();
    _filterCache[cacheKey] = filtered;

    // Clear cache after 5 minutes
    Timer(const Duration(minutes: 5), () => _filterCache.remove(cacheKey));

    return filtered;
  }

  // Clear all caches
  static void clearCaches() {
    _filterCache.clear();
    _debounceTimer?.cancel();
    _lastExecution = null;
  }

  // Optimized color calculations
  static Color getOptimizedColor(Color baseColor, double opacity) {
    return baseColor.withOpacity(opacity);
  }

  // Batch processing for large lists
  static Future<List<T>> processBatch<T>(
    List<T> items,
    Future<T> Function(T) processor, {
    int batchSize = 10,
  }) async {
    final results = <T>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      final batch = items.sublist(i, end);

      final batchResults = await Future.wait(
        batch.map((item) => processor(item)),
      );

      results.addAll(batchResults);

      // Yield control to allow UI updates
      await Future.delayed(const Duration(milliseconds: 1));
    }

    return results;
  }

  // Optimized string formatting
  static String formatCurrency(double amount, String currency) {
    return '$currency ${amount.toStringAsFixed(2)}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) return 'Overdue';
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference <= 7) return 'In $difference days';

    return '${date.day}/${date.month}/${date.year}';
  }

  // Memory-efficient list operations
  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<T> sortEfficiently<T>(List<T> list, int Function(T, T) compare) {
    final sorted = List<T>.from(list);
    sorted.sort(compare);
    return sorted;
  }

  // Optimized widget building helpers
  static Widget buildOptimizedList<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }

  // Performance monitoring
  static void measurePerformance(String operation, VoidCallback callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();

    if (stopwatch.elapsedMilliseconds > 16) {
      // 60fps threshold
      debugPrint(
        'Performance warning: $operation took ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  // Optimized async operations
  static Future<T> runInBackground<T>(Future<T> Function() operation) async {
    return await compute(_isolateOperation, operation);
  }

  static Future<T> _isolateOperation<T>(Future<T> Function() operation) async {
    return await operation();
  }
}

// Extension for common performance optimizations
extension PerformanceExtensions on Widget {
  Widget withRepaintBoundary() {
    return RepaintBoundary(child: this);
  }

  Widget withPerformanceOptimization() {
    return RepaintBoundary(child: this);
  }
}

extension ListPerformanceExtensions<T> on List<T> {
  List<T> optimizedWhere(bool Function(T) test) {
    return where(test).toList();
  }

  List<R> optimizedMap<R>(R Function(T) convert) {
    return map(convert).toList();
  }
}
