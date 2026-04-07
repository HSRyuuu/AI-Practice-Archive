---
name: kb-ingest
description: |
  소스를 KB에 추가하고 즉시 wiki를 업데이트한다.
  트리거: "/kb-ingest {소스}", "이거 KB에 넣어줘", "이 문서 정리해줘"
---

# kb-ingest

소스를 추가하고, 핵심 내용을 논의한 뒤, wiki 전체를 한 번에 업데이트한다.

> **원칙**: Ingest 즉시 wiki 업데이트. 별도 compile 단계 없음.

---

## 워크플로우

### 핵심 (반드시 완료)

#### Step 0. 볼트 경로 확인 + 스키마 로드

1. `~/.config/kb/config.json`을 읽어 `kb_root` 경로를 확인한다.
2. 파일이 없거나 `kb_root`가 없으면 사용자에게 볼트 경로를 물어본 뒤 `~/.config/kb/config.json`에 저장한다.
3. `{kb_root}/CLAUDE.md`를 읽고 핵심 태그, slug 규칙, frontmatter 컨벤션, 문서 타입을 로드한다.
4. CLAUDE.md가 없으면 에러: **"CLAUDE.md가 없습니다. `/kb-setup`을 먼저 실행하세요."**

#### Step 1. 소스 감지 + Raw 저장

**1-1. 입력 타입 감지**

| 입력 패턴 | type | 처리 |
|---|---|---|
| `http(s)://...` | `web` | fetch → 마크다운 변환 → 정제 |
| `*.pdf` | `pdf` | 텍스트 추출 + PDF 원본 보관 |
| `*.png\|jpg\|gif\|webp\|...` | `image` | LLM이 이미지 읽고 설명 생성 |
| 그 외 텍스트/파일 | `note` | 텍스트 그대로 또는 파일 읽기 |

**텍스트+이미지 혼합 문서**: 2단계 처리를 적용한다.
1. 텍스트를 먼저 읽고 전체 맥락을 파악한다.
2. 참조된 이미지를 개별로 읽고 설명을 생성하여 본문에 통합한다.

**1-2. 핵심 태그(scope) 판단**

- 내용을 분석하여 `mobigen` / `personal` / 둘 다 중 자동 판단한다.
- **모호하면 반드시 사용자에게 역질문**한다: "이 소스는 mobigen/personal 중 어디에 해당하나요?"
- 자유 태그(evax, rag, python 등)도 함께 결정한다.

**1-3. 민감 정보 감지**

- `--sensitive` 플래그가 있거나, 내용에서 비밀번호/API 키/접속 정보 등이 감지되면:
  - `secrets/` 에 저장한다 (raw가 아님).
  - wiki 가공을 하지 않는다.
  - 사용자에게 민감 정보 감지 사실을 알리고 **여기서 종료**한다.

**1-4. Raw 저장 + Slug 생성**

파일을 `raw/{type}/{slug}.md`에 저장한다.

Slug 생성 규칙:

| type | 규칙 |
|---|---|
| `web` | URL 경로 → kebab-case, 최대 60자 |
| `pdf` | 파일명 → kebab-case |
| `image` | 파일명 → kebab-case |
| `note` | 첫 6단어 → kebab-case |

공통: 한글 가능, 특수문자 제거, 공백은 `-`, 연속 `-` 금지, 최대 60자.

Raw frontmatter:

```yaml
---
source: {URL 또는 파일 경로}
ingested_at: {ISO 8601 UTC}
type: {web|pdf|image|note}
scope: [mobigen|personal|둘 다]
sensitive: false
---
```

#### Step 2. 핵심 내용 논의 (생략 가능)

- 소스의 주요 takeaway를 사용자에게 공유한다.
- 무엇을 강조할지, 어떤 관점에서 정리할지 가이드를 받는다.
- 사용자가 빠른 처리를 원하면("바로 처리해", "스킵") 이 단계를 생략하고 Step 3으로 진행한다.

#### Step 3. Wiki 업데이트 (한 번에 처리)

아래 작업을 **한 패스**로 처리한다. 순서대로 진행하되 하나의 논리적 단위로 완료한다.

**3-1. Source 요약 생성**

`wiki/sources/{slug}.md`를 생성한다.

```yaml
---
source: {원본 URL/경로}
ingested_at: {ISO 8601 UTC}
type: {web|pdf|image|note}
tags: [핵심태그, 자유태그1, 자유태그2, ...]
---
```

본문 구조:
- `# {제목}` — 소스 제목
- `## 요약` — 2-4문장 핵심 요약
- `## 주요 개념` — `[[concepts/{slug}]]` 링크 + 한 줄 설명 (3-5개)
- `## 주요 사실` — 보존할 가치가 있는 구체적 사실, 수치, 인용
- `## 백링크` — `원본: [[raw/{type}/{slug}]]`

**3-2. Concept 문서 생성/업데이트 (3-5개)**

소스에서 핵심 개념을 추출한다. 개수는 소스의 성격과 깊이에 따라 LLM이 판단한다.

- **새 concept**: `wiki/concepts/{slug}.md` 생성
- **기존 concept**: 새 정보를 통합하여 업데이트 + `updated_at` 갱신 + 출처에 새 source 링크 추가

Concept type 선택 기준:

| type | 사용 시점 |
|---|---|
| `concept` | 단일 개념 설명 |
| `entity` | 특정 제품/서비스/조직 |
| `comparison` | 둘 이상의 기술 비교 |
| `overview` | 영역 전체 조감도 |
| `synthesis` | 여러 소스 교차 분석으로 새 통찰 도출 |
| `hub` | 프로젝트/주제 허브 (Step 3-4에서 별도 처리) |
| `answer` | kb-ask 전용 (kb-ingest에서는 사용하지 않음) |

Concept frontmatter:

```yaml
---
tags: [핵심태그, 자유태그, ...]
type: {concept|entity|comparison|overview|synthesis}
created_at: {ISO 8601 UTC}
updated_at: {ISO 8601 UTC}
---
```

본문 구조:
- `# {개념명}` — 독립적으로 읽을 수 있는 참조 문서
- `## 관련 개념` — `[[concepts/{slug}]]` 위키링크
- `## 출처` — `[[sources/{slug}]]` 위키링크

**3-3. 모순 감지**

새 소스의 내용이 기존 wiki concept과 충돌하는지 확인한다.

- 모순 발견 시:
  - 해당 concept 문서에 경고를 삽입한다: `> [!warning] 모순 감지 ({날짜})\n> {기존 주장} vs {새 소스 주장}. 출처: [[sources/{slug}]]`
  - `wiki/log.md`에도 모순 사실을 기록한다.
- 사용자에게 모순 발견 사실을 보고하고 어떻게 처리할지 확인한다.

**3-4. Hub 페이지 생성/업데이트**

소스가 특정 프로젝트와 관련될 경우(예: evax, 특정 업무 프로젝트):

- 해당 프로젝트의 hub 문서(`type: hub`)가 존재하면 업데이트한다.
- 없으면 새로 생성한다.
- Hub에 새 concept/source 링크와 타임라인 항목을 추가한다.

**3-5. index 업데이트**

`wiki/index.md`에 새로 생성된 문서들을 추가한다.

- `## 개념 (Concepts)` 섹션에 새 concept 추가
- `## 출처 (Sources)` 섹션에 새 source 추가
- 한 줄 설명 포함

**3-6. log.md 업데이트**

`wiki/log.md` 하단에 새 로그 엔트리를 append한다.

```markdown
## [{날짜}] ingest | {제목}
- 소스: raw/{type}/{slug}.md
- 생성: sources/{slug}.md
- 생성/업데이트: concepts/{slug1}.md, concepts/{slug2}.md, ...
- 태그: {태그 목록}
```

**3-7. 교차참조 위키링크**

모든 새로 생성/업데이트된 문서 간에 `[[wikilink]]`가 올바르게 연결되어 있는지 확인한다. 관련 기존 concept에도 새 소스로의 백링크를 추가한다.

#### Step 4. Git 커밋

```
kb: ingest '{제목}'
```

하나의 논리적 작업 = 하나의 커밋.

---

### 부수 (실패해도 불일치 없음)

#### Step 5. qmd 검색 인덱스 갱신

- qmd가 설치되어 있으면 검색 인덱스를 리빌드한다.
- 실패해도 wiki 데이터에는 영향이 없으므로 에러를 보고만 하고 진행한다.

---

## Re-ingest (동일 소스 재처리)

동일한 slug의 소스가 이미 존재할 때의 워크플로우:

1. **Raw 덮어쓰기**: `raw/{type}/{slug}.md`를 새 내용으로 덮어쓴다.
2. **영향 페이지 추적**: `wiki/sources/{slug}.md`의 `## 주요 개념` 섹션에서 관련 concept 링크 목록을 확보한다.
3. **전체 재가공**: source 요약을 새로 생성하고, 영향받는 모든 concept 페이지를 재가공한다.
4. **index/log 갱신**: log.md에 re-ingest 사실을 기록한다.
5. **Git 커밋**: `kb: ingest '{제목}'` (동일 형식)

---

## 예시

```
/kb-ingest https://example.com/attention-mechanism
  → type: web, scope: personal
  → raw/web/attention-mechanism.md 저장
  → 사용자와 takeaway 논의
  → wiki/sources/attention-mechanism.md + concepts 3-5개 생성
  → index.md, log.md 갱신
  → git commit "kb: ingest 'Attention Mechanism'"

/kb-ingest ~/회의록-evax-0407.md
  → type: note, scope: mobigen
  → raw/notes/meeting-evax-주간회의-0407.md 저장
  → wiki 업데이트 + evax hub 페이지 업데이트
  → git commit "kb: ingest 'EVAX 주간회의 0407'"

/kb-ingest ~/python-async-정리.md
  → LLM: "이 소스는 mobigen/personal 중 어디에 해당하나요?"
  → 사용자: "둘 다"
  → scope: [mobigen, personal], tags: [mobigen, personal, python]
```
