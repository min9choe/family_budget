import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models.dart';

/// 선택한 달의 수입/지출 내역 (날짜별로 묶어서 표시)
class LedgerTab extends StatelessWidget {
  const LedgerTab({
    super.key,
    required this.txs,
    required this.onTap,
    required this.onDelete,
  });

  final List<Tx> txs;
  final void Function(Tx tx) onTap;
  final Future<void> Function(Tx tx) onDelete;

  @override
  Widget build(BuildContext context) {
    final income =
        txs.where((t) => !t.isExpense).fold<int>(0, (s, t) => s + t.amount);
    final expense =
        txs.where((t) => t.isExpense).fold<int>(0, (s, t) => s + t.amount);

    final byDay = <DateTime, List<Tx>>{};
    for (final t in txs) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      byDay.putIfAbsent(day, () => []).add(t);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final dayFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        _SummaryCard(income: income, expense: expense),
        if (txs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
            child: Text(
              '이번 달 내역이 없어요.\n아래 [내역 추가] 버튼으로 첫 내역을 남겨 보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        for (final day in days) ...[
          _DayHeader(
            label: dayFormat.format(day),
            income: byDay[day]!
                .where((t) => !t.isExpense)
                .fold<int>(0, (s, t) => s + t.amount),
            expense: byDay[day]!
                .where((t) => t.isExpense)
                .fold<int>(0, (s, t) => s + t.amount),
          ),
          for (final t in byDay[day]!) _txTile(context, t),
        ],
      ],
    );
  }

  Widget _txTile(BuildContext context, Tx t) {
    return Dismissible(
      key: ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
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
      onDismissed: (_) => onDelete(t),
      child: ListTile(
        onTap: () => onTap(t),
        leading: CircleAvatar(
          backgroundColor: categoryColor(t.category).withOpacity(0.15),
          child: Icon(iconFor(t.category), color: categoryColor(t.category)),
        ),
        title: Text(t.memo.isEmpty ? t.category : t.memo),
        subtitle: Text(
            t.authorName.isEmpty ? t.category : '${t.category} · ${t.authorName}'),
        trailing: Text(
          '${t.isExpense ? '-' : '+'}${won(t.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: t.isExpense ? expenseColor : incomeColor,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.income, required this.expense});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            ],
          ),
        );
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            cell('수입', won(income), incomeColor),
            cell('지출', won(expense), expenseColor),
            cell('합계', '${balance < 0 ? '-' : ''}${won(balance.abs())}',
                Theme.of(context).colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(
      {required this.label, required this.income, required this.expense});

  final String label;
  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(label, style: style?.copyWith(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (income > 0)
            Text('+${won(income)}  ',
                style: style?.copyWith(color: incomeColor)),
          if (expense > 0)
            Text('-${won(expense)}', style: style?.copyWith(color: expenseColor)),
        ],
      ),
    );
  }
}
