import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models.dart';
import '../theme.dart';

/// 홈: 이번 달 합계 + 달력 + (선택한 날의) 내역
class LedgerTab extends StatefulWidget {
  const LedgerTab({
    super.key,
    required this.month,
    required this.txs,
    required this.onTap,
    required this.onDelete,
  });

  final DateTime month;
  final List<Tx> txs;
  final void Function(Tx tx) onTap;
  final Future<void> Function(Tx tx) onDelete;

  @override
  State<LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends State<LedgerTab> {
  /// 선택한 날짜(일). null이면 한 달 전체를 보여줍니다.
  int? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (sameMonth(now, widget.month)) _selectedDay = now.day;
  }

  int _sum(Iterable<Tx> list, bool expense) => list
      .where((t) => t.isExpense == expense)
      .fold<int>(0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final txs = widget.txs;
    final income = _sum(txs, false);
    final expense = _sum(txs, true);
    final balance = income - expense;

    final byDay = <int, List<Tx>>{};
    for (final t in txs) {
      byDay.putIfAbsent(t.date.day, () => []).add(t);
    }

    final shown = _selectedDay == null ? txs : (byDay[_selectedDay] ?? <Tx>[]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.month.month}월 합계',
                  style: const TextStyle(color: Palette.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                '${balance < 0 ? '−' : ''}${won(balance.abs())}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniStat('수입', income, Palette.income),
                  const SizedBox(width: 20),
                  _miniStat('지출', expense, Palette.ink),
                ],
              ),
            ],
          ),
        ),
        Panel(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: _calendar(byDay),
        ),
        const SizedBox(height: 18),
        _listHeader(byDay),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            child: Text(
              _selectedDay == null
                  ? '이번 달 내역이 없어요.\n가운데 + 버튼으로 첫 내역을 남겨 보세요.'
                  : '이 날은 내역이 없어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.muted, height: 1.5),
            ),
          )
        else
          ..._groupedTiles(shown),
      ],
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Palette.muted, fontSize: 13)),
        const SizedBox(width: 6),
        Text(won(value),
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }

  // ───────────── 달력 ─────────────

  Widget _calendar(Map<int, List<Tx>> byDay) {
    final y = widget.month.year;
    final m = widget.month.month;
    final lead = DateTime(y, m, 1).weekday - 1; // 월요일 시작
    final days = lastDayOfMonth(y, m);
    final rows = ((lead + days) / 7).ceil();
    final now = DateTime.now();

    var maxExpense = 0;
    final expenseOf = <int, int>{};
    final incomeOf = <int, int>{};
    byDay.forEach((d, list) {
      final e = _sum(list, true);
      expenseOf[d] = e;
      incomeOf[d] = _sum(list, false);
      if (e > maxExpense) maxExpense = e;
    });

    const names = ['월', '화', '수', '목', '금', '토', '일'];

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    names[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: i == 6 ? Palette.danger : Palette.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: _dayCell(
                    day: r * 7 + c - lead + 1,
                    days: days,
                    expense: expenseOf,
                    income: incomeOf,
                    maxExpense: maxExpense,
                    isToday: sameMonth(now, widget.month) &&
                        now.day == r * 7 + c - lead + 1,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell({
    required int day,
    required int days,
    required Map<int, int> expense,
    required Map<int, int> income,
    required int maxExpense,
    required bool isToday,
  }) {
    if (day < 1 || day > days) return const SizedBox(height: 56);

    final e = expense[day] ?? 0;
    final i = income[day] ?? 0;
    final selected = _selectedDay == day;

    Color fill = Colors.transparent;
    if (selected) {
      fill = Palette.yellow;
    } else if (e > 0 && maxExpense > 0) {
      fill = Color.lerp(Palette.taupeSoft, Palette.taupe, e / maxExpense * 0.8)!;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedDay = selected ? null : day),
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: isToday && !selected
                    ? Border.all(color: Palette.ink, width: 1.2)
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (e > 0 || i > 0 || selected)
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: Palette.ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 12,
              child: e > 0
                  ? Text(compactWon(e),
                      maxLines: 1,
                      style: const TextStyle(fontSize: 9, color: Palette.muted))
                  : i > 0
                      ? Text('+${compactWon(i)}',
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 9, color: Palette.income))
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── 내역 목록 ─────────────

  Widget _listHeader(Map<int, List<Tx>> byDay) {
    final String title;
    int? sumExpense;
    if (_selectedDay == null) {
      title = '${widget.month.month}월 전체 내역';
    } else {
      final d = DateTime(widget.month.year, widget.month.month, _selectedDay!);
      title = DateFormat('M월 d일 (E)', 'ko_KR').format(d);
      sumExpense = _sum(byDay[_selectedDay] ?? <Tx>[], true);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          if (sumExpense != null && sumExpense > 0)
            Text('지출 ${won(sumExpense)}',
                style: const TextStyle(color: Palette.muted, fontSize: 13))
          else if (_selectedDay == null)
            const Text('날짜를 누르면 그날만 볼 수 있어요',
                style: TextStyle(fontSize: 12, color: Palette.muted)),
        ],
      ),
    );
  }

  List<Widget> _groupedTiles(List<Tx> list) {
    // 전체 보기에서는 날짜별 소제목을 넣어 줍니다.
    final widgets = <Widget>[];
    int? lastDay;
    final dayFormat = DateFormat('M월 d일 (E)', 'ko_KR');
    for (final t in list) {
      if (_selectedDay == null && t.date.day != lastDay) {
        lastDay = t.date.day;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
          child: Text(dayFormat.format(t.date),
              style: const TextStyle(color: Palette.muted, fontSize: 12)),
        ));
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _txTile(t),
      ));
    }
    return widgets;
  }

  Widget _txTile(Tx t) {
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Palette.danger,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async =>
          await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('내역 삭제'),
              content: Text('${t.category} ${won(t.amount)} 내역을 삭제할까요?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('삭제')),
              ],
            ),
          ) ??
          false,
      onDismissed: (_) => widget.onDelete(t),
      child: Panel(
        onTap: () => widget.onTap(t),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CategoryDot(icon: iconFor(t.category), color: categoryColor(t.category)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.memo.isEmpty ? t.category : t.memo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                      if (t.isAuto) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Palette.yellowSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('고정',
                              style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.isAuto || t.authorName.isEmpty
                        ? t.category
                        : '${t.category} · ${t.authorName}',
                    style: const TextStyle(color: Palette.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${t.isExpense ? '−' : '+'}${won(t.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: t.isExpense ? Palette.ink : Palette.income,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
