---
name: causw-backend-guide
description: >
  CAUSW_backend 프로젝트의 패키지 구조와 코드 작성 가이드.
  이 프로젝트에서 새로운 API, 도메인, 기능을 추가하거나 기존 코드를 수정할 때 사용.
  Controller → Service → Reader/Writer (implementation) → Repository 의존관계,
  V2 아키텍처 패턴(Command/Query/Result DTO, Reader/Writer 분리),
  Entity 설계, 패키지 구조, 레이어별 책임, 코딩 컨벤션을 안내함.
  도메인 추가, 엔드포인트 개발, 리팩토링 등 백엔드 개발 전반에 적용.
---

# CAUSW Backend 개발 가이드

## 프로젝트 개요

Spring Boot + Gradle 멀티모듈 프로젝트 (중앙대학교 소프트웨어학부 동문네트워크 커뮤니티)

- **app-main**: 메인 API 서버
- **global**: 공유 예외/유틸리티

기본 패키지: `net.causw.app.main`

**자세한 패키지 구조**: `references/package-structure.md` 참고
**계층별 코드 패턴**: `references/layer-patterns.md` 참고

---

## 핵심 아키텍처 (V2 패턴)

신규 개발 시 V2 패턴을 우선 적용한다. 기존 도메인을 확장할 때는 주변 패키지 구조와 의존성 관성을 먼저 확인하고, 아래 패턴과 다르면 기존 로컬 패턴을 우선한다.

```
HTTP 요청
  ↓
Controller (api/v2/controller/)
  - Request DTO 수신 → API Mapper로 Command/Query 변환
  - ApiResponse<T>로 응답 래핑
  ↓
Service (service/v2/ 또는 기존 도메인의 service/)
  - 클래스 레벨 @Transactional(readOnly = true) 또는 메서드별 @Transactional 명시
  - 쓰기 메서드는 @Transactional
  - Reader/Writer/Resolver/Manager 등 implementation 컴포넌트에 의존
  - Repository 직접 의존은 피하되, 단순 조회 전용 레거시/관리자 QueryRepository 예외는 주변 패턴을 확인
  - Validator로 검증, Mapper로 Entity↔DTO 변환
  ↓
Reader / Writer / Resolver / Manager (service/v2/implementation/ 또는 service/implementation/)
  - Reader: @Component + @Transactional(readOnly = true)
  - Writer: @Component + @Transactional
  - orElseThrow(BaseResponseCode::toBaseException) 예외 처리
  ↓
Repository (repository/)
  - JpaRepository: 기본 CRUD + JPQL
  - QueryRepository: QueryDSL 복잡 쿼리
  ↓
Entity (entity/)
  - 신규 Entity는 BaseEntity 상속 권장 (String UUID id, createdAt, updatedAt)
  - 정적 팩토리 메서드 of(...) 또는 from(...)로 생성
  - Builder(PROTECTED), NoArgsConstructor(PROTECTED), AllArgsConstructor(PRIVATE)
```

---

## 새 도메인/기능 추가 체크리스트

### 1. 패키지 생성

```
domain/{카테고리}/{도메인명}/
├── api/v2/
│   ├── controller/   XxxController.java
│   ├── dto/
│   │   ├── request/  XxxCreateRequest.java  (record)
│   │   └── response/ XxxCreateResponse.java (record + @Builder)
│   └── mapper/       XxxDtoMapper.java      (MapStruct @Mapper)
├── entity/           Xxx.java               (extends BaseEntity)
├── enums/
├── repository/
│   ├── XxxRepository.java                   (JpaRepository)
│   └── query/XxxQueryRepository.java        (QueryDSL, 복잡 쿼리 시)
└── service/v2/ 또는 기존 도메인의 service/
    ├── XxxService.java
    ├── dto/
    │   ├── XxxCreateCommand.java  (record)
    │   ├── XxxCreateResult.java   (record)
    │   └── XxxListQuery.java      (record)
    ├── implementation/
    │   ├── XxxReader.java
    │   └── XxxWriter.java
    ├── mapper/XxxMapper.java      (static 메서드 또는 MapStruct)
    └── util/XxxValidator.java     (static util 또는 implementation 컴포넌트)
```

### 2. 구현 순서

Entity → Repository → Reader/Writer → Service → Controller (하단에서 상단으로)

### 3. 기존 도메인 확장 시 우선순위

1. 같은 도메인의 최신 V2 코드 구조를 먼저 따른다.
2. 같은 도메인에 V2 구조가 없으면 인접 도메인의 최신 구현(Post, Locker, User Account 등)을 참고한다.
3. 새 구조를 도입할 때는 API DTO와 Service DTO를 분리하고, Controller에 비즈니스 로직을 넣지 않는다.
4. 기존 레거시 구조와 충돌하면 대규모 이동보다 변경 범위를 작게 유지한다.

---

## 주요 컨벤션

| 항목 | 규칙 |
|------|------|
| DTO | `record` 사용 권장, Request는 `@Valid`+`@Schema`, Response는 필요 시 `@Builder` |
| ID 타입 | `String` (UUID, `@UuidGenerator`) |
| 테이블명 | 신규 테이블은 `tb_` 접두사 권장, 기존 대문자/레거시 테이블명은 유지 |
| 소프트 삭제 | `isDeleted` 필드, `setIsDeleted(true)` |
| 페이징 | 커서 기반 (`Slice<T>`) 또는 `Page<T>` |
| 예외 처리 | `BaseResponseCode` 구현 enum + `XxxErrorCode::toBaseException` |
| 응답 형식 | `ApiResponse<T>` |
| 인증 유저 | `@AuthenticationPrincipal CustomUserDetails userDetails` |
| 이미지/파일 처리 | `FileWriter`, `PostImageManager` 등 기존 도메인 전용 Manager/Writer 우선 |

---

## V1 vs V2 차이

| 구분 | V1 (레거시, 수정 최소화) | V2 (신규 개발 기준) |
|------|------------------------|-------------------|
| Service | 큰 단일 클래스 | Reader/Writer 분리 |
| Repository 의존 | Service에서 직접 | Reader/Writer 통해서만 |
| DTO 이름 | RequestDto / ResponseDto | Command/Query/Result |
| Mapper | 수동 또는 MapStruct | MapStruct @Mapper, 수동 @Component, static util 중 주변 패턴 우선 |
| 검증 | Service 내부 | static Validator util 또는 implementation Validator 컴포넌트 |

---

## 상세 코드 패턴

각 계층의 상세 코드 예시는 `references/layer-patterns.md` 참고.
패키지 전체 구조는 `references/package-structure.md` 참고.
