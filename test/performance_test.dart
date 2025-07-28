import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:payables/data/subscription_database.dart';
import 'package:payables/utils/performance_utils.dart';

void main() {
  group('Performance Tests', () {
    test('Database query performance', () async {
      final stopwatch = Stopwatch()..start();

      // Test the optimized getDashboardData method
      final result = await SubscriptionDatabase.getDashboardData();

      stopwatch.stop();

      // Should complete within 100ms for good performance
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // Verify the result structure
      expect(result, isA<Map<String, dynamic>>());
      expect(result['allSubscriptions'], isA<List>());
      expect(result['counts'], isA<Map<String, int>>());
    });

    test('Performance utils debounce', () async {
      int callCount = 0;

      // Test debounce functionality
      PerformanceUtils.debounce(() {
        callCount++;
      }, duration: const Duration(milliseconds: 100));

      PerformanceUtils.debounce(() {
        callCount++;
      }, duration: const Duration(milliseconds: 100));

      // Wait for debounce to complete
      await Future.delayed(const Duration(milliseconds: 200));

      // Should only be called once due to debouncing
      expect(callCount, equals(1));
    });

    test('Performance utils throttle', () {
      int callCount = 0;

      // Test throttle functionality
      final shouldExecute1 = PerformanceUtils.throttle();
      if (shouldExecute1) callCount++;

      final shouldExecute2 = PerformanceUtils.throttle();
      if (shouldExecute2) callCount++;

      // Should only execute once due to throttling
      expect(callCount, equals(1));
    });

    test('List filtering performance', () {
      final testList = List.generate(1000, (index) => 'Item $index');

      final stopwatch = Stopwatch()..start();

      // Test optimized filtering
      final filtered = PerformanceUtils.filterWithCache(
        testList,
        'test_filter',
        (item) => item.contains('5'),
      );

      stopwatch.stop();

      // Should complete within 10ms for good performance
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(filtered.length, greaterThan(0));
    });

    test('String formatting performance', () {
      final stopwatch = Stopwatch()..start();

      // Test optimized string formatting
      for (int i = 0; i < 1000; i++) {
        PerformanceUtils.formatCurrency(123.45, 'EUR');
        PerformanceUtils.formatDate(DateTime.now());
      }

      stopwatch.stop();

      // Should complete within 50ms for good performance
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Performance measurement', () {
      bool warningLogged = false;

      // Mock the debugPrint to capture performance warnings
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message?.contains('Performance warning') == true) {
          warningLogged = true;
        }
        originalDebugPrint(message, wrapWidth: wrapWidth);
      };

      // Test performance measurement with slow operation
      PerformanceUtils.measurePerformance('Slow Test', () {
        // Simulate slow operation
        for (int i = 0; i < 1000000; i++) {
          // Do some work
        }
      });

      // Should log a performance warning
      expect(warningLogged, isTrue);

      // Restore original debugPrint
      debugPrint = originalDebugPrint;
    });
  });
}
