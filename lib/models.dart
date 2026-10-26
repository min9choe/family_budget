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
  });

  final String id;
  final bool isExpense;
  final int amount;
  final String category;
  final String memo;
  final DateTime date;
  final String authorUid;
  final String authorName;

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
    );
  }
}
