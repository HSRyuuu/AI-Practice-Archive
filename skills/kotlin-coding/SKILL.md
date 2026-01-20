---
name: kotlin-coding
description: "Kotlin 코딩 규칙 및 Spring Boot 3.x 패턴 가이드. (1) Kotlin 코드 작성 시, (2) Spring Boot + Kotlin 프로젝트, (3) JPA Entity/DTO 패턴, (4) MockK 기반 테스트 작성 시 사용."
---

# Kotlin Coding Conventions

## Kotlin-Specific Patterns (Not Standard Java)

### Validation Annotations
Kotlin data class에서 validation은 `@field:` prefix 필수:
```kotlin
data class CreateUserRequest(
    @field:NotBlank val name: String,
    @field:Email val email: String
)
```

### Nullable Handling in Repository
Spring Data JPA의 `findByIdOrNull()` 확장 함수 활용:
```kotlin
val user = repository.findByIdOrNull(id)
    ?: throw UserNotFoundException(id)
```

### JPA Entity Pattern
- `data class` 사용 금지 (프록시, 지연로딩 이슈)
- ID는 nullable로 선언, body에서 초기화
- `equals/hashCode`는 ID 기반으로 직접 구현

```kotlin
@Entity
class User(
    @Column(nullable = false)
    var name: String,
    val email: String
) {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is User) return false
        return id != null && id == other.id
    }
    override fun hashCode(): Int = id?.hashCode() ?: 0
}
```

### DTO Factory Pattern
companion object의 `from()` 팩토리 메서드:
```kotlin
data class UserResponse(val id: Long, val name: String) {
    companion object {
        fun from(user: User) = UserResponse(
            id = user.id!!,
            name = user.name
        )
    }
}
```

### Transaction Management
클래스 레벨 `readOnly = true`, 쓰기 메서드만 `@Transactional` override:
```kotlin
@Service
@Transactional(readOnly = true)
class UserService(private val userRepository: UserRepository) {

    fun findById(id: Long): UserResponse { /* read */ }

    @Transactional
    fun create(request: CreateUserRequest): UserResponse { /* write */ }
}
```

### Constructor Injection
`@Autowired` 불필요, primary constructor에 직접 선언:
```kotlin
@RestController
class UserController(private val userService: UserService)
```

## Testing with MockK

MockK는 Kotlin 전용 mocking 라이브러리. Mockito와 다른 문법 주의:

```kotlin
@ExtendWith(MockKExtension::class)
class UserServiceTest {
    @MockK
    private lateinit var userRepository: UserRepository

    @InjectMockKs
    private lateinit var userService: UserService

    @Test
    fun `create user success`() {
        every { userRepository.save(any()) } returns savedUser

        val result = userService.create(request)

        verify(exactly = 1) { userRepository.save(any()) }
    }
}
```

## 상세 참조

- Spring Boot 레이어별 상세 패턴: `references/spring-boot.md`
- 디자인 패턴 구현 예제: `references/design-patterns.md`
