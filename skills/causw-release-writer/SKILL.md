---
name: causw-release-writer
description: CAUSW_backend 프로젝트에서 현재 브랜치(또는 지정 브랜치)와 main 브랜치 사이의 변경사항을 분석해 릴리즈 노트 마크다운 파일을 자동 생성하는 스킬. "릴리즈 노트 작성해줘", "release note 만들어줘", "버전 릴리즈 준비해줘", "변경사항 정리해줘 main 기준", "gh release 만들어줘" 등의 요청에 사용. 버전 미지정 시 최신 태그 기반으로 다음 버전을 자동 제안.
---

# CAUSW Release Writer

현재 체크아웃된 브랜치(또는 지정 브랜치)와 `main` 브랜치 사이의 변경사항을 git으로 분석하고,
한국어 릴리즈 노트를 마크다운 파일로 생성한다. 완료 후 GitHub Release 생성 여부를 사용자에게 묻는다.

## 실행 순서

### 1단계: 브랜치·태그 정보 수집

아래 명령어를 순서대로 실행해 필요한 정보를 모은다.

```bash
# 현재 브랜치 확인
git branch --show-current

# main 대비 커밋 목록 (한 줄 요약)
git log main..HEAD --oneline

# 변경 파일 통계
git diff main..HEAD --stat

# 최근 태그 목록 (버전 제안용)
git tag --sort=-v:refname | head -10

# 관련 PR/이슈 번호 추출 (커밋 메시지에서)
git log main..HEAD --format="%s" | grep -oE '#[0-9]+' | sort -u

# 기간 계산
git log main..HEAD --format="%ad" --date=short | tail -1   # 첫 커밋
git log main..HEAD --format="%ad" --date=short | head -1   # 마지막 커밋
```

`main` 브랜치가 로컬에 없으면 `origin/main`을 사용한다.

### 2단계: 버전 결정

최신 태그(예: `v2.2.0`)를 기반으로 다음 버전을 제안한다.

- `feat:` 커밋이 있으면 → **minor** 버전 업 (v2.2.0 → v2.3.0)
- `feat:` 없이 `fix:` / `refactor:` 만 있으면 → **patch** 버전 업 (v2.2.0 → v2.2.1)
- `BREAKING CHANGE` 또는 `!:` 커밋이 있으면 → **major** 버전 업 (v2.2.0 → v3.0.0)
- 태그가 아예 없으면 `v1.0.0` 제안

사용자가 버전을 직접 지정했으면 그것을 사용한다.

### 3단계: 변경사항 분류

커밋 메시지 prefix 기준으로 분류한다.

| prefix | 분류 |
|--------|------|
| `feat:` | ✨ 새 기능 |
| `fix:` | 🐛 버그 수정 |
| `refactor:` | ♻️ 리팩토링 |
| `perf:` | ⚡ 성능 개선 |
| `test:` | 🧪 테스트 |
| `docs:` | 📝 문서 |
| `chore:` / `build:` / `ci:` | 🔧 기타 |
| `rename:` / `style:` | 🎨 코드 정리 |

커밋 메시지 뒤의 `(#1234)` 는 PR 링크로 변환한다:
`[#1234](https://github.com/CAUCW/causw_backend/pull/1234)`

### 4단계: 릴리즈 노트 작성

**파일명**: `.claude/out-docs/release-note-<버전>.md`

디렉터리가 없으면 먼저 생성한다:
```bash
mkdir -p .claude/out-docs
```

---

```markdown
# 🚀 Release <버전>

> <첫 커밋 날짜> ~ <마지막 커밋 날짜>

## 📋 변경사항 요약

<!-- 이 릴리즈에서 가장 중요한 변경 1~3줄 자유 서술 -->

## ✨ 새 기능

- 기능 설명 [#PR번호](링크)

## 🐛 버그 수정

- 수정 내용 [#PR번호](링크)

## ♻️ 리팩토링

- 리팩토링 내용 [#PR번호](링크)

## ⚡ 성능 개선

- 개선 내용 [#PR번호](링크)

## 🔧 기타

- 기타 변경사항 [#PR번호](링크)

---

**Full Changelog**: https://github.com/CAUCW/causw_backend/compare/<이전 태그>...<버전>
```

---

변경사항이 없는 섹션은 생략한다.

## 각 섹션 작성 가이드

**변경사항 요약**
- 이번 릴리즈의 핵심을 2~3문장으로 설명 (단순 목록 나열 X)
- 사용자/운영자가 무엇이 달라졌는지 한눈에 파악할 수 있게 작성

**각 항목 서술**
- 커밋 메시지를 그대로 복붙하지 말고, 사람이 읽기 좋게 재서술
- 관련 PR 번호는 반드시 링크로 변환
- 연관 커밋 여러 개가 같은 기능이면 하나의 항목으로 묶어 표현

**Full Changelog 링크**
- 이전 태그와 새 버전 태그를 비교하는 GitHub compare URL 생성

## 완료 후

1. 파일 경로를 사용자에게 알려주고 내용을 터미널에 출력한다.
2. GitHub Release 생성 여부를 사용자에게 묻는다.
   - **Yes**라면 아래 명령어로 생성한다 (태그가 없으면 함께 생성):
     ```bash
     gh release create <버전> \
       --title "<버전>" \
       --notes-file .claude/out-docs/release-note-<버전>.md \
       --target <현재 브랜치>
     ```
   - **No**라면 파일 경로만 안내하고 종료한다.
3. 내용이 불만족스러우면 피드백을 받아 수정한다.
