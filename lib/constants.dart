import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  '기타': Icons.more_horiz,
  '급여': Icons.payments,
  '용돈': Icons.savings,
  '부수입': Icons.add_card,
  '기타 수입': Icons.attach_money,
};

IconData iconFor(String category) =>
    _categoryIcons[category] ?? Icons.category;

const List<Color> chartColors = [
  Color(0xFF4E79A7),
  Color(0xFFF28E2B),
  Color(0xFF59A14F),
  Color(0xFFE15759),
  Color(0xFF76B7B2),
  Color(0xFFEDC948),
  Color(0xFFB07AA1),
  Color(0xFFFF9DA7),
  Color(0xFF9C755F),
  Color(0xFFBAB0AC),
  Color(0xFF86BCB6),
  Color(0xFF8CD17D),
];

Color categoryColor(String category) {
  final all = [...expenseCategories, ...incomeCategories];
  final i = all.indexOf(category);
  return chartColors[(i < 0 ? 0 : i) % chartColors.length];
}

const Color incomeColor = Color(0xFF2E7D32);
const Color expenseColor = Color(0xFFC62828);

final NumberFormat _numberFormat = NumberFormat('#,###');

String won(int value) => '${_numberFormat.format(value)}원';

String monthLabel(DateTime d) => '${d.year}년 ${d.month}월';

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;
