# DopaDip Design

iOS **Clock 앱(Timer 탭)** 의 비주얼 언어를 그대로 따른다. 다크 전용, 순black 캔버스,
얇은 거대 숫자, 휠 피커, 원형 액션 버튼, floating 탭바.

핵심 한 줄: **"조용한 타이머."** 앱 자체가 집중을 방해하지 않게, 크롬은 사라지고 시간이 말한다.

## Color (dark only)

| Token | Hex | 용도 |
|---|---|---|
| `canvas` | `#000000` | 모든 화면 배경(순black, OLED) |
| `surfaceRaised` | `#1C1C1E` | 그룹 카드·휠 선택 pill·보조(그레이) 버튼·separator 면 |
| `surfaceRaisedHigh` | `#2C2C2E` | 상단 원형 칩(Edit/＋/✕) |
| `textPrimary` | `#FFFFFF` | 제목·히어로 숫자·행 타이틀 |
| `textSecondary` | `#8E8E93` | 2차 라벨·행 값·캡션 |
| `textTertiary` | `#48484A` | 휠 비선택 숫자·disabled |
| `accentBrand` | `#FF9F0A` | **브랜드 오렌지** — 탭 선택, 집중 진행 링, 핵심 값, 확인 체크 |
| `actionStart` | `#34C759` | **그린** — "집중 시작" go 액션, 토글 ON |
| `separator` | `rgba(255,255,255,0.10)` | 행 hairline |
| `ringTrack` | `rgba(255,255,255,0.12)` | active 프로그레스 링 트랙 |

규칙: 액센트는 **셋만** — 오렌지(브랜드/선택/진행), 그린(시작/ON), 그레이(취소/보조). 다른 색 금지.

## Typography (SF Pro)

| Token | Size / Weight | 비고 |
|---|---|---|
| `largeTitle` | 34 Bold | 화면 라지타이틀("집중", "설정") |
| `heroNumeral` | ~80 Light, **monospacedDigit** | 카운트다운/남은시간. 얇은 게 핵심, 숫자 폭 고정해 깜빡임 방지 |
| `sectionHeader` | 20 Bold | 그룹 섹션 헤더 |
| `rowTitle` | 17 Regular | 리스트 행 타이틀 |
| `rowValue` | 17 Regular / `textSecondary` | 행 우측 값 |
| `caption` | 13 Regular / `textSecondary` | 보조 설명·"집중 중" 라벨 |
| `buttonLabel` | 17 Semibold | 원형 버튼 라벨 |
| `tabLabel` | 10 Medium | 탭바 라벨 |

Dynamic Type 지원, 단 `heroNumeral`은 상한 둠(레이아웃 보호).

## Shape · Spacing · Motion

- 스페이싱 8pt 베이스: 4 / 8 / 12 / 16 / 24 / 32.
- 그룹 카드 radius **14**, 원형 액션 버튼 지름 **76pt**.
- **그림자 없음**(Clock처럼 flat). 입체감은 surface 색 단차(`#1C1C1E` on `#000000`)로만.
- 버튼 press = `scale(0.95)`.

## Components

- **CircularActionButton** — 지름 76, 필. `Start`=`actionStart` 필+white 라벨, `Stop/포기`=`surfaceRaised` 필+white 라벨. press scale 0.95.
- **FocusRing** (Home active) — 원형 stroke. 트랙 `ringTrack`, 진행 `accentBrand`(오렌지), lineWidth ~10, 끝 라운드. 중앙에 `heroNumeral` 남은시간.
- **DurationWheel** (Home idle) — `UIDatePicker(.countDownTimer)` UIViewRepresentable. 시:분, 중앙 선택은 시스템 다크 pill. 하한 1분·상한 60분은 앱 로직 검증(시작 버튼 비활성).
- **GroupedCard / Row** (Settings) — `surfaceRaised` 카드 radius 14, 행 높이 ~52, 타이틀 white + 우측 값/chevron/토글(ON=그린), inset separator.
- **FloatingTabBar** — Home / Settings 2탭. 선택 `accentBrand`(아이콘+라벨), 비선택 `textSecondary`.

## Screens

- **PermissionGate** — black, 라지타이틀 + 1줄 설명 + 그린 캡슐/원형 "권한 허용". Screen Time 미승인 시 전체 게이트.
- **Home idle** — 라지타이틀 → `DurationWheel` → 차단 앱 선택 행(탭 시 FamilyActivityPicker 시트) → 하단 그린 원형 "집중 시작"(앱 미선택/길이 미달 시 비활성).
- **Home active** — `FocusRing` + 중앙 남은시간 `heroNumeral`, 하단 그레이 원형 "포기".
- **Settings** — GroupedCard: Screen Time 권한(상태/해제), 앱 정보. 얇게.
- **Shield**(ShieldConfiguration ext) — black, `heroNumeral`로 "남은 N분" + `caption` "집중 중". 미니멀. (시스템 ShieldConfiguration 제약 내에서 근사 — 완전 커스텀 뷰는 불가, 텍스트/색/아이콘만.)

## Do / Don't

- **Do** 순black 캔버스. 액센트 3색만. 히어로 숫자는 얇게+monospacedDigit. 입체는 surface 단차로. press scale 0.95.
- **Don't** 라이트 모드 추가(MVP). 그림자. 4번째 액센트 색. 그린을 시작/ON 외에 쓰기. 오렌지를 본문 텍스트에 쓰기.

## Known constraint

- **ShieldConfiguration는 완전 자유 뷰가 아님** — 시스템이 정한 레이아웃(아이콘·타이틀·서브타이틀·버튼) 안에서 텍스트/색만 커스텀. 위 Shield 스펙은 그 제약 안에서의 근사치다.
