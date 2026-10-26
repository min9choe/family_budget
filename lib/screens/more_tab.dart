import 'package:flutter/material.dart';

import '../theme.dart';
import 'family_screen.dart';
import 'fixed_screen.dart';

/// 더보기: 고정 지출 관리, 가족/초대 코드
class MoreTab extends StatelessWidget {
  const MoreTab({
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

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => page)),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Palette.yellowSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Palette.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Palette.muted, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Palette.muted),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        _tile(
          context,
          icon: Icons.event_repeat,
          title: '고정 지출',
          subtitle: '매달 같은 날 나가는 보험료, 대출이자 등을 자동으로 넣어요',
          page: FixedScreen(familyId: familyId),
        ),
        _tile(
          context,
          icon: Icons.group_outlined,
          title: '우리 가족',
          subtitle: '초대 코드 확인 · 구성원 $memberCount명',
          page: FamilyScreen(
            familyId: familyId,
            familyName: familyName,
            inviteCode: inviteCode,
            memberCount: memberCount,
            userName: userName,
          ),
        ),
      ],
    );
  }
}
