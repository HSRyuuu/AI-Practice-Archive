# Frontend QA Test Planner

프론트엔드 소스 코드를 분석하여 QA 테스트 항목을 자동으로 생성하는 Claude Skill입니다.

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

### Claude CLI 사용 시

1. IDE에서 분석할 파일의 **전체 경로 복사** (Copy Path)
2. Claude CLI에 명령어 입력:

```bash
/frontend-qa-test-planner /Users/username/project/frontend/pages/index.vue
```

### 테스트 상세도 선택

```bash
# 필수항목만 (기본값)
/frontend-qa-test-planner @[파일경로]

# 상세하게 (예외 케이스, 에러 처리 포함)
/frontend-qa-test-planner --detailed @[파일경로]

# 가능한 모든 것 (UI/UX, 엣지케이스, 접근성 등)
/frontend-qa-test-planner --max @[파일경로]
```

> **참고**: 테스트 항목 개수는 페이지 복잡도에 따라 달라집니다 (간단한 페이지 10개 미만 ~ 복잡한 페이지 80개 이상)

### 다중 파일 분석

```bash
/frontend-qa-test-planner @[pages/index.vue] @[components/Grid.vue]
```

---

## 🖥️ Claude CLI 없이 사용하기

1. `skill.md` 파일 내용을 복사
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

## 💡 활용 팁

- **파일 경로 필수**: 자동 파일 탐색은 수행하지 않습니다. 반드시 경로를 명시하세요.
- **디렉터리 지정**: 특정 디렉터리 전체를 분석하려면 디렉터리 경로를 지정하세요.
- **결과 활용**: 생성된 CSV를 QA 시트에 붙여넣어 즉시 활용하세요.
