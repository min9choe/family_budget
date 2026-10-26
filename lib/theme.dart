import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 디자인 토큰
///
/// 방향: 따뜻한 오프화이트 바탕 + 버터 옐로(행동/선택) + 토프(보조).
/// 금액 숫자는 크고 굵게, 나머지는 조용하게. 카드는 흰색에 얇은 선, 그림자 없음.
class Palette {
  static const Color bg = Color(0xFFFAFAF6);
  static const Color ink = Color(0xFF1F1E1A);
  static const Color muted = Color(0xFF8C8A80);
  static const Color line = Color(0xFFECEAE0);

  static const Color yellow = Color(0xFFF3D55B);
  static const Color yellowSoft = Color(0xFFFBF1C4);
  static const Color yellowFill = Color(0xFFF7E39A);

  static const Color taupe = Color(0xFFB8AB92);
  static const Color taupeSoft = Color(0xFFF1EEE4);

  static const Color income = Color(0xFF3F6FD8);
  static const Color danger = Color(0xFFE0503F);
  static const Color dangerFill = Color(0xFFF2B8B0);
  static const Color warnFill = Color(0xFFF5CF94);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.yellow,
      brightness: Brightness.light,
    ).copyWith(
      primary: Palette.ink,
      onPrimary: Colors.white,
      secondary: Palette.yellow,
      onSecondary: Palette.ink,
      surface: Palette.bg,
      onSurface: Palette.ink,
      onSurfaceVariant: Palette.muted,
      outline: Palette.line,
    ),
    scaffoldBackgroundColor: Palette.bg,
  );

  return base.copyWith(
    textTheme: GoogleFonts.gothicA1TextTheme(base.textTheme).apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.yellow,
        foregroundColor: Palette.ink,
        disabledBackgroundColor: Palette.taupeSoft,
        disabledForegroundColor: Palette.muted,
        minimumSize: const Size(64, 52),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
    ),
  );
}

/// 화면 위쪽 제목 줄 (배경과 같은 색, 그림자·색 번짐 없음)
AppBar plainAppBar({
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
}) =>
    AppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: Palette.bg,
      foregroundColor: Palette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    );

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

/// 입력칸 공통 모양
InputDecoration fieldDecoration({
  String? label,
  String? hint,
  String? suffix,
  String? helper,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      helperText: helper,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: _border(Palette.line),
      enabledBorder: _border(Palette.line),
      focusedBorder: _border(Palette.ink, 1.5),
    );

/// 흰색 둥근 카드 (얇은 선, 그림자 없음)
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// 배경이 비율만큼 차오르는 한 줄 (통계/예산 목록에 사용)
class FillRow extends StatelessWidget {
  const FillRow({
    super.key,
    required this.ratio,
    required this.fill,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final double ratio;
  final Color fill;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0).toDouble();
    return Material(
      color: Palette.taupeSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: r,
                  heightFactor: 1,
                  child: ColoredBox(color: fill),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// 알약 모양 선택 토글 (예: 지출 / 수입)
class PillToggle extends StatelessWidget {
  const PillToggle({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Palette.taupeSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChanged == null ? null : () => onChanged!(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? Palette.yellow : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                      color: i == index ? Palette.ink : Palette.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 카테고리 아이콘 원
class CategoryDot extends StatelessWidget {
  const CategoryDot({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
    this.selected = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? Palette.yellow : color.withAlpha(46),
        shape: BoxShape.circle,
        border: selected ? Border.all(color: Palette.ink, width: 1.5) : null,
      ),
      child: Icon(icon, size: size * 0.5, color: selected ? Palette.ink : color),
    );
  }
}
