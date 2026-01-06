# Spring Boot Best Practices

> **When to apply:** All Java applications using Spring Boot framework
> **Framework:** Spring Boot 3.x
> **Language:** Java 17+

Production-ready Spring Boot development with annotations, dependency injection, Spring Data, REST APIs, and testing.

## Project Structure

```
myapp/
├── src/main/java/com/example/myapp/
│   ├── MyAppApplication.java        # Main application
│   ├── config/                      # Configuration
│   ├── controller/                  # REST controllers
│   ├── service/                     # Business logic
│   ├── repository/                  # Data access
│   ├── model/                       # Domain entities
│   ├── dto/                         # Data transfer objects
│   └── exception/                   # Custom exceptions
├── src/main/resources/
│   ├── application.yml
│   ├── application-dev.yml
│   └── application-prod.yml
└── src/test/java/
```

## Controller Layer

**Rule:** Use `@RestController` for REST APIs. Apply validation with `@Valid`. Return `ResponseEntity` for explicit status codes.

```java
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        return ResponseEntity.ok(userService.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUserById(@PathVariable Long id) {
        return userService.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public UserDTO createUser(@Valid @RequestBody CreateUserRequest request) {
        return userService.create(request);
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> updateUser(
        @PathVariable Long id,
        @Valid @RequestBody UpdateUserRequest request
    ) {
        return userService.update(id, request)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteUser(@PathVariable Long id) {
        userService.delete(id);
    }
}
```

## Service Layer

**Rule:** Annotate with `@Service`. Use `@Transactional` for database operations. Mark read-only methods with `@Transactional(readOnly = true)`.

```java
@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UserDTO> findAll() {
        return userRepository.findAll().stream()
            .map(this::toDTO)
            .toList();
    }

    @Transactional(readOnly = true)
    public Optional<UserDTO> findById(Long id) {
        return userRepository.findById(id).map(this::toDTO);
    }

    public UserDTO create(CreateUserRequest request) {
        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setName(request.getName());

        User saved = userRepository.save(user);
        return toDTO(saved);
    }

    private UserDTO toDTO(User user) {
        return new UserDTO(
            user.getId(),
            user.getEmail(),
            user.getName(),
            user.getCreatedAt()
        );
    }
}
```

## Repository Layer

**Rule:** Extend `JpaRepository`. Use method naming conventions or `@Query` for custom queries.

```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    @Query("SELECT u FROM User u WHERE u.active = true")
    List<User> findActiveUsers();

    @Query("SELECT u FROM User u WHERE u.createdAt >= :since")
    List<User> findRecentUsers(@Param("since") LocalDateTime since);

    boolean existsByEmail(String email);
}
```

## Entity Design

**Rule:** Use `@Entity` and `@Table`. Apply indexes to frequently queried columns. Use lifecycle callbacks for timestamps.

```java
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_email", columnList = "email")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

## DTOs

**Rule:** Use records for immutable DTOs. Apply validation annotations.

```java
public record CreateUserRequest(
    @NotNull @Email String email,
    @NotNull @Size(min = 8) String password,
    @NotNull @Size(min = 2, max = 100) String name
) {}

public record UserDTO(
    Long id,
    String email,
    String name,
    LocalDateTime createdAt
) {}

public record UpdateUserRequest(
    @Email String email,
    @Size(min = 2, max = 100) String name
) {}
```

## Global Exception Handling

**Rule:** Use `@RestControllerAdvice` for centralized error handling. Return consistent error responses.

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            ex.getMessage(),
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException ex) {
        List<String> errors = ex.getBindingResult()
            .getFieldErrors()
            .stream()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .toList();

        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "Validation failed: " + String.join(", ", errors),
            LocalDateTime.now()
        );
        return ResponseEntity.badRequest().body(error);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneral(Exception ex) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            "Internal server error",
            LocalDateTime.now()
        );
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}

public record ErrorResponse(int status, String message, LocalDateTime timestamp) {}
```

## Configuration

**Rule:** Split configuration by environment. Use YAML for readability. Externalize secrets.

```yaml
# application.yml
spring:
  application:
    name: myapp

  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USER}
    password: ${DATABASE_PASSWORD}
    driver-class-name: org.postgresql.Driver
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5

  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.PostgreSQLDialect

server:
  port: 8080
  error:
    include-message: always
    include-stacktrace: never
```

**Configuration class:**
```java
@Configuration
public class AppConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public ModelMapper modelMapper() {
        return new ModelMapper();
    }

    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
            .registerModule(new JavaTimeModule())
            .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }
}
```

## Security Configuration

**Rule:** Use Spring Security for authentication. Implement JWT validation. Apply method-level security.

```java
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/api/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

## Testing

**Rule:** Use `@SpringBootTest` for integration tests. Use `MockMvc` for controller tests. Use `@MockBean` for service mocks.

```java
// Integration tests
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureMockMvc
class UserControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
    }

    @Test
    void shouldCreateUser() throws Exception {
        CreateUserRequest request = new CreateUserRequest(
            "test@example.com",
            "password123",
            "Test User"
        );

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.email").value("test@example.com"))
            .andExpect(jsonPath("$.name").value("Test User"));
    }
}

// Unit tests
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    @Test
    void shouldCreateUser() {
        CreateUserRequest request = new CreateUserRequest(
            "test@example.com",
            "password123",
            "Test User"
        );

        User savedUser = new User();
        savedUser.setId(1L);
        savedUser.setEmail(request.email());
        savedUser.setName(request.name());

        when(passwordEncoder.encode(anyString())).thenReturn("encoded");
        when(userRepository.save(any(User.class))).thenReturn(savedUser);

        UserDTO result = userService.create(request);

        assertThat(result.email()).isEqualTo("test@example.com");
        verify(userRepository).save(any(User.class));
    }
}
```

## Performance Optimization

**Rule:** Apply database indexes. Use connection pooling. Implement caching for frequently accessed data.

```java
// Caching configuration
@Configuration
@EnableCaching
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        return new ConcurrentMapCacheManager("users", "posts");
    }
}

// Service with caching
@Service
public class UserService {

    @Cacheable(value = "users", key = "#id")
    @Transactional(readOnly = true)
    public Optional<UserDTO> findById(Long id) {
        return userRepository.findById(id).map(this::toDTO);
    }

    @CacheEvict(value = "users", key = "#id")
    public void delete(Long id) {
        userRepository.deleteById(id);
    }
}
```

## Related Resources

- `languages/java/coding-standards.md` - Java patterns
- `languages/java/testing.md` - Testing strategies
- `base/architecture-principles.md` - Architecture patterns
