import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';
import '../theme.dart';

/// 수입/지출 입력 화면 (tx가 null이면 새로 추가)
///
/// 1단계: 금액을 키패드로 입력하고 [지출]/[수입] 선택
/// 2단계: 카테고리, 날짜, 메모를 정하고 저장
class TxEditScreen extends StatefulWidget {
  const TxEditScreen({
    super.key,
    required this.familyId,
    required this.userName,
    required this.initialDate,
    this.tx,
  });

  final String familyId;
  final String userName;
  final DateTime initialDate;
  final Tx? tx;

  @override
  State<TxEditScreen> createState() => _TxEditScreenState();
}

class _TxEditScreenState extends State<TxEditScreen> {
  late bool _expense;
  late String _category;
  late DateTime _date;
  late final TextEditingController _memo;
  late int _step;
  String _digits = '';
  bool _saving = false;

  int get _amount => int.tryParse(_digits) ?? 0;
  List<String> get _categories => _expense ? expenseCategories : incomeCategories;

  @override
  void initState() {
    super.initState();
    final t = widget.tx;
    _expense = t?.isExpense ?? true;
    _category = t?.category ?? expenseCategories.first;
    _date = t?.date ?? widget.initialDate;
    _digits = t == null ? '' : t.amount.toString();
    _step = t == null ? 0 : 1;
    _memo = TextEditingController(text: t?.memo ?? '');
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ───────────── 1단계: 키패드 ─────────────

  void _press(String k) {
    setState(() {
      if (k == '<') {
        if (_digits.isNotEmpty) _digits = _digits.substring(0, _digits.length - 1);
      } else if (k == '00') {
        if (_digits.isNotEmpty) _digits = '${_digits}00';
      } else if (k == '0') {
        if (_digits.isNotEmpty) _digits = '${_digits}0';
      } else {
        _digits = '$_digits$k';
      }
      if (_digits.length > 11) _digits = _digits.substring(0, 11);
    });
  }

  void _quickAdd(int v) {
    setState(() {
      final s = (_amount + v).toString();
      if (s.length <= 11) _digits = s;
    });
  }

  void _goDetails(bool expense) {
    if (_amount <= 0) {
      _toast('금액을 입력해 주세요.');
      return;
    }
    setState(() {
      if (_expense != expense) {
        _expense = expense;
        _category = _categories.first;
      }
      _step = 1;
    });
  }

  Widget _stepAmount() {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '00', '0', '<'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            _amount == 0 ? '0원' : won(_amount),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: _amount == 0 ? Palette.taupe : Palette.ink,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            children: [
              for (final v in const [1000, 10000, 100000])
                ActionChip(
                  label: Text('+${won(v).replaceAll('원', '')}'),
                  backgroundColor: Palette.taupeSoft,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => _quickAdd(v),
                ),
              ActionChip(
                label: const Text('지우기'),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Palette.line),
                shape: const StadiumBorder(),
                onPressed: () => setState(() => _digits = ''),
              ),
            ],
          ),
        ),
        const Spacer(),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            for (final k in keys)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _press(k),
                child: Center(
                  child: k == '<'
                      ? const Icon(Icons.backspace_outlined, size: 24)
                      : Text(k,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: FilledButton(
                  onPressed: () => _goDetails(true),
                  child: const Text('지출  −'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.taupe,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _goDetails(false),
                  child: const Text('수입  +'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────── 2단계: 카테고리 / 날짜 / 메모 ─────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_amount <= 0) {
      _toast('금액을 입력해 주세요.');
      setState(() => _step = 0);
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'type': _expense ? 'expense' : 'income',
        'amount': _amount,
        'category': _category,
        'memo': _memo.text.trim(),
        'date': Timestamp.fromDate(DateTime(_date.year, _date.month, _date.day)),
      };
      final existing = widget.tx;
      if (existing == null) {
        data['authorUid'] = Repo.uid;
        data['authorName'] = widget.userName;
        await Repo.addTx(widget.familyId, data);
      } else {
        await Repo.updateTx(widget.familyId, existing.id, data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('저장하지 못했어요.\n$e');
      }
    }
  }

  Widget _stepDetails() {
    final isEdit = widget.tx != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _step = 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${_expense ? '−' : '+'}${won(_amount)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: _expense ? Palette.ink : Palette.income,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.edit_outlined, size: 18, color: Palette.muted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        PillToggle(
          labels: const ['지출', '수입'],
          index: _expense ? 0 : 1,
          onChanged: (i) => setState(() {
            _expense = i == 0;
            _category = _categories.first;
          }),
        ),
        const SizedBox(height: 16),
        Panel(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Text('날짜',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date)),
              const SizedBox(width: 6),
              const Icon(Icons.calendar_today, size: 16, color: Palette.muted),
            ],
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _memo,
          decoration: fieldDecoration(label: '메모 (선택)', hint: '예: 마트 장보기'),
        ),
        const SizedBox(height: 20),
        const Text('카테고리',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
          children: [
            for (final c in _categories)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _category = c),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CategoryDot(
                      icon: iconFor(c),
                      color: categoryColor(c),
                      size: 52,
                      selected: _category == c,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            _category == c ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
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
        if (isEdit && widget.tx!.authorName.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            widget.tx!.isAuto
                ? '고정 지출에서 자동으로 들어온 내역이에요.'
                : '${widget.tx!.authorName}님이 작성한 내역이에요.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.muted, fontSize: 13),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tx != null;
    return Scaffold(
      appBar: plainAppBar(
        leading: IconButton(
          icon: Icon(_step == 1 && !isEdit ? Icons.arrow_back : Icons.close),
          onPressed: () {
            if (_step == 1 && !isEdit) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(isEdit ? '내역 수정' : '내역 추가'),
      ),
      body: SafeArea(child: _step == 0 ? _stepAmount() : _stepDetails()),
    );
  }
}
