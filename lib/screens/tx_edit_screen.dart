import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../models.dart';
import '../repo.dart';

/// 수입/지출 추가 및 수정 화면 (tx가 null이면 새로 추가)
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
  late final TextEditingController _amount;
  late final TextEditingController _memo;
  bool _saving = false;

  List<String> get _categories => _expense ? expenseCategories : incomeCategories;

  @override
  void initState() {
    super.initState();
    final t = widget.tx;
    _expense = t?.isExpense ?? true;
    _category = t?.category ?? expenseCategories.first;
    _date = t?.date ?? widget.initialDate;
    _amount = TextEditingController(text: t == null ? '' : t.amount.toString());
    _memo = TextEditingController(text: t?.memo ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

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
    final amount = int.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      _toast('금액을 입력해 주세요.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'type': _expense ? 'expense' : 'income',
        'amount': amount,
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

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(_amount.text) ?? 0;
    final isEdit = widget.tx != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? '내역 수정' : '내역 추가')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: true,
                  label: Text('지출'),
                  icon: Icon(Icons.remove_circle_outline)),
              ButtonSegment(
                  value: false,
                  label: Text('수입'),
                  icon: Icon(Icons.add_circle_outline)),
            ],
            selected: {_expense},
            onSelectionChanged: (s) => setState(() {
              _expense = s.first;
              _category = _categories.first;
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amount,
            autofocus: !isEdit,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: '금액',
              suffixText: '원',
              helperText: amount > 0 ? won(amount) : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text('카테고리', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in _categories)
                ChoiceChip(
                  avatar: Icon(iconFor(c), size: 18),
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '날짜',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _memo,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              hintText: '예: 마트 장보기',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('저장'),
            ),
          ),
          if (isEdit && widget.tx!.authorName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${widget.tx!.authorName}님이 작성한 내역이에요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
