import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'repo.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 시작 중 문제가 생기면 흰 화면 대신 원인을 화면에 보여줍니다.
  String? problem;
  final o = DefaultFirebaseOptions.currentPlatform;
  final missing = <String>[
    if (o.apiKey.isEmpty) 'FIREBASE_API_KEY',
    if (o.appId.isEmpty) 'FIREBASE_APP_ID',
    if (o.messagingSenderId.isEmpty) 'FIREBASE_SENDER_ID',
    if (o.projectId.isEmpty) 'FIREBASE_PROJECT_ID',
  ];
  if (missing.isNotEmpty) {
    problem = '다음 GitHub Secrets 값이 비어 있어요:\n${missing.join('\n')}\n\n'
        'Secrets를 등록(또는 수정)한 뒤 Build APK를 다시 실행해 주세요.';
  } else {
    try {
      await initializeDateFormatting('ko_KR');
      await Firebase.initializeApp(options: o);
    } catch (e) {
      problem = 'Firebase 연결에 실패했어요.\n\n$e';
    }
  }

  if (problem != null) {
    runApp(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: SelectableText(problem)),
          ),
        ),
      ),
    ));
    return;
  }
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '우리집 가계부',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

/// 익명 로그인 -> 내 가족이 있으면 홈, 없으면 가족 만들기/입장 화면
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<User> _signIn;

  @override
  void initState() {
    super.initState();
    _signIn = _ensureUser();
  }

  Future<User> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final current = auth.currentUser;
    if (current != null) return current;
    return (await auth.signInAnonymously()).user!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _signIn,
      builder: (context, signIn) {
        if (signIn.hasError) {
          return _MessageView(
            message: '로그인에 실패했어요.\n인터넷 연결과 Firebase 설정을 확인해 주세요.\n\n${signIn.error}',
            onRetry: () => setState(() => _signIn = _ensureUser()),
          );
        }
        if (!signIn.hasData) return const _LoadingView();

        final uid = signIn.data!.uid;
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: Repo.user(uid).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _MessageView(message: '정보를 불러오지 못했어요.\n\n${snap.error}');
            }
            if (!snap.hasData) return const _LoadingView();

            final data = snap.data!.data();
            final familyId = data?['familyId'] as String?;
            final name = (data?['name'] as String?) ?? '';
            if (familyId == null) {
              return OnboardingScreen(initialName: name);
            }
            return HomeScreen(
              key: ValueKey(familyId),
              familyId: familyId,
              userName: name,
            );
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
