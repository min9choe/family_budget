import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

const List<String> expenseCategories = [
  '식비',
  '카페·간식',
  '교통',
  '주거·통신',
  '생활용품',
  '의료·건강',
  '교육',
  '육아',
  '문화·여가',
  '쇼핑',
  '경조사',
  '보험·대출',
  '기타',
];

const List<String> incomeCategories = ['급여', '용돈', '부수입', '기타 수입'];

/// 전체 예산을 저장할 때 쓰는 키
const String totalBudgetKey = '_total';

const Map<String, IconData> _categoryIcons = {
  '식비': Icons.restaurant,
  '카페·간식': Icons.local_cafe,
  '교통': Icons.directions_bus,
  '주거·통신': Icons.home,
  '생활용품': Icons.shopping_basket,
  '의료·건강': Icons.local_hospital,
  '교육': Icons.school,
  '육아': Icons.child_care,
  '문화·여가': Icons.movie,
  '쇼핑': Icons.shopping_bag,
  '경조사': Icons.card_giftcard,
  '보험·대출': Icons.account_balance,
  '기타': Icons.more_horiz,
  '급여': Icons.payments,
  '용돈': Icons.savings,
  '부수입': Icons.add_card,
  '기타 수입': Icons.attach_money,
};

IconData iconFor(String category) =>
    _categoryIcons[category] ?? Icons.category;

/// 차트/아이콘에 쓰는 색 (채도를 낮춘 한 가족의 색)
const List<Color> chartColors = [
  Color(0xFFE9C42F), // 버터 옐로
  Color(0xFFB8AB92), // 토프
  Color(0xFF7FB39B), // 세이지
  Color(0xFFE59A87), // 코랄
  Color(0xFF8FA9D6), // 더스티 블루
  Color(0xFFC9A0C4), // 라일락
  Color(0xFFB5B05A), // 올리브
  Color(0xFFE0A85A), // 앰버
  Color(0xFF6FA3A0), // 틸
  Color(0xFFBF9778), // 탠
  Color(0xFF9C9C92), // 그레이
  Color(0xFF7C8FB0), // 슬레이트
  Color(0xFFD1C17A), // 샌드
];

Color categoryColor(String category) {
  final all = [...expenseCategories, ...incomeCategories];
  final i = all.indexOf(category);
  return chartColors[(i < 0 ? 0 : i) % chartColors.length];
}

/// 수입은 파랑, 지출은 잉크색(검정)으로 보여줍니다.
const Color incomeColor = Palette.income;
const Color expenseColor = Palette.ink;

/// 막대 차트에서 지출을 나타내는 색
const Color expenseBarColor = Palette.yellow;

final NumberFormat _numberFormat = NumberFormat('#,###');

String won(int value) => '${_numberFormat.format(value)}원';

/// 달력 칸처럼 좁은 곳에 쓰는 짧은 금액 (예: 9,800 / 1.2만 / 35만)
String compactWon(int v) {
  if (v >= 100000000) return '${_trim(v / 100000000)}억';
  if (v >= 100000) return '${(v / 10000).round()}만';
  if (v >= 10000) return '${_trim(v / 10000)}만';
  return _numberFormat.format(v);
}

String _trim(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String monthLabel(DateTime d) => '${d.year}년 ${d.month}월';

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

int lastDayOfMonth(int year, int month) => DateTime(year, month + 1, 0).day;
