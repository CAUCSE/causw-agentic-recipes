# Frontend API Report Template

Use this structure when exporting an API report. Remove sections that are truly irrelevant, but do not leave placeholders.

```markdown
# <API/Feature Name> Frontend Implementation Report

## Scope

- Endpoint(s):
  - `<METHOD> <PATH>`
- Purpose:
  - <프론트엔드에서 구현할 화면/API client 목적>

## Summary

<프론트엔드 개발자가 이 API로 무엇을 구현할 수 있는지 2-4문장으로 요약>

## Authentication And Authorization

- Authentication: <required / optional / none / unknown>
- Principal: `<CustomUserDetails>` 사용 여부
- Authorization rule: <역할, 소유자 검증, 관리자 권한 등>
- Failure handling:
  - `<ERROR_CODE>`: <의미와 프론트 처리>

## Endpoint Contract

### `<METHOD> <PATH>`

#### Request

| Location | Name | Type | Required | Rule | Description |
| :--- | :--- | :--- | :---: | :--- | :--- |
| path | `<name>` | `<type>` | Y |  |  |
| query | `<name>` | `<type>` | N | default: `<value>` |  |
| body | `<field>` | `<type>` | Y | `@NotBlank` |  |

```json
{
  "example": "request"
}
```

#### Response

- Wrapper: `ApiResponse<T>`
- Data type: `<ResponseDto>`

```json
{
  "isSuccess": true,
  "code": "...",
  "message": "...",
  "result": {}
}
```

If paged:

- Wrapper: `ApiResponse<PageResponse<T>>`
- Page base: <0-based / 1-based / unknown>
- Sort default: <field,direction>

#### Fields

| Field | Type | Nullable | Description | Frontend Note |
| :--- | :--- | :---: | :--- | :--- |
| `<field>` | `<type>` | N |  |  |

## Enums And Constants

| Name | Values | Frontend Use |
| :--- | :--- | :--- |
| `<Enum>` | `<A>`, `<B>` | <label/branch/filter implications> |

## Business Rules

- <검증, 상태 전이, 중복 제한, 기간 제한 등>
- 추론: <코드 흐름상 예상되지만 직접 명시되지 않은 동작>

## Error Handling

| Error Code | HTTP Status | Cause | Frontend Handling |
| :--- | :---: | :--- | :--- |
| `<ERROR_CODE>` | 400 | <cause> | <message/action guidance> |

## Side Effects And Refresh Strategy

- Mutates: <created/updated/deleted resource>
- Related data to refetch: <list/query/detail/count 등>
- File/image effects: <S3/Firebase/etc if relevant>
- Cache invalidation hint: <query keys or affected screens if inferable>

## Frontend Implementation Checklist

- [ ] API client method added with correct method/path
- [ ] Request validation mirrors required backend constraints
- [ ] Success response mapped from `result`
- [ ] Empty/loading/error states handled
- [ ] Known domain errors mapped to user-facing actions
- [ ] Related list/detail data refreshed after mutation

## Open Questions

- <확인이 필요한 항목. 없으면 "없음">
```
