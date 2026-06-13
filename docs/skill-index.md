# Skill Index

| 스킬 | 트리거 | 산출물 | 비고 |
|------|--------|--------|------|
| `causw-issue-writer` | 이슈 작성, 버그 이슈, 기능 이슈, 인프라 이슈, `gh issue` | `issue-draft-<type>-<topic>.md` | `.github/ISSUE_TEMPLATE` 기반 |
| `causw-pr-writer` | PR 작성, PR 초안, pull request 작성 | `pr-draft-<branch>.md` | 기본 base 브랜치: `dev` |
| `causw-test-runner` | 테스트 실행, 테스트 실패 수정, 전체 테스트 통과 | 테스트 코드 수정 및 실행 결과 보고 | `src/test/`만 수정 |
| `skill-creator` | 새 스킬 생성, 기존 스킬 개선, eval/benchmark | 스킬 디렉터리, eval 결과, 개선안 | 범용 메타 스킬 |

## Commands

| 커맨드 | 역할 |
|--------|------|
| `pr-review.md` | PR 리뷰 요청/검토 워크플로우 |

## 관리 규칙

- 스킬 디렉터리명과 `SKILL.md`의 `name:`은 일치해야 한다.
- `description:`에는 언제 자동으로 사용해야 하는지 구체적인 사용자 표현을 포함한다.
- 긴 도메인 규칙은 `SKILL.md`에 모두 넣지 말고 `references/`로 분리한다.
- 템플릿은 `assets/`, 반복 실행 코드는 `scripts/`, 평가 입력은 `evals/`에 둔다.
