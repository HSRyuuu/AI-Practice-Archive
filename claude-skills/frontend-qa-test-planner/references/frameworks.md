# 프레임워크별 특화 분석 가이드

이 문서는 각 프레임워크별 특화된 분석 요소를 제공합니다. SKILL.md의 기본 워크플로우를 보완하는 심화 가이드입니다.

## React / Next.js

### 주요 분석 포인트

**Hooks 동작:**
- `useState`: 상태 변화에 따른 리렌더링 검증
- `useEffect`: 의존성 배열 변경 시 사이드 이펙트 검증
- `useCallback` / `useMemo`: 성능 최적화가 의도대로 작동하는지 검증
- `useRef`: DOM 참조 및 값 유지 검증

**이벤트 핸들러:**
- 합성 이벤트(SyntheticEvent) 처리
- 이벤트 버블링/캡처링
- `e.preventDefault()`, `e.stopPropagation()` 동작

**조건부 렌더링:**
- `{condition && <Component />}`
- `{condition ? <A /> : <B />}`
- null/undefined 반환 시 렌더링 방지

**리스트 렌더링:**
- `key` prop 변경 시 컴포넌트 재생성 검증
- 동적 리스트 추가/삭제/정렬 시 렌더링 검증

### 테스트 케이스 예시

```csv
분류,점검 항목,테스트 데이터,기대 결과
상태변경 (ONCHANGE),useState로 관리되는 입력값 변경 확인,텍스트 입력,입력값이 실시간으로 상태에 반영되고 UI가 갱신된다.
사이드이펙트 (USEEFFECT),useEffect 의존성 변경 시 재실행 확인,의존성 값 변경,useEffect 내부 로직이 재실행된다.
조건부렌더링 (CONDITIONAL),조건에 따른 컴포넌트 표시/숨김 확인,조건값 true/false 변경,해당 컴포넌트가 DOM에 추가/제거된다.
```

## Vue / Nuxt

### 주요 분석 포인트

**Reactivity System:**
- `ref()`, `reactive()`: 반응형 데이터 변경 시 자동 렌더링
- `computed()`: 의존성 변경 시 자동 재계산
- `watch()` / `watchEffect()`: 감시 대상 변경 시 콜백 실행

**Lifecycle Hooks:**
- `onMounted()`: 컴포넌트 마운트 시 초기화 로직
- `onUnmounted()`: 컴포넌트 언마운트 시 정리 로직
- `onBeforeUpdate()` / `onUpdated()`: 업데이트 전후 동작

**Directives:**
- `v-if` / `v-show`: 조건부 렌더링 검증
- `v-for`: 리스트 렌더링 및 key 관리
- `v-model`: 양방향 바인딩 검증
- `v-on` (@): 이벤트 핸들러 바인딩

**Composables:**
- 재사용 가능한 로직의 상태 관리
- 여러 컴포넌트에서 공유되는 상태 검증

### 테스트 케이스 예시

```csv
분류,점검 항목,테스트 데이터,기대 결과
반응형데이터 (ONCHANGE),ref 데이터 변경 시 UI 자동 갱신 확인,반응형 변수 수정,변경된 값이 즉시 UI에 반영된다.
계산속성 (COMPUTED),computed 의존성 변경 시 자동 재계산 확인,의존성 값 변경,computed 값이 재계산되고 UI가 갱신된다.
양방향바인딩 (V-MODEL),v-model 입력 시 데이터 동기화 확인,input 필드에 텍스트 입력,입력값이 바인딩된 변수에 즉시 반영된다.
감시자 (WATCH),watch 대상 변경 시 콜백 실행 확인,watch 대상 값 변경,watch 콜백이 실행되고 의도한 사이드 이펙트가 발생한다.
```

## Angular

### 주요 분석 포인트

**Component Lifecycle:**
- `ngOnInit()`: 컴포넌트 초기화
- `ngOnChanges()`: Input 프로퍼티 변경 감지
- `ngOnDestroy()`: 구독 해제 및 정리

**RxJS Observables:**
- `subscribe()`: 구독 시작 및 데이터 수신
- `pipe()`: 연산자 체이닝 (map, filter, switchMap 등)
- `unsubscribe()`: 메모리 누수 방지

**Dependency Injection:**
- Service 주입 및 메서드 호출
- Provider 범위에 따른 인스턴스 공유

**Two-way Binding:**
- `[(ngModel)]`: 양방향 바인딩 검증
- FormControl / FormGroup: 폼 상태 관리

### 테스트 케이스 예시

```csv
분류,점검 항목,테스트 데이터,기대 결과
초기화 (NGONINIT),ngOnInit에서 데이터 로드 확인,컴포넌트 초기화,초기 데이터가 로드되고 UI에 표시된다.
입력변경 (NGONCHANGES),Input 프로퍼티 변경 시 ngOnChanges 실행 확인,부모에서 Input 값 변경,ngOnChanges가 호출되고 새 값으로 UI가 갱신된다.
구독 (RXJS),Observable 구독 시 데이터 수신 확인,Observable emit,subscribe 콜백이 실행되고 데이터가 처리된다.
양방향바인딩 (NGMODEL),ngModel 입력 시 모델 동기화 확인,input 필드 입력,입력값이 즉시 컴포넌트 프로퍼티에 반영된다.
```

## Svelte / SvelteKit

### 주요 분석 포인트

**Reactive Declarations:**
- `$:`: 반응형 구문 (의존성 변경 시 자동 재실행)
- `$$props`: 모든 props 접근

**Stores:**
- `writable()`, `readable()`, `derived()`: 스토어 상태 변경 시 구독자 갱신
- `$store`: 자동 구독 및 해제

**Transitions & Animations:**
- `transition:`, `in:`, `out:`: 요소 추가/제거 시 애니메이션
- `animate:`: 리스트 재정렬 시 애니메이션

**Event Handling:**
- `on:event`: 이벤트 핸들러
- `on:event|modifier`: 이벤트 수정자 (preventDefault, stopPropagation 등)

### 테스트 케이스 예시

```csv
분류,점검 항목,테스트 데이터,기대 결과
반응형구문 (REACTIVE),반응형 구문 의존성 변경 시 재실행 확인,의존 변수 변경,$: 구문이 자동으로 재실행되고 값이 갱신된다.
스토어 (STORE),writable 스토어 업데이트 시 구독자 갱신 확인,store.set() 호출,구독 중인 모든 컴포넌트가 새 값으로 갱신된다.
트랜지션 (TRANSITION),요소 추가 시 트랜지션 애니메이션 확인,조건부 렌더링 true,요소가 트랜지션 효과와 함께 나타난다.
```

## Vanilla JavaScript / TypeScript

### 주요 분석 포인트

**DOM Manipulation:**
- `document.querySelector()`: 요소 선택
- `addEventListener()`: 이벤트 리스너 등록
- `removeEventListener()`: 이벤트 리스너 해제 (메모리 누수 방지)

**Async Operations:**
- `fetch()`: API 호출
- `async/await`: 비동기 처리
- Promise chaining: `.then()`, `.catch()`

**Event Delegation:**
- 부모 요소에서 하위 요소 이벤트 처리
- `event.target` 확인

### 테스트 케이스 예시

```csv
분류,점검 항목,테스트 데이터,기대 결과
DOM조작 (ONCLICK),클릭 이벤트로 DOM 변경 확인,버튼 클릭,대상 요소의 클래스/스타일/내용이 변경된다.
비동기호출 (FETCH),fetch API 호출 및 응답 처리 확인,API 엔드포인트 호출,응답 데이터가 파싱되고 UI에 표시된다.
이벤트위임 (EVENT),부모 요소에서 동적 자식 이벤트 처리 확인,동적 생성된 버튼 클릭,이벤트가 올바르게 캡처되고 처리된다.
```

## 프레임워크 공통 패턴

모든 프레임워크에서 공통적으로 검증해야 할 항목:

1. **초기 렌더링**: 컴포넌트가 처음 마운트될 때 올바른 초기 상태 표시
2. **사용자 입력**: 폼 필드, 버튼, 선택 요소 등의 상호작용
3. **비동기 데이터 로딩**: API 호출 중 로딩 상태, 성공/실패 처리
4. **조건부 렌더링**: 상태에 따른 UI 변화
5. **리스트 렌더링**: 동적 데이터 표시 및 업데이트
6. **에러 핸들링**: 예외 상황에서의 UI 피드백
7. **메모리 정리**: 이벤트 리스너, 타이머, 구독 해제
