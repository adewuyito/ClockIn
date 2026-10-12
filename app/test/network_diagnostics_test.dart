import 'package:clockin/core/providers/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkDiagnostics.epochProgress', () {
    NetworkDiagnostics diagnostics({
      required int slotIndex,
      required int slotsInEpoch,
    }) {
      return NetworkDiagnostics(
        latencyMs: 42,
        epoch: 123,
        slotIndex: slotIndex,
        slotsInEpoch: slotsInEpoch,
        finalizedSlot: 999,
      );
    }

    test('returns 0 when slotsInEpoch is zero', () {
      final data = diagnostics(slotIndex: 25, slotsInEpoch: 0);
      expect(data.epochProgress, 0);
    });

    test('returns in-range ratio for normal epoch data', () {
      final data = diagnostics(slotIndex: 250, slotsInEpoch: 1000);
      expect(data.epochProgress, 0.25);
    });

    test('clamps progress above 1 to 1.0', () {
      final data = diagnostics(slotIndex: 1250, slotsInEpoch: 1000);
      expect(data.epochProgress, 1.0);
    });

    test('clamps progress below 0 to 0.0', () {
      final data = diagnostics(slotIndex: -25, slotsInEpoch: 1000);
      expect(data.epochProgress, 0.0);
    });
  });
}
