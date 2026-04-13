# ccssaa-backend-agentic-recipes-archive

`ccssaa` 백엔드 프로젝트를 위한 Agentic 자산(스킬, 커맨드, 문서)을
도구별 숨김 디렉터리(`.cursor`, `.claude`, `.codex`)에 아카이빙하고 재사용하기 위한 저장소입니다.

## 목적

- 에이전트/도구별로 흩어진 운영 자산을 한 레포에서 일관되게 관리
- 반복되는 구현/운영 패턴을 스킬과 커맨드로 표준화
- 시행착오, 설계 근거, 트러블슈팅 내용을 문서로 축적

## 폴더 구조

```text
.
├── .claude/
│   ├── commands/
│   ├── docs/
│   └── skills/
├── .codex/
│   ├── commands/
│   ├── docs/
│   └── skills/
├── .cursor/
│   ├── commands/
│   ├── docs/
│   └── skills/
└── .shared/
    ├── commands/
    ├── docs/
    └── skills/
```

## `.claude/skills` 실제 스킬 요약

- `causw-issue-writer`
  - `.github/ISSUE_TEMPLATE` 기반으로 이슈 타입(feature/bug/infra/general)을 판별해 이슈 초안을 생성하는 스킬
- `causw-pr-writer`
  - 현재 브랜치와 base(`dev` 기본값) 차이를 분석해 PR 템플릿 형식의 한국어 PR 초안을 생성하는 스킬
- `causw-test-runner`
  - 전체 테스트를 반복 실행하면서 실패한 테스트 코드를 자동 수정하고 재검증하는 스킬
  - 원칙: `src/test/`만 수정하고 프로덕션 코드(`src/main/`)는 수정하지 않음
- `skill-creator`
  - 새 스킬 작성, 기존 스킬 개선, eval/benchmark 기반 품질 검증까지 반복 개선하는 메타 스킬
