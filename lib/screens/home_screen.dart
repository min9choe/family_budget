import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';
import 'budget_tab.dart';
import 'family_screen.dart';
import 'ledger_tab.dart';
import 'stats_tab.dart';
import 'tx_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.familyId, required this.userName});

  final String familyId;
  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late DateTime _month;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _txStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _familyStream =
      Repo.family(widget.familyId).snapshots();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _txStream = _buildTxStream();
  }

  /// 선택한 달을 포함해 최근 6개월 내역을 한 번에 구독합니다 (통계 막대그래프용)
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildTxStream() {
    final from = DateTime(_month.year, _month.month - 5, 1);
    final to = DateTime(_month.year, _month.month + 1, 1);
    return Repo.txs(widget.familyId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _txStream = _buildTxStream();
    });
  }

  void _openEdit({Tx? tx}) {
    final now = DateTime.now();
    final initial = sameMonth(_month, now)
        ? DateTime(now.year, now.month, now.day)
        : DateTime(_month.year, _month.month, 1);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TxEditScreen(
        familyId: widget.familyId,
        userName: widget.userName,
        initialDate: initial,
        tx: tx,
      ),
    ));
  }

  Future<void> _delete(Tx tx) async {
    await Repo.deleteTx(widget.familyId, tx.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('삭제했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _familyStream,
      builder: (context, famSnap) {
        if (famSnap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('가족 정보를 불러오지 못했어요.\n\n${famSnap.error}',
                    textAlign: TextAlign.center),
              ),
            ),
          );
        }
        if (!famSnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final fam = famSnap.data!.data();
        if (fam == null) {
          return const Scaffold(body: Center(child: Text('가계부를 찾을 수 없어요.')));
        }

        final budgets = <String, int>{
          for (final e in ((fam['budgets'] as Map?) ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        };
        final familyName = (fam['name'] as String?) ?? '우리집 가계부';
        final inviteCode = (fam['inviteCode'] as String?) ?? '';
        final memberCount = ((fam['members'] as List?) ?? const []).length;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '이전 달',
                  onPressed: () => _shiftMonth(-1),
                ),
                Text(monthLabel(_month)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '다음 달',
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.group),
                tooltip: '가족 / 초대 코드',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => FamilyScreen(
                    familyId: widget.familyId,
                    familyName: familyName,
                    inviteCode: inviteCode,
                    memberCount: memberCount,
                    userName: widget.userName,
                  ),
                )),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _txStream,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('내역을 불러오지 못했어요.\n\n${snap.error}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!.docs.map(Tx.fromDoc).toList();
              final monthTxs =
                  all.where((t) => sameMonth(t.date, _month)).toList();

              switch (_tab) {
                case 0:
                  return LedgerTab(
                    txs: monthTxs,
                    onTap: (t) => _openEdit(tx: t),
                    onDelete: _delete,
                  );
                case 1:
                  return StatsTab(allTxs: all, month: _month);
                default:
                  return BudgetTab(
                    txs: monthTxs,
                    budgets: budgets,
                    onSet: (key, value) =>
                        Repo.setBudget(widget.familyId, key, value),
                  );
              }
            },
          ),
          floatingActionButton: _tab == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _openEdit(),
                  icon: const Icon(Icons.add),
                  label: const Text('내역 추가'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: '내역'),
              NavigationDestination(
                  icon: Icon(Icons.pie_chart_outline),
                  selectedIcon: Icon(Icons.pie_chart),
                  label: '통계'),
              NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: '예산'),
            ],
          ),
        );
      },
    );
  }
}
