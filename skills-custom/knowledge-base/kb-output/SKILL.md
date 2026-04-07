---
name: kb-output
description: |
  Knowledge Base 출력 변환 스킬.
  위키 지식을 슬라이드, 차트, 캔버스 등 다양한 형태로 변환하여 저장한다.
  트리거: "/kb-output --slides 주제", "/kb-output --chart 주제", "/kb-output --canvas 주제"
---

# KB 출력 변환

이 스킬은 Knowledge Base의 지식을 다양한 출력 형식으로 변환한다.

## Step 0. 볼트 경로 확인 + 스키마 읽기

1. `~/.config/kb/config.json`을 읽어 `kb_root` 경로를 확인한다.
2. 파일이 없거나 `kb_root`가 없으면 사용자에게 볼트 경로를 물어본 뒤 `~/.config/kb/config.json`에 저장한다.
3. `{kb_root}/CLAUDE.md`를 읽고 slug 규칙, 태그 컨벤션, 커밋 메시지 형식을 확인한다.
4. CLAUDE.md가 없으면 에러: **"CLAUDE.md가 없습니다. `/kb-setup`을 먼저 실행하세요."**

## 공통 규칙

- **slug 생성**: CLAUDE.md §5 규칙을 따른다 (kebab-case, 최대 60자, 한글 허용).
- **git 커밋**: 모든 출력 생성 후 `kb: output '{제목}' as {format}` 형식으로 커밋한다.
- **log 기록**: `wiki/log.md`에 아래 형식으로 append한다:
  ```
  ## [YYYY-MM-DD] output | {제목} ({format})
  - 형식: {slides|chart|canvas}
  - 저장 경로: {파일 경로}
  - 관련 문서: [[concepts/{slug}]]
  ```

---

## Format 1: `--slides` (Marp 슬라이드)

Marp 형식의 마크다운 슬라이드 덱을 생성한다.

### 저장 경로

```
wiki/concepts/{slug}-slides.md
```

### 슬라이드 구성

1. **타이틀 슬라이드**
   - 제목, 날짜, scope 태그 표시

2. **개념 슬라이드** (주제당 1장)
   - 슬라이드당 **최대 5개 bullet point**
   - 핵심 키워드는 **굵게** 표시
   - 관련 wiki 문서가 있으면 각주에 위키링크 표기

3. **코드 슬라이드** (해당 시)
   - 코드 예제가 있으면 별도 슬라이드로 분리
   - 언어별 syntax highlighting 지정
   - 코드 블록은 슬라이드당 20줄 이내

4. **요약 슬라이드**
   - 전체 내용을 3-5개 핵심 포인트로 정리
   - 추가 학습을 위한 관련 concept 위키링크 나열

5. **출처 슬라이드**
   - 참조한 wiki/sources/ 문서를 위키링크로 나열
   - 원본 URL이 있으면 함께 표기

### Marp 템플릿

```markdown
---
marp: true
theme: default
paginate: true
tags: [{scope_tags}]
type: overview
created_at: {ISO 8601 UTC}
---

# {제목}

**{날짜}** | {scope_tags}

---

## {개념 1 제목}

- bullet point 1
- bullet point 2
- **핵심 키워드** 설명
- bullet point 4
- bullet point 5

---

## 코드 예시

```{language}
# 코드 블록
```

---

## 요약

1. 핵심 포인트 1
2. 핵심 포인트 2
3. 핵심 포인트 3

---

## 출처

- [[sources/{slug-a}]] — {제목}
- [[sources/{slug-b}]] — {제목}
```

### 수행 절차

1. 주제와 관련된 wiki 문서를 검색한다 (`wiki/index.md` → 서브 인덱스 → concepts/ 탐색).
2. 관련 문서의 내용을 읽고 슬라이드 구조를 설계한다.
3. Marp 형식 마크다운을 생성하여 `wiki/concepts/{slug}-slides.md`에 저장한다.
4. `wiki/index.md`에 슬라이드 항목을 추가한다.
5. git 커밋 + log 기록.

---

## Format 2: `--chart` (matplotlib 차트)

Python matplotlib 스크립트를 생성하고 실행하여 PNG 차트를 저장한다.

### 저장 경로

```
raw/assets/{slug}-chart.png       # 생성된 PNG 이미지
raw/assets/{slug}-chart.py        # 생성에 사용된 Python 스크립트
```

### 차트 타입 자동 선택

위키 데이터의 성격에 따라 최적 차트 타입을 자동 판단한다:

| 데이터 성격 | 차트 타입 | 사용 예 |
|---|---|---|
| 개념 간 관계/연결 | **network graph** (`networkx` + `matplotlib`) | 기술 스택 관계도, 개념 의존성 |
| 시간순 이벤트/변화 | **timeline** (수평 막대 또는 scatter) | 기술 발전사, 프로젝트 마일스톤 |
| 수치 비교 | **bar chart** (수평/수직) | 성능 벤치마크, 기능 비교 |
| 비율/구성 | **pie chart** (또는 donut) | 카테고리별 분포, 기술 점유율 |

### Python 스크립트 규칙

- `matplotlib`, `networkx` (network graph인 경우) 사용
- 한글 폰트 설정 포함: `plt.rcParams['font.family'] = 'AppleGothic'` (macOS)
- DPI 150 이상, figsize 적절히 설정
- 범례와 제목 포함
- `plt.tight_layout()` 적용
- 볼트 루트에서 실행: `plt.savefig('raw/assets/{slug}-chart.png', dpi=150, bbox_inches='tight')`

### 수행 절차

1. 주제와 관련된 wiki 문서를 검색하여 데이터를 수집한다.
2. 데이터 성격을 분석하여 차트 타입을 자동 선택한다 (사용자가 명시하면 그에 따른다).
3. Python 스크립트를 생성하여 `raw/assets/{slug}-chart.py`에 저장한다.
4. 스크립트를 실행하여 PNG를 생성한다:
   ```bash
   cd 
   python raw/assets/{slug}-chart.py
   ```
5. PNG가 정상 생성되었는지 확인한다.
6. 관련 concept 문서가 있으면 `![[{slug}-chart.png]]` 임베드를 추가한다.
7. git 커밋 + log 기록.

---

## Format 3: `--canvas` (Obsidian JSON Canvas)

Obsidian JSON Canvas 형식으로 개념 맵을 생성한다.

### 저장 경로

```
wiki/concepts/{slug}.canvas
```

### 캔버스 구성 규칙

#### 노드 (Nodes)

- 각 관련 concept 문서를 **file 노드**로 배치한다.
- 독립 개념(concept 문서가 없는 것)은 **text 노드**로 생성한다.
- 노드 크기: width 250, height 60 (기본값, 내용에 따라 조정).

#### 엣지 (Edges)

- wiki 문서 간 위키링크(`[[...]]`)가 있으면 해당 노드 간에 엣지를 생성한다.
- 엣지 label에 관계 설명을 간략히 표기한다 (예: "사용", "확장", "비교").

#### 색상 (scope 태그 기반)

| scope 태그 | 색상 코드 |
|---|---|
| `mobigen` | `"1"` (빨강 계열) |
| `personal` | `"4"` (초록 계열) |
| 양쪽 모두 | `"6"` (보라 계열) |
| 태그 없음 | 색상 미지정 (기본값) |

> Obsidian canvas color 값은 `"1"`~`"6"` 문자열 또는 hex 코드를 사용한다.

### JSON Canvas 템플릿

```json
{
  "nodes": [
    {
      "id": "node-1",
      "type": "file",
      "file": "wiki/concepts/{slug-a}.md",
      "x": 0,
      "y": 0,
      "width": 250,
      "height": 60,
      "color": "1"
    },
    {
      "id": "node-2",
      "type": "text",
      "text": "{개념 이름}",
      "x": 300,
      "y": 0,
      "width": 250,
      "height": 60,
      "color": "4"
    }
  ],
  "edges": [
    {
      "id": "edge-1",
      "fromNode": "node-1",
      "fromSide": "right",
      "toNode": "node-2",
      "toSide": "left",
      "label": "관계 설명"
    }
  ]
}
```

### 레이아웃 규칙

- 중심 노드(주제)를 캔버스 중앙 `(0, 0)`에 배치한다.
- 관련 노드를 방사형으로 배치한다 (간격 x: 350, y: 150).
- 노드가 10개 이상이면 그리드 배치로 전환한다 (4열 기준).
- 노드 간 겹침이 없도록 좌표를 조정한다.

### 수행 절차

1. 주제와 관련된 wiki 문서를 검색한다.
2. 각 문서의 frontmatter에서 scope 태그를 확인한다.
3. 문서 간 위키링크를 분석하여 엣지 관계를 파악한다.
4. JSON Canvas 구조를 생성하여 `wiki/concepts/{slug}.canvas`에 저장한다.
5. `wiki/index.md`에 캔버스 항목을 추가한다.
6. git 커밋 + log 기록.

---

## 오류 처리

| 상황 | 대응 |
|---|---|
| 관련 wiki 문서가 없음 | 사용자에게 안내: "'{주제}'에 대한 wiki 문서가 없습니다. 먼저 kb-ingest로 소스를 추가하세요." |
| matplotlib 미설치 | `pip install matplotlib` 안내 (networkx 필요 시 함께 안내) |
| 차트 생성 실패 | 스크립트 오류를 분석하고 수정 후 재실행. 3회 실패 시 스크립트만 저장하고 사용자에게 안내 |
| 캔버스 노드 50개 초과 | 사용자에게 범위 축소를 제안: "노드가 {N}개입니다. 특정 태그나 하위 주제로 범위를 좁힐까요?" |
