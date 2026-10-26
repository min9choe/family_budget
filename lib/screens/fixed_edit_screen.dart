import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';

/// 고정 지출(또는 고정 수입) 항목 추가/수정 (item이 null이면 새로 추가)
class FixedEditScreen extends StatefulWidget {
  const FixedEditScreen({super.key, required this.familyId, this.item});

  final String familyId;
  final FixedItem? item;

  @override
  State<FixedEditScreen> createState() => _FixedEditScreenState();
}

class _FixedEditScreenState extends State<FixedEditScreen> {
  late bool _expense;
  late String _category;
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _day;

  /// 새 항목이고 이번 달 결제일이 이미 지났을 때: 이번 달 분도 지금 내역에 넣을지
  bool _includeThisMonth = true;
  bool _saving = false;

  List<String> get _categories => _expense ? expenseCategories : incomeCategories;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _expense = it?.isExpense ?? true;
    _category = it?.category ?? '보험·대출';
    _name = TextEditingController(text: it?.name ?? '');
    _amount = TextEditingController(text: it == null ? '' : it.amount.toString());
    _day = TextEditingController(text: it == null ? '' : it.day.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _day.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  int get _dayValue => int.tryParse(_day.text) ?? 0;

  /// 이번 달 결제일이 이미 지났는가
  bool get _thisMonthPassed {
    final d = _dayValue;
    if (d < 1 || d > 31) return false;
    final now = DateTime.now();
    final end = lastDayOfMonth(now.year, now.month);
    return (d > end ? end : d) <= now.day;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final amount = int.tryParse(_amount.text) ?? 0;
    final day = _dayValue;
    if (name.isEmpty) {
      _toast('항목 이름을 입력해 주세요. (예: 보험료)');
      return;
    }
    if (amount <= 0) {
      _toast('금액을 입력해 주세요.');
      return;
    }
    if (day < 1 || day > 31) {
      _toast('결제일은 1~31 사이로 입력해 주세요.');
      return;
    }

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'name': name,
        'amount': amount,
        'day': day,
        'category': _category,
        'type': _expense ? 'expense' : 'income',
      };
      final existing = widget.item;
      if (existing == null) {
        // lastApplied: 이 달 이전까지는 이미 처리된 것으로 본다.
        // 이번 달 결제일이 지났고 "이번 달은 넣지 않기"를 고르면 이번 달까지 처리된 것으로 표시.
        final now = DateTime.now();
        final skipThisMonth = _thisMonthPassed && !_includeThisMonth;
        final base = skipThisMonth
            ? DateTime(now.year, now.month, 1)
            : DateTime(now.year, now.month - 1, 1);
        data['lastApplied'] = Repo.monthKey(base);
        await Repo.addFixed(widget.familyId, data);
      } else {
        await Repo.updateFixed(widget.familyId, existing.id, data);
      }
      Repo.applyFixed(widget.familyId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('저장하지 못했어요.\n$e');
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('고정 항목 삭제'),
        content: const Text('앞으로는 자동으로 들어가지 않아요.\n이미 들어간 내역은 그대로 남아요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('삭제')),
        ],
      ),
    );
    if (ok != true) return;
    await Repo.deleteFixed(widget.familyId, widget.item!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;
    return Scaffold(
      appBar: plainAppBar(
        title: Text(isEdit ? '고정 항목 수정' : '고정 항목 추가'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '삭제',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          PillToggle(
            labels: const ['지출', '수입'],
            index: _expense ? 0 : 1,
            onChanged: (i) => setState(() {
              _expense = i == 0;
              _category = _expense ? '보험·대출' : incomeCategories.first;
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: fieldDecoration(label: '항목 이름', hint: '예: 보험료, 대출이자'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: fieldDecoration(label: '금액', suffix: '원'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _day,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: fieldDecoration(
              label: '매월 며칠',
              suffix: '일',
              helper: '31일처럼 없는 날이 있는 달에는 그 달 말일에 들어가요.',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          const Text('카테고리',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  avatar: Icon(iconFor(c), size: 18),
                  label: Text(c),
                  selected: _category == c,
                  showCheckmark: false,
                  selectedColor: Palette.yellow,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Palette.line),
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          if (!isEdit && _thisMonthPassed) ...[
            const SizedBox(height: 20),
            Panel(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('이번 달 분도 지금 넣기',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('이번 달 결제일이 이미 지났어요. 이미 직접 적었다면 꺼 주세요.',
                            style: TextStyle(
                                color: Palette.muted, fontSize: 12, height: 1.4)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _includeThisMonth,
                    onChanged: (v) => setState(() => _includeThisMonth = v),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }
}
