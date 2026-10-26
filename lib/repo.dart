import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firestore 읽기/쓰기를 한 곳에 모아 둔 클래스
///
/// 구조
///  users/{uid}                      : { name, familyId }
///  invites/{code}                   : { familyId }
///  families/{fid}                   : { name, inviteCode, members[], budgets{} }
///  families/{fid}/transactions/{id} : { type, amount, category, memo, date, authorUid, authorName }
class Repo {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get uid => FirebaseAuth.instance.currentUser!.uid;

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      _db.collection('users').doc(uid);

  static DocumentReference<Map<String, dynamic>> family(String id) =>
      _db.collection('families').doc(id);

  static CollectionReference<Map<String, dynamic>> txs(String familyId) =>
      family(familyId).collection('transactions');

  // 헷갈리기 쉬운 문자(0,O,1,I)는 뺀 초대 코드 문자
  static const String _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String _newCode() {
    final r = Random.secure();
    return List.generate(6, (_) => _alphabet[r.nextInt(_alphabet.length)])
        .join();
  }

  /// 오프라인이면 서버 응답이 오래 걸릴 수 있어서, 일정 시간 뒤에는 기다리지 않고 넘어갑니다.
  /// (쓰기는 기기에 저장되어 있다가 연결되면 자동으로 서버에 반영됩니다)
  static Future<void> _bounded(Future<void> f) =>
      f.timeout(const Duration(seconds: 6), onTimeout: () {});

  /// 새 가족 가계부를 만들고 초대 코드를 돌려줍니다.
  static Future<String> createFamily({
    required String familyName,
    required String userName,
  }) async {
    final me = uid;
    for (var i = 0; i < 5; i++) {
      final code = _newCode();
      final inviteRef = _db.collection('invites').doc(code);
      if ((await inviteRef.get()).exists) continue;

      final famRef = _db.collection('families').doc();
      final batch = _db.batch();
      batch.set(famRef, {
        'name': familyName,
        'inviteCode': code,
        'members': [me],
        'budgets': <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(inviteRef, {'familyId': famRef.id});
      batch.set(user(me), {'name': userName, 'familyId': famRef.id});
      await batch.commit();
      return code;
    }
    throw Exception('초대 코드를 만들지 못했어요. 다시 시도해 주세요.');
  }

  /// 초대 코드로 기존 가족 가계부에 들어갑니다.
  static Future<void> joinFamily({
    required String code,
    required String userName,
  }) async {
    final snap =
        await _db.collection('invites').doc(code.trim().toUpperCase()).get();
    if (!snap.exists) {
      throw Exception('초대 코드를 찾을 수 없어요. 코드를 다시 확인해 주세요.');
    }
    final fid = snap.data()!['familyId'] as String;
    await family(fid).update({
      'members': FieldValue.arrayUnion([uid]),
    });
    await user(uid).set({'name': userName, 'familyId': fid});
  }

  /// 가족 가계부에서 나갑니다. (가계부 데이터는 남은 가족이 계속 사용)
  static Future<void> leaveFamily(String familyId) async {
    await family(familyId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
    await user(uid).update({'familyId': FieldValue.delete()});
  }

  static Future<void> addTx(String familyId, Map<String, dynamic> data) =>
      _bounded(txs(familyId)
          .add({...data, 'createdAt': FieldValue.serverTimestamp()}).then((_) {}));

  static Future<void> updateTx(
          String familyId, String txId, Map<String, dynamic> data) =>
      _bounded(txs(familyId).doc(txId).update(data));

  static Future<void> deleteTx(String familyId, String txId) =>
      _bounded(txs(familyId).doc(txId).delete());

  // ───────────────────────── 고정 지출 ─────────────────────────

  static CollectionReference<Map<String, dynamic>> fixed(String familyId) =>
      family(familyId).collection('fixed');

  /// '2026-10' 형태의 달 키
  static String monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static Future<void> addFixed(String familyId, Map<String, dynamic> data) =>
      _bounded(fixed(familyId)
          .add({...data, 'createdAt': FieldValue.serverTimestamp()}).then((_) {}));

  static Future<void> updateFixed(
          String familyId, String id, Map<String, dynamic> data) =>
      _bounded(fixed(familyId).doc(id).update(data));

  static Future<void> deleteFixed(String familyId, String id) =>
      _bounded(fixed(familyId).doc(id).delete());

  /// 결제일이 지났는데 아직 내역에 없는 달들의 날짜 목록
  /// (lastApplied 다음 달부터 오늘까지, 31일처럼 없는 날은 그 달 말일로)
  static List<DateTime> _dueDates(String? last, int day, DateTime today) {
    var y = today.year;
    var m = today.month;
    if (last != null && last.length == 7) {
      y = int.tryParse(last.substring(0, 4)) ?? y;
      m = (int.tryParse(last.substring(5, 7)) ?? (m - 1)) + 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
    final result = <DateTime>[];
    for (var i = 0; i < 24; i++) {
      final end = DateTime(y, m + 1, 0).day;
      final date = DateTime(y, m, day > end ? end : day);
      if (date.isAfter(today)) break;
      result.add(date);
      m += 1;
      if (m > 12) {
        m = 1;
        y += 1;
      }
    }
    return result;
  }

  /// 결제일이 지난 고정 지출/수입을 내역에 자동으로 넣습니다.
  /// 거래(transaction)로 처리해서 여러 가족이 동시에 앱을 열어도 중복되지 않아요.
  /// 인터넷이 안 되면 조용히 건너뛰고, 다음에 앱을 열 때 다시 시도합니다.
  static Future<int> applyFixed(String familyId) async {
    var created = 0;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final snap = await fixed(familyId).get();
      for (final doc in snap.docs) {
        try {
          created += await _db.runTransaction<int>((t) async {
            final fresh = await t.get(doc.reference);
            final d = fresh.data();
            if (d == null) return 0;
            final day = ((d['day'] as num?)?.toInt() ?? 1).clamp(1, 31).toInt();
            final dates =
                _dueDates(d['lastApplied'] as String?, day, today);
            if (dates.isEmpty) return 0;
            for (final date in dates) {
              t.set(txs(familyId).doc('fx_${doc.id}_${monthKey(date)}'), {
                'type': (d['type'] as String?) ?? 'expense',
                'amount': (d['amount'] as num?)?.toInt() ?? 0,
                'category': (d['category'] as String?) ?? '기타',
                'memo': (d['name'] as String?) ?? '',
                'date': Timestamp.fromDate(date),
                'authorUid': '',
                'authorName': '고정',
                'fixedId': doc.id,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }
            t.update(doc.reference, {'lastApplied': monthKey(dates.last)});
            return dates.length;
          });
        } catch (_) {
          // 이 항목은 다음에 다시 시도
        }
      }
    } catch (_) {
      // 오프라인 등: 다음 실행 때 다시 시도
    }
    return created;
  }

  /// 월 예산 저장. value가 null이면 예산을 해제합니다.
  static Future<void> setBudget(String familyId, String key, int? value) =>
      _bounded(family(familyId).set({
        'budgets': {key: value ?? FieldValue.delete()},
      }, SetOptions(merge: true)));
}
