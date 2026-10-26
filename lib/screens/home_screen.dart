import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';
import 'budget_tab.dart';
import 'ledger_tab.dart';
import 'more_tab.dart';
import 'stats_tab.dart';
import 'tx_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.familyId, required this.userName});

  final String familyId;
  final String userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _tab = 0;
  late DateTime _month;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _txStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _familyStream =
      Repo.family(widget.familyId).snapshots();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _txStream = _buildTxStream();
    // 결제일이 지난 고정 지출을 내역에 자동으로 넣습니다.
    Repo.applyFixed(widget.familyId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱을 며칠 켜 둔 채로 두었다가 다시 열었을 때도 확인
    if (state == AppLifecycleState.resumed) {
      Repo.applyFixed(widget.familyId);
    }
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

  // ───────────── 위쪽 머리글 (가족 이름 + 달 선택) ─────────────

  Widget _header(String familyName, int memberCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Palette.yellowSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.home_rounded, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  familyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                ),
                Text('함께 쓰는 가족 $memberCount명',
                    style: const TextStyle(color: Palette.muted, fontSize: 11)),
              ],
            ),
          ),
          if (_tab != 3) _monthPill(),
        ],
      ),
    );
  }

  Widget _monthPill() {
    Widget arrow(IconData icon, int delta, String tip) => IconButton(
          icon: Icon(icon, size: 20),
          tooltip: tip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: () => _shiftMonth(delta),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Palette.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow(Icons.chevron_left, -1, '이전 달'),
          Text(monthLabel(_month),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          arrow(Icons.chevron_right, 1, '다음 달'),
        ],
      ),
    );
  }

  // ───────────── 아래쪽 탭 막대 ─────────────

  Widget _navItem(int i, IconData icon, IconData activeIcon, String label) {
    final selected = _tab == i;
    final color = selected ? Palette.ink : Palette.muted;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
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
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(familyName, memberCount),
                Expanded(
                  child: _tab == 3
                      ? MoreTab(
                          familyId: widget.familyId,
                          familyName: familyName,
                          inviteCode: inviteCode,
                          memberCount: memberCount,
                          userName: widget.userName,
                        )
                      : _txBody(budgets),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openEdit(),
            backgroundColor: Palette.yellow,
            foregroundColor: Palette.ink,
            elevation: 2,
            shape: const CircleBorder(),
            tooltip: '내역 추가',
            child: const Icon(Icons.add, size: 32),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            padding: EdgeInsets.zero,
            height: 66,
            child: Row(
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, '홈'),
                _navItem(1, Icons.pie_chart_outline, Icons.pie_chart, '통계'),
                const SizedBox(width: 72),
                _navItem(2, Icons.savings_outlined, Icons.savings, '예산'),
                _navItem(3, Icons.menu, Icons.menu, '더보기'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _txBody(Map<String, int> budgets) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
        final monthTxs = all.where((t) => sameMonth(t.date, _month)).toList();

        switch (_tab) {
          case 0:
            return LedgerTab(
              key: ValueKey('ledger-${_month.year}-${_month.month}'),
              month: _month,
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
              onSet: (key, value) => Repo.setBudget(widget.familyId, key, value),
            );
        }
      },
    );
  }
}
