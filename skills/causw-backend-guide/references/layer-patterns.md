# CAUSW Backend 계층별 코드 패턴

## 1. Controller 계층

**위치**: `domain/{domain}/api/v2/controller/`

기존 도메인에서는 `api/v2/controller/admin`, `api/v2/controller/dto`, `api/v2/dto`처럼 세부 위치가 다를 수 있다. 같은 도메인 안의 최신 컨트롤러 구조를 우선한다.

```java
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v2/{resource}")
@Tag(name = "게시글 API (V2)", description = "게시글 관련 API")
public class PostController {

    private final PostService postService;
    private final PostDtoMapper postDtoMapper;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "게시글 생성", description = "새로운 게시글을 생성합니다.")
    public ApiResponse<PostCreateResponse> create(
        @Valid @RequestPart(value = "postCreateRequest") PostCreateRequest postCreateRequest,
        @RequestPart(value = "attachImageList", required = false) List<MultipartFile> images,
        @AuthenticationPrincipal CustomUserDetails userDetails) {
        PostCreateResult result = postService
            .create(postDtoMapper.toCommand(postCreateRequest, userDetails.getUser(), images));
        return ApiResponse.success(postDtoMapper.toResponse(result));
    }

    @GetMapping
    @ResponseStatus(HttpStatus.OK)
    public ApiResponse<PostListResponse> getPosts(
        @ModelAttribute PostListCondition condition,
        @AuthenticationPrincipal CustomUserDetails userDetails) {
        PostListQuery query = postDtoMapper.toListQuery(condition, userDetails.getUser());
        PostListResult result = postService.getPosts(query);
        return ApiResponse.success(postDtoMapper.toListResponse(result));
    }

    @DeleteMapping("/{postId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public ApiResponse<Void> delete(
        @PathVariable String postId,
        @AuthenticationPrincipal CustomUserDetails userDetails) {
        postService.deletePost(userDetails.getUser(), postId);
        return ApiResponse.success();
    }
}
```

**핵심 규칙**:
- `ApiResponse<T>` 로 항상 래핑
- `@AuthenticationPrincipal CustomUserDetails userDetails` 로 인증 유저 주입
- Controller는 DTO 변환만 담당 (비즈니스 로직 금지)
- API Mapper로 Request → Command/Query, Result → Response 변환. MapStruct를 우선하되, 변환 로직이 복잡하면 수동 `@Component` Mapper도 사용된다.

---

## 2. API DTO (api/v2/dto/)

기본 위치는 `api/v2/dto/request`, `api/v2/dto/response`이다. 기존 도메인의 `api/v2/controller/dto` 구조는 유지하고, 새 도메인은 기본 위치를 우선한다.

```java
// Request - record 사용, @Valid 어노테이션
public record PostCreateRequest(
    @NotBlank(message = "게시글 내용을 입력해 주세요.")
    @Schema(description = "게시글 내용", example = "안녕하세요")
    String content,

    @NotBlank(message = "게시판 id를 입력해 주세요.")
    @Schema(description = "게시판 id", example = "uuid")
    String boardId,

    @NotNull(message = "익명글 여부를 선택해 주세요.")
    @Schema(description = "익명글 여부", example = "false")
    Boolean isAnonymous) {
}

// Response - record 사용, @Builder
@Builder
public record PostCreateResponse(
    @Schema(description = "게시글 id") String id,
    @Schema(description = "게시글 내용") String content,
    @Schema(description = "익명글 여부") Boolean isAnonymous,
    LocalDateTime createdAt,
    LocalDateTime updatedAt) {
}
```

---

## 3. API Mapper (api/v2/mapper/)

단순 필드 매핑은 MapStruct를 우선한다. 요약 문자열, metadata map 구성, 분기 로직처럼 명시적 코드가 더 읽기 쉬운 경우에는 수동 `@Component` Mapper를 사용한다.

```java
@Mapper(componentModel = "spring")
public interface PostDtoMapper {

    @Mapping(target = "writer", source = "user")
    @Mapping(target = "images", source = "files")
    PostCreateCommand toCommand(PostCreateRequest request, User user, List<MultipartFile> files);

    PostCreateResponse toResponse(PostCreateResult result);

    @Mapping(target = "viewer", source = "user")
    PostListQuery toListQuery(PostListCondition condition, User user);
}
```

---

## 4. Service 계층 (V2)

**위치**: `domain/{domain}/service/v2/`

기존 도메인에는 `domain/{domain}/service/implementation/` 컴포넌트를 `service/v2`에서 함께 참조하는 구조도 많다. 새로 만들 때는 `service/v2`를 우선하고, 기존 도메인을 확장할 때는 주변 구조를 따른다.

```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)      // 기본: 읽기 전용
public class PostService {
    private final PostReader postReader;
    private final PostWriter postWriter;
    private final BoardReader boardReader;
    private final BoardConfigReader boardConfigReader;
    private final FileWriter fileWriter;

    @Transactional                    // 쓰기 작업은 명시
    public PostCreateResult create(PostCreateCommand command) {
        User writer = command.writer();
        Board board = boardReader.getById(command.boardId());
        BoardConfig boardConfig = boardConfigReader.getByBoardId(command.boardId());
        List<String> boardAdminIds = boardConfigReader.getAdminIdsByBoardId(command.boardId());

        PostValidator.validateCreate(writer, board, boardConfig, boardAdminIds, command.isAnonymous());

        List<UuidFile> images = (command.images() != null && !command.images().isEmpty())
            ? fileWriter.uploadAndSaveList(command.images(), FilePath.POST)
            : new ArrayList<>();

        Post post = PostMapper.fromCreateCommand(command, writer, board, images);
        Post savedPost = postWriter.save(post);

        return PostMapper.toCreateResult(savedPost, images.stream().map(UuidFile::getFileUrl).toList());
    }

    // 조회는 @Transactional 없이 (클래스 레벨 readOnly 적용)
    public PostDetailResult getPostDetail(PostDetailQuery query) {
        Post post = postReader.findById(query.postId());
        // ...
        return PostMapper.toPostDetailResult(post, ...);
    }
}
```

**핵심 규칙**:
- 클래스 레벨 `@Transactional(readOnly = true)` 또는 메서드별 `@Transactional(readOnly = true)`를 사용한다.
- 쓰기 메서드는 `@Transactional`을 명시한다.
- Service는 Reader/Writer/Resolver/Manager/Validator 등 implementation 컴포넌트에 의존한다.
- Repository 직접 의존은 피한다. 단, 단순 조회 전용 관리자/레거시 서비스의 QueryRepository 직접 사용은 기존 패턴을 확인하고 작은 범위에서만 허용한다.
- 검증은 static Validator util 또는 implementation Validator 컴포넌트에 위임한다.
- Entity ↔ DTO 변환은 static Mapper, MapStruct, 수동 Component Mapper 중 주변 패턴에 맞춘다.

---

## 5. Service DTO (service/v2/dto/)

```java
// Command - 쓰기 작업 입력
public record PostCreateCommand(
    String content,
    String boardId,
    Boolean isAnonymous,
    User writer,
    List<MultipartFile> images) {
}

// Query - 읽기 작업 입력
public record PostListQuery(
    List<String> boardIds,
    String cursor,
    Integer size,
    String keyword,
    User viewer) {
}

// Result - 결과 반환
public record PostCreateResult(
    String id,
    String content,
    List<String> fileUrlList,
    Boolean isAnonymous,
    LocalDateTime createdAt,
    LocalDateTime updatedAt,
    String boardName) {
}
```

---

## 6. implementation/ 계층 개요

**위치**: `domain/{domain}/service/v2/implementation/` 또는 기존 도메인의 `domain/{domain}/service/implementation/`

Reader/Writer 외에도 도메인 복잡도에 따라 다양한 컴포넌트를 둔다.

| 클래스 | 어노테이션 | 역할 |
|--------|-----------|------|
| `XxxReader` | `@Component` + `@Transactional(readOnly = true)` | DB 조회, 예외 포장 |
| `XxxWriter` | `@Component` + `@Transactional` | 저장/수정/삭제 |
| `XxxValidator` | `@Component` + `@Transactional(readOnly = true)` | 비즈니스 규칙 검증 |
| `XxxLogWriter` | `@Component` + `@Transactional` | 감사 로그 기록 |
| `XxxPolicyReader` | `@Component` + `@Transactional(readOnly = true)` | 정책 원시값 조회 |
| `XxxPeriodResolver` | `@Component` + `@Transactional(readOnly = true)` | 기간 판별 비즈니스 로직 |
| `XxxManager` | `@Component` | 파일/이미지/외부 연동 등 하위 흐름 조율 |
| `XxxAggregator` | `@Component` | 여러 조회 결과 조합 |

> 모두 `@RequiredArgsConstructor`를 사용하며, 서로 의존할 수 있다.
> (예: `LockerValidator` → `LockerPeriodResolver`, `LockerReader` 의존)

---

## 7. Reader

```java
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LockerReader {
    private final LockerRepository lockerRepository;
    private final LockerQueryRepository lockerQueryRepository;

    // 비관적 락이 필요한 쓰기 전용 조회 (Service의 @Transactional 내부에서 호출)
    public Locker findByIdForWrite(String lockerId) {
        return lockerRepository.findByIdForWrite(lockerId)
            .orElseThrow(LockerErrorCode.LOCKER_NOT_FOUND::toBaseException);
    }

    // Optional 반환 - 없어도 정상인 경우
    public Optional<Locker> findByUserId(String userId) {
        return lockerRepository.findByUser_Id(userId);
    }

    // boolean 반환
    public boolean existsByUserId(String userId) {
        return lockerRepository.findByUser_Id(userId).isPresent();
    }

    // QueryRepository 위임 (복잡한 조건 검색)
    public Page<Locker> findLockerList(String userKeyword, LockerName location,
        Boolean isActive, Boolean isOccupied, Boolean isExpired, Pageable pageable) {
        return lockerQueryRepository.findLockers(userKeyword, location, isActive, isOccupied, isExpired, pageable);
    }

    // 집계 - Map으로 반환
    public Map<String, LockerCountByLocation> countGroupByLocation() {
        return lockerRepository.countGroupByLocation().stream()
            .collect(Collectors.toMap(LockerCountByLocation::locationId, Function.identity()));
    }
}
```

**핵심 규칙**:
- `@Component` + `@Transactional(readOnly = true)`
- 조회 실패 → `orElseThrow(XxxErrorCode.SOME_ERROR::toBaseException)` (`XxxErrorCode` enum은 `BaseResponseCode` 구현)
- 없어도 정상인 경우 → `Optional<T>` 반환
- 복잡한 쿼리 → `QueryRepository` 위임

---

## 8. Writer

```java
@Component
@RequiredArgsConstructor
@Transactional
public class LockerLogWriter {
    private final LockerLogRepository lockerLogRepository;

    public void logRegister(Locker locker, User user) {
        save(locker, user.getEmail(), user.getName(), LockerLogAction.REGISTER, "사물함 신청");
    }

    public void logReturn(Locker locker, User user) {
        save(locker, user.getEmail(), user.getName(), LockerLogAction.RETURN, "사물함 반납");
    }

    public void logAdminAssign(Locker locker, User admin) {
        save(locker, admin.getEmail(), admin.getName(), LockerLogAction.ADMIN_ASSIGN, "관리자 사물함 배정");
    }

    public void logAdminRelease(Locker locker, User admin) {
        save(locker, admin.getEmail(), admin.getName(), LockerLogAction.ADMIN_RELEASE, "관리자 사물함 회수");
    }

    private void save(Locker locker, String email, String name, LockerLogAction action, String message) {
        lockerLogRepository.save(LockerLog.of(
            locker.getLockerNumber(), locker.getLocation().getName(), email, name, action, message));
    }
}
```

```java
@Component
@RequiredArgsConstructor
@Transactional
public class LockerPolicyWriter {
    private final TextFieldRepository textFieldRepository;
    private final FlagRepository flagRepository;

    public void updateRegisterPeriod(LocalDateTime start, LocalDateTime end, LocalDateTime expiredAt) {
        setOrUpdateDateTime(StaticValue.REGISTER_START_AT, start);
        setOrUpdateDateTime(StaticValue.REGISTER_END_AT, end);
        setOrUpdateDateTime(StaticValue.EXPIRED_AT, expiredAt);
    }

    public void updateRegisterStatus(boolean status) {
        flagRepository.findByKey(StaticValue.LOCKER_ACCESS)
            .ifPresentOrElse(flag -> flag.setValue(status),
                () -> flagRepository.save(Flag.of(StaticValue.LOCKER_ACCESS, status)));
    }

    private void setOrUpdateDateTime(String key, LocalDateTime value) {
        textFieldRepository.findByKey(key)
            .ifPresentOrElse(
                tf -> tf.setValue(value.format(StaticValue.LOCKER_DATE_TIME_FORMATTER)),
                () -> textFieldRepository.save(
                    TextField.of(key, value.format(StaticValue.LOCKER_DATE_TIME_FORMATTER))));
    }
}
```

**핵심 규칙**:
- `@Component` + `@Transactional` (클래스 레벨)
- 로그성 Writer는 도메인 Writer와 분리 (예: `LockerLogWriter`)
- `ifPresentOrElse` 패턴으로 upsert 처리

---

## 9. Validator

Validator는 두 패턴이 모두 사용된다.

- 의존성이 필요한 검증: `service/v2/implementation/XxxValidator`의 `@Component`로 둔다.
- 순수 도메인 값 검증: `service/v2/util/XxxValidator`의 static util로 둔다.

```java
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LockerValidator {
    private final LockerPeriodResolver lockerPeriodResolver;  // implementation 내부 참조 가능
    private final LockerReader lockerReader;

    // 기간 검증
    public void validateRegisterPeriod(LocalDateTime time) {
        if (!lockerPeriodResolver.isRegisterActive(time)) {
            throw LockerErrorCode.LOCKER_REGISTER_NOT_ALLOWED.toBaseException();
        }
    }

    // 상태 검증
    public void validateRegisterAvailable(Locker locker) {
        LockerStatus status = locker.getStatus();
        if (status == LockerStatus.IN_USE) {
            throw LockerErrorCode.LOCKER_IN_USE.toBaseException();
        }
        if (status == LockerStatus.DISABLED) {
            throw LockerErrorCode.LOCKER_DISABLED.toBaseException();
        }
    }

    // 소유자 검증
    public void validateOwner(Locker locker, User user) {
        locker.getUser()
            .filter(owner -> owner.getId().equals(user.getId()))
            .orElseThrow(LockerErrorCode.LOCKER_NOT_OWNER::toBaseException);
    }

    // 중복 보유 검증 (다른 Reader 의존)
    public void validateUserNotHavingLocker(String userId) {
        if (lockerReader.existsByUserId(userId)) {
            throw LockerErrorCode.LOCKER_USER_ALREADY_HAS_LOCKER.toBaseException();
        }
    }

    // 선후관계 검증
    public void validatePeriodOrder(LocalDateTime start, LocalDateTime end, LocalDateTime expiredAt) {
        if (!start.isBefore(end)) throw LockerErrorCode.LOCKER_PERIOD_START_AFTER_END.toBaseException();
        if (!end.isBefore(expiredAt)) throw LockerErrorCode.LOCKER_PERIOD_END_AFTER_EXPIRE.toBaseException();
    }
}
```

**핵심 규칙**:
- 의존성이 있는 Validator는 `@Component` + `@Transactional(readOnly = true)`
- 의존성이 없는 Validator는 `@NoArgsConstructor(access = AccessLevel.PRIVATE)` static util
- 관심사별 메서드 분리 (기간 / 상태 / 소유자 / 중복 등)
- implementation 내 다른 컴포넌트에 의존 가능
- 예외는 `throw XxxErrorCode.SOME_ERROR.toBaseException()`

---

## 10. 전문화 컴포넌트 (PeriodResolver, PolicyReader)

복잡한 도메인은 Reader/Writer 외에 비즈니스 로직 전담 컴포넌트를 둔다.

```java
// 정책 원시값 조회 전담 (DB/Flag/TextField에서 값 읽기)
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LockerPolicyReader {
    private final FlagReader flagReader;
    private final TextFieldReader textFieldReader;

    public boolean getLockerAccessStatusFlag() {
        return flagReader.findValueByKey(StaticValue.LOCKER_ACCESS);
    }

    public LocalDateTime findExpireDate() {
        return LocalDateTime.parse(
            textFieldReader.findValueByKey(StaticValue.EXPIRED_AT)
                .orElseThrow(LockerErrorCode.LOCKER_EXPIRE_DATE_NOT_SET::toBaseException),
            StaticValue.LOCKER_DATE_TIME_FORMATTER);
    }

    public Optional<LocalDateTime> findRegisterStartDate() {
        return textFieldReader.findValueByKey(StaticValue.REGISTER_START_AT)
            .map(v -> LocalDateTime.parse(v, StaticValue.LOCKER_DATE_TIME_FORMATTER));
    }
}

// 기간 판별 비즈니스 로직 전담 (원시값 조회는 PolicyReader에 위임)
@Component
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LockerPeriodResolver {
    private final LockerPolicyReader lockerPolicyReader;  // 정책값 조회 위임

    public boolean isRegisterActive(LocalDateTime now) {
        boolean flag = lockerPolicyReader.getLockerAccessStatusFlag();
        return flag && isOnPeriod(now,
            lockerPolicyReader.findRegisterStartDate(),
            lockerPolicyReader.findRegisterEndDate());
    }

    public LockerPeriodStatusResult resolveCurrentPhase(LocalDateTime now) {
        if (lockerPolicyReader.getLockerAccessStatusFlag()) {
            return resolvePhase(now, LockerPeriodPhase.APPLY,
                lockerPolicyReader.findRegisterStartDate(),
                lockerPolicyReader.findRegisterEndDate());
        }
        if (lockerPolicyReader.getLockerExtendStatusFlag()) {
            return resolvePhase(now, LockerPeriodPhase.EXTEND,
                lockerPolicyReader.findExtendStartDate(),
                lockerPolicyReader.findExtendEndDate());
        }
        return LockerPeriodStatusResult.builder().phase(LockerPeriodPhase.CLOSED).build();
    }

    private boolean isOnPeriod(LocalDateTime now, Optional<LocalDateTime> start, Optional<LocalDateTime> end) {
        if (start.isEmpty() || end.isEmpty()) return false;
        return !now.isBefore(start.get()) && !now.isAfter(end.get());
    }
}
```

**설계 원칙**:
- `PolicyReader`: 원시값(flag, datetime) 조회만 담당
- `PeriodResolver`: flag + 기간 조합 판별 로직만 담당 → `PolicyReader`에 위임
- 단일 책임 원칙(SRP)에 따라 역할을 분리할수록 테스트·유지보수 용이

---

## 11. Service와 implementation 연결 예시

```java
@Service
@RequiredArgsConstructor
public class LockerService {   // 클래스 레벨 @Transactional 없음 — 메서드별 명시
    private final LockerReader lockerReader;
    private final LockerLocationReader lockerLocationReader;
    private final LockerPolicyReader lockerPolicyReader;
    private final LockerPeriodResolver lockerPeriodResolver;
    private final LockerLogWriter lockerLogWriter;
    private final LockerValidator lockerValidator;
    private final UserReader userReader;

    @Transactional
    public void registerLocker(String lockerId, String userId) {
        User user = userReader.findUserById(userId);
        lockerValidator.validateRegisterPeriod(LocalDateTime.now());     // 기간 검증

        Locker locker = lockerReader.findByIdForWrite(lockerId);         // 비관적 락 조회
        lockerValidator.validateRegisterAvailable(locker);               // 상태 검증

        // 기존 사물함 보유 시 자동 반납 (Optional 활용)
        lockerReader.findByUserId(user.getId()).ifPresent(existingLocker -> {
            existingLocker.returnLocker();
            lockerLogWriter.logReturn(existingLocker, user);
        });

        locker.register(user, lockerPolicyReader.findExpireDate());      // 도메인 메서드 호출
        lockerLogWriter.logRegister(locker, user);                       // 로그 기록
    }

    @Transactional(readOnly = true)
    public LockerFloorListResult findAllFloors() {
        List<LockerLocation> locations = lockerLocationReader.findAll();
        Map<String, LockerCountByLocation> counts = lockerReader.countGroupByLocation();
        // ...
    }
}
```

**Service 트랜잭션 패턴**:
- 클래스 레벨 `@Transactional(readOnly = true)` **또는** 메서드별 명시 — 둘 다 사용됨
- 쓰기 메서드: `@Transactional`
- 읽기 메서드: `@Transactional(readOnly = true)` 또는 생략(클래스 레벨 적용 시)

---

## 12. Repository 계층

### JpaRepository

```java
@Repository
public interface PostRepository extends JpaRepository<Post, String> {
    // 메서드 이름 쿼리
    Optional<Post> findByIdAndIsDeletedFalse(String postId);
    Page<Post> findAllByBoard_IdAndIsDeletedIsFalseOrderByCreatedAtDesc(String boardId, Pageable pageable);

    // JPQL
    @Query("SELECT p FROM Post p LEFT JOIN FETCH p.writer w WHERE p.board.id = :boardId ...")
    Page<Post> findPostsByBoardWithFilters(@Param("boardId") String boardId, ...);

    // Soft Delete 벌크 수정
    @Query("UPDATE Post p SET p.isDeleted = true WHERE p.board.id = :boardId AND p.isDeleted = false")
    @Modifying
    int deleteAllPostsByBoardId(@Param("boardId") String boardId);
}
```

### QueryRepository (QueryDSL)

```java
@Repository
@RequiredArgsConstructor
public class PostQueryRepository {
    private final JPAQueryFactory jpaQueryFactory;

    public Slice<PostCursorResult> findPostsWithCursor(
        List<String> boardIds, String cursorCreatedAt,
        String cursorId, int size, String keyword) {

        QPost post = QPost.post;
        BooleanExpression condition = post.isDeleted.isFalse();

        if (boardIds != null && !boardIds.isEmpty()) {
            condition = condition.and(post.board.id.in(boardIds));
        }

        List<PostCursorResult> content = jpaQueryFactory
            .select(/* projection */)
            .from(post)
            .where(condition)
            .orderBy(post.createdAt.desc(), post.id.desc())
            .limit(size + 1)
            .fetch();

        boolean hasNext = content.size() > size;
        if (hasNext) content.remove(size);

        return new SliceImpl<>(content, PageRequest.of(0, size), hasNext);
    }
}
```

---

## 13. Entity 계층

```java
@Getter
@Entity
@Builder(access = AccessLevel.PROTECTED)
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Table(name = "tb_post", indexes = {
    @Index(name = "board_id_index", columnList = "board_id"),
    @Index(name = "post_cursor_index", columnList = "created_at, id")
})
public class Post extends BaseEntity {

    @Lob
    @Column(columnDefinition = "TEXT", name = "content", nullable = false)
    private String content;

    @ManyToOne(targetEntity = User.class)
    @JoinColumn(name = "user_id", nullable = false)
    private User writer;

    @Column(name = "is_deleted")
    @Builder.Default
    @ColumnDefault("false")
    private Boolean isDeleted = false;

    @ManyToOne(targetEntity = Board.class)
    @JoinColumn(name = "board_id", nullable = false)
    private Board board;

    @OneToMany(cascade = {CascadeType.REMOVE, CascadeType.PERSIST}, mappedBy = "post")
    @Builder.Default
    private List<PostAttachImage> postAttachImageList = new ArrayList<>();

    // 정적 팩토리 메서드
    public static Post of(String content, User writer, Boolean isAnonymous, Board board,
                          List<UuidFile> images) {
        Post post = Post.builder()
            .content(content).writer(writer).isAnonymous(isAnonymous).board(board).build();
        // 이미지 연관관계 설정
        List<PostAttachImage> attachImages = images.stream()
            .map(uuidFile -> PostAttachImage.of(post, uuidFile)).toList();
        post.setPostAttachFileList(attachImages);
        return post;
    }

    // 도메인 로직
    public void updateContentAndImages(String content, List<PostAttachImage> images) {
        this.content = content;
        this.postAttachImageList = images;
    }
}
```

**핵심 규칙**:
- `BaseEntity` 상속 (UUID id, createdAt, updatedAt 자동 제공)
- Builder 접근제어: `access = AccessLevel.PROTECTED`
- 생성자 접근제어: `@NoArgsConstructor(PROTECTED)`, `@AllArgsConstructor(PRIVATE)`
- 정적 팩토리 메서드 `of(...)` 로 Entity 생성
- 테이블명: `tb_` 접두사 사용

---

## 14. BaseEntity / AuditableEntity

```java
// AuditableEntity
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public class AuditableEntity {
    @CreatedDate
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}

// BaseEntity
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public class BaseEntity extends AuditableEntity {
    @Id
    @UuidGenerator
    @Column(name = "id", nullable = false, unique = true)
    private String id;
}
```

---

## 15. ErrorCode 패턴

```java
// app-main/shared/exception/errorcode 아래 도메인별 enum
@RequiredArgsConstructor(access = AccessLevel.PROTECTED)
public enum PostErrorCode implements BaseResponseCode {
    POST_NOT_FOUND(HttpStatus.NOT_FOUND, "POST_404_001", "게시글을 찾을 수 없습니다"),
    POST_FORBIDDEN(HttpStatus.FORBIDDEN, "POST_403_001", "게시글에 대한 권한이 없습니다");

    private final HttpStatus status;
    private final String code;
    private final String message;

    @Override
    public String getCode() { return code; }

    @Override
    public String getMessage() { return message; }

    @Override
    public HttpStatus getStatus() { return status; }
}

// 사용 패턴
postRepository.findById(postId)
    .orElseThrow(PostErrorCode.POST_NOT_FOUND::toBaseException);
```

`toBaseException()`은 `BaseResponseCode`의 default method를 사용하며 `BaseRunTimeV2Exception`을 생성한다.

---

## 16. ApiResponse

```java
@Getter
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private String code;
    private String message;
    private T data;

    public static <T> ApiResponse<T> success(T data) { ... }
    public static ApiResponse<Void> success() { ... }
}
```
