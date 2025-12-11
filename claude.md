# dots-hyprland - Claude 개발 가이드

## 프로젝트 개요

이 저장소는 **end-4의 Hyprland dotfiles**로, Wayland 기반 타일링 컴포지터인 Hyprland를 위한 완전한 데스크톱 환경 구성입니다. "illogical-impulse" (ii)라는 이름의 현대적인 셸 환경을 **Quickshell** (QtQuick 기반 위젯 시스템)로 구현하여 Material Design 3 스타일의 데스크톱 경험을 제공합니다.

### 핵심 기술

- **윈도우 컴포지터**: Hyprland (Wayland 기반)
- **셸/UI 프레임워크**: Quickshell (QtQuick/Qt 6)
- **UI 언어**: QML (Qt Modeling Language)
- **스크립팅**: Bash, JavaScript (QML 내부)
- **테마 시스템**: Material Design 3
- **색상 생성**: 배경화면 기반 Material 색상 추출
- **AI 통합**: Gemini API, Ollama, OpenAI, Mistral

### 주요 기능

- 동적 색상 생성 (배경화면 기반)
- AI 통합 (여러 공급자 지원)
- 포괄적인 윈도우 관리
- 시스템 트레이, 빠른 설정, 알림 센터
- 애플리케이션 런처 및 오버뷰
- 미디어 컨트롤, 음량 믹서
- 블루투스, WiFi 관리
- 투두 리스트, 뽀모도로 타이머
- 화면 잠금, 세션 관리
- 드롭다운 터미널
- 클립보드 히스토리 위젯 (검색, 키보드 네비게이션)
- 여러 배포판 지원 (Arch, Gentoo, Fedora, Nix)

---

## 디렉토리 구조

```
/home/garam/.theme/dots-hyprland/
├── dots/                          # 메인 dotfiles 디렉토리
│   ├── .config/                   # 사용자 설정 파일
│   │   ├── quickshell/            # Quickshell 셸 설정 (핵심)
│   │   ├── hypr/                  # Hyprland 컴포지터 설정
│   │   ├── kde-material-you-colors/
│   │   ├── Kvantum/               # Qt 테마 설정
│   │   ├── fontconfig/            # 폰트 설정
│   │   ├── foot/                  # 터미널 에뮬레이터
│   │   ├── fuzzel/                # 애플리케이션 런처
│   │   ├── mpv/                   # 비디오 플레이어
│   │   ├── starship.toml          # 셸 프롬프트 설정
│   │   └── [기타 앱 설정]
│   └── .local/share/              # 로컬 데이터 파일
├── dots-extra/                    # 추가/선택적 설정
│   ├── emacs/
│   ├── fcitx5/                    # 입력 메서드 프레임워크
│   ├── fontsets/
│   └── via-nix/                   # Nix 패키지 매니저 지원
├── sdata/                         # 설치/설정 데이터
│   ├── dist-arch/                 # Arch Linux 패키지 목록
│   ├── dist-gentoo/               # Gentoo 패키지 목록
│   ├── dist-nix/                  # Nix flakes
│   ├── dist-fedora/               # Fedora 패키지 목록
│   ├── lib/                       # 설치 스크립트 라이브러리
│   ├── subcmd-*/                  # 설치 하위 명령
│   └── uv/                        # UV 패키지 매니저
├── .github/                       # GitHub 메타데이터 및 문서
├── licenses/                      # 라이선스 파일
├── setup                          # 메인 설치 스크립트
└── diagnose                       # 진단 유틸리티 스크립트
```

---

## Quickshell 구조 심층 분석

### 1. 최상위 구조

```
dots/.config/quickshell/ii/
├── shell.qml                    # 루트 셸 진입점
├── GlobalStates.qml             # 전역 상태 싱글톤
├── settings.qml                 # 설정 앱 윈도우
├── welcome.qml                  # 첫 실행 환영 앱
├── killDialog.qml               # 종료 대화상자
├── ReloadPopup.qml              # HMR(Hot Module Reload) 알림
├── modules/                     # 모듈 디렉토리
├── services/                    # 시스템 서비스 통합
├── scripts/                     # 시스템 통합 스크립트
├── defaults/                    # 기본 설정
├── assets/                      # 리소스 파일
└── translations/                # 국제화 지원
```

### 2. 진입점 분석 - `shell.qml`

이 파일은 Quickshell 애플리케이션의 루트 컴포넌트입니다.

**주요 역할:**
- `ShellRoot`를 메인 애플리케이션 컨테이너로 사용
- 모든 주요 모듈 임포트 (common, ii, waffle, services)
- 조건부 로딩을 위한 `PanelLoader` 컴포넌트 관리
- 두 가지 패널 패밀리 지원: "ii" (illogical-impulse)와 "waffle" (대안 테마)
- 시작 시 싱글톤 초기화 (MaterialThemeLoader, Hyprsunset, FirstRunExperience 등)

**패널 로딩 시스템:**
```qml
LazyLoader {
    active: Config.ready && Config.options.enabledPanels.includes("bar")
    Bar {} // 조건이 만족되면 로드
}
```

### 3. 전역 상태 관리 - `GlobalStates.qml`

싱글톤 컴포넌트로 전체 UI의 상태를 관리합니다.

**주요 프로퍼티:**
- **패널 가시성**: `barOpen`, `sidebarLeftOpen`, `sidebarRightOpen`
- **오버레이 상태**: `overlayOpen`, `overviewOpen`, `regionSelectorOpen`
- **입력 상태**: `superDown` (Super 키 누름), `appLauncherOpen`, `searchOpen`
- **잠금 상태**: `screenLocked`, `screenLockContainsCharacters`
- **화면 상태**: `screenZoom` (확대/축소 IPC 핸들러 포함)
- **알림 상태**: `osdBrightnessOpen`, `osdVolumeOpen`

**IPC 핸들러 예시:**
```qml
IpcHandler {
    target: "zoomin"
    onTriggered: GlobalStates.screenZoom = Math.min(GlobalStates.screenZoom + 0.1, 1.5)
}
```

### 4. 설정 시스템 - `Config.qml`

JSON 파일을 통한 영구 설정을 관리하는 싱글톤입니다.

**핵심 기능:**
- 파일 변경 감지 및 자동 리로드
- 중첩된 설정을 위한 `setNestedValue()` 함수
- 기본 설정 포함:
  - `enabledPanels`: 활성 패널 식별자 배열
  - `panelFamily`: "ii"와 "waffle" 간 전환
  - `policies`: AI 사용, weeb 모드 설정
  - `ai`: 시스템 프롬프트, 모델 선택, API 설정
  - 바 옵션: 세로 모드, 자동 숨김, 화면 필터링
  - 배경: 배경화면 경로, 썸네일 경로
  - 외관: 투명도, 둥근 모서리, 색상
  - 기타 많은 하위 설정

**설정 파일 위치:**
`~/.config/quickshell/ii/shell-config.json`

### 5. 외관/테마 - `Appearance.qml`

Material Design 3 색상을 관리하는 싱글톤입니다.

**핵심 기능:**
- `ColorQuantizer`를 사용한 배경화면 색상 추출
- 배경화면 생동감 기반 자동 투명도 계산

**주요 프로퍼티:**
- `m3colors`: Material 색상 스킴 (primary, secondary, tertiary 등)
- `animation`: 애니메이션 정의
- `rounding`: 테두리 반경 값
- `font`: 타이포그래피 설정
- `sizes`: 레이아웃 치수

**색상 생성 흐름:**
```
배경화면 이미지 → ColorQuantizer → Material Color Scheme → UI 컴포넌트
```

### 6. 모듈 구조

#### 6.1 Common 모듈 (`modules/common/`)

147개의 QML 파일로 구성된 공유 유틸리티 및 컴포넌트 라이브러리입니다.

**주요 컴포넌트:**

##### A. 코어 유틸리티
- **`Appearance.qml`**: 테마 및 색상 관리
- **`Config.qml`**: 설정 파일 처리
- **`Directories.qml`**: 파일시스템 경로
- **`Icons.qml`**: 아이콘 로딩 시스템
- **`Images.qml`**: 이미지 처리
- **`Persistent.qml`**: 영구 저장소

##### B. 함수 라이브러리 (`functions/`)
11개의 유틸리티 모듈:
- **`ColorUtils.qml`**: 색상 변환 및 조작
- **`DateUtils.qml`**: 날짜/시간 포맷팅
- **`FileUtils.qml`**: 파일 작업
- **`StringUtils.qml`**: 문자열 조작
- **`NotificationUtils.qml`**: 알림 헬퍼
- **`ObjectUtils.qml`**: 객체 조작
- **`Session.qml`**: 세션 관리
- **`Fuzzy.qml`**: 퍼지 검색
- **`Levendist.qml`**: Levenshtein 거리
- **`fuzzysort.js`**: JavaScript 퍼지 검색 라이브러리
- **`levendist.js`**: JavaScript Levenshtein 구현

##### C. 데이터 모델 (`models/`)
22개의 데이터 모델:
- **`AdaptedMaterialScheme.qml`**: Material 색상 스킴 어댑터
- **`AnimatedTabIndexPair.qml`**: 애니메이션 탭 인덱스
- **`FolderListModelWithHistory.qml`**: 히스토리가 있는 폴더 목록
- **`LauncherSearchResult.qml`**: 런처 검색 결과

##### D. 빠른 토글 모델 (`models/quickToggles/`)
17개의 시스템 빠른 설정 토글:

1. **`QuickToggleModel.qml`** (베이스 클래스)
2. **`AudioToggle.qml`** - 오디오 음소거/음소거 해제
3. **`BluetoothToggle.qml`** - 블루투스 켜기/끄기
4. **`DarkModeToggle.qml`** - 다크 모드 전환
5. **`NetworkToggle.qml`** - WiFi 켜기/끄기
6. **`NightLightToggle.qml`** - 야간 모드
7. **`MicToggle.qml`** - 마이크 음소거
8. **`GameModeToggle.qml`** - 게임 모드 (성능 최적화)
9. **`PowerProfilesToggle.qml`** - 전원 프로필 (성능/균형/절전)
10. **`IdleInhibitorToggle.qml`** - 유휴 금지
11. **`CloudflareWarpToggle.qml`** - Cloudflare WARP VPN
12. **`EasyEffectsToggle.qml`** - 오디오 효과
13. **`NotificationToggle.qml`** - 알림 방해 금지
14. **`OnScreenKeyboardToggle.qml`** - 화상 키보드
15. **`AntiFlashbangToggle.qml`** - 밝은 화면 방지
16. **`ColorPickerToggle.qml`** - 색상 선택 도구
17. **`ScreenSnipToggle.qml`** - 스크린샷 도구
18. **`MusicRecognitionToggle.qml`** - 음악 인식 (Shazam 스타일)

각 토글은 다음을 포함:
- 아이콘, 레이블, 설명
- 활성/비활성 상태
- 토글 액션
- 선택적 팝업 (상세 설정용)

##### E. 위젯 컴포넌트 (`widgets/`)
70개 이상의 재사용 가능한 UI 컴포넌트:

**입력 컴포넌트:**
- `AddressBar.qml` - URL/경로 입력
- `ButtonGroup.qml` - 버튼 그룹
- `DialogButton.qml` - 대화상자 버튼
- `FloatingActionButton.qml` - FAB 버튼
- `GroupButton.qml` - 그룹화된 버튼
- `KeyboardKey.qml` - 키보드 키 표시
- `LightDarkPreferenceButton.qml` - 테마 전환 버튼

**표시 컴포넌트:**
- `CalendarView.qml` - 달력 뷰
- `CircularProgress.qml` - 원형 진행 표시
- `MaterialLoadingIndicator.qml` - Material 로딩
- `MaterialShape.qml` - Material 모양

**설정 컴포넌트:**
- `ConfigRow.qml` - 설정 행
- `ConfigSwitch.qml` - 설정 스위치
- 기타 설정 관련 위젯

**도형 (`shapes/` 하위 모듈):**
- 둥근 다각형 모양 라이브러리

#### 6.2 ii 모듈 (`modules/ii/`)

196개의 QML 파일로 구성된 메인 "illogical-impulse" 테마입니다.

##### A. 바 (`bar/`)
27개 파일로 구성된 상태 바 구현:

**핵심 컴포넌트:**
- **`Bar.qml`** - 메인 바 컴포넌트
  - 멀티 모니터 지원 (각 화면마다 하나씩)
  - 세로/가로 모드 전환
  - 자동 숨김 기능
  - 투명도 및 블러 효과

- **`BarContent.qml`** - 바 콘텐츠 레이아웃
  - 왼쪽: 워크스페이스, 활성 창
  - 중앙: 미디어 컨트롤
  - 오른쪽: 리소스, 시스템 트레이, 시계

**주요 위젯:**
- **`Workspaces.qml`** - 워크스페이스 인디케이터
  - 활성/비활성 워크스페이스 표시
  - 워크스페이스당 창 수 표시
  - 클릭으로 전환

- **`ActiveWindow.qml`** - 활성 창 제목 표시
  - 앱 아이콘 및 제목
  - 긴 제목 자동 스크롤

- **`Media.qml`** - 미디어 플레이어 컨트롤
  - 재생/일시정지/다음/이전
  - 앨범 아트
  - 진행 바

- **`Resources.qml`** - CPU/RAM/VRAM 표시
  - 실시간 사용량 그래프
  - 클릭 시 상세 정보 팝업

- **`SysTray.qml`** - 시스템 트레이
  - StatusNotifierItem 프로토콜 지원
  - 앱별 아이콘 표시

- **`ClockWidget.qml`** - 시계 및 달력
  - 현재 시간/날짜
  - 클릭 시 달력 팝업

- **`BatteryIndicator.qml`** - 배터리 상태
  - 충전 레벨 및 아이콘
  - 남은 시간 추정

- **`HyprlandXkbIndicator.qml`** - 키보드 레이아웃
  - 현재 레이아웃 표시 (예: EN, KR)
  - 클릭으로 전환

- **`weather/`** - 날씨 위젯
  - 현재 날씨 및 온도
  - 예보

##### B. 오버뷰 (`overview/`)
6개 파일로 구성된 애플리케이션 오버뷰 화면:

- **`Overview.qml`** - 메인 컴포넌트
  - 전체 화면 오버레이
  - 열린 창 표시 (라이브 프리뷰)
  - 워크스페이스 그리드

- **`OverviewWidget.qml`** - 오버뷰 위젯
- **`OverviewWindow.qml`** - 창 표현
- **`SearchBar.qml`** - 검색 바
- **`SearchWidget.qml`** - 검색 위젯
- **`SearchItem.qml`** - 검색 결과 항목

**기능:**
- 열린 창 빠른 전환
- 워크스페이스 간 드래그 앤 드롭
- 애플리케이션 검색 (AppSearch 서비스 통합)
- 퍼지 검색으로 빠른 필터링

##### C. 앱 런처 (`appLauncher/`)

- **`AppLauncher.qml`** - 애플리케이션 런처 오버레이
  - 설치된 앱 표시
  - 퍼지 검색
  - 즐겨찾기 지원
  - 최근 사용 앱

##### D. 왼쪽 사이드바 (`sidebarLeft/`)

5개 디렉토리로 구성:
- 추가 위젯 및 정보 패널
- 사용자 정의 가능한 레이아웃

##### E. 오른쪽 사이드바 (`sidebarRight/`)

11개 디렉토리로 구성된 빠른 설정 사이드바:

**핵심 컴포넌트:**
- **`SidebarRight.qml`** - 메인 사이드바
- **`SidebarRightContent.qml`** - 콘텐츠 레이아웃
- **`QuickSliders.qml`** - 볼륨/밝기 슬라이더

**주요 섹션:**

1. **`quickToggles/`** - 빠른 토글 그리드
   - 위에서 설명한 17개 토글
   - 4열 그리드 레이아웃

2. **`bluetoothDevices/`** - 블루투스 장치 목록
   - 페어링된 장치
   - 연결/연결 해제
   - 배터리 레벨

3. **`wifiNetworks/`** - WiFi 네트워크 브라우저
   - 사용 가능한 네트워크
   - 신호 강도
   - 연결/연결 해제
   - 암호 입력

4. **`calendar/`** - 달력 위젯
   - 월별 뷰
   - 이벤트 통합 (향후)

5. **`notifications/`** - 알림 센터
   - 알림 히스토리
   - 그룹화
   - 액션 버튼
   - 모두 지우기

6. **`volumeMixer/`** - 음량 믹서
   - 앱별 음량 조절
   - 입력/출력 장치 선택
   - 음소거 제어

7. **`todo/`** - 투두 리스트
   - 작업 추가/제거
   - 완료 표시
   - 영구 저장

8. **`pomodoro/`** - 뽀모도로 타이머
   - 25분 작업 + 5분 휴식
   - 알림
   - 통계

9. **`nightLight/`** - 야간 모드 제어
   - 색온도 조절
   - 일정 설정

##### F. 기타 주요 모듈

10. **`verticalBar/`** - 대안 세로 바 레이아웃

11. **`dropdownTerminal/`** - 빠른 터미널 오버레이
    - 상단에서 드롭다운
    - 빠른 명령 실행
    - 숨김/표시 토글

12. **`dock/`** - 애플리케이션 독
    - 고정된 앱
    - 실행 중인 앱 표시
    - 드래그 앤 드롭 재정렬

13. **`cheatsheet/`** - 키보드 단축키 도움말
    - 카테고리별 단축키
    - 검색 가능

14. **`lock/`** - 화면 잠금 UI
    - 암호 입력
    - 시계 및 날짜
    - 배터리/네트워크 상태

15. **`mediaControls/`** - 미디어 컨트롤 패널
    - 전체 미디어 플레이어
    - 재생 목록 (지원 시)

16. **`notificationPopup/`** - 알림 팝업
    - 새 알림 표시
    - 자동 숨김
    - 액션 버튼

17. **`onScreenDisplay/`** - OSD (음량, 밝기)
    - 변경 시 표시
    - 진행 바

18. **`onScreenKeyboard/`** - 화상 키보드
    - 터치 입력
    - 여러 레이아웃

19. **`overlay/`** - 오버레이 컴포넌트
    - 9개 하위 디렉토리
    - 다양한 오버레이 유형

20. **`polkit/`** - 인증 대화상자
    - 관리자 권한 요청
    - 암호 입력

21. **`regionSelector/`** - 스크린샷 선택 도구
    - 영역 선택
    - 전체 화면/창 캡처

22. **`screenCorners/`** - 화면 모서리 액션
    - 핫 코너 트리거

23. **`sessionScreen/`** - 로그아웃/종료 화면
    - 로그아웃, 재시작, 종료 옵션

24. **`background/`** - 배경화면 관리
    - 배경화면 설정
    - 색상 추출

25. **`wallpaperSelector/`** - 배경화면 선택기
    - 미리보기
    - 여러 소스 (로컬, Booru 등)

26. **`clipboardWidget/`** - 클립보드 히스토리 위젯
    - 클립보드 히스토리 표시 및 검색
    - 키보드 네비게이션 지원 (위/아래 화살표)
    - 텍스트 및 이미지 클립보드 지원
    - 항목 삭제 및 전체 클리어 기능
    - Cliphist 서비스 통합

#### 6.3 Waffle 모듈 (`modules/waffle/`)

108개의 QML 파일로 구성된 대안 테마:

**주요 차이점:**
- 다른 시각적 스타일 (더 심플한 디자인)
- 다른 레이아웃
- "ii"보다 가벼움

**주요 컴포넌트:**
- **`actionCenter/`** - 알림 액션 센터
- **`background/`** - 배경화면
- **`bar/`** - 다른 바 구현
- **`notificationCenter/`** - 알림 센터
- **`onScreenDisplay/`** - OSD
- **`startMenu/`** - 시작 메뉴 스타일 런처
- **`looks/`** - 외관 설정

#### 6.4 설정 모듈 (`modules/settings/`)

8개 파일로 구성된 설정 애플리케이션 패널:

1. **`QuickConfig.qml`** - 빠른 설정
   - 자주 사용하는 옵션
   - 테마 전환

2. **`GeneralConfig.qml`** - 일반 설정
   - 시스템 전체 동작
   - 언어

3. **`BarConfig.qml`** - 바 사용자 정의
   - 위치 (상단/하단/왼쪽/오른쪽)
   - 크기
   - 표시할 위젯

4. **`BackgroundConfig.qml`** - 배경화면 설정
   - 배경화면 선택
   - 색상 추출 옵션

5. **`InterfaceConfig.qml`** - UI 사용자 정의
   - 둥근 모서리
   - 투명도
   - 애니메이션 속도

6. **`AdvancedConfig.qml`** - 고급 옵션
   - 개발자 도구
   - 디버그 모드

7. **`ServicesConfig.qml`** - 서비스 관리
   - 통합 활성화/비활성화
   - API 키 설정

8. **`About.qml`** - 정보 화면
   - 버전 정보
   - 라이선스

### 7. 서비스 시스템 (`services/`)

47개의 서비스 모듈로 구성된 시스템 통합 레이어입니다. 각 서비스는 특정 시스템 기능을 관리하는 싱글톤입니다.

#### 핵심 서비스:

1. **`Ai.qml`** - AI 통합 서비스
   - 여러 공급자 지원 (Gemini, OpenAI, Mistral, Ollama)
   - 대화 관리
   - 스트리밍 응답

2. **`AppSearch.qml`** - 애플리케이션 검색 서비스
   - 설치된 앱 인덱싱
   - 퍼지 검색
   - .desktop 파일 파싱

3. **`Audio.qml`** - 오디오/PulseAudio 관리
   - 볼륨 제어
   - 장치 열거
   - 스트림 관리

4. **`Battery.qml`** - 배터리 상태
   - 충전 레벨
   - 충전 중 여부
   - 남은 시간 추정

5. **`BluetoothStatus.qml`** - 블루투스 관리
   - 장치 검색
   - 페어링/페어링 해제
   - 연결 상태

6. **`Brightness.qml`** - 디스플레이 밝기
   - 밝기 레벨 읽기/쓰기
   - 여러 디스플레이 지원

7. **`Cliphist.qml`** - 클립보드 히스토리
   - 최근 항목
   - 검색
   - 텍스트/이미지 지원

8. **`ConflictKiller.qml`** - 충돌 감지/해결
   - 다른 바와의 충돌 감지 (예: waybar)
   - 자동 종료 옵션

9. **`DateTime.qml`** - 시간/날짜 관리
   - 현재 시간
   - 타임존
   - 포맷팅

10. **`EasyEffects.qml`** - 오디오 효과
    - 이퀄라이저
    - 프리셋 관리

11. **`Emojis.qml`** - 이모지 지원
    - 이모지 선택기
    - 검색

12. **`FirstRunExperience.qml`** - 첫 실행 설정
    - 환영 마법사
    - 초기 구성

13. **`HyprlandData.qml`** - Hyprland 워크스페이스 데이터
    - 워크스페이스 목록
    - 모니터 정보
    - 창 목록

14. **`HyprlandKeybinds.qml`** - 키바인딩 관리
    - 키바인딩 읽기
    - 동적 업데이트

15. **`HyprlandXkb.qml`** - 키보드 레이아웃
    - 현재 레이아웃
    - 레이아웃 전환

16. **`Hyprsunset.qml`** - 야간 모드/일몰
    - 색온도 조절
    - 일정 기반 전환

17. **`Idle.qml`** - 유휴 감지
    - 마지막 활동 시간
    - 유휴 콜백

18. **`KeyringStorage.qml`** - 암호/키 저장소
    - 보안 저장
    - API 키 관리

19. **`Notifications.qml`** - D-Bus 알림
    - org.freedesktop.Notifications 구현
    - 알림 히스토리
    - 액션 지원

20. **`Booru.qml`** - 이미지 소싱
    - Booru API 통합
    - 배경화면 다운로드

21. **`BooruResponseData.qml`** - Booru 응답 데이터

22. **`Wallpapers.qml`** - 배경화면 관리
    - 배경화면 설정
    - 여러 소스
    - 색상 추출 트리거

23. **`Weather.qml`** - 날씨 통합
    - 현재 날씨
    - 예보
    - 여러 공급자

24. **`Ydotool.qml`** - 입력 자동화
    - 키보드/마우스 시뮬레이션
    - Wayland 지원

25. **`Translation.qml`** - i18n/번역
    - 언어 전환
    - 번역 로딩

#### AI 하위 시스템 (`services/ai/`)

6개 파일로 구성:

- **`AiMessageData.qml`** - 메시지 데이터 모델
- **`AiModel.qml`** - AI 모델 추상화
- **`ApiStrategy.qml`** - API 전략 인터페이스
- **`GeminiApiStrategy.qml`** - Gemini 구현
- **`OpenAiApiStrategy.qml`** - OpenAI 구현
- **`MistralApiStrategy.qml`** - Mistral 구현

**아키텍처:**
```
Ai.qml (파사드)
    ↓
ApiStrategy (인터페이스)
    ↓
GeminiApiStrategy | OpenAiApiStrategy | MistralApiStrategy
    ↓
HTTP 요청 → 스트리밍 응답
```

#### 네트워크 서비스 (`services/network/`)

- **`WifiAccessPoint.qml`** - WiFi 액세스 포인트 데이터

### 8. 스크립트 시스템 (`scripts/`)

14개 디렉토리로 구성된 시스템 통합 스크립트:

1. **`ai/`** - AI 관련 스크립트
   - API 요청 래퍼
   - 프롬프트 처리

2. **`cava/`** - 오디오 비주얼라이저
   - cava 통합
   - 실시간 오디오 데이터

3. **`colors/`** - 색상/배경화면 유틸리티
   - **`code/`** - 색상 추출 코드
   - **`random/`** - 랜덤 배경화면
   - **`terminal/`** - 터미널 색상

4. **`hyprland/`** - Hyprland 특정 스크립트
   - IPC 래퍼
   - 워크스페이스 관리

5. **`images/`** - 이미지 처리
   - 썸네일 생성
   - 크기 조정

6. **`keyring/`** - 암호 관리
   - 보안 저장
   - 검색

7. **`kvantum/`** - Qt 테마 스크립트
   - 테마 생성
   - 색상 동기화

8. **`musicRecognition/`** - 음악 식별
   - Shazam 스타일 인식

9. **`thumbnails/`** - 썸네일 생성
   - 이미지 미리보기
   - 비디오 프레임

10. **`videos/`** - 비디오 처리

### 9. 데이터 흐름 및 반응성

Qt의 프로퍼티 바인딩 시스템 사용:

```
Config.qml (파일 기반 상태)
    ↓
Services (시스템 데이터)
    ↓
GlobalStates (UI 상태)
    ↓
개별 컴포넌트 (반응형 업데이트)
```

**예시: 볼륨 변경**
1. `Audio` 서비스가 D-Bus를 통해 볼륨 감지
2. `Audio.volume` 프로퍼티 업데이트
3. `QuickSliders`가 `Audio.volume` 리스닝
4. UI가 실시간으로 업데이트
5. 사용자도 슬라이더로 조절 가능, `Audio`에 다시 쓰기

### 10. 패널 시스템 및 컴포넌트 로딩

**Variants 패턴**: 멀티 모니터 지원
```qml
Variants {
    model: Quickshell.screens
    Bar {} // 각 화면마다 하나씩 생성
}
```

**지연 로딩**: `LazyLoader` 컴포넌트가 다음 조건에서만 패널 로드:
1. `Config.ready`가 true
2. 패널이 `Config.options.enabledPanels`에 포함
3. 추가 조건 충족 (예: 화면 잠금 시 바 숨김)

**패널 패밀리**: 두 가지 완전한 테마 간 전환 지원:
- **"ii" (illogical-impulse)**: 현대적이고 기능이 풍부한 메인 테마
- **"waffle"**: 대안 경량 테마
- 사이클 함수로 활성화된 패널과 패밀리 모두 변경

### 11. 설정 및 사용자 정의

**사용자 설정 진입점:**

1. **설정 앱** (`settings.qml`): GUI 기반 설정
   - 8개 설정 패널
   - 실시간 미리보기
   - 저장/리셋 기능

2. **설정 파일**: JSON 직접 편집
   - 위치: `~/.config/quickshell/ii/shell-config.json`
   - 자동 리로드
   - 유효성 검사

3. **스크립트 기반**: `scripts/` 디렉토리의 시스템 통합 스크립트
   - Bash 스크립트
   - 시스템 수준 설정

4. **IPC**: `IpcHandler` 컴포넌트로 외부 프로그램이 UI 제어
   - Hyprland 바인딩
   - 명령줄 도구

**설정 파일 구조:**
```json
{
  "enabledPanels": ["bar", "sidebarRight", "overview", ...],
  "panelFamily": "ii",
  "policies": {
    "ai": "gemini",
    "weeb": false
  },
  "ai": {
    "systemPrompt": "...",
    "model": "gemini-1.5-flash",
    "geminiApiKey": "..."
  },
  "bar": {
    "vertical": false,
    "autohide": false,
    "monitorFilter": "all"
  },
  "background": {
    "wallpaperPath": "...",
    "thumbnailPath": "..."
  },
  "appearance": {
    "transparency": 0.8,
    "rounding": 12,
    "primaryColor": "#...",
    ...
  },
  ...
}
```

### 12. 통계 요약

| 메트릭 | 개수 |
|--------|------|
| 전체 QML 파일 | 512 |
| ii 모듈 QML 파일 | 196 |
| Common 모듈 QML 파일 | 147 |
| Waffle 모듈 QML 파일 | 108 |
| 서비스 모듈 | 47 |
| 빠른 토글 모델 | 17 |
| 위젯 컴포넌트 | 70+ |
| SVG 아이콘 | 220+ |
| 스크립트 디렉토리 | 14 |
| 설정 패널 | 8 |

---

## Hyprland 설정

### 핵심 설정 파일

**위치**: `dots/.config/hypr/`

1. **`hyprland.conf`** - 메인 설정
   - 다른 설정 파일 임포트
   - 전역 변수

2. **`hyprland/keybinds.conf`** - 키보드 바인딩 (수정됨)
   - 워크스페이스 전환
   - 창 관리
   - 애플리케이션 실행
   - Quickshell 토글

3. **`hyprland/rules.conf`** - 창 규칙
   - 앱별 설정
   - 플로팅 규칙
   - 작업 공간 할당

4. **`hyprland/general.conf`** - 일반 설정
   - 간격, 테두리
   - 애니메이션
   - 장식

5. **`monitors.conf`** - 모니터/디스플레이 설정 (수정됨)
   - 해상도
   - 새로 고침 빈도
   - 위치

### Hyprland ↔ Quickshell 통합

**IPC 통신:**
- Hyprland 소켓을 통한 양방향 통신
- Quickshell이 Hyprland 상태 읽기
- Hyprland가 Quickshell 명령 트리거

**예시:**
```conf
# Hyprland 키바인드가 Quickshell IPC 호출
bind = SUPER, Space, exec, qs ipc ii appLauncherOpen toggle
bind = SUPER, Tab, exec, qs ipc ii overviewOpen toggle
```

---

## 개발 워크플로우

### 1. Quickshell 컴포넌트 수정

**단계:**
1. 관련 QML 파일 찾기 (위의 구조 참조)
2. 파일 편집
3. Quickshell이 자동으로 리로드 (HMR)
4. 변경 사항이 즉시 반영됨

**HMR (Hot Module Reload):**
- Quickshell은 QML 파일 변경 감지
- 자동 리로드
- `ReloadPopup.qml`이 알림 표시

### 2. 새 위젯 추가

**예시: 새 빠른 토글 추가**

1. `modules/common/models/quickToggles/`에 새 파일 생성:
```qml
// MyCustomToggle.qml
import QtQuick

QuickToggleModel {
    id: root
    name: "My Custom Feature"
    icon: "icon-name"
    description: "Toggles my custom feature"

    property bool isActive: false

    active: isActive

    onToggle: {
        isActive = !isActive
        // 실제 토글 로직
    }
}
```

2. `modules/ii/sidebarRight/quickToggles/`에서 사용:
```qml
MyCustomToggle {
    id: myCustomToggle
}
```

3. 설정 업데이트하여 포함

### 3. 새 서비스 추가

**예시: 날씨 서비스 (이미 존재하지만 예시로)**

1. `services/`에 새 파일 생성:
```qml
// MyService.qml
pragma Singleton
import QtQuick

QtObject {
    id: root

    property string data: ""

    function fetchData() {
        // 데이터 가져오기 로직
    }

    Component.onCompleted: {
        fetchData()
    }
}
```

2. `shell.qml`에서 임포트:
```qml
import "services" as Services

ShellRoot {
    // ...
    Component.onCompleted: {
        Services.MyService.fetchData()
    }
}
```

3. UI 컴포넌트에서 사용:
```qml
Text {
    text: Services.MyService.data
}
```

### 4. 테스트

**수동 테스트:**
1. Quickshell 재시작: `killall quickshell && quickshell`
2. 로그 확인: `journalctl --user -u quickshell -f`
3. UI 변경 확인

**디버깅:**
- `console.log()` 사용
- QML 디버거 활성화
- Quickshell 개발자 도구

### 5. Git 워크플로우

**현재 상태:**
- 브랜치: `main`
- 수정된 파일:
  - `dots/.config/hypr/hyprland/keybinds.conf`
  - `dots/.config/hypr/monitors.conf`
- 추적되지 않음: `.vscode/`

**권장 워크플로우:**
1. 기능 브랜치 생성: `git checkout -b feature/my-feature`
2. 변경 사항 커밋: `git commit -m "Add my feature"`
3. 푸시: `git push origin feature/my-feature`
4. 메인에 병합

---

## 유용한 명령어

### Quickshell

```bash
# Quickshell 시작
quickshell

# Quickshell 재시작
killall quickshell && quickshell

# IPC 명령 보내기
qs ipc <target> <action>

# 예시
qs ipc ii appLauncherOpen toggle
qs ipc ii overviewOpen toggle
qs ipc zoomin  # 확대
qs ipc zoomout # 축소
```

### Hyprland

```bash
# Hyprland 리로드
hyprctl reload

# 활성 창 정보
hyprctl activewindow

# 워크스페이스 목록
hyprctl workspaces

# 모니터 정보
hyprctl monitors

# 키바인드 목록
hyprctl binds
```

### 진단

```bash
# 진단 스크립트 실행
./diagnose

# 서비스 상태 확인
systemctl --user status quickshell

# 로그 확인
journalctl --user -u quickshell -f
```

---

## 문제 해결

### 일반적인 문제

**1. Quickshell이 시작되지 않음**
- 로그 확인: `journalctl --user -u quickshell`
- 설정 파일 유효성 검사: QML 구문 오류 확인
- 의존성 확인: Qt6, Quickshell 설치 확인

**2. 패널이 표시되지 않음**
- `Config.options.enabledPanels` 확인
- 모니터 설정 확인
- 레이어 충돌 확인 (다른 바와)

**3. AI 기능 작동 안 함**
- API 키 확인: `Config.options.ai.geminiApiKey` 등
- 네트워크 연결 확인
- 로그에서 오류 확인

**4. 색상이 업데이트되지 않음**
- 배경화면 경로 확인
- `ColorQuantizer` 로그 확인
- 수동으로 색상 추출 스크립트 실행

**5. 서비스가 응답하지 않음**
- D-Bus 연결 확인
- 서비스 활성화 확인 (예: PulseAudio, Bluetooth)
- 권한 확인

### 로그 및 디버깅

**로그 위치:**
- Quickshell: `journalctl --user -u quickshell`
- Hyprland: `~/.hyprland.log`
- 시스템: `journalctl -xe`

**디버그 모드:**
```bash
# Quickshell 디버그 출력
QT_LOGGING_RULES="*.debug=true" quickshell
```

---

## 기여 가이드라인

### 코드 스타일

**QML:**
- 들여쓰기: 4 스페이스
- 프로퍼티 순서: id, 기본 프로퍼티, 사용자 정의 프로퍼티, 신호, 함수
- 명명: camelCase

**Bash:**
- 들여쓰기: 2 스페이스
- 셸뱅: `#!/usr/bin/env bash`
- 오류 처리: `set -euo pipefail`

### 커밋 메시지

형식:
```
<type>(<scope>): <subject>

<body>

<footer>
```

타입:
- `feat`: 새 기능
- `fix`: 버그 수정
- `docs`: 문서
- `style`: 포맷팅
- `refactor`: 리팩토링
- `test`: 테스트
- `chore`: 유지보수

예시:
```
feat(bar): add weather widget

Add weather widget to the bar showing current temperature and conditions.
Integrates with Weather service.

Closes #123
```

---

## 참고 자료

### 공식 문서

- [Quickshell 문서](https://quickshell.outfoxxed.me/)
- [Hyprland 위키](https://wiki.hyprland.org/)
- [Qt QML 문서](https://doc.qt.io/qt-6/qmlapplications.html)
- [Material Design 3](https://m3.material.io/)

### 프로젝트 리소스

- [GitHub 저장소](https://github.com/end-4/dots-hyprland)
- [이슈 트래커](https://github.com/end-4/dots-hyprland/issues)
- [토론](https://github.com/end-4/dots-hyprland/discussions)

### 커뮤니티

- [Hyprland 디스코드](https://discord.gg/hyprland)
- [r/hyprland](https://reddit.com/r/hyprland)

---

## 라이선스

이 프로젝트는 GNU General Public License v3 (GPL-3.0)에 따라 라이선스가 부여됩니다.

자세한 내용은 [licenses/](licenses/) 디렉토리를 참조하세요.

---

## 추가 정보

### 최근 변경 사항

현재 작업 디렉토리 상태:
- **브랜치**: main
- **수정된 파일**:
  - [dots/.config/hypr/hyprland/keybinds.conf](dots/.config/hypr/hyprland/keybinds.conf) - 키바인딩 설정
  - [dots/.config/hypr/monitors.conf](dots/.config/hypr/monitors.conf) - 모니터 설정
- **추적되지 않음**: `.vscode/` - VSCode 설정

### 최근 커밋

```
5aa5c60a - fix orphan dropdown terminal
ed14d91e - update keys
af6e18ff - implement drop-up terminal
a60b60e7 - add python interpreter
50b46ef6 - enable lock functionality
```

### 현재 설정

**환경:**
- OS: Linux 6.17.9-arch1-1
- 플랫폼: linux
- Git 저장소: 예
- 작업 디렉토리: `/home/garam/.theme/dots-hyprland`

---

이 문서는 Claude Code에 의해 생성되었습니다. 프로젝트가 발전함에 따라 업데이트하세요.
