---
name: learning-algorithm-helper
description: Java 알고리즘/자료구조 학습 도우미. (1) 알고리즘/자료구조 주제별 문제 제시, (2) 프로그래머스/백준 웹 링크를 받으면 해당 문제 텍스트 생성, (3) 문제 풀이를 위한 Java 클래스 파일 자동 생성 (Javadoc 헤더 + QUESTION 상수 + main 메서드 + solution 스캐폴딩). 사용자가 알고리즘 문제를 풀고 싶다고 하거나, 문제 링크를 공유하거나, 특정 알고리즘/자료구조를 연습하고 싶다고 할 때 사용.
---

# Learning Algorithm

Java 백엔드 개발자를 위한 알고리즘/자료구조 학습 스킬.

## Workflow

### Mode 1: 주제별 문제 제시

사용자가 알고리즘/자료구조 주제를 말하면:

1. 해당 주제에 적합한 문제를 추천 (프로그래머스 또는 백준)
2. 난이도, 문제명, 링크 제공
3. Mode 3으로 이어서 클래스 파일 생성

### Mode 2: 웹에서 복사해온 내용을 기반으로 클래스 생성성

사용자가 단순 텍스트 또는 임시로 작성한 markdown 문서를 지정하면 

1. 텍스트 또는 markdown을 통해 문제 추출출
2. Mode 3으로 이어서 클래스 파일 생성

### Mode 3: Java 클래스 파일 생성

추출/제시된 문제 정보로 풀이용 클래스 파일을 생성한다.

**파일 위치 결정:**
- 프로그래머스: `src/Algorithm/{알고리즘}/Lv{레벨}_{알고리즘}_{문제번호}.java`
- 백준: `src/Algorithm/{알고리즘}/{Tier}_{알고리즘}_No{문제번호}.java`

**클래스 파일 템플릿:**

```java
package Algorithm.{알고리즘};

import java.io.*;
import java.util.*;

/**
 * @문제명: {문제 이름}
 * @Tear: {Lv2 / Silver 1 / Gold 5}
 * @Algorithm: {Queue, BFS, Hash 등}
 * @Link: {문제 URL}
 */
public class {클래스명} {

    static String QUESTION = """
            {문제 설명 전문}

            [제한사항]
            {제한사항}

            [입출력 예]
            {입출력 예시}
            """;

    public static void main(String[] args) throws IOException {
        // 테스트 케이스
        // System.out.println("result: " + solution(...)); // 기대값
    }

    static {리턴타입} solution({파라미터}) {
        return {기본값};
    }
}
```

**핵심 규칙:**
- `static String QUESTION`은 반드시 클래스 선언과 main 메서드 사이에 위치
- text block(`"""`)을 사용하여 가독성 확보
- main에 예제 테스트 케이스를 주석과 함께 미리 작성
- solution 메서드는 빈 껍데기로 생성 (사용자가 직접 구현)
- 프로그래머스는 `solution` 메서드 시그니처를 문제 원본과 동일하게 맞춤
- 백준은 `main`에서 `BufferedReader`/`StringTokenizer`로 입력을 모두 파싱한 뒤, `solution` 메서드에 인자로 전달하는 구조를 사용
- 백준도 반드시 `static {리턴타입} solution({파라미터})` 메서드를 별도로 생성하고, `main`에서 호출

**백준 문제 템플릿 (stdin 입력 → solution 호출 방식):**

```java
package Algorithm.{알고리즘};

import java.io.*;
import java.util.*;

/**
 * @문제명: {문제 이름}
 * @Tear: {Silver 1 / Gold 5}
 * @Algorithm: {BFS, DP 등}
 * @Link: {문제 URL}
 */
public class {클래스명} {

    static String QUESTION = """
            {문제 설명 전문}

            [입력]
            {입력 형식}

            [출력]
            {출력 형식}

            [예제 입력]
            {예제}

            [예제 출력]
            {예제}
            """;

    public static void main(String[] args) throws IOException {
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        StringTokenizer st;

        // 입력 파싱 (문제에 맞게 변수 생성)
        st = new StringTokenizer(br.readLine());
        {타입} {변수1} = {파싱}; // e.g. int n = Integer.parseInt(st.nextToken());
        {타입} {변수2} = {파싱}; // e.g. int m = Integer.parseInt(st.nextToken());

        // 배열/리스트 입력이 있으면 여기서 파싱
        // e.g. int[] arr = new int[n];
        // for (int i = 0; i < n; i++) { ... }

        // solution 호출 및 출력
        System.out.println(solution({변수1}, {변수2} /*, ... */));
    }

    static {리턴타입} solution({파라미터}) {
        return {기본값};
    }
}
```

**백준 템플릿 핵심 규칙:**
- `main`은 오직 **입력 파싱**과 **solution 호출 + 출력**만 담당
- 모든 풀이 로직은 `solution` 메서드 안에 작성
- 문제의 입력 형식을 분석하여 `main`에서 적절한 변수로 파싱하고 `solution`의 파라미터로 전달
- `solution`의 리턴타입은 문제의 출력 형식에 맞춤 (int, long, String 등)
- 출력이 여러 줄인 경우 `StringBuilder`를 리턴하거나, `solution` 내에서 직접 출력도 허용 (이 경우 리턴타입 `void`)

## 알고리즘 디렉터리 매핑

| 알고리즘 | 디렉터리명 |
|----------|-----------|
| Hash | `Hash` |
| Stack, Queue | `StackQueue` |
| Dynamic Programming | `DP` |
| BFS, DFS | `bfs` |
| Greedy | `Greedy` |
| Binary Search | `BinarySearch` |
| Sort | `Sort` |
| Brute Force | `BruteForce` |
| Two Pointer | `TwoPointer` |
| Graph | `Graph` |

새 알고리즘 디렉터리가 필요하면 `src/Algorithm/` 아래에 생성한다.
