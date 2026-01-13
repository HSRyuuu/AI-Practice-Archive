# Frontend QA Test Planner Skill

`frontend-qa-test-planner`는 프론트엔드 소스 코드를 분석하여 QA 진행 시 필요한 테스트 항목과 검증 시나리오를 자동으로 선정해주는 도구입니다.

## 🚀 사용 상황

- **기능 개발 완료 후**: 코드 구현이 끝난 후, 어떤 부분을 중점적으로 테스트해야 할지 리스트업이 필요할 때
- **QA 준비 단계**: 기획서 기반이 아닌, 실제 구현된 정교한 로직을 바탕으로 테스트 케이스를 설계하고 싶을 때
- **코드 리뷰 시**: 변경된 코드에 대한 영향도를 파악하고 테스트 범위를 확정하고 싶을 때

---

## 💻 사용 방법

### 1. Claude CLI를 사용하는 경우 (추천)

로컬 개발 환경에서 가장 빠르고 효율적으로 사용하는 방법입니다.

1.  **파일 경로 복사**: IDE(VS Code 등)에서 분석하고자 하는 컴포넌트 파일의 전체 경로를 복사합니다. (예: `Copy Path`)
    - 예: `/Users/happyhsryu/dev/some-project/frontend/pages/sm/sl/api-log/index.vue`
2.  **명령어 실행**: Claude CLI 터미널에 스킬 이름과 파일 경로를 함께 입력합니다.

```bash
/frontend-qa-test-planner /Users/happyhsryu/dev/some-project/frontend/pages/sm/sl/api-log/index.vue
```

AI가 해당 파일을 읽고, 여기에 포함된 `import`, `composables`, `components` 등을 추적하여 테스트 플랜을 생성합니다.

### 2. Claude CLI를 사용하지 않는 경우 (단순 프롬프트)

클라우드 웹 인터페이스나 CLI 기능이 없는 환경에서도 이 스킬을 활용할 수 있습니다.

1.  **스킬 등록**: `skill.md` 파일의 내용을 복사하여 Claude에게 "다음은 내가 사용할 스킬 정의야. 앞으로 `/frontend-qa-test-planner` 명령을 내리면 이 규칙에 따라 동작해줘"라고 입력합니다.
2.  **파일 내용 제공**: 분석하고 싶은 파일의 내용을 스킬 이름과 함께 붙여넣습니다.

```text
/frontend-qa-test-planner

[파일 내용 붙여넣기]
```

---

## 💡 활용 팁

- **다중 파일 분석**: 연관된 여러 파일을 한 번에 분석하고 싶다면 경로를 여러 개 나열하세요.
  ```bash
  /frontend-qa-test-planner @[pages/index.vue] @[components/Grid.vue]
  ```
- **디렉터리 지정**: 특정 디렉터리 내의 모든 파일을 분석하려면 디렉터리 경로를 지정할 수 있습니다.
  ```bash
  /frontend-qa-test-planner @[/frontend/pages/sm/sl/]
  ```
- **파일 경로 필수**: 이 스킬은 자동으로 파일을 탐색하거나 추천하지 않습니다. 반드시 분석하고자 하는 파일 또는 디렉터리의 경로를 명시적으로 제공해야 합니다.
- **결과 활용**: 생성된 마크다운 테이블을 복사하여 QA 시트(Excel, Jira 등)에 붙여넣어 즉시 활용하세요.
