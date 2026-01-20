# Spring Boot 3.x + Kotlin Patterns

## Layer Examples

### Controller
```kotlin
@RestController
@RequestMapping("/api/v1/users")
@Validated
class UserController(private val userService: UserService) {

    @GetMapping("/{id}")
    fun getUser(@PathVariable id: Long): ResponseEntity<UserResponse> =
        ResponseEntity.ok(userService.findById(id))

    @PostMapping
    fun createUser(@Valid @RequestBody request: CreateUserRequest): ResponseEntity<UserResponse> =
        ResponseEntity.status(HttpStatus.CREATED).body(userService.create(request))

    @PutMapping("/{id}")
    fun updateUser(
        @PathVariable id: Long,
        @Valid @RequestBody request: UpdateUserRequest
    ): ResponseEntity<UserResponse> =
        ResponseEntity.ok(userService.update(id, request))

    @DeleteMapping("/{id}")
    fun deleteUser(@PathVariable id: Long): ResponseEntity<Unit> {
        userService.delete(id)
        return ResponseEntity.noContent().build()
    }
}
```

### Service
```kotlin
@Service
@Transactional(readOnly = true)
class UserService(private val userRepository: UserRepository) {

    fun findById(id: Long): UserResponse {
        val user = userRepository.findByIdOrNull(id)
            ?: throw UserNotFoundException(id)
        return UserResponse.from(user)
    }

    fun findAll(): List<UserResponse> =
        userRepository.findAll().map { UserResponse.from(it) }

    @Transactional
    fun create(request: CreateUserRequest): UserResponse {
        val user = request.toEntity()
        return UserResponse.from(userRepository.save(user))
    }

    @Transactional
    fun update(id: Long, request: UpdateUserRequest): UserResponse {
        val user = userRepository.findByIdOrNull(id)
            ?: throw UserNotFoundException(id)
        user.update(request.name, request.age)
        return UserResponse.from(user)
    }

    @Transactional
    fun delete(id: Long) {
        if (!userRepository.existsById(id)) {
            throw UserNotFoundException(id)
        }
        userRepository.deleteById(id)
    }
}
```

### Repository
```kotlin
@Repository
interface UserRepository : JpaRepository<User, Long> {
    fun findByEmail(email: String): User?
    fun findAllByStatus(status: UserStatus): List<User>
    fun existsByEmail(email: String): Boolean

    @Query("SELECT u FROM User u WHERE u.createdAt >= :date")
    fun findRecentUsers(@Param("date") date: LocalDateTime): List<User>
}
```

## DTO Patterns

### Request DTO
```kotlin
data class CreateUserRequest(
    @field:NotBlank(message = "Name is required")
    @field:Size(min = 2, max = 50)
    val name: String,

    @field:NotBlank
    @field:Email
    val email: String,

    @field:NotNull
    @field:Min(18)
    val age: Int
) {
    fun toEntity() = User(name = name, email = email, age = age)
}

// Partial update용
data class UpdateUserRequest(
    val name: String? = null,
    val age: Int? = null
) {
    fun applyTo(user: User) {
        name?.let { user.name = it }
        age?.let { user.age = it }
    }
}
```

### Response DTO
```kotlin
data class UserResponse(
    val id: Long,
    val name: String,
    val email: String,
    val status: UserStatus,
    val createdAt: LocalDateTime
) {
    companion object {
        fun from(user: User) = UserResponse(
            id = user.id!!,
            name = user.name,
            email = user.email,
            status = user.status,
            createdAt = user.createdAt
        )
    }
}

// Paginated response
data class PageResponse<T>(
    val content: List<T>,
    val totalPages: Int,
    val totalElements: Long,
    val number: Int,
    val size: Int
) {
    companion object {
        fun <T, R> from(page: Page<T>, mapper: (T) -> R) = PageResponse(
            content = page.content.map(mapper),
            totalPages = page.totalPages,
            totalElements = page.totalElements,
            number = page.number,
            size = page.size
        )
    }
}
```

## Entity Pattern

```kotlin
@Entity
@Table(name = "users")
@EntityListeners(AuditingEntityListener::class)
class User(
    @Column(nullable = false, length = 50)
    var name: String,

    @Column(nullable = false, unique = true)
    val email: String,

    @Column(nullable = false)
    var age: Int,

    @Enumerated(EnumType.STRING)
    var status: UserStatus = UserStatus.ACTIVE
) {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null

    @CreatedDate
    @Column(nullable = false, updatable = false)
    lateinit var createdAt: LocalDateTime
        private set

    @LastModifiedDate
    @Column(nullable = false)
    lateinit var updatedAt: LocalDateTime
        private set

    fun update(name: String, age: Int) {
        this.name = name
        this.age = age
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is User) return false
        return id != null && id == other.id
    }

    override fun hashCode(): Int = id?.hashCode() ?: 0
}
```

## Exception Handling

```kotlin
// Custom exceptions
class UserNotFoundException(id: Long) : RuntimeException("User not found: $id")
class DuplicateEmailException(email: String) : RuntimeException("Email exists: $email")

// Global handler
@RestControllerAdvice
class GlobalExceptionHandler {
    private val logger = LoggerFactory.getLogger(javaClass)

    @ExceptionHandler(UserNotFoundException::class)
    fun handleNotFound(e: UserNotFoundException): ResponseEntity<ErrorResponse> {
        logger.error("Not found: ${e.message}")
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(ErrorResponse(HttpStatus.NOT_FOUND.value(), e.message ?: "Not found"))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(e: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val message = e.bindingResult.allErrors.joinToString(", ") {
            it.defaultMessage ?: "Validation error"
        }
        return ResponseEntity.badRequest()
            .body(ErrorResponse(HttpStatus.BAD_REQUEST.value(), message))
    }
}

data class ErrorResponse(val status: Int, val message: String)
```

## Testing

### Controller Test
```kotlin
@WebMvcTest(UserController::class)
class UserControllerTest {
    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockkBean
    private lateinit var userService: UserService

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @Test
    fun `get user returns 200`() {
        val response = UserResponse(1L, "John", "john@test.com", UserStatus.ACTIVE, LocalDateTime.now())
        every { userService.findById(1L) } returns response

        mockMvc.perform(get("/api/v1/users/1"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.id").value(1L))
    }

    @Test
    fun `create user returns 201`() {
        val request = CreateUserRequest("John", "john@test.com", 25)
        val response = UserResponse(1L, "John", "john@test.com", UserStatus.ACTIVE, LocalDateTime.now())
        every { userService.create(any()) } returns response

        mockMvc.perform(
            post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
    }
}
```

### Service Test
```kotlin
@ExtendWith(MockKExtension::class)
class UserServiceTest {
    @MockK
    private lateinit var userRepository: UserRepository

    @InjectMockKs
    private lateinit var userService: UserService

    @Test
    fun `findById throws when not found`() {
        every { userRepository.findByIdOrNull(1L) } returns null

        assertThrows<UserNotFoundException> {
            userService.findById(1L)
        }
    }

    @Test
    fun `create saves and returns response`() {
        val request = CreateUserRequest("John", "john@test.com", 25)
        val savedUser = User("John", "john@test.com", 25).apply {
            ReflectionTestUtils.setField(this, "id", 1L)
        }
        every { userRepository.save(any()) } returns savedUser

        val result = userService.create(request)

        assertThat(result.id).isEqualTo(1L)
        verify(exactly = 1) { userRepository.save(any()) }
    }
}
```

### Repository Test
```kotlin
@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
class UserRepositoryTest {
    @Autowired
    private lateinit var userRepository: UserRepository

    @Test
    fun `findByEmail returns user`() {
        val user = User("John", "john@test.com", 25)
        userRepository.save(user)

        val found = userRepository.findByEmail("john@test.com")

        assertThat(found).isNotNull
        assertThat(found?.name).isEqualTo("John")
    }
}
```

## Extension Functions

```kotlin
// Repository extension
fun UserRepository.findByEmailOrThrow(email: String): User =
    findByEmail(email) ?: throw UserNotFoundException(email)

// Entity to response
fun User.toResponse() = UserResponse.from(this)

// List mapping
fun List<User>.toResponses() = map { it.toResponse() }
```
