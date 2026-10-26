import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../models.dart';
import '../theme.dart';

/// 통계: 카테고리별 지출(원형), 최근 6개월 수입/지출(막대), 가족 구성원별 지출
class StatsTab extends StatelessWidget {
  const StatsTab({super.key, required this.allTxs, required this.month});

  /// 선택한 달을 포함한 최근 6개월 내역
  final List<Tx> allTxs;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final expenses =
        allTxs.where((t) => t.isExpense && sameMonth(t.date, month)).toList();
    final total = expenses.fold<int>(0, (s, t) => s + t.amount);

    final byCategory = <String, int>{};
    final byPerson = <String, int>{};
    for (final t in expenses) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      final who = t.authorName.isEmpty ? '고정' : t.authorName;
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${month.month}월 지출',
                  style: const TextStyle(color: Palette.muted, fontSize: 13)),
              const SizedBox(height: 2),
              Text(won(total),
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800, height: 1.15)),
            ],
          ),
        ),
        Panel(
          child: total == 0
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text('이번 달 지출 내역이 없어요.',
                        style: TextStyle(color: Palette.muted)),
                  ),
                )
              : SizedBox(
                  height: 210,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      sections: [
                        for (final e in categories)
                          PieChartSectionData(
                            value: e.value.toDouble(),
                            color: categoryColor(e.key),
                            radius: 56,
                            title: e.value * 100 / total >= 7
                                ? '${(e.value * 100 / total).round()}%'
                                : '',
                            titleStyle: const TextStyle(
                                color: Palette.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 16),
          for (final e in categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FillRow(
                ratio: e.value / total,
                fill: categoryColor(e.key).withAlpha(120),
                child: Row(
                  children: [
                    CategoryDot(
                        icon: iconFor(e.key),
                        color: categoryColor(e.key),
                        size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(won(e.value),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 34,
                      child: Text('${(e.value * 100 / total).round()}%',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Palette.muted, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('최근 6개월',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Panel(
          padding: const EdgeInsets.fromLTRB(12, 14, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 4),
                  _legend(Palette.income, '수입'),
                  const SizedBox(width: 12),
                  _legend(expenseBarColor, '지출'),
                  const Spacer(),
                  const Text('단위: 만원',
                      style: TextStyle(color: Palette.muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    alignment: BarChartAlignment.spaceAround,
                    gridData: const FlGridData(
                      show: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 38,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 10, color: Palette.muted),
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
                                  style: const TextStyle(
                                      fontSize: 11, color: Palette.muted)),
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
                              color: Palette.income,
                              width: 9,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            BarChartRodData(
                              toY: spends[i] / 10000,
                              color: expenseBarColor,
                              width: 9,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('${month.month}월 누가 얼마 썼을까?',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        if (people.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('지출 내역이 없어요.',
                style: TextStyle(color: Palette.muted)),
          )
        else
          for (final e in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FillRow(
                ratio: total == 0 ? 0 : e.value / total,
                fill: Palette.yellowFill,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(won(e.value),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _legend(Color color, String label) => Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      );
}
