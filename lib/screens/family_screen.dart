import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../repo.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('우리 가족')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: Text(familyName),
              subtitle: Text('구성원 $memberCount명 · 나: $userName'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('가족 초대 코드',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          inviteCode,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.copy),
                        label: const Text('복사'),
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: inviteCode));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('초대 코드를 복사했어요.')));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '가족이 앱을 설치한 뒤 [초대 코드로 입장]에서 이 코드를 입력하면 같은 가계부를 함께 쓸 수 있어요. 코드는 가족에게만 알려주세요.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
            icon: const Icon(Icons.logout),
            label: const Text('이 가계부에서 나가기'),
            onPressed: () => _leave(context),
          ),
        ],
      ),
    );
  }
}
