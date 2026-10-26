import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models.dart';
import '../theme.dart';

/// 월 예산 설정과 사용 현황 (예산은 매달 같은 금액이 적용됩니다)
class BudgetTab extends StatelessWidget {
  const BudgetTab({
    super.key,
    required this.txs,
    required this.budgets,
    required this.onSet,
  });

  /// 선택한 달의 내역
  final List<Tx> txs;

  /// 카테고리(또는 totalBudgetKey) -> 월 예산
  final Map<String, int> budgets;

  /// value가 null이면 예산 해제
  final Future<void> Function(String key, int? value) onSet;

  Color _fillFor(double ratio) {
    if (ratio > 1) return Palette.dangerFill;
    if (ratio > 0.8) return Palette.warnFill;
    return Palette.yellowFill;
  }

  Future<void> _edit(BuildContext context, String key, String title) async {
    final ctrl = TextEditingController(text: budgets[key]?.toString() ?? '');
    final res = await showDialog<Object>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('$title 월 예산'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: fieldDecoration(suffix: '원', hint: '예: 300000'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('취소')),
          if (budgets[key] != null)
            TextButton(
                onPressed: () => Navigator.pop(c, 'delete'),
                child: const Text('예산 해제')),
          FilledButton(
              onPressed: () => Navigator.pop(c, int.tryParse(ctrl.text) ?? 0),
              child: const Text('저장')),
        ],
      ),
    );
    if (res == 'delete') {
      await onSet(key, null);
    } else if (res is int) {
      await onSet(key, res > 0 ? res : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spentByCat = <String, int>{};
    for (final t in txs.where((t) => t.isExpense)) {
      spentByCat[t.category] = (spentByCat[t.category] ?? 0) + t.amount;
    }
    final totalSpent = spentByCat.values.fold<int>(0, (a, b) => a + b);
    final totalBudget = budgets[totalBudgetKey];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Panel(
          onTap: () => _edit(context, totalBudgetKey, '전체'),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('이번 달 전체 예산',
                      style: TextStyle(color: Palette.muted, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.edit_outlined, size: 16, color: Palette.muted),
                ],
              ),
              const SizedBox(height: 6),
              if (totalBudget == null)
                const Text('눌러서 전체 예산을 정해 보세요.',
                    style: TextStyle(color: Palette.muted, height: 1.4))
              else ...[
                Text(
                  totalSpent <= totalBudget
                      ? '${won(totalBudget - totalSpent)} 남음'
                      : '${won(totalSpent - totalBudget)} 초과',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: totalSpent <= totalBudget
                        ? Palette.ink
                        : Palette.danger,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (totalSpent / totalBudget).clamp(0.0, 1.0).toDouble(),
                    minHeight: 12,
                    backgroundColor: Palette.taupeSoft,
                    color: totalSpent > totalBudget
                        ? Palette.danger
                        : Palette.yellow,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${won(totalSpent)} / ${won(totalBudget)}',
                    style: const TextStyle(color: Palette.muted, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('카테고리별 예산',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(height: 2),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('눌러서 월 예산을 정하면 매달 같은 금액이 적용돼요.',
              style: TextStyle(color: Palette.muted, fontSize: 12)),
        ),
        const SizedBox(height: 10),
        for (final c in expenseCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _categoryRow(context, c, spentByCat[c] ?? 0, budgets[c]),
          ),
      ],
    );
  }

  Widget _categoryRow(
      BuildContext context, String category, int spent, int? budget) {
    final ratio = (budget == null || budget == 0) ? 0.0 : spent / budget;
    final over = budget != null && spent > budget;
    return FillRow(
      ratio: ratio,
      fill: _fillFor(ratio),
      onTap: () => _edit(context, category, category),
      child: Row(
        children: [
          CategoryDot(
              icon: iconFor(category), color: categoryColor(category), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  budget == null
                      ? '예산 미설정'
                      : over
                          ? '${won(spent - budget)} 초과'
                          : '${won(budget - spent)} 남음',
                  style: TextStyle(
                    fontSize: 12,
                    color: over ? Palette.danger : Palette.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(won(spent),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (budget != null)
                Text('목표 ${won(budget)}',
                    style: const TextStyle(color: Palette.muted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
