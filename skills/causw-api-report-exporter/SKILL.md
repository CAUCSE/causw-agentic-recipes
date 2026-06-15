---
name: causw-api-report-exporter
description: CAUSW_backend Spring Boot 프로젝트에서 특정 API 또는 API 묶음을 분석해 프론트엔드 개발자가 구현에 바로 사용할 수 있는 마크다운 API 리포트를 export하는 스킬. "이 API 프론트 구현 문서 만들어줘", "FE 전달용 API 명세 뽑아줘", "엔드포인트 보고서 export", "프론트 개발자용 request/response 정리", "API들 마크다운 리포트" 같은 요청에 사용.
---

# CAUSW API Report Exporter

특정 API 또는 연관 API 묶음의 실제 백엔드 구현을 읽고, 프론트엔드 개발자가 화면/상태/API client 구현에 필요한 정보를 마크다운 파일로 생성한다.

## Output Location

리포트는 기본적으로 저장소 루트의 `.claude/out-docs/` 아래에 저장한다.

파일명:

```text
.claude/out-docs/api-report-<short-topic>.md
```

디렉터리가 없으면 먼저 생성한다.

```bash
mkdir -p .claude/out-docs
```

## Workflow

### 1. Determine Scope

사용자가 지정한 API 범위를 파악한다.

- 단일 endpoint: `GET /api/v2/...`
- 여러 endpoint: CRUD, 관리 화면, 특정 도메인 API 묶음
- 애매한 요청: 도메인명, controller명, 화면명, 기능명을 단서로 후보 endpoint를 찾는다.

범위가 모호해 리포트가 잘못될 위험이 있으면 짧게 확인 질문을 한다. 단, 코드 검색으로 합리적인 후보를 찾을 수 있으면 먼저 조사한다.

### 2. Locate Backend Sources

저장소 루트에서 `rg`를 우선 사용해 관련 소스를 찾는다.

권장 검색 순서:

```bash
rg -n '@(Get|Post|Put|Patch|Delete)Mapping|@RequestMapping' app-main/src/main/java
rg -n '<endpoint-fragment>|<domain-keyword>|<dto-name>' app-main/src/main/java app-main/src/test/java
```

읽을 소스:

- Controller: HTTP method, path, auth principal, request binding, response wrapper
- API request/response DTO: field names, types, validation annotations, examples if present
- API mapper: API DTO와 service DTO 변환 규칙
- Service and implementation components: business rules, transactions, side effects
- Repository/query code: filtering, sorting, pagination, N+1-sensitive data shape
- Entity/enums/error codes: response values, status transitions, domain errors
- Tests: expected scenarios and edge cases
- Flyway migrations only when schema details are necessary for frontend behavior

OpenAPI/Swagger 문서가 있으면 참고하되, 실제 Java 구현과 다르면 구현을 우선한다.

### 3. Extract Frontend-Relevant Facts

프론트엔드 구현에 필요한 사실만 선별한다.

필수 확인 항목:

- method, full path, path variables, query params, request body
- authentication/authorization requirement
- content type, multipart/file upload 여부
- request validation rules and nullable/optional distinction
- success response shape inside `ApiResponse<T>`
- paging response shape when `PageResponse<T>` is used
- enum values and display/branching implications
- domain error codes, HTTP status, user-facing handling guidance
- state changes, side effects, cache invalidation hints
- sorting/filtering defaults and server-side constraints
- frontend assumptions that are inferred from code, clearly labeled as inference

Do not expose backend entities directly as if they were API contracts. Use API DTOs as the contract.

### 4. Write the Markdown Report

Read `references/report-template.md` before writing the final report.

Report writing rules:

- Write in Korean unless the user requests English.
- Keep endpoint facts precise and implementation-oriented.
- Include request/response examples when they can be derived safely.
- Use `unknown` or `코드에서 확인 필요` instead of guessing.
- Treat backend source paths and line numbers as internal verification notes only.
- Do not include backend file paths, Java class locations, package names, or line-number citations in the final frontend report unless the user explicitly asks for backend traceability.
- Mark inferred behavior with `추론:` so the frontend developer can validate it.
- Include a frontend checklist at the end.

### 5. Validate Before Finishing

Before final response:

- Confirm the report file exists.
- Re-read the generated markdown for broken headings, stale placeholders, and malformed code fences.
- Re-read the generated markdown and confirm it does not contain backend source paths such as `app-main/src`, `.java:<line>`, package paths, or "Backend source" sections unless explicitly requested.
- If tests or build commands were unnecessary, do not run them just for a documentation export.
- If the report depends on uncertain behavior, list the uncertainty explicitly in the final response.

## Completion Response

완료 응답에는 아래만 간결히 포함한다.

- 생성된 리포트 파일 경로
- 다룬 API 범위
- 확인이 필요한 불확실성 또는 없으면 "확인 필요 항목 없음"
