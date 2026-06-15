---
name: causw-test-guide
description: CAUSW_backend 프로젝트의 테스트 코드 작성 가이드. 단위 테스트, 통합 테스트, Repository 테스트, Fixture 클래스 생성 시 사용. 테스트 코드 작성을 요청받거나("테스트 코드 작성해줘", "test code 작성", "테스트 만들어줘") 테스트 파일을 새로 생성할 때 반드시 이 스킬을 사용한다.
---

# CAUSW 테스트 코드 작성 가이드

## 파일 위치

테스트 파일은 main과 동일한 패키지 경로의 test 디렉토리에 생성한다.

```
src/main/java/net/causw/app/main/domain/foo/service/FooService.java
→ src/test/java/net/causw/app/main/domain/foo/service/FooServiceTest.java
```

## 클래스 명명

| 종류 | 형식 |
|------|------|
| 단위 테스트 | `{클래스명}Test` |
| 통합 테스트 | `{클래스명}IntegrationTest` |
| Repository 테스트 | `{클래스명}RepositoryTest` |

## 메서드 명명

```
given{조건}_when{행위}_then{결과}
```

- 한글 `@DisplayName` 필수
- `@Nested` + `@DisplayName`으로 메서드/기능 단위 그룹화 권장

## 테스트 구조

```java
@Test
@DisplayName("설명")
void given조건_when행위_then결과() {
    // given

    // when

    // then
}
```

when/then 분리가 애매하면 `// when & then`으로 합쳐서 작성.

---

## 단위 테스트 (Service)

```java
@ExtendWith(MockitoExtension.class)
class FooServiceTest {

    @InjectMocks
    private FooService fooService;

    @Mock
    private FooReader fooReader;

    @Nested
    @DisplayName("foo 조회 (findFoo)")
    class FindFooTest {

        @Test
        @DisplayName("성공: 정상 조회")
        void givenValidId_whenFindFoo_thenReturnFoo() {
            // given
            Long id = 1L;
            Foo mockFoo = mock(Foo.class);
            given(fooReader.findById(id)).willReturn(mockFoo);

            // when
            Foo result = fooService.findFoo(id);

            // then
            assertThat(result).isEqualTo(mockFoo);
        }

        @Test
        @DisplayName("실패: 존재하지 않는 ID면 예외 발생")
        void givenInvalidId_whenFindFoo_thenThrowException() {
            // given
            Long id = 999L;
            given(fooReader.findById(id))
                .willThrow(FooErrorCode.NOT_FOUND.toBaseException());

            // when & then
            assertThatThrownBy(() -> fooService.findFoo(id))
                .isInstanceOf(BaseRunTimeV2Exception.class)
                .hasFieldOrPropertyWithValue("errorCode", FooErrorCode.NOT_FOUND);
        }
    }
}
```

- Mock: `@Mock` 필드 또는 `mock(클래스.class)` 인라인
- private 필드(id 등) 설정: `ReflectionTestUtils.setField(obj, "fieldName", value)`
- BDD 스타일: `given(...).willReturn(...)`, `doThrow(...).when(...)`

---

## Fixture 클래스

테스트 데이터는 Fixture 클래스로 분리한다. 위치는 같은 패키지 또는 `util/` 하위.

```java
public class FooFixture {

    public static Foo createDefault() {
        return Foo.of("userId", FooKey.KEY_A, true);
    }

    public static Foo createWithId(Long id) {
        Foo foo = createDefault();
        ReflectionTestUtils.setField(foo, "id", id);
        return foo;
    }
}
```

- 정적 팩토리 메서드만 사용
- 여러 테스트에서 공유하는 데이터는 Fixture에 모아둔다

---

## Assertion

AssertJ만 사용한다. JUnit 기본 Assertions (`assertEquals`, `assertTrue`) 사용 금지.

```java
// ✅ AssertJ
assertThat(result.getName()).isEqualTo("홍길동");
assertThat(list).hasSize(3).extracting("name").containsExactly("A", "B", "C");
assertThatThrownBy(() -> service.doSomething())
    .isInstanceOf(BaseRunTimeV2Exception.class);

// ❌ JUnit
assertEquals("홍길동", result.getName());
```

---

## Repository / 통합 테스트

상세 패턴은 [references/integration-test.md](references/integration-test.md) 참고.

---

## import 컨벤션

```java
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.BDDMockito.*;
import static org.mockito.Mockito.*;
```
