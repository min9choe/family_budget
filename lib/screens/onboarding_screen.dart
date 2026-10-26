import 'package:flutter/material.dart';

import '../repo.dart';
import '../theme.dart';

/// 처음 실행했을 때: 새 가계부 만들기 / 초대 코드로 입장
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialName = ''});

  final String initialName;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _create = true;
  bool _busy = false;

  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  final TextEditingController _family =
      TextEditingController(text: '우리집 가계부');
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _family.dispose();
    _code.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast('내 이름(별명)을 입력해 주세요.');
      return;
    }
    if (!_create && _code.text.trim().isEmpty) {
      _toast('초대 코드를 입력해 주세요.');
      return;
    }

    setState(() => _busy = true);
    try {
      if (_create) {
        final fam = _family.text.trim();
        await Repo.createFamily(
          familyName: fam.isEmpty ? '우리집 가계부' : fam,
          userName: name,
        );
      } else {
        await Repo.joinFamily(code: _code.text, userName: name);
      }
      // 성공하면 사용자 문서가 바뀌면서 홈 화면으로 자동 전환됩니다.
    } catch (e) {
      if (mounted) _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: Palette.yellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          size: 38),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '우리집 가계부',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '가족이 함께 쓰고 함께 보는 가계부',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Palette.muted),
                  ),
                  const SizedBox(height: 28),
                  PillToggle(
                    labels: const ['새 가계부 만들기', '초대 코드로 입장'],
                    index: _create ? 0 : 1,
                    onChanged: _busy ? null : (i) => setState(() => _create = i == 0),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _name,
                    decoration: fieldDecoration(
                      label: '내 이름 (가족에게 보이는 이름)',
                      hint: '예: 아빠, 엄마, 첫째',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_create)
                    TextField(
                      controller: _family,
                      decoration: fieldDecoration(label: '가계부 이름'),
                    )
                  else
                    TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: fieldDecoration(
                        label: '초대 코드 (6자리)',
                        hint: '가족에게 받은 코드를 입력하세요',
                      ),
                    ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_create ? '가계부 만들기' : '입장하기'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _create
                        ? '만들고 나면 초대 코드가 생겨요. 가족에게 코드를 알려주면 같은 가계부를 함께 쓸 수 있어요.'
                        : '코드를 알고 있는 가족만 들어올 수 있어요.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Palette.muted, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
