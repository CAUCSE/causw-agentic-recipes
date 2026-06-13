# Agentic Recipes Architecture

이 저장소는 도구별 설정 디렉터리의 백업본이 아니라, CAUSW 프로젝트에서 재사용할 Agentic 자산의 원본 저장소다.

## 원칙

- `skills/`와 `commands/`를 원본으로 둔다.
- `.claude/`, `.codex/`, `.cursor/`는 직접 편집하지 않는다.
- 스킬은 `SKILL.md`를 작게 유지하고, 긴 규칙은 `references/`로 분리한다.
- 반복 실행이 필요한 작업은 스킬 본문에 긴 코드를 넣지 말고 `scripts/`로 둔다.
- 템플릿과 예시는 `assets/`로 분리해 재사용한다.
- 평가 프롬프트나 스모크 테스트는 `evals/`에 둔다.

## 배포 모델

대상 프로젝트에는 심볼릭 링크로 설치한다.

```text
causw-agentic-recipes/skills/causw-pr-writer
    -> CAUSW_backend/.claude/skills/causw-pr-writer
```

이 방식은 원본 저장소를 `git pull`했을 때 대상 프로젝트의 스킬도 함께 갱신되게 한다.
