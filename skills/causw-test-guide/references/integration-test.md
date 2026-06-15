# Repository / 통합 테스트 패턴

## Repository 테스트

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@ActiveProfiles("test")
class FooRepositoryTest {

    @Autowired
    private FooRepository fooRepository;

    @Test
    @DisplayName("userId와 settingKey로 조회 성공")
    void givenUserIdAndKey_whenFindByUserIdAndSettingKey_thenReturnEntity() {
        // given
        Foo foo = FooFixture.createDefault();
        fooRepository.save(foo);

        // when
        Optional<Foo> result = fooRepository.findByUserIdAndSettingKey(
            foo.getUserId(), foo.getSettingKey());

        // then
        assertThat(result).isPresent();
        assertThat(result.get().getUserId()).isEqualTo(foo.getUserId());
    }
}
```

- `Replace.NONE`: 실제 DB 사용 (제거 시 H2 인메모리 DB 사용)
- `@ActiveProfiles("test")`: `application-test.yml` 적용

---

## 통합 테스트 (Controller)

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class FooApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /api/foo/{id} - 정상 조회")
    void givenValidId_whenGetFoo_thenReturn200() throws Exception {
        // given
        Long id = 1L;

        // when & then
        mockMvc.perform(get("/api/foo/{id}", id)
                .contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id));
    }
}
```
