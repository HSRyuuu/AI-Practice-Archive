### <주의> 이 claude skill 세팅 시 이 README.md 파일은 제외하고 업로드해야합니다.

# Frontend QA Test Planner

Frontend 소스 코드를 분석하여 QA 테스트 항목을 CSV 형식으로 자동 생성하는 Claude Skill입니다.

## 📋 개요

| 항목 | 내용 |
|------|------|
| **스킬명** | `frontend-qa-test-planner` |
| **지원 프레임워크** | Vue, React, Angular, Svelte, Vanilla JS/TS |
| **출력 형식** | CSV (Excel, Google Sheets에 바로 붙여넣기 가능) |

## 🚀 사용 상황

- **기능 개발 완료 후**: 어떤 부분을 테스트해야 할지 리스트업이 필요할 때
- **QA 준비 단계**: 실제 구현된 로직 기반으로 테스트 케이스를 설계할 때
- **코드 리뷰 시**: 변경된 코드의 영향도를 파악하고 테스트 범위를 확정할 때

---

## 💻 사용 방법

### 기본 사용

```bash
/frontend-qa-test-planner @[/path/to/file.vue]
```

### 테스트 상세도 옵션

| 옵션 | 범위 | 예상 항목 수* |
|------|------|---------------|
| `--simple` (기본) | 핵심 기능만 | 10-30개 |
| `--detailed` | + 예외 케이스, 상태 관리 | 30-60개 |
| `--max` | + UI/UX 세부사항, 접근성 | 50개 이상 |

*페이지 복잡도에 따라 달라짐. 실제 테스트 가능한 항목 수만큼만 생성.

**예시:**
```bash
# 기본 (핵심만)
/frontend-qa-test-planner @[/pages/dashboard.vue]

# 상세
/frontend-qa-test-planner --detailed @[/pages/dashboard.vue]

# 최대
/frontend-qa-test-planner --max @[/pages/dashboard.vue]
```

### 다중 파일 분석

```bash
/frontend-qa-test-planner @[파일1.vue] @[파일2.tsx] @[파일3.svelte]
```

---

## 🖥️ Claude CLI 없이 사용하기

1. `SKILL.md` 파일 내용을 복사
2. Claude에게 다음과 같이 입력:
   > "다음은 내가 사용할 스킬 정의야. `/frontend-qa-test-planner` 명령을 내리면 이 규칙에 따라 동작해줘"
3. 분석할 파일 내용과 함께 명령어 입력

---

## 📊 출력 예시

CSV 형식으로 출력되어 Excel/Google Sheets에 바로 붙여넣기 가능합니다:

```csv
분류,점검 항목,테스트 데이터,기대 결과
초기화면 (ONLOADED),초기 검색 조건 기본값 설정 확인,페이지 진입,"시작일은 7일 전, 종료일은 오늘로 설정된다."
버튼클릭 (ONCLICK),검색 버튼 클릭 시 조회 동작 확인,검색 버튼 클릭,입력된 조건으로 데이터가 조회된다.
유효성검사 (VALIDATION),필수값 미입력 시 검증 확인,빈 값으로 저장 시도,오류 메시지가 표시된다.
```

---

## 📁 스킬 구조

```
frontend-qa-test-planner/
├── SKILL.md                    # 메인 스킬 정의 (Claude에 업로드)
├── references/
│   ├── frameworks.md           # 프레임워크별 분석 가이드
│   ├── output-guide.md         # CSV 작성 상세 원칙
│   └── code-analysis.md        # 코드 품질 분석 가이드
└── assets/
    └── template.csv            # CSV 출력 템플릿
```

### 참조 파일 설명

| 파일 | 설명 |
|------|------|
| `references/frameworks.md` | React, Vue, Angular, Svelte별 특화 분석 포인트 |
| `references/output-guide.md` | CSV 컬럼 작성 원칙 및 상세도별 예시 |
| `references/code-analysis.md` | 미사용 코드, 타입 오류, 메모리 누수 등 식별 가이드 |
| `assets/template.csv` | CSV 출력 형식 템플릿 |

---

## 🔍 주요 기능

### 1. 코드 분석
- 지정된 파일 및 **로컬 import 재귀 추적**
- 하위 컴포넌트, Composables/Hooks, Utils, Types 자동 읽기

### 2. 테스트 케이스 생성
- 4개 컬럼 CSV: `분류`, `점검 항목`, `테스트 데이터`, `기대 결과`
- 상세도 옵션에 따라 범위 조절

### 3. 코드 품질 분석 (선택)
- 미사용 변수/함수
- 타입 오류 가능성
- API 에러 핸들링 누락
- 메모리 누수 가능성

---

## 💡 활용 팁

- **파일 경로 필수**: 자동 파일 탐색은 수행하지 않습니다. 반드시 경로를 명시하세요.
- **디렉터리 지정**: 특정 디렉터리 전체를 분석하려면 디렉터리 경로를 지정하세요.
- **결과 활용**: 생성된 CSV를 QA 시트에 붙여넣어 즉시 활용하세요.
