---
name: java-coding
description: "Java 17+ 및 Spring Boot 3.x 코딩 규칙 가이드. (1) Java 코드 작성 시, (2) Spring Boot 프로젝트, (3) JPA Entity/DTO 패턴, (4) Lombok 활용, (5) Mockito 기반 테스트 작성 시 사용."
---

# Java Coding Conventions

## Google Java Style (Non-Obvious Rules)

### Indentation: 2 spaces (NOT 4)
```java
if (condition) {
  doSomething();  // 2 spaces
}
```

### Column limit: 100 characters
Package/import 문은 예외.

### Braces: K&R style, always required
```java
// Good - braces required even for single statement
if (condition) {
  return value;
}

// Bad
if (condition)
  return value;
```

### Wildcard imports: NOT used
```java
// Good
import java.util.List;
import java.util.Map;

// Bad
import java.util.*;
```

### Imports ordering
1. Static imports (single group)
2. Non-static imports (single group)
- 그룹 내 ASCII 정렬, 그룹 간 빈 줄 하나

### Switch: always exhaustive
모든 switch는 `default` 포함 필수 (enum 전체 매칭 제외).

### Acronyms: 일반 단어처럼 처리
```java
// Good
XmlHttpRequest, newCustomerId, supportsIpv6OnIos

// Bad
XMLHTTPRequest, newCustomerID, supportsIPv6OnIOS
```

## Lombok Patterns

### DTO with protected no-args constructor
Jackson deserialization을 위해 `PROTECTED` 필수:
```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class CreateUserRequest {
    @NotBlank
    private String name;

    @Builder
    public CreateUserRequest(String name) {
        this.name = name;
    }

    public User toEntity() {
        return User.builder().name(name).build();
    }
}
```

### Entity with JPA auditing
```java
@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @Builder
    public User(String name) {
        this.name = name;
    }
}
```

### Response DTO with static factory
```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserResponse {
    private Long id;
    private String name;

    @Builder
    public UserResponse(Long id, String name) {
        this.id = id;
        this.name = name;
    }

    public static UserResponse from(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .name(user.getName())
                .build();
    }
}
```

## Spring Boot Patterns

### Constructor injection with Lombok
```java
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;

    @Override
    @Transactional  // write operation
    public UserResponse create(CreateUserRequest request) {
        return UserResponse.from(userRepository.save(request.toEntity()));
    }
}
```

### Interface-based Service (Java convention)
Java에서는 테스트 용이성을 위해 Service interface 분리 권장:
```java
public interface UserService {
    UserResponse findById(Long id);
    UserResponse create(CreateUserRequest request);
}
```

## Testing with Mockito

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserServiceImpl userService;

    @Test
    void createUser_success() {
        // given
        var request = CreateUserRequest.builder().name("John").build();
        var savedUser = User.builder().name("John").build();
        ReflectionTestUtils.setField(savedUser, "id", 1L);

        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        // when
        var response = userService.create(request);

        // then
        assertThat(response.getId()).isEqualTo(1L);
        verify(userRepository).save(any(User.class));
    }
}
```

## 상세 참조

- Spring Boot 레이어별 상세 패턴: `references/spring-boot.md`
- 디자인 패턴 구현 예제: `references/design-patterns.md`
