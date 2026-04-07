---
name: kb-help
description: |
  Knowledge Base 스킬 사용법 안내. 각 스킬의 용도와 사용 예시를 보여준다.
  트리거: "/kb-help", "KB 도움말", "KB 스킬 뭐있어"
---

# KB Help — 스킬 사용 가이드

사용자에게 아래 내용을 보여준다.

---

## 스킬 목록

### `/kb-add` — 새 지식 추가

**언제:** 새로운 내용을 KB에 넣고 싶을 때. 어디서든 호출 가능.

```
/kb-add https://example.com/rag-tutorial
/kb-add evax 프로젝트에 회의록 추가해줘 [회의 내용]
/kb-add               ← Inbox에 있는 파일 정리
```

- 웹 링크, 파일(pdf/pptx), 구체적 내용 모두 지원
- LLM이 일반 지식을 생성하는 요청은 거부됨
- 배치 위치를 제안하고 사용자 확인 후 진행

---

### `/kb-update` — 기존 문서 업데이트

**언제:** 이미 있는 문서에 내용을 추가/수정하고 싶을 때.

```
/kb-update EVAX GraphIO 메시지 프로토콜에 새 필드 추가됨 [내용]
/kb-update 김해 접속정보에 DB 하나 추가해 (192.168.xxx.xxx, ...)
```

- 관련 문서를 탐색해서 "이 문서를 업데이트하겠습니다" 제시
- 문서가 없으면 "/kb-add로 추가할까요?" 안내

---

### `/kb-search` — 검색/질문 답변

**언제:** KB에 축적된 지식을 검색하거나 질문할 때.

```
/kb-search EVAX에서 GraphIO 메시지 프로토콜이 어떻게 동작해?
/kb-search RAG 관련 문서 찾아줘
```

- frontmatter + index + qmd + 위키링크 탐색으로 답변 합성
- 참조 문서 목록 제시
- 읽기 전용 (문서 수정 안 함)

---

### `/kb-update-schema` — 폴더 구조 변경

**언제:** 새 폴더를 추가하거나, Group을 변경하거나, SCHEMA.md를 수정할 때.

```
/kb-update-schema
/kb-update-schema Common/FastAPI 폴더 추가해줘
```

- 현재 SCHEMA를 보여주고 대화형으로 변경
- 폴더 추가 시 실제 디렉토리 + 00_index_{Name}.md 자동 생성

---

### `/kb-lint` — 건강 점검

**언제:** KB 품질을 점검하고 싶을 때. 주기적으로 실행 권장.

```
/kb-lint
```

점검 항목:
1. 깨진 위키링크
2. 00_index_{Name}.md에 누락된 문서
3. 고아 페이지 (링크 없는 문서)
4. tags 누락
5. group과 폴더 위치 불일치
6. 중복 의심 문서
7. Inbox 방치 파일

---

### `/kb-merge` — 중복 문서 병합

**언제:** 비슷한 내용의 문서를 하나로 합치고 싶을 때.

```
/kb-merge 문서A 문서B     ← 두 문서 지정
/kb-merge                  ← 전체 중복 스캔
```

- primary 문서에 내용 병합, absorbed 문서 삭제
- 백링크 자동 수정

---

### `/kb-setup` — 초기 세팅

**언제:** 새 KB 볼트를 처음 만들 때. 보통 1번만 실행.

```
/kb-setup
```

- config.json, SCHEMA.md, CLAUDE.md, 폴더 구조, 00_index 파일 생성
- 대화형으로 초기 폴더/Group 정의

---

### `/kb-help` — 이 도움말

```
/kb-help
```
