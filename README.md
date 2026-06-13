# causw-agentic-recipes

CAUSW 백엔드 프로젝트를 위한 Agentic 자산(스킬, 커맨드, 문서)을 한 곳에서 관리하는 원본 저장소입니다.

## 목적

- 반복되는 구현/운영 패턴을 스킬과 커맨드로 표준화
- Claude, Codex, Cursor 같은 도구별 설치 위치와 원본 소스를 분리
- 시행착오, 설계 근거, 트러블슈팅 내용을 문서로 축적

## 구조

```text
.
├── skills/              # 스킬 원본
│   └── {skill-name}/
│       ├── SKILL.md
│       ├── references/  # 선택: 상세 규칙
│       ├── assets/      # 선택: 템플릿/정적 자산
│       ├── scripts/     # 선택: 반복 작업 자동화
│       └── evals/       # 선택: 평가 프롬프트/스모크 테스트
├── commands/            # 커맨드 원본
├── docs/                # 운영 문서
├── scripts/             # 설치/검증 스크립트
├── .claude/             # 도구별 설치 대상 예시/placeholder
├── .codex/
└── .cursor/
```

`skills/`와 `commands/`가 원본입니다. `.claude/`, `.codex/`, `.cursor/`는 직접 편집하는 위치가 아니라 대상 프로젝트나 도구별 설치 위치로 취급합니다.

## 스킬 목록

자세한 목록은 [docs/skill-index.md](docs/skill-index.md)를 봅니다.

| 스킬 | 역할 |
|------|------|
| `causw-issue-writer` | GitHub 이슈 템플릿 기반 이슈 초안 생성 |
| `causw-pr-writer` | 브랜치 변경사항 기반 PR 초안 생성 |
| `causw-test-runner` | CAUSW 백엔드 테스트 실행 및 테스트 코드 수정 루프 |
| `skill-creator` | 새 스킬 작성, 평가, 개선 |

## 설치

대상 프로젝트의 도구별 스킬 디렉터리에 심볼릭 링크를 만듭니다.

```bash
# Claude 기본값: <project>/.claude/skills/{skill-name}
./scripts/link-skill-to-project.sh causw-pr-writer /path/to/CAUSW_backend

# Codex 대상: <project>/.codex/skills/{skill-name}
./scripts/link-skill-to-project.sh causw-pr-writer /path/to/CAUSW_backend codex

# Cursor 대상: <project>/.cursor/skills/{skill-name}
./scripts/link-skill-to-project.sh causw-pr-writer /path/to/CAUSW_backend cursor
```

Windows PowerShell:

```powershell
.\scripts\link-skill-to-project.ps1 causw-pr-writer C:\Projects\CAUSW_backend
.\scripts\link-skill-to-project.ps1 causw-pr-writer C:\Projects\CAUSW_backend codex
```

## 검증

스킬 구조와 frontmatter를 빠르게 확인합니다.

```bash
bash scripts/validate-skills.sh
```

검증 항목:

- `skills/*/SKILL.md` 존재 여부
- `name:` frontmatter와 디렉터리명 일치 여부
- `description:` frontmatter 존재 여부
- `commands/*.md` 존재 여부 확인

## 새 스킬 추가

1. `skills/{skill-name}/SKILL.md`를 만든다.
2. frontmatter에 `name`과 `description`을 넣는다.
3. 상세 규칙이 길면 `references/`, 템플릿은 `assets/`, 반복 로직은 `scripts/`, 평가 입력은 `evals/`로 분리한다.
4. `docs/skill-index.md`와 이 README의 스킬 목록을 갱신한다.
5. `bash scripts/validate-skills.sh`로 구조를 확인한다.
