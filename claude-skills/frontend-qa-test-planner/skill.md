---
name: frontend-qa-test-planner
description: >
  Frontend 소스 코드(Vue, React, Angular, Svelte)를 분석하여 QA 테스트 케이스를 CSV 형식으로 자동 생성합니다.
  다음 상황에서 사용:
  (1) QA 테스트 항목이 필요할 때
  (2) 프론트엔드 컴포넌트 검증 시나리오가 필요할 때
  (3) 코드 변경 후 회귀 테스트 체크리스트가 필요할 때
  (4) 사용자가 "QA", "테스트 케이스", "테스트 항목", "검증" 등의 키워드와 함께 프론트엔드 파일을 언급할 때
---

# Frontend QA Test Planner

Frontend 소스 코드를 분석하여 실제 QA 환경에서 즉시 사용 가능한 테스트 항목 체크리스트를 CSV 형식으로 생성합니다.

## 사용법

### 기본 형식

```
/frontend-qa-test-planner @[파일경로]
```

### 테스트 상세도 옵션

| 옵션 | 범위 | 예상 항목 수* |
|------|------|---------------|
| `--simple` (기본) | 핵심 기능만 | 10-30개 |
| `--detailed` | + 예외 케이스, 상태 관리 | 30-60개 |
| `--max` | + UI/UX 세부사항, 접근성 | 50개 이상 |

*페이지 복잡도에 따라 달라짐. 실제 테스트 가능한 항목 수만큼만 생성.

**예시:**
```
# 기본 (핵심만)
/frontend-qa-test-planner @[/pages/dashboard.vue]

# 상세
/frontend-qa-test-planner --detailed @[/pages/dashboard.vue]

# 최대
/frontend-qa-test-planner --max @[/pages/dashboard.vue]
```

### 다중 파일

```
/frontend-qa-test-planner @[파일1.vue] @[파일2.tsx] @[파일3.svelte]
```

## 분석 프로세스

### 1. 파일 지정 확인

파일이 지정되지 않은 경우 사용자에게 요청:

```
분석할 파일 또는 디렉터리를 지정해주세요.

예시:
- 단일 파일: /frontend-qa-test-planner @[/pages/menu-log/index.vue]
- 디렉터리: /frontend-qa-test-planner @[/pages/]
- 다중 파일: /frontend-qa-test-planner @[파일1.vue] @[파일2.vue]
```

### 2. 코드 분석

**주요 파일 읽기:**
- 지정된 컴포넌트 파일 읽기

**참조 파일 자동 읽기:**
- 모든 로컬 import 재귀적으로 추적 (`~`, `@`, `./`, `../`)
- 하위 컴포넌트, Hooks/Composables, Utils, Types, State Management, API Clients 포함

**프레임워크별 특화 분석:**
- 각 프레임워크별 상세 분석 가이드는 **[references/frameworks.md](references/frameworks.md)** 참조
- React: Hooks, 이벤트 핸들러, 조건부 렌더링
- Vue: Reactivity, Lifecycle, Directives, Composables
- Angular: Lifecycle, RxJS, Dependency Injection
- Svelte: Reactive declarations, Stores, Transitions

### 3. 테스트 케이스 생성

**출력 형식:** CSV (4개 컬럼)

```csv
분류,점검 항목,테스트 데이터,기대 결과
```

**작성 원칙:**
- 상세 작성 가이드: **[references/output-guide.md](references/output-guide.md)** 참조
- 템플릿: **[assets/template.csv](assets/template.csv)** 참조

**간단 요약:**
- **분류**: 기능/이벤트명 (이벤트타입) - 예: `초기화면 (ONLOADED)`, `버튼클릭 (ONCLICK)`
- **점검 항목**: "~~ 확인" 형태 - 예: "초기 검색 조건 기본값 설정 확인"
- **테스트 데이터**: 즉시 실행 가능한 값 - 예: "시작일: 7일 전, 종료일: 오늘"
- **기대 결과**: 관찰 가능한 UI/상태 변화 - 예: "그리드 데이터가 갱신된다"

**다중 파일 출력:**
```csv
## 페이지 1: /pages/dashboard.vue
분류,점검 항목,테스트 데이터,기대 결과
...

## 페이지 2: /pages/profile.vue
분류,점검 항목,테스트 데이터,기대 결과
...
```

### 4. 코드 품질 분석 (선택)

코드 분석 중 발견된 잠재적 오류도 보고:

- 상세 분석 가이드: **[references/code-analysis.md](references/code-analysis.md)** 참조

**주요 체크 항목:**
- 미사용 변수/함수
- 타입 오류 가능성 (null/undefined 처리 누락)
- 이벤트 핸들러 누락
- API 에러 핸들링 누락
- 메모리 누수 가능성 (이벤트 리스너, 타이머, 구독)
- 조건부 렌더링 오류
- 성능 이슈 (불필요한 재렌더링)

**보고 형식:**
```
## 코드 품질 분석 결과

### ⚠️ 개선 권장 (3건)
[경고] 타입 오류 가능성:
- 변수 'user' (line 125): null 체크 없이 user.name 접근

[경고] 메모리 누수 가능성:
- useEffect (line 88): addEventListener 호출하지만 cleanup 없음
...
```

## 예시 출력

```csv
분류,점검 항목,테스트 데이터,기대 결과
초기화면 (ONLOADED),초기 검색 조건 기본값 설정 확인,페이지 진입,"시작일은 10년 전, 종료일은 오늘로 설정된다."
초기화면 (ONLOADED),초기 데이터 조회 수행 확인,페이지 진입,기본 검색 조건으로 그리드 데이터가 로드된다.
버튼클릭 (ONCLICK),검색 버튼 클릭 시 조회 동작 확인,검색 버튼 클릭,입력된 조건으로 데이터가 조회되고 그리드가 갱신된다.
엔터키 (ONKEYPRESS),검색어 입력 후 엔터키 입력 시 조회 동작 확인,검색어 입력 + Enter 키,검색 버튼 클릭과 동일하게 조회가 수행된다.
유효성검사 (VALIDATION),날짜 범위 7일 초과 시 검증 확인,"시작일: 2026-01-01, 종료일: 2026-01-15","경고 메시지 ""조회 기간은 최대 7일입니다"" 표시 및 조회 차단"
페이지네이션 (ONCHANGE),페이지 번호 클릭 시 목록 갱신 확인,2페이지 클릭,해당 페이지의 데이터로 그리드가 갱신된다.
정렬 (ONCLICK),컬럼 헤더 클릭 시 정렬 동작 확인,날짜 컬럼 헤더 클릭,날짜 기준 오름차순/내림차순 정렬이 적용된다.
에러처리 (ONERROR),API 호출 실패 시 처리 확인,네트워크 오류 발생,사용자에게 오류 메시지가 표시되고 로딩 상태가 해제된다.
엣지케이스 (EDGE),조회 결과 0건인 경우 확인,존재하지 않는 조건으로 검색,"""조회된 데이터가 없습니다"" 메시지가 그리드에 표시된다."
```

## Reference Files

상세 가이드는 아래 파일들을 참조:

- **[references/frameworks.md](references/frameworks.md)**: 프레임워크별 특화 분석 가이드 (React, Vue, Angular, Svelte)
- **[references/output-guide.md](references/output-guide.md)**: CSV 작성 원칙 및 상세 예시
- **[references/code-analysis.md](references/code-analysis.md)**: 소스코드 오류 식별 가이드
- **[assets/template.csv](assets/template.csv)**: CSV 템플릿
