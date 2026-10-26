import 'package:cloud_firestore/cloud_firestore.dart';

/// 수입/지출 내역 한 건
class Tx {
  Tx({
    required this.id,
    required this.isExpense,
    required this.amount,
    required this.category,
    required this.memo,
    required this.date,
    required this.authorUid,
    required this.authorName,
    this.fixedId,
  });

  final String id;
  final bool isExpense;
  final int amount;
  final String category;
  final String memo;
  final DateTime date;
  final String authorUid;
  final String authorName;

  /// 고정 지출에서 자동으로 들어온 내역이면 그 항목의 id
  final String? fixedId;

  bool get isAuto => fixedId != null;

  factory Tx.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return Tx(
      id: doc.id,
      isExpense: (d['type'] as String?) != 'income',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      category: (d['category'] as String?) ?? '기타',
      memo: (d['memo'] as String?) ?? '',
      date: ((d['date'] as Timestamp?) ?? Timestamp.now()).toDate(),
      authorUid: (d['authorUid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? '',
      fixedId: d['fixedId'] as String?,
    );
  }
}

/// 매달 같은 날 반복되는 고정 지출(또는 고정 수입) 한 항목
class FixedItem {
  FixedItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.day,
    required this.category,
    required this.isExpense,
    required this.lastApplied,
  });

  final String id;
  final String name;
  final int amount;

  /// 매월 며칠 (1~31)
  final int day;
  final String category;
  final bool isExpense;

  /// 마지막으로 내역에 반영한 달 ('2026-10' 형태)
  final String? lastApplied;

  factory FixedItem.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return FixedItem(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      day: ((d['day'] as num?)?.toInt() ?? 1).clamp(1, 31).toInt(),
      category: (d['category'] as String?) ?? '기타',
      isExpense: (d['type'] as String?) != 'income',
      lastApplied: d['lastApplied'] as String?,
    );
  }
}
