---
name: spring-api-builder
description: "Spring Boot 3.x REST API 구축. CSR 아키텍처 기반 API 엔드포인트 생성, CRUD 구현, 테스트 코드 생성. Java/Kotlin 지원. (1) 새 REST API 엔드포인트 생성, (2) Entity-DTO-Repository-Service-Controller 계층 구현, (3) 테스트 코드 생성 시 사용."
---

# Spring API Builder

## Workflow

### 1. 요구사항 수집

**필수 확인 사항:**
- 리소스/엔티티명 (예: User, Product, Order)
- 필요한 작업 (GET, POST, PUT, DELETE, PATCH)
- 언어 선택 (Java / Kotlin)

**선택적 확인 사항 (필요 시 질문):**
- 엔티티 필드 및 관계
- 유효성 검사 규칙
- 페이지네이션 필요 여부
- 테스트 코드 생성 여부

### 2. 구현 순서

```
Entity → DTO → Repository → Exception → Service → Controller → (Test)
```

**a. Entity**
- JPA 어노테이션
- Auditing 필드 (createdAt, updatedAt)

**b. DTO**
- Request: validation 어노테이션 + `toEntity()`
- Response: `static from(Entity)` 팩토리 메서드

**c. Repository**
- `JpaRepository<Entity, Long>` 확장
- 필요 시 커스텀 쿼리 메서드

**d. Exception (필요 시)**
- `{Resource}NotFoundException`
- `@RestControllerAdvice` 핸들러

**e. Service**
- Java: Interface + Impl 분리
- Kotlin: 직접 구현 (MockK 사용)
- `@Transactional(readOnly = true)` 클래스 레벨, 쓰기 메서드만 `@Transactional`

**f. Controller**
- `@RestController`, `@RequestMapping("/api/v1/{resources}")`
- `@Valid` + `@RequestBody`
- 적절한 HTTP 상태 코드

**g. Test (요청 시)**
- Controller: `@WebMvcTest`
- Service: `@ExtendWith(MockitoExtension.class)` / `@ExtendWith(MockKExtension.class)`
- Repository: `@DataJpaTest`

### 3. 코딩 규칙 참조

- **Java**: `java-coding` 스킬 참조
- **Kotlin**: `kotlin-coding` 스킬 참조

두 스킬에서 상세 패턴 및 코드 예제 확인 가능:
- Entity/DTO 패턴
- Lombok/data class 사용법
- 테스트 작성법
- 예외 처리 패턴
