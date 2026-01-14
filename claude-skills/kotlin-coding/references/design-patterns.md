# Kotlin Design Patterns

Kotlin은 언어 차원에서 많은 디자인 패턴을 간소화. Java boilerplate 없이 구현 가능.

## Factory Pattern

companion object의 `from()` 또는 의미있는 팩토리 메서드:

```kotlin
data class UserResponse(val id: Long, val name: String) {
    companion object {
        fun from(user: User) = UserResponse(id = user.id!!, name = user.name)
        fun empty() = UserResponse(id = 0L, name = "")
    }
}

// 사용
val response = UserResponse.from(user)
```

## Builder Pattern

Kotlin은 default parameters + named arguments로 Builder 불필요:

```kotlin
// Builder 불필요
data class SearchCriteria(
    val keyword: String? = null,
    val status: Status? = null,
    val minAge: Int? = null,
    val maxAge: Int? = null,
    val page: Int = 0,
    val size: Int = 20
)

// 사용
val criteria = SearchCriteria(
    keyword = "john",
    status = Status.ACTIVE,
    size = 50
)
```

## Singleton Pattern

`object` 키워드로 자동 구현:

```kotlin
object DateUtils {
    fun startOfDay(date: LocalDate): LocalDateTime = date.atStartOfDay()
    fun endOfDay(date: LocalDate): LocalDateTime = date.atTime(LocalTime.MAX)
}

// 사용
val start = DateUtils.startOfDay(LocalDate.now())
```

## QueryDSL Pattern

동적 쿼리를 위한 QueryDSL 사용 (타입 안전):

```kotlin
@Repository
class UserRepositoryCustomImpl(
    private val queryFactory: JPAQueryFactory
) : UserRepositoryCustom {

    fun findByConditions(
        name: String?,
        status: UserStatus?,
        createdAfter: LocalDateTime?,
        pageable: Pageable
    ): Page<User> {
        val user = QUser.user
        val builder = BooleanBuilder()

        name?.let { builder.and(user.name.eq(it)) }
        status?.let { builder.and(user.status.eq(it)) }
        createdAfter?.let { builder.and(user.createdAt.goe(it)) }

        val content = queryFactory
            .selectFrom(user)
            .where(builder)
            .offset(pageable.offset)
            .limit(pageable.pageSize.toLong())
            .fetch()

        val total = queryFactory
            .select(user.count())
            .from(user)
            .where(builder)
            .fetchOne() ?: 0L

        return PageImpl(content, pageable, total)
    }
}
```

## Mapper Pattern

확장 함수로 mapper class 불필요:

```kotlin
// Entity → Response
fun User.toResponse() = UserResponse(
    id = id!!,
    name = name,
    email = email
)

// Request → Entity
fun CreateUserRequest.toEntity() = User(
    name = name,
    email = email,
    age = age
)

// List mapping
fun List<User>.toResponses() = map { it.toResponse() }

// 사용
val response = user.toResponse()
val users = userList.toResponses()
```

## Partial Update Pattern (PATCH)

nullable 필드 + `let`으로 부분 업데이트:

```kotlin
data class UpdateUserRequest(
    val name: String? = null,
    val email: String? = null,
    val age: Int? = null
) {
    fun applyTo(user: User) {
        name?.let { user.name = it }
        email?.let { user.email = it }
        age?.let { user.age = it }
    }
}

// Service에서
@Transactional
fun update(id: Long, request: UpdateUserRequest): UserResponse {
    val user = userRepository.findByIdOrNull(id)
        ?: throw UserNotFoundException(id)
    request.applyTo(user)
    return user.toResponse()
}
```

## API Response Wrapper

```kotlin
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null
) {
    companion object {
        fun <T> success(data: T) = ApiResponse(success = true, data = data)
        fun <T> success(data: T, message: String) = ApiResponse(success = true, data = data, message = message)
        fun <T> error(message: String) = ApiResponse<T>(success = false, message = message)
    }
}
```

## Service Interface 불필요

Kotlin에서는 일반적으로 Service interface 생략 (테스트에서 MockK 사용):

```kotlin
// Interface 없이 직접 구현
@Service
@Transactional(readOnly = true)
class UserService(private val userRepository: UserRepository) {
    fun findById(id: Long): UserResponse { ... }
}

// 테스트에서는 MockK로 직접 mock
@MockK
private lateinit var userService: UserService
```

Interface가 필요한 경우:
- 여러 구현체가 필요할 때 (전략 패턴)
- 외부 모듈에 API를 노출할 때
