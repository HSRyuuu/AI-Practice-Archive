# Spring Boot 3.x + Java Patterns

## Layer Examples

### Controller
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {
    private final UserService userService;

    @GetMapping("/{id}")
    public ResponseEntity<UserResponse> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(userService.findById(id));
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(userService.create(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserResponse> updateUser(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(userService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
```

### Service
```java
public interface UserService {
    UserResponse findById(Long id);
    List<UserResponse> findAll();
    UserResponse create(CreateUserRequest request);
    UserResponse update(Long id, UpdateUserRequest request);
    void delete(Long id);
}

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;

    @Override
    public UserResponse findById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
        return UserResponse.from(user);
    }

    @Override
    public List<UserResponse> findAll() {
        return userRepository.findAll().stream()
                .map(UserResponse::from)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public UserResponse create(CreateUserRequest request) {
        User user = request.toEntity();
        return UserResponse.from(userRepository.save(user));
    }

    @Override
    @Transactional
    public UserResponse update(Long id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(id));
        user.update(request.getName(), request.getAge());
        return UserResponse.from(user);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        if (!userRepository.existsById(id)) {
            throw new UserNotFoundException(id);
        }
        userRepository.deleteById(id);
    }
}
```

### Repository
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    List<User> findAllByStatus(UserStatus status);
    boolean existsByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.createdAt >= :date")
    List<User> findRecentUsers(@Param("date") LocalDateTime date);
}
```

## DTO Patterns

### Request DTO
```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CreateUserRequest {
    @NotBlank(message = "Name is required")
    @Size(min = 2, max = 50)
    private String name;

    @NotBlank
    @Email
    private String email;

    @NotNull
    @Min(18)
    private Integer age;

    @Builder
    public CreateUserRequest(String name, String email, Integer age) {
        this.name = name;
        this.email = email;
        this.age = age;
    }

    public User toEntity() {
        return User.builder()
                .name(name)
                .email(email)
                .age(age)
                .build();
    }
}

// Partial update
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UpdateUserRequest {
    private String name;
    private Integer age;

    @Builder
    public UpdateUserRequest(String name, Integer age) {
        this.name = name;
        this.age = age;
    }

    public void applyTo(User user) {
        if (name != null) user.updateName(name);
        if (age != null) user.updateAge(age);
    }
}
```

### Response DTO
```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserResponse {
    private Long id;
    private String name;
    private String email;
    private UserStatus status;
    private LocalDateTime createdAt;

    @Builder
    public UserResponse(Long id, String name, String email,
                       UserStatus status, LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.status = status;
        this.createdAt = createdAt;
    }

    public static UserResponse from(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .status(user.getStatus())
                .createdAt(user.getCreatedAt())
                .build();
    }
}

// Paginated response
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class PageResponse<T> {
    private List<T> content;
    private int totalPages;
    private long totalElements;
    private int number;
    private int size;

    @Builder
    public PageResponse(List<T> content, int totalPages,
                       long totalElements, int number, int size) {
        this.content = content;
        this.totalPages = totalPages;
        this.totalElements = totalElements;
        this.number = number;
        this.size = size;
    }

    public static <T, R> PageResponse<R> from(Page<T> page, Function<T, R> mapper) {
        return PageResponse.<R>builder()
                .content(page.getContent().stream()
                        .map(mapper)
                        .collect(Collectors.toList()))
                .totalPages(page.getTotalPages())
                .totalElements(page.getTotalElements())
                .number(page.getNumber())
                .size(page.getSize())
                .build();
    }
}
```

## Entity Pattern

```java
@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(nullable = false, unique = true, length = 100)
    private String email;

    @Column(nullable = false)
    private Integer age;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserStatus status;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @Builder
    public User(String name, String email, Integer age) {
        this.name = name;
        this.email = email;
        this.age = age;
        this.status = UserStatus.ACTIVE;
    }

    public void update(String name, Integer age) {
        this.name = name;
        this.age = age;
    }
}
```

## Exception Handling

```java
// Custom exceptions
public class UserNotFoundException extends RuntimeException {
    public UserNotFoundException(Long id) {
        super("User not found with id: " + id);
    }
}

public class DuplicateEmailException extends RuntimeException {
    public DuplicateEmailException(String email) {
        super("Email already exists: " + email);
    }
}

// Global handler
@RestControllerAdvice
@Slf4j
public class GlobalExceptionHandler {

    @ExceptionHandler(UserNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(UserNotFoundException e) {
        log.error("Not found: {}", e.getMessage());
        ErrorResponse response = ErrorResponse.builder()
                .status(HttpStatus.NOT_FOUND.value())
                .message(e.getMessage())
                .timestamp(LocalDateTime.now())
                .build();
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(
            MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getAllErrors().stream()
                .map(DefaultMessageSourceResolvable::getDefaultMessage)
                .collect(Collectors.joining(", "));
        ErrorResponse response = ErrorResponse.builder()
                .status(HttpStatus.BAD_REQUEST.value())
                .message(message)
                .timestamp(LocalDateTime.now())
                .build();
        return ResponseEntity.badRequest().body(response);
    }
}

@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ErrorResponse {
    private int status;
    private String message;
    private LocalDateTime timestamp;

    @Builder
    public ErrorResponse(int status, String message, LocalDateTime timestamp) {
        this.status = status;
        this.message = message;
        this.timestamp = timestamp;
    }
}
```

## Testing

### Controller Test
```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    @DisplayName("GET /users/{id} returns 200")
    void getUser_success() throws Exception {
        Long userId = 1L;
        UserResponse response = UserResponse.builder()
                .id(userId)
                .name("John")
                .email("john@test.com")
                .build();

        when(userService.findById(userId)).thenReturn(response);

        mockMvc.perform(get("/api/v1/users/{id}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId))
                .andExpect(jsonPath("$.name").value("John"));
    }

    @Test
    @DisplayName("POST /users returns 201")
    void createUser_success() throws Exception {
        CreateUserRequest request = CreateUserRequest.builder()
                .name("John")
                .email("john@test.com")
                .age(25)
                .build();
        UserResponse response = UserResponse.builder()
                .id(1L)
                .name("John")
                .build();

        when(userService.create(any())).thenReturn(response);

        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1L));
    }
}
```

### Service Test
```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserServiceImpl userService;

    @Test
    @DisplayName("findById throws when not found")
    void findById_notFound() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        assertThrows(UserNotFoundException.class,
                () -> userService.findById(1L));
    }

    @Test
    @DisplayName("create saves and returns response")
    void create_success() {
        CreateUserRequest request = CreateUserRequest.builder()
                .name("John")
                .email("john@test.com")
                .age(25)
                .build();
        User savedUser = User.builder()
                .name("John")
                .email("john@test.com")
                .age(25)
                .build();
        ReflectionTestUtils.setField(savedUser, "id", 1L);

        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        UserResponse response = userService.create(request);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getName()).isEqualTo("John");
        verify(userRepository).save(any(User.class));
    }
}
```

### Repository Test
```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
class UserRepositoryTest {
    @Autowired
    private UserRepository userRepository;

    @Test
    @DisplayName("findByEmail returns user")
    void findByEmail_success() {
        User user = User.builder()
                .name("John")
                .email("john@test.com")
                .age(25)
                .build();
        userRepository.save(user);

        Optional<User> found = userRepository.findByEmail("john@test.com");

        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("John");
    }
}
```
