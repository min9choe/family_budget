import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models.dart';

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

  Color _barColor(double ratio) {
    if (ratio > 1) return Colors.red.shade600;
    if (ratio > 0.8) return Colors.orange.shade700;
    return Colors.green.shade600;
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
          decoration: const InputDecoration(
            suffixText: '원',
            hintText: '예: 300000',
          ),
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
    final cs = Theme.of(context).colorScheme;

    final spentByCat = <String, int>{};
    for (final t in txs.where((t) => t.isExpense)) {
      spentByCat[t.category] = (spentByCat[t.category] ?? 0) + t.amount;
    }
    final totalSpent = spentByCat.values.fold<int>(0, (a, b) => a + b);
    final totalBudget = budgets[totalBudgetKey];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _edit(context, totalBudgetKey, '전체'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('이번 달 전체 예산',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Icon(Icons.edit, size: 18, color: cs.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (totalBudget == null)
                    Text('아직 설정하지 않았어요. 눌러서 전체 예산을 정해 보세요.',
                        style: TextStyle(color: cs.onSurfaceVariant))
                  else ...[
                    Text(
                      '${won(totalSpent)} / ${won(totalBudget)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (totalSpent / totalBudget).clamp(0.0, 1.0),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                      color: _barColor(totalSpent / totalBudget),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalSpent <= totalBudget
                          ? '${won(totalBudget - totalSpent)} 남았어요'
                          : '${won(totalSpent - totalBudget)} 초과했어요',
                      style: TextStyle(
                        color: totalSpent <= totalBudget
                            ? cs.onSurfaceVariant
                            : Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('카테고리별 예산', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('카테고리를 눌러 월 예산을 설정하세요. 매달 같은 금액이 적용돼요.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 8),
        for (final c in expenseCategories)
          _categoryTile(context, c, spentByCat[c] ?? 0, budgets[c]),
      ],
    );
  }

  Widget _categoryTile(
      BuildContext context, String category, int spent, int? budget) {
    final cs = Theme.of(context).colorScheme;
    final ratio = (budget == null || budget == 0) ? 0.0 : spent / budget;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => _edit(context, category, category),
      leading: CircleAvatar(
        backgroundColor: categoryColor(category).withOpacity(0.15),
        child: Icon(iconFor(category), color: categoryColor(category)),
      ),
      title: Text(category),
      subtitle: budget == null
          ? Text('예산 미설정 · 사용 ${won(spent)}',
              style: TextStyle(color: cs.onSurfaceVariant))
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: ratio.clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    color: _barColor(ratio),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spent <= budget
                        ? '${won(spent)} / ${won(budget)}  (${won(budget - spent)} 남음)'
                        : '${won(spent)} / ${won(budget)}  (${won(spent - budget)} 초과)',
                    style: TextStyle(
                      fontSize: 12,
                      color: spent <= budget
                          ? cs.onSurfaceVariant
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
    );
  }
}
