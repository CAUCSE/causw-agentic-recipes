# CAUSW Backend 패키지 구조

## 모듈 구성

```
CAUSW_backend/
├── app-main/          # 메인 애플리케이션
└── global/            # 공유 유틸리티 및 예외 처리
```

## app-main 패키지 구조

기본 패키지: `net.causw.app.main`

```
net/causw/app/main/
├── CauswApplication.java
├── core/                          # 인프라 설정
│   ├── aop/                       # AOP (MeasureTime, LogAspect)
│   ├── batch/                     # Spring Batch 설정
│   ├── config/                    # 설정 클래스 (async, JPA, Querydsl, Swagger, Flyway)
│   ├── security/                  # Spring Security, JWT
│   ├── filter/
│   └── datasourceProxy/
│
├── domain/                        # 도메인 비즈니스 로직
│   ├── asset/
│   │   ├── file/                  # 파일/이미지 관리
│   │   └── locker/                # 사물함 관리
│   ├── campus/
│   │   ├── circle/                # 동아리
│   │   ├── event/                 # 행사
│   │   ├── schedule/              # 학사일정
│   │   └── semester/              # 학기
│   ├── community/
│   │   ├── board/                 # 게시판
│   │   ├── post/                  # 게시글
│   │   ├── comment/               # 댓글
│   │   ├── reaction/              # 좋아요/즐겨찾기
│   │   ├── vote/                  # 투표
│   │   ├── form/                  # 설문
│   │   ├── ceremony/              # 경조사
│   │   └── report/                # 신고
│   ├── user/
│   │   ├── account/               # 사용자 계정
│   │   ├── academic/              # 학적 정보
│   │   ├── auth/                  # 인증
│   │   └── relation/              # 관계
│   ├── notification/              # 알림
│   ├── finance/                   # 재정
│   └── integration/               # 외부 연동
│
└── shared/                        # 공유 컴포넌트
    ├── dto/                       # ApiResponse, PageResponse
    ├── entity/                    # BaseEntity, AuditableEntity
    ├── exception/                 # 예외 클래스
    └── util/
```

## 도메인 내부 패키지 구조 (예: post)

```
domain/community/post/
├── api/
│   ├── v1/
│   │   ├── controller/
│   │   └── dto/
│   └── v2/
│       ├── controller/
│       │   └── PostController.java
│       ├── dto/
│       │   ├── request/           # PostCreateRequest.java (record)
│       │   └── response/          # PostCreateResponse.java (record)
│       └── mapper/                # PostDtoMapper.java (MapStruct)
├── entity/
│   └── Post.java
├── enums/
├── repository/
│   ├── PostRepository.java        # JpaRepository
│   └── query/
│       ├── PostQueryRepository.java  # QueryDSL
│       ├── PostCursorResult.java
│       └── PostQueryResult.java
└── service/
    ├── v1/
    │   └── PostV1Service.java     # 레거시
    └── v2/
        ├── PostService.java       # 메인 서비스
        ├── dto/                   # Command/Query/Result
        │   ├── PostCreateCommand.java
        │   ├── PostCreateResult.java
        │   ├── PostUpdateCommand.java
        │   └── PostListQuery.java
        ├── implementation/
        │   ├── PostReader.java    # 읽기 전용
        │   └── PostWriter.java    # 쓰기 작업
        ├── mapper/
        │   └── PostMapper.java    # Entity ↔ DTO 변환 (static)
        └── util/
            ├── PostValidator.java
            └── PostCursorManager.java
```

> 신규 도메인은 위 구조를 우선한다. 기존 도메인 확장은 `service/v2/implementation`뿐 아니라 `service/implementation`, `api/v2/controller/dto`, `domain/{domain}/util` 등 이미 사용 중인 주변 구조를 먼저 확인한다.

## global 모듈 패키지

```
net/causw/global/
├── constant/
│   ├── StaticValue.java
│   ├── HttpStatusCodes.java
│   └── MessageUtil.java
├── exception/
│   ├── BaseRuntimeException.java
│   ├── BadRequestException.java
│   ├── UnauthorizedException.java
│   ├── ForbiddenException.java
│   ├── NotFoundException.java
│   └── ErrorCode.java
└── util/
    ├── PatternUtil.java
    └── HashUtil.java
```

## app-main shared 패키지

V2 공통 응답, 예외, 엔티티 기반 클래스는 주로 `app-main`의 `shared` 패키지에 있다.

```
net/causw/app/main/shared/
├── dto/                       # ApiResponse, PageResponse
├── entity/                    # BaseEntity, AuditableEntity
├── exception/                 # BaseResponseCode, BaseRunTimeV2Exception, handlers
├── exception/errorcode/       # 도메인별 ErrorCode enum
├── infra/                     # Firebase, Redis, storage, mail
└── util/
```

## 주요 Enum (user/account/enums/)

- `Role`: ADMIN, COUNCIL_LEADER, CIRCLE_LEADER, COMMON, INACTIVE, AWAIT 등
- `UserState`: ACTIVE, INACTIVE, DELETED, BLOCKED, DROP 등
- `Department`: 소속 학부 목록
- `AcademicStatus`: 학적 상태 (재학, 휴학, 졸업 등)
