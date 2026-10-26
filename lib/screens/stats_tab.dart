import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';

/// 월별 통계: 카테고리별 지출(원형), 최근 6개월 수입/지출(막대), 가족 구성원별 지출
class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.allTxs, required this.month});

  /// 선택한 달을 포함한 최근 6개월 내역
  final List<Tx> allTxs;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final expenses =
        allTxs.where((t) => t.isExpense && sameMonth(t.date, month)).toList();
    final total = expenses.fold<int>(0, (s, t) => s + t.amount);

    final byCategory = <String, int>{};
    final byPerson = <String, int>{};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      final who = t.authorName.isEmpty ? '이름 없음' : t.authorName;
      byPerson[who] = (byPerson[who] ?? 0) + t.amount;
    }
    final categories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final people = byPerson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 최근 6개월
    final months =
        List.generate(6, (i) => DateTime(month.year, month.month - 5 + i));
    int sumOf(DateTime m, bool expense) => allTxs
        .where((t) => t.isExpense == expense && sameMonth(t.date, m))
        .fold<int>(0, (s, t) => s + t.amount);
    final incomes = months.map((m) => sumOf(m, false)).toList();
    final spends = months.map((m) => sumOf(m, true)).toList();
    final maxValue = [...incomes, ...spends].fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue == 0 ? 10.0 : maxValue / 10000 * 1.15;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${month.month}월 지출 ${won(total)}',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('이번 달 지출 내역이 없어요.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          )
        else ...[
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  for (final e in categories)
                    PieChartSectionData(
                      value: e.value.toDouble(),
                      color: categoryColor(e.key),
                      radius: 62,
                      title: e.value * 100 / total >= 6
                          ? '${(e.value * 100 / total).round()}%'
                          : '',
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final e in categories)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: categoryColor(e.key),
                child: Icon(iconFor(e.key), size: 16, color: Colors.white),
              ),
              title: Text(e.key),
              trailing: Text(
                '${won(e.value)}  (${(e.value * 100 / total).round()}%)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
        const Divider(height: 40),
        Text('최근 6개월 수입 · 지출', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            _legend(incomeColor, '수입'),
            const SizedBox(width: 12),
            _legend(expenseColor, '지출'),
            const Spacer(),
            Text('(단위: 만원)',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= months.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${months[i].month}월',
                            style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < months.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: incomes[i] / 10000,
                        color: incomeColor,
                        width: 9,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: spends[i] / 10000,
                        color: expenseColor,
                        width: 9,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 40),
        Text('${month.month}월 누가 얼마 썼을까?',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (people.isEmpty)
          Text('지출 내역이 없어요.', style: TextStyle(color: cs.onSurfaceVariant))
        else
          for (final e in people)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(e.key),
                      const Spacer(),
                      Text(won(e.value),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : e.value / total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(width: 10, height: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
