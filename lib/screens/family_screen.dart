import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repo.dart';
import '../theme.dart';

/// 가족 정보: 초대 코드 확인/복사, 가계부에서 나가기
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({
    super.key,
    required this.familyId,
    required this.familyName,
    required this.inviteCode,
    required this.memberCount,
    required this.userName,
  });

  final String familyId;
  final String familyName;
  final String inviteCode;
  final int memberCount;
  final String userName;

  Future<void> _leave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('가계부에서 나갈까요?'),
        content: const Text(
            '나가도 가계부 내역은 남은 가족이 계속 볼 수 있어요.\n다시 들어오려면 초대 코드가 필요해요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('나가기')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Repo.leaveFamily(familyId);
      if (context.mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('나가지 못했어요.\n$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: plainAppBar(title: const Text('우리 가족')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Panel(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Palette.yellowSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.home_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(familyName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 17)),
                      const SizedBox(height: 2),
                      Text('구성원 $memberCount명 · 나: $userName',
                          style: const TextStyle(
                              color: Palette.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('가족 초대 코드',
                    style: TextStyle(color: Palette.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        inviteCode,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 44),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: inviteCode));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('초대 코드를 복사했어요.')));
                        }
                      },
                      child: const Text('복사'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '가족이 앱을 설치한 뒤 [초대 코드로 입장]에서 이 코드를 입력하면 같은 가계부를 함께 쓸 수 있어요. 코드는 가족에게만 알려주세요.',
                  style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.danger,
              side: const BorderSide(color: Palette.line),
              minimumSize: const Size(64, 50),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('이 가계부에서 나가기'),
            onPressed: () => _leave(context),
          ),
        ],
      ),
    );
  }
}
