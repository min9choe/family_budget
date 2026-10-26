import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'fixed_edit_screen.dart';

/// 고정 지출 관리: 매달 같은 날 나가는 돈(보험료, 대출이자 등)을 등록해 두면
/// 결제일이 지난 뒤 앱을 열 때 내역에 자동으로 들어갑니다.
class FixedScreen extends StatelessWidget {
  const FixedScreen({super.key, required this.familyId});

  final String familyId;

  void _open(BuildContext context, {FixedItem? item}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FixedEditScreen(familyId: familyId, item: item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: plainAppBar(title: const Text('고정 지출')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context),
        backgroundColor: Palette.yellow,
        foregroundColor: Palette.ink,
        elevation: 1,
        icon: const Icon(Icons.add),
        label: const Text('고정 항목 추가',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: Repo.fixed(familyId).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('불러오지 못했어요.\n\n${snap.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snap.data!.docs.map(FixedItem.fromDoc).toList()
            ..sort((a, b) => a.day.compareTo(b.day));
          final spend = items
              .where((i) => i.isExpense)
              .fold<int>(0, (s, i) => s + i.amount);
          final earn = items
              .where((i) => !i.isExpense)
              .fold<int>(0, (s, i) => s + i.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
            children: [
              Panel(
                color: Palette.yellowSoft,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('매달 나가는 고정 지출',
                        style: TextStyle(color: Palette.muted, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(won(spend),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    if (earn > 0) ...[
                      const SizedBox(height: 6),
                      Text('매달 들어오는 고정 수입 ${won(earn)}',
                          style: const TextStyle(
                              color: Palette.income,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '결제일이 지난 뒤 가족 중 누군가 앱을 열면 내역에 자동으로 들어가요. '
                  '금액을 바꾸면 아직 들어가지 않은 달부터 적용돼요.',
                  style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    '등록된 고정 항목이 없어요.\n보험료, 대출이자, 통신비처럼 매달 나가는 돈을 추가해 보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.muted, height: 1.6),
                  ),
                ),
              for (final i in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    onTap: () => _open(context, item: i),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CategoryDot(
                            icon: iconFor(i.category),
                            color: categoryColor(i.category)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('매월 ${i.day}일 · ${i.category}',
                                  style: const TextStyle(
                                      color: Palette.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${i.isExpense ? '−' : '+'}${won(i.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: i.isExpense ? Palette.ink : Palette.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
