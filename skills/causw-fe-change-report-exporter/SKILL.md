---
name: causw-fe-change-report-exporter
description: CAUSW_backend 프로젝트에서 현재 브랜치/PR의 백엔드 변경사항을 분석해 프론트엔드 팀 공유용 마크다운 문서를 생성하는 스킬. "프론트에 변경사항 공유 문서", "FE 전달용 변경사항", "이번 PR 프론트 영향 정리", "백엔드 변경사항 공유 문서" 같은 요청에 사용.
---

# CAUSW FE Change Report Exporter

현재 브랜치와 base 브랜치(기본값: `dev`) 사이의 변경사항을 실제 코드 기준으로 분석해, 프론트엔드 개발자가 API client, 화면 상태, 타입, 에러 처리, QA를 준비할 수 있는 공유 문서를 생성한다.

## Output Location

문서는 기본적으로 저장소 루트의 `.claude/out-docs/` 아래에 저장한다.

파일명:

```text
.claude/out-docs/fe-change-report-<short-topic>.md
```

디렉터리가 없으면 먼저 생성한다.

```bash
mkdir -p .claude/out-docs
```

## Workflow

### 1. Determine Base And Scope

사용자가 base 브랜치를 지정하면 그 값을 사용하고, 지정하지 않으면 `dev`를 사용한다.

먼저 아래 정보를 수집한다.

```bash
git branch --show-current
git status --short
git log <base>..HEAD --oneline
git diff <base>..HEAD --stat
git diff <base>..HEAD --name-only
```

워크트리가 dirty이면 변경사항을 읽되, 사용자 변경을 되돌리거나 자동 커밋하지 않는다. 문서에 포함할 범위가 브랜치 diff인지 uncommitted diff까지인지 불명확하면 짧게 확인한다.

### 2. Locate Frontend-Relevant Changes

변경 파일과 diff에서 프론트엔드 영향이 있는 항목을 선별한다.

우선 확인할 파일:

- Controller: endpoint 추가/삭제/경로/HTTP method/query/path/body 변경
- API request/response DTO: 필드 추가/삭제/rename/type/nullable/validation/example 변경
- API mapper: API DTO와 service DTO 변환 변경
- Service/implementation: 상태 전이, 권한, 기간 검증, side effect, 알림/푸시/로그 생성
- Enum/error code: 프론트 분기, 표시명, 에러 핸들링 변경
- Flyway migration: API 응답 enum이나 상태값처럼 FE 계약에 직접 노출되는 DB 변경만 확인
- Tests: 변경된 기대 동작과 edge case 확인

권장 검색:

```bash
rg -n '@(Get|Post|Put|Patch|Delete)Mapping|@RequestMapping' app-main/src/main/java
rg -n 'record |class .*Request|class .*Response|enum .*|implements BaseResponseCode' app-main/src/main/java
rg -n '<changed-domain-keyword>|<dto-name>|<endpoint-fragment>' app-main/src/main/java app-main/src/test/java
```

단순 내부 리팩토링, 포맷팅, 로그 문구 변경처럼 FE 대응이 필요 없는 변경은 최종 문서에 포함하지 않는다.

### 3. Extract FE Contract Facts

프론트엔드가 바로 사용할 수 있는 계약 정보만 정리한다.

필수 확인 항목:

- 변경된 endpoint의 method, path, path/query/body params
- 인증/권한 요구사항 변화
- request validation, required/optional/nullable 구분
- response shape inside `ApiResponse<T>` and `PageResponse<T>`
- 추가/삭제/변경된 필드와 타입
- enum 값, 상태값, 표시/분기 영향
- 새 error code, HTTP status, 사용자 안내 필요 여부
- side effect: 알림, 푸시, 캐시 무효화, 재조회 필요성
- FE-visible compatibility: 새 enum/필드가 기존 FE 타입, fallback, 라우팅에 주는 영향
- FE action items: 타입 수정, API client 수정, UI 조건 변경, QA 시나리오

추론한 내용은 반드시 `추론:`으로 표시한다. 코드에서 확인하지 못한 항목은 `확인 필요`로 적고 임의로 채우지 않는다.

### 4. Write The Markdown Report

최종 문서를 작성하기 전에 `references/fe-change-report-template.md`를 읽고 해당 템플릿을 따른다.

작성 규칙:

- 한국어로 작성한다.
- 백엔드 내부 파일 경로와 Java 클래스명은 최종 문서에 남발하지 않는다. FE가 확인해야 하는 계약/동작 중심으로 쓴다.
- 단, 불확실성 추적이 필요하거나 사용자가 요청하면 내부 근거 섹션에 제한적으로 포함한다.
- API 변경이 없으면 "API 계약 변경 없음"을 명시한다.
- DB 마이그레이션은 새 enum/필드처럼 FE 계약에 드러나는 영향만 명시한다. DB 배포 순서, `db-change` 라벨, 백엔드 운영 메모는 FE 문서에 쓰지 않는다.
- 요청/응답 예시는 코드에서 안전하게 도출 가능한 경우에만 작성한다.
- 기존 문서와 중복되는 API 상세 명세가 필요하면 `causw-api-report-exporter`를 별도로 사용하라고 안내한다.

### 5. Validate Before Finishing

완료 전 확인한다.

- 문서 파일이 존재한다.
- 제목, 체크박스, 코드펜스가 깨지지 않았다.
- stale placeholder가 없다.
- "추론"과 "확인 필요"가 구분되어 있다.
- FE 대응 항목이 실행 가능한 체크리스트 형태다.
- 최종 문서에 백엔드 운영 메모, 배포 순서, PR 라벨, FE 대응 불필요 내부 변경 섹션이 없다.
- 테스트/빌드는 문서 생성만으로 필요하지 않으면 실행하지 않는다.

## Completion Response

완료 응답에는 아래만 간결히 포함한다.

- 생성된 문서 파일 경로
- 기준 브랜치와 분석 범위
- FE 대응 필요 항목 수
- 확인 필요 항목 또는 없으면 "확인 필요 항목 없음"
