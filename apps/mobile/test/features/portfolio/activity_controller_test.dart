import 'package:dex_app/features/portfolio/activity_controller.dart';
import 'package:dex_app/features/portfolio/activity_models.dart';
import 'package:flutter_test/flutter_test.dart';

ActivityItem _item({
  required String txHash,
  required ActivityStatus status,
  required ActivityType type,
  required DateTime timestamp,
  String title = 'entry',
}) => ActivityItem(
  type: type,
  status: status,
  title: title,
  txHash: txHash,
  timestamp: timestamp,
);

void main() {
  group('mergeActivity', () {
    test(
      'confirmed server entry replaces pending local entry with same hash regardless of case',
      () {
        final pending = _item(
          txHash: '0xABC',
          status: ActivityStatus.pending,
          type: ActivityType.withdraw,
          timestamp: DateTime.utc(2026, 1, 1),
        );
        final confirmed = _item(
          txHash: '0xabc',
          status: ActivityStatus.confirmed,
          type: ActivityType.swap,
          timestamp: DateTime.utc(2026, 1, 2),
        );

        final merged = mergeActivity([pending], [confirmed]);

        expect(merged, hasLength(1));
        expect(merged.single.status, ActivityStatus.confirmed);
        expect(merged.single.type, ActivityType.swap);
      },
    );

    test('sorts entries descending by timestamp', () {
      final older = _item(
        txHash: '0x1',
        status: ActivityStatus.confirmed,
        type: ActivityType.swap,
        timestamp: DateTime.utc(2026, 1, 1),
      );
      final newer = _item(
        txHash: '0x2',
        status: ActivityStatus.confirmed,
        type: ActivityType.swap,
        timestamp: DateTime.utc(2026, 6, 1),
      );

      final merged = mergeActivity(const [], [older, newer]);

      expect(merged.map((item) => item.txHash), ['0x2', '0x1']);
    });

    test('pending entries without a matching server row remain in result', () {
      final orphaned = _item(
        txHash: '0xDEAD',
        status: ActivityStatus.pending,
        type: ActivityType.withdraw,
        timestamp: DateTime.utc(2026, 3, 1),
      );

      final merged = mergeActivity([orphaned], const []);

      expect(merged, hasLength(1));
      expect(merged.single.status, ActivityStatus.pending);
      expect(merged.single.txHash, '0xDEAD');
    });

    test('explorer URL points at BaseScan', () {
      final item = _item(
        txHash: '0xfeed',
        status: ActivityStatus.confirmed,
        type: ActivityType.swap,
        timestamp: DateTime.utc(2026, 1, 1),
      );
      expect(item.explorerUrl, 'https://basescan.org/tx/0xfeed');
    });
  });
}
