---
name: knowledge-hub
description: 전역 지식 저장소(knowledge_hub) 활용 스킬. PARA 방법론 기반 Obsidian 볼트에 기술 지식을 저장·관리한다. "정리해줘", "저장해줘", "knowledge hub", "지식 저장소", "knowledge_hub에 저장", "노트 정리", "학습 정리" 등 요청 시 사용. 세션 중 가치 있는 기술 지식을 발견했을 때도 이 스킬을 참조하여 올바른 위치와 형식으로 저장한다.
---

# Knowledge Hub

전역 지식 저장소 경로: `/Users/happyhsryu/dev/local_workspace/knowledge_hub`

Obsidian 볼트로 운영되며, 프로젝트와 무관하게 가치 있는 기술 지식을 축적하는 공간이다.

## PARA 구조

이 저장소는 PARA 방법론으로 구성한다.

| 폴더 | 용도 |
|---|---|
| `00_Inbox/` | 미처리 항목. 분류 후 적절한 PARA 폴더로 이동 |
| `01_Projects/` | 마감이 있는 활성 프로젝트 (`01_Projects/{projectName}/`) |
| `02_Areas/` | 마감 없는 지속적 책임 영역 |
| `03_Resources/` | 프로젝트에 종속되지 않는 범용 지식 (`03_Resources/{topic}/`) |
| `04_Archives/` | 비활성화된 항목 (완료/중단된 프로젝트, 불필요한 자료) |

## 저장 위치 규칙

1. **대화 기록, 학습 노트, 정리 요청** 등 즉석에서 생성되는 문서는 **항상 `00_Inbox/`에 저장**한다.
2. 저장 위치가 명확하지 않은 경우, **반드시 사용자에게 어디에 저장할지 먼저 물어본다.**
3. PARA 폴더 구조 바깥(루트, 임의 폴더)에 직접 파일을 생성하지 않는다.
4. 루트에 프로젝트 상세 파일을 두지 않는다.
5. 범용 기술 지식(RAG, Docker 등)은 `03_Resources/` 아래 주제별로 배치한다.

## 파일 보호 규칙

frontmatter에 `protect` 속성으로 파일 보호 등급을 지정한다. `protect`는 항상 frontmatter의 첫 번째 속성으로 작성한다.

| 값 | 의미 | 허용 동작 |
|---|---|---|
| `readonly` | 원본 보존 필수 | 읽기만 가능. 수정/삭제/병합 금지 |
| `archive` | 수정 불가, 이동만 허용 | `04_Archives/`로 이동만 가능 |
| (없음) | 일반 문서 | 자유롭게 수정/삭제/병합 가능 |

### 수정/삭제/병합 시 준수 사항

- 파일 수정·삭제 전 frontmatter의 `protect` 속성을 확인한다.
- `protect: readonly` 파일은 어떤 경우에도 내용을 수정하거나 삭제하지 않는다.
- 두 문서를 병합할 때 원본은 삭제하지 않고 `04_Archives/`로 이동하며, 병합 문서에 출처(원본 파일명)를 기록한다.
- 사용자가 명시적으로 보호 해제를 요청한 경우에만 `protect` 속성을 변경할 수 있다.
- 파일명이 `_`로 시작하는 파일은 secret 파일이다. 항상 `protect: readonly`를 지정하며, `tags: [secret]`을 포함한다.

## 파일 네이밍 규칙

- 볼트 홈 페이지: `Home.md`
- 각 폴더의 인덱스/MOC 문서는 `00_Index_{폴더명}.md` 형식으로 작성한다.
  - 예: `01_Projects/EVAX/00_Index_EVAX.md`, `03_Resources/RAG/00_Index_RAG.md`

## 접속정보 표 형식

`_secret` 파일에서 서버/서비스 접속정보를 기록할 때는 아래 형식을 사용한다:

```markdown
| name | url/ip | port | username | password | 비고 |
|---|---|---|---|---|---|
| **서비스명** | 주소 | 포트 | 사용자명 | 비밀번호 | 추가정보 |
```

- `name` 필드는 반드시 **bold** 처리한다.
- 해당하지 않는 필드는 `-`로 채운다.
- 접속 절차 등 표로 표현할 수 없는 내용은 표 아래에 배치한다.

## 관련 스킬

Obsidian 볼트 작업 시 아래 스킬을 함께 활용한다:

- `obsidian-markdown` — Obsidian Flavored Markdown 작성 (위키링크, 임베드, 콜아웃, 프로퍼티)
- `obsidian-bases` — `.base` 파일로 데이터베이스형 뷰 생성
- `obsidian-cli` — Obsidian CLI로 노트 읽기/생성/검색/관리
- `json-canvas` — `.canvas` 파일로 마인드맵, 플로우차트 등 시각적 캔버스 생성
