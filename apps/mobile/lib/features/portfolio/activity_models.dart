enum ActivityStatus { pending, confirmed, failed }

enum ActivityType { approve, swap, deposit, withdraw }

final class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.status,
    required this.title,
    required this.txHash,
    required this.timestamp,
  });
  final ActivityType type;
  final ActivityStatus status;
  final String title;
  final String txHash;
  final DateTime timestamp;

  String get explorerUrl => 'https://basescan.org/tx/$txHash';
}
