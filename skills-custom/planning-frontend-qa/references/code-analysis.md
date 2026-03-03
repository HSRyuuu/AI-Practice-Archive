# 소스코드 오류 및 개선점 식별 가이드

코드 분석 시 테스트 케이스 생성과 함께 잠재적 오류나 개선점을 식별합니다. 이 문서는 어떤 패턴을 찾아야 하는지 상세히 설명합니다.

## 1. 미사용 변수/함수

선언되었으나 실제로 사용되지 않는 코드를 식별합니다.

### 체크 포인트

**변수:**
- 선언만 되고 읽히지 않는 변수
- import했지만 사용하지 않는 모듈
- 함수 파라미터로 받지만 사용하지 않는 값

**함수:**
- 선언되었지만 어디서도 호출되지 않는 함수
- export되지만 import하는 곳이 없는 함수

### 예시

```javascript
// ❌ 미사용 변수
const unusedVar = 10;
const result = calculate(); // unusedVar를 사용하지 않음

// ❌ 미사용 import
import { apiCall, fetchData } from './api'; // fetchData를 사용하지 않음
apiCall();

// ❌ 미사용 함수
function handleDelete() {
  // 선언되었지만 어디서도 호출되지 않음
}
```

### 보고 형식

```
[경고] 미사용 코드 발견:
- 변수 'unusedVar' (line 15): 선언되었으나 사용되지 않음
- 함수 'handleDelete' (line 42): 선언되었으나 호출되지 않음
- import 'fetchData' (line 3): import되었으나 사용되지 않음
```

## 2. 타입 오류 가능성

TypeScript 타입 불일치 및 null/undefined 처리 누락을 식별합니다.

### 체크 포인트

**타입 불일치:**
- 함수 반환 타입과 실제 반환값 불일치
- 잘못된 타입의 인자 전달
- any 타입 남용

**Null/Undefined 처리:**
- optional 값을 체크 없이 사용
- API 응답을 null 체크 없이 접근
- 배열/객체를 존재 여부 확인 없이 접근

### 예시

```typescript
// ❌ 타입 불일치
function getUser(): User {
  return null; // User 타입이어야 하는데 null 반환
}

// ❌ Null 체크 누락
const user = apiResponse.data; // apiResponse.data가 undefined일 수 있음
console.log(user.name); // 런타임 에러 가능성

// ❌ Optional 체크 누락
interface Config {
  timeout?: number;
}
const config: Config = {};
const delay = config.timeout * 1000; // undefined * 1000 = NaN

// ✅ 올바른 처리
const user = apiResponse.data;
if (user) {
  console.log(user.name);
}
```

### 보고 형식

```
[경고] 타입 오류 가능성:
- 함수 'getUser' (line 20): 반환 타입 User이지만 null을 반환할 수 있음
- 변수 'user' (line 35): null/undefined 체크 없이 user.name 접근
- 변수 'delay' (line 42): config.timeout이 undefined일 수 있음 (optional)
```

## 3. 이벤트 핸들러 누락

선언된 함수가 실제로 UI 요소에 바인딩되지 않은 경우를 식별합니다.

### 체크 포인트

**함수 선언 vs 바인딩:**
- `handleClick` 함수가 있지만 `onClick` 바인딩 없음
- `handleSubmit` 함수가 있지만 `onSubmit` 바인딩 없음
- 이벤트 핸들러 이름 규칙(`handle*`, `on*`)으로 시작하는 함수

### 예시

```jsx
// ❌ 이벤트 핸들러 바인딩 누락
function MyComponent() {
  const handleClick = () => {
    console.log('clicked');
  };

  // handleClick을 어디에도 연결하지 않음
  return <button>Click me</button>;
}

// ✅ 올바른 바인딩
function MyComponent() {
  const handleClick = () => {
    console.log('clicked');
  };

  return <button onClick={handleClick}>Click me</button>;
}
```

### 보고 형식

```
[경고] 이벤트 핸들러 바인딩 누락:
- 함수 'handleClick' (line 12): 선언되었으나 onClick 이벤트에 바인딩되지 않음
- 함수 'handleSubmit' (line 25): 선언되었으나 onSubmit 이벤트에 바인딩되지 않음
```

## 4. API 에러 핸들링 누락

try-catch 없는 비동기 호출 또는 에러 처리 누락을 식별합니다.

### 체크 포인트

**비동기 호출:**
- `await` 사용하지만 try-catch 없음
- `.then()` 사용하지만 `.catch()` 없음
- `fetch()` 호출 후 응답 상태 확인 없음

**에러 상태:**
- API 에러를 UI에 표시하지 않음
- 에러 발생 시 로딩 상태 해제 안 함

### 예시

```javascript
// ❌ try-catch 없는 async/await
async function fetchData() {
  const response = await fetch('/api/data'); // 에러 처리 없음
  const data = await response.json();
  return data;
}

// ❌ .catch() 없는 Promise
fetch('/api/data')
  .then(res => res.json())
  .then(data => setData(data)); // 에러 처리 없음

// ✅ 올바른 에러 처리
async function fetchData() {
  try {
    const response = await fetch('/api/data');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    const data = await response.json();
    return data;
  } catch (error) {
    console.error('Failed to fetch data:', error);
    showErrorMessage('데이터를 불러오는데 실패했습니다.');
    throw error;
  }
}
```

### 보고 형식

```
[경고] API 에러 핸들링 누락:
- 함수 'fetchData' (line 18): await 사용하지만 try-catch 블록이 없음
- 함수 'loadUsers' (line 35): fetch() 후 응답 상태(response.ok) 확인 없음
- Promise chain (line 52): .then() 사용하지만 .catch() 없음
```

## 5. 메모리 누수 가능성

정리되지 않는 이벤트 리스너, 타이머, 구독을 식별합니다.

### 체크 포인트

**이벤트 리스너:**
- `addEventListener` 호출하지만 `removeEventListener` 없음
- React/Vue 컴포넌트 언마운트 시 정리 코드 없음

**타이머:**
- `setInterval` / `setTimeout` 사용하지만 `clearInterval` / `clearTimeout` 없음

**구독:**
- Observable/EventEmitter 구독하지만 unsubscribe 없음
- WebSocket 연결 후 close 없음

### 예시

```javascript
// ❌ 이벤트 리스너 정리 누락 (React)
useEffect(() => {
  window.addEventListener('resize', handleResize);
  // cleanup 함수 없음 - 메모리 누수!
}, []);

// ✅ 올바른 정리
useEffect(() => {
  window.addEventListener('resize', handleResize);
  return () => {
    window.removeEventListener('resize', handleResize);
  };
}, []);

// ❌ 타이머 정리 누락 (Vue)
onMounted(() => {
  const interval = setInterval(() => {
    fetchData();
  }, 5000);
  // clearInterval 없음 - 메모리 누수!
});

// ✅ 올바른 정리 (Vue)
onMounted(() => {
  const interval = setInterval(() => {
    fetchData();
  }, 5000);

  onUnmounted(() => {
    clearInterval(interval);
  });
});
```

### 보고 형식

```
[경고] 메모리 누수 가능성:
- useEffect (line 25): addEventListener 호출하지만 cleanup 함수에서 removeEventListener 없음
- onMounted (line 42): setInterval 사용하지만 onUnmounted에서 clearInterval 없음
- 구독 (line 58): subscribe() 호출하지만 unsubscribe() 없음
```

## 6. 조건부 렌더링 오류

잘못된 조건으로 인한 UI 깨짐 가능성을 식별합니다.

### 체크 포인트

**Falsy 값 처리:**
- 숫자 0을 falsy로 처리하여 렌더링 누락
- 빈 문자열을 조건으로 사용
- `&&` 연산자 잘못 사용

**삼항 연산자:**
- 복잡한 중첩 삼항 연산자 (가독성)
- null/undefined 반환 실수

### 예시

```jsx
// ❌ 숫자 0이 화면에 표시됨
{count && <div>Count: {count}</div>}
// count가 0이면 "0"이 화면에 표시됨

// ✅ 올바른 조건
{count > 0 && <div>Count: {count}</div>}

// ❌ 빈 배열 체크 누락
{items && items.map(item => <Item key={item.id} />)}
// items가 빈 배열이면 아무것도 렌더링 안 됨 (의도한 동작인가?)

// ✅ 명확한 조건
{items.length > 0 && items.map(item => <Item key={item.id} />)}

// ❌ 복잡한 중첩 삼항 연산자
{status === 'loading'
  ? <Spinner />
  : status === 'error'
    ? <Error />
    : status === 'success'
      ? <Data />
      : null}

// ✅ 명확한 조건문 사용
{status === 'loading' && <Spinner />}
{status === 'error' && <Error />}
{status === 'success' && <Data />}
```

### 보고 형식

```
[경고] 조건부 렌더링 오류 가능성:
- JSX (line 15): count && <div> 패턴 사용 - count가 0이면 "0"이 화면에 표시됨
- JSX (line 28): 빈 배열 체크 없이 items && items.map() 사용
- JSX (line 42): 3단계 이상 중첩된 삼항 연산자 - 가독성 저하
```

## 7. 성능 이슈

불필요한 재렌더링 또는 비효율적인 코드를 식별합니다.

### 체크 포인트

**React:**
- useEffect 의존성 배열 누락 (무한 루프 가능성)
- 인라인 함수를 props로 전달 (불필요한 재렌더링)
- key prop에 index 사용 (리스트 재정렬 시)

**Vue:**
- computed 대신 method 사용 (불필요한 재계산)
- watch에서 deep: true 남용

### 예시

```jsx
// ❌ 의존성 배열 누락 (React)
useEffect(() => {
  fetchData(userId); // userId 변경 시마다 실행되어야 하는데...
}); // 의존성 배열 없음 - 매 렌더링마다 실행!

// ✅ 올바른 의존성 배열
useEffect(() => {
  fetchData(userId);
}, [userId]);

// ❌ 인라인 함수 (React)
<Button onClick={() => handleClick(id)} /> // 매 렌더링마다 새 함수 생성

// ✅ useCallback 사용
const handleButtonClick = useCallback(() => {
  handleClick(id);
}, [id]);
<Button onClick={handleButtonClick} />

// ❌ key에 index 사용 (React)
{items.map((item, index) => (
  <Item key={index} {...item} />
))}

// ✅ 고유 ID 사용
{items.map(item => (
  <Item key={item.id} {...item} />
))}
```

### 보고 형식

```
[경고] 성능 이슈 가능성:
- useEffect (line 18): 의존성 배열이 비어있음 - 무한 루프 가능성
- JSX (line 32): 인라인 함수를 onClick prop으로 전달 - 불필요한 재렌더링
- map (line 45): key prop에 배열 index 사용 - 리스트 재정렬 시 버그 가능성
```

## 보고서 출력 형식

코드 분석 완료 후 아래 형식으로 보고:

```
## 코드 품질 분석 결과

### ✅ 양호
- 전체 200줄 중 95%가 타입 안정성을 갖춤
- 모든 API 호출에 에러 핸들링 존재

### ⚠️ 개선 권장 (4건)

[경고] 미사용 코드:
- 변수 'tempData' (line 42): 선언되었으나 사용되지 않음
- 함수 'handleDelete' (line 68): 선언되었으나 호출되지 않음

[경고] 타입 오류 가능성:
- 변수 'user' (line 125): null 체크 없이 user.name 접근

[경고] 메모리 누수 가능성:
- useEffect (line 88): addEventListener 호출하지만 cleanup에서 removeEventListener 없음

### 권장 조치
1. 미사용 변수 'tempData' 제거 (line 42)
2. user?.name 또는 if (user) 체크 추가 (line 125)
3. useEffect cleanup에서 이벤트 리스너 해제 (line 88)
```

## 주의사항

- **모든 경고가 실제 오류는 아님**: 의도된 설계일 수 있으므로 "가능성"으로 표현
- **우선순위 구분**: 치명적 오류 > 성능 이슈 > 코드 품질
- **긍정적 피드백도 포함**: 잘 작성된 부분도 언급하여 균형 유지
