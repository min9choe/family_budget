# 우리집 가계부 (family_budget)

가족끼리 함께 쓰는 가계부 Android 앱입니다. Flutter + Firebase로 만들었고, GitHub Actions가 APK를 자동으로 빌드합니다.

## 기능

- **초대 코드로 가족 공유**: 한 명이 가계부를 만들고 6자리 초대 코드를 보내면, 코드를 입력한 가족만 같은 가계부에 들어올 수 있어요. 로그인/회원가입은 없습니다(익명 인증).
- **수입/지출 입력**: 금액, 카테고리, 날짜, 메모. 누가 적었는지 이름이 함께 기록돼요. 내역을 눌러 수정, 왼쪽으로 밀어 삭제.
- **월별 통계/차트**: 카테고리별 지출 원형 차트, 최근 6개월 수입·지출 막대 차트, 가족 구성원별 지출.
- **예산 설정**: 전체 예산과 카테고리별 월 예산, 사용 현황 막대(80% 주황, 초과 시 빨강).
- 가족 누군가 입력하면 모두의 화면에 실시간 반영됩니다.

## 1. Firebase 준비 (한 번만)

1. [Firebase 콘솔](https://console.firebase.google.com)에서 프로젝트 생성
2. **Authentication → 로그인 방법 → 익명** 사용 설정
3. **Firestore Database → 데이터베이스 만들기** (위치: `asia-northeast3 (서울)` 권장, 프로덕션 모드)
4. Firestore **규칙** 탭에 이 저장소의 `firestore.rules` 내용을 붙여넣고 **게시**
5. **프로젝트 설정 → 내 앱 → Android 앱 추가**
   - Android 패키지 이름: `com.family.family_budget`
   - 앱을 등록하고 나온 `google-services.json`을 열어 아래 값을 확인합니다. (파일 자체는 저장소에 올리지 않아도 됩니다)

| GitHub Secret 이름 | google-services.json에서 찾을 값 |
|---|---|
| `FIREBASE_API_KEY` | `client[0].api_key[0].current_key` |
| `FIREBASE_APP_ID` | `client[0].client_info.mobilesdk_app_id` |
| `FIREBASE_SENDER_ID` | `project_info.project_number` |
| `FIREBASE_PROJECT_ID` | `project_info.project_id` |
| `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` (없으면 빈 값으로 두어도 됨) |

## 2. GitHub에서 APK 빌드

1. 이 폴더를 GitHub 저장소(`main` 브랜치)에 올립니다.
2. 저장소 **Settings → Secrets and variables → Actions**에 위 5개 Secret을 등록합니다.
3. `main`에 push하면 자동으로 빌드됩니다. (Actions 탭에서 **Build APK → Run workflow**로 직접 실행도 가능)
4. 빌드가 끝나면 실행 결과 화면 아래 **Artifacts → family-budget-apk**에서 `app-release.apk`를 내려받습니다.

> `android/` 폴더는 저장소에 두지 않고 워크플로가 매번 `flutter create`로 만들어요. 패키지 이름은 `com.family.family_budget`로 고정되므로 Firebase에 등록한 이름과 같아야 합니다.

## 3. 가족에게 배포

1. APK 파일을 카카오톡 등으로 가족에게 보냅니다.
2. 설치할 때 "출처를 알 수 없는 앱" 허용이 필요합니다.
3. 첫 번째 사람이 **새 가계부 만들기** → 상단 **가족(👥) 아이콘**에서 초대 코드 확인 → 가족에게 전달
4. 나머지 가족은 **초대 코드로 입장**에서 코드를 입력

## 참고 / 주의

- 익명 인증이라 **앱을 지우고 다시 설치하면 새 사용자**로 인식됩니다. 이때는 초대 코드로 다시 입장하면 돼요(내역은 그대로 남아 있음).
- 기기를 바꿔도 같은 방식으로 초대 코드를 입력하면 됩니다.
- 예산은 매달 같은 금액이 적용됩니다.
- 로컬에서 실행하려면:
  ```
  flutter create . --platforms=android --org com.family --project-name family_budget
  flutter run \
    --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
    --dart-define=FIREBASE_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
    --dart-define=FIREBASE_STORAGE_BUCKET=...
  ```
  (로컬 빌드는 `android/app/src/main/AndroidManifest.xml`에 INTERNET 권한 추가가 필요할 수 있어요. 워크플로의 "Patch Android settings" 단계 참고)

## 데이터 구조

```
users/{uid}                       { name, familyId }
invites/{code}                    { familyId }
families/{fid}                    { name, inviteCode, members[], budgets{} }
families/{fid}/transactions/{id}  { type, amount, category, memo, date, authorUid, authorName }
```
