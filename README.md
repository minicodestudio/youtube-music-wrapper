# YouTube Music Wrapper (macOS)

Mac Chrome에서 YouTube Music 재생이 안 되는 이슈를 회피하기 위한 네이티브 macOS 래퍼 앱. Safari 엔진(`WKWebView`)으로 `music.youtube.com`을 띄우고, 미디어키 / 제어 센터 Now Playing / 메뉴바 앱 기능을 제공한다.

## 설치 (사용자용)

### 1. DMG 다운로드

[Releases](../../releases) 페이지에서 최신 `YouTubeMusicWrapper-x.y.z.dmg` 다운로드.

### 2. DMG 열고 Applications로 드래그

DMG 더블클릭 → `YouTubeMusicWrapper.app` 을 `Applications` 폴더로 드래그.

### 3. Gatekeeper 우회 (최초 1회)

이 앱은 **코드 서명이 없습니다** (개인 개발자 프로그램 미가입). 그래서 macOS가 "확인되지 않은 개발자" 경고를 띄워요. 아래 둘 중 한 가지 방법으로 우회하세요.

**방법 A — 우클릭 열기 (쉬움)**

1. Finder → Applications 폴더 → `YouTubeMusicWrapper` 우클릭 → **열기**
2. 경고창에서 다시 **열기** 클릭
3. (macOS Sonoma 이상) 시스템 설정 → 개인정보 보호 및 보안 → 보안 섹션으로 가서 "그래도 열기" 버튼 클릭

한 번만 하면 이후엔 더블클릭으로 열립니다.

**방법 B — 터미널에서 격리 속성 제거 (확실함)**

```
xattr -d com.apple.quarantine /Applications/YouTubeMusicWrapper.app
```

그 다음 일반적으로 더블클릭.

### "앱이 손상되었습니다" 에러가 뜰 때

격리(quarantine) 속성이 남아있어서 그래요. 방법 B 커맨드를 실행하면 해결됩니다.

---

## 개발자용

### 요구사항

- macOS 13.0 (Ventura) 이상
- Xcode 16.4 이상

### Xcode에서 빌드·실행

```
open YouTubeMusicWrapper.xcodeproj
```

⌘R 로 실행.

### 커맨드라인 빌드

```
xcodebuild -project YouTubeMusicWrapper.xcodeproj \
  -scheme YouTubeMusicWrapper \
  -configuration Debug build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

### 배포용 DMG 만들기

```
./scripts/build-dmg.sh
```

결과: `dist/YouTubeMusicWrapper-<version>.dmg` (ad-hoc 서명된 미공증 빌드).

## 구조

```
YouTubeMusicWrapper/
├── YouTubeMusicWrapperApp.swift   # @main, SwiftUI App
├── AppDelegate.swift              # 매니저 부트, PlaybackState
├── ContentView.swift              # WebView 담는 루트
├── WebView/
│   ├── YouTubeMusicWebView.swift  # NSViewRepresentable + WKWebView, 네비 딜리게이트
│   └── WebViewBridge.swift        # WKScriptMessageHandler (JS→Swift)
├── Playback/
│   ├── TrackInfo.swift            # 트랙 모델
│   ├── NowPlayingManager.swift    # MPNowPlayingInfoCenter
│   └── RemoteCommandManager.swift # MPRemoteCommandCenter → WebView 제어
├── MenuBar/
│   └── StatusItemController.swift # NSStatusItem + NSMenu
├── Resources/
│   └── injected.js                # DOM 감시/제어 (변경 빈도 높음)
└── Assets.xcassets                # 아이콘, 색상
```

## 핵심 흐름

1. `WKWebView`가 `music.youtube.com` 로드 (로그인 쿠키는 `WKWebsiteDataStore.default()`로 영속)
2. `injected.js`가 `<video>` 엘리먼트와 `ytmusic-player-bar` 감시, 변화를 `webkit.messageHandlers`로 Swift에 전달
3. `WebViewBridge`가 받아 `TrackInfo`로 디코드하여 `PlaybackState.currentTrack` 갱신
4. `NowPlayingManager`가 `MPNowPlayingInfoCenter`에 반영 (앨범아트는 URL 바뀔 때만 비동기 다운로드)
5. 미디어키/제어센터 입력은 `MPRemoteCommandCenter` → `evaluateJavaScript("window.__ymw.play()")` 로 페이지 제어
6. 메뉴바 `NSStatusItem`은 현재곡 + 재생 컨트롤 노출
7. 네비게이션 딜리게이트가 `youtube.com` 으로의 이탈을 잡아 `music.youtube.com` 으로 되돌림

## 알려진 제한

- **미서명 / 미공증**: 첫 실행 시 Gatekeeper 우회 필요 (위 설치 섹션).
- **YouTube Music DOM 변경 시 트랙 정보 깨질 수 있음**: 수정 지점은 `Resources/injected.js`의 `SELECTORS` 한 곳.
- **App Sandbox 미사용**.

## 의도적으로 넣지 않은 것

전역 단축키, 플러그인, 테마, 미니 플레이어 커스텀 UI, Discord/Last.fm 연동, 자동 업데이트.

## 라이선스 / 면책

비공식 개인 프로젝트. YouTube Music은 Google의 서비스이며, 이 앱은 브라우저 래퍼일 뿐 Google과 무관함.
