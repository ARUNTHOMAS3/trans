# Development Guidelines

## Code Quality Standards

### Naming Conventions
- **Dart/Flutter**: Use camelCase for variables/methods, PascalCase for classes, snake_case for file names
  - Example: `ItemsController`, `items_controller.dart`, `loadItems()`
- **TypeScript/NestJS**: Use camelCase for variables/methods, PascalCase for classes/interfaces
  - Example: `ProductsService`, `createProduct()`, `UpdateProductDto`
- **Database**: Use snake_case for all table and column names
  - Example: `product_contents`, `unit_id`, `is_active`

### File Organization
- **Frontend**: Group by feature modules with consistent structure:
  ```
  module_name/
  ├── models/              # Data models
  ├── repositories/        # Data access
  ├── providers/           # State management
  ├── controllers/         # Business logic
  └── presentation/        # UI components
      └── widgets/         # Reusable widgets
  ```
- **Backend**: Organize by NestJS modules with service/controller/dto pattern:
  ```
  module_name/
  ├── dto/                 # Data transfer objects
  ├── module_name.controller.ts
  ├── module_name.service.ts
  └── module_name.module.ts
  ```

### Documentation Standards
- Use inline comments sparingly - prefer self-documenting code
- Add JSDoc/DartDoc comments for public APIs and complex logic
- Include file header comments with purpose description
- Document non-obvious business logic with explanatory comments

### Code Formatting
- **Dart**: Follow official Dart style guide, use `flutter format`
- **TypeScript**: Use Prettier with project configuration
- **Indentation**: 2 spaces for both Dart and TypeScript
- **Line Length**: 80-100 characters preferred, 120 max
- **Trailing Commas**: Always use in Dart for better formatting

## Architectural Patterns

### State Management (Frontend)
- **Pattern**: Riverpod with StateNotifier
- **State Classes**: Immutable with copyWith methods
- **Controllers**: Extend StateNotifier, handle business logic
- **Providers**: Define at file level, use family/autoDispose when needed
- **Example**:
  ```dart
  class ItemsController extends StateNotifier<ItemsState> {
    ItemsController(this.repo) : super(const ItemsState());
    
    Future<void> loadItems() async {
      state = state.copyWith(isLoading: true);
      final items = await repo.getItems();
      state = state.copyWith(items: items, isLoading: false);
    }
  }
  
  final itemsControllerProvider = 
    StateNotifierProvider<ItemsController, ItemsState>((ref) {
      return ItemsController(ref.watch(itemRepositoryProvider));
    });
  ```

### Repository Pattern (Frontend)
- Separate data access from business logic
- Use abstract interfaces for testability
- Handle API communication and error transformation
- **Example**:
  ```dart
  abstract class ItemRepository {
    Future<List<Item>> getItems();
    Future<Item> createItem(Item item);
  }
  
  class ItemRepositoryImpl implements ItemRepository {
    final ApiClient _client;
    
    @override
    Future<List<Item>> getItems() async {
      final response = await _client.get('/products');
      return (response.data as List)
        .map((json) => Item.fromJson(json))
        .toList();
    }
  }
  ```

### Service Layer (Backend)
- Business logic resides in services, not controllers
- Services are injected via NestJS dependency injection
- Use DTOs for request/response validation
- **Example**:
  ```typescript
  @Injectable()
  export class ProductsService {
    constructor(private readonly supabaseService: SupabaseService) {}
    
    async create(dto: CreateProductDto, userId: string) {
      const supabase = this.supabaseService.getClient();
      const { data, error } = await supabase
        .from('products')
        .insert({ ...dto, created_by_id: userId })
        .select()
        .single();
      
      if (error) throw new BadRequestException(error.message);
      return data;
    }
  }
  ```

### Multi-Tenancy Pattern
- **Middleware**: Inject org_id and outlet_id from headers into request context
- **Automatic Filtering**: All queries automatically filter by tenant context
- **Header Names**: `X-Org-Id`, `X-Outlet-Id`
- **Implementation**: Applied at NestJS middleware level before controllers

## Error Handling

### Frontend Error Handling
- Use custom exception classes extending AppException
- Catch specific exceptions (NetworkException, ValidationException, ApiException)
- Always provide user-friendly error messages
- Log errors with AppLogger for debugging
- **Example**:
  ```dart
  try {
    await repo.createItem(item);
  } on ValidationException catch (e) {
    state = state.copyWith(error: e.userMessage);
  } on NetworkException catch (e) {
    state = state.copyWith(error: 'Network error. Please check connection.');
  } catch (e) {
    AppLogger.error('Unexpected error', error: e);
    state = state.copyWith(error: 'An unexpected error occurred.');
  }
  ```

### Backend Error Handling
- Use NestJS built-in exceptions (BadRequestException, NotFoundException, ConflictException)
- Handle database constraint violations explicitly (23505 for duplicates)
- Return meaningful error messages to frontend
- Log errors with context for debugging
- **Example**:
  ```typescript
  if (error.code === '23505') {
    if (error.detail.includes('item_code')) {
      throw new ConflictException(`Item code '${dto.item_code}' already exists`);
    }
  }
  throw new BadRequestException(`Failed to create: ${error.message}`);
  ```

## Data Validation

### Frontend Validation
- Validate in controllers before API calls
- Return validation errors as Map<String, String>
- Display field-specific errors in UI
- **Example**:
  ```dart
  Map<String, String> validateItem(Item item) {
    final errors = <String, String>{};
    if (item.productName.trim().isEmpty) {
      errors['productName'] = 'Product name is required';
    }
    if (item.sellingPrice != null && item.sellingPrice! < 0) {
      errors['sellingPrice'] = 'Price must be positive';
    }
    return errors;
  }
  ```

### Backend Validation
- Use class-validator decorators in DTOs
- Validate UUIDs before database operations
- Clean and sanitize input data
- **Example**:
  ```typescript
  private cleanUuid(value: any): string | null {
    if (!value || typeof value !== 'string') return null;
    const trimmed = value.trim();
    return this.isUUID(trimmed) ? trimmed : null;
  }
  
  // In service method:
  const payload = {
    ...dto,
    unit_id: this.cleanUuid(dto.unit_id),
    category_id: this.cleanUuid(dto.category_id),
  };
  ```

## Database Patterns

### Query Optimization
- Use indexes for frequently queried columns
- Implement cursor-based pagination for large datasets
- Limit result sets (default 50 items per page)
- Use select() to fetch only needed columns
- **Example**:
  ```typescript
  async findAllCursor(limit: number = 50, cursor?: string) {
    let query = supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .order('id', { ascending: false });
    
    if (cursor) query = query.lt('id', cursor);
    query = query.limit(limit);
    
    const { data } = await query;
    const next_cursor = data.length === limit ? data[data.length - 1].id : null;
    
    return { items: data, next_cursor };
  }
  ```

### Search Implementation
- Use trigram indexes (pg_trgm) for fuzzy text search
- Prioritize exact matches over partial matches
- Implement server-side search with ranking
- **Example**:
  ```typescript
  async searchProducts(q: string, limit: number = 30) {
    const { data } = await supabase
      .from('products')
      .select('*')
      .eq('is_active', true)
      .or(`sku.eq."${q}",ean.eq."${q}",product_name.ilike."%${q}%"`)
      .limit(limit);
    
    // Sort: exact matches first, then prefix matches, then others
    const exactMatches = data.filter(d => d.sku === q || d.ean === q);
    const prefixMatches = data.filter(d => 
      !exactMatches.includes(d) && 
      d.product_name?.toLowerCase().startsWith(q.toLowerCase())
    );
    const otherMatches = data.filter(d => 
      !exactMatches.includes(d) && !prefixMatches.includes(d)
    );
    
    return [...exactMatches, ...prefixMatches, ...otherMatches];
  }
  ```

### Soft Deletes
- Never hard delete records - use is_active flag
- Filter by is_active in queries
- Provide restore functionality when needed
- **Example**:
  ```typescript
  async remove(id: string) {
    await supabase
      .from('products')
      .update({ is_active: false })
      .eq('id', id);
  }
  ```

## Performance Best Practices

### Frontend Performance
- **Lazy Loading**: Load data on-demand, not all at once
- **Pagination**: Use cursor-based pagination for large lists
- **Caching**: Cache lookup data in state to avoid redundant API calls
- **Debouncing**: Debounce search inputs (300ms) to reduce API load
- **Optimistic Updates**: Update UI immediately, sync with server in background
- **Example**:
  ```dart
  // Debounced search
  Timer? _searchDebounce;
  void onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(Duration(milliseconds: 300), () {
      performSearch(query);
    });
  }
  
  // Optimistic update
  Future<bool> updateItem(Item item) async {
    final updatedList = state.items.map((i) => 
      i.id == item.id ? item : i
    ).toList();
    state = state.copyWith(items: updatedList);
    
    await repo.updateItem(item);
    return true;
  }
  ```

### Backend Performance
- **Batch Operations**: Support bulk updates/deletes
- **Connection Pooling**: Reuse database connections
- **Query Limits**: Always set reasonable limits on queries
- **Selective Joins**: Only join tables when needed
- **Example**:
  ```typescript
  async bulkUpdate(ids: string[], dto: UpdateProductDto) {
    const { data } = await supabase
      .from('products')
      .update(dto)
      .in('id', ids)
      .select();
    
    return { count: data?.length || 0 };
  }
  ```

## Testing Patterns

### Unit Testing (Frontend)
- Test business logic in controllers
- Mock repositories and services
- Use mocktail for mocking
- Test error scenarios
- **Example**:
  ```dart
  test('loadItems updates state with items', () async {
    when(() => mockRepo.getItems()).thenAnswer((_) async => [testItem]);
    
    final controller = ItemsController(mockRepo);
    await controller.loadItems();
    
    expect(controller.state.items, [testItem]);
    expect(controller.state.isLoading, false);
  });
  ```

### Integration Testing (Backend)
- Test API endpoints with supertest
- Use test database or mocked Supabase client
- Test authentication and authorization
- Verify error responses

## Logging Standards

### Frontend Logging
- Use AppLogger with module context
- Log levels: debug, info, warning, error
- Include relevant data in structured format
- **Example**:
  ```dart
  AppLogger.info('Item created', 
    module: 'items',
    data: {'id': item.id, 'name': item.productName}
  );
  
  AppLogger.error('Failed to load items', 
    error: e, 
    module: 'items'
  );
  ```

### Backend Logging
- Use console.log with prefixes for visibility
- Log errors with full context
- Include request IDs for tracing
- **Example**:
  ```typescript
  console.log(`✅ Successfully synced ${data.length} items`);
  console.error('❌ Error creating product:', error);
  ```

## Security Best Practices

### Authentication & Authorization
- Use JWT tokens from Supabase Auth
- Validate tokens in backend middleware
- Include user ID in audit fields (created_by_id, updated_by_id)
- Never expose service role keys to frontend

### Data Sanitization
- Clean and validate all user inputs
- Use parameterized queries (Supabase handles this)
- Validate UUIDs before database operations
- Strip undefined/null values before inserts

### Row-Level Security (RLS)
- Enable RLS on all tables
- Define policies for org_id filtering
- Test RLS policies thoroughly
- Use service role key only in backend

## API Design Patterns

### RESTful Endpoints
- Use standard HTTP methods (GET, POST, PUT, DELETE)
- Return appropriate status codes
- Use plural nouns for resources (/products, /items)
- Support query parameters for filtering/pagination
- **Example**:
  ```typescript
  @Get()
  async findAll(
    @Query('limit') limit?: number,
    @Query('cursor') cursor?: string,
  ) {
    return this.productsService.findAllCursor(limit, cursor);
  }
  
  @Post()
  async create(@Body() dto: CreateProductDto, @Req() req) {
    return this.productsService.create(dto, req.user.id);
  }
  ```

### Response Format
- Return data directly for success
- Use consistent error format
- Include metadata for paginated responses
- **Example**:
  ```typescript
  // Success response
  { items: [...], next_cursor: 'abc123' }
  
  // Error response
  { statusCode: 400, message: 'Validation failed', error: 'Bad Request' }
  ```

## Common Code Idioms

### Null Safety (Dart)
- Use null-aware operators (?., ??, !)
- Prefer ?? for default values
- Use late for deferred initialization
- **Example**:
  ```dart
  final name = item.productName ?? 'Unknown';
  final price = item.sellingPrice?.toStringAsFixed(2) ?? '0.00';
  ```

### Async/Await
- Always use async/await for asynchronous operations
- Handle errors with try-catch
- Use Future.wait for parallel operations
- **Example**:
  ```dart
  final results = await Future.wait([
    repo.getItems(),
    repo.getCategories(),
    repo.getManufacturers(),
  ]);
  ```

### Destructuring (TypeScript)
- Use object destructuring for cleaner code
- Separate concerns in function parameters
- **Example**:
  ```typescript
  const { compositions, ...productData } = dto;
  const { data, error } = await supabase.from('products').insert(productData);
  ```

## Frequently Used Annotations

### Dart Annotations
- `@override` - Override parent class methods
- `@immutable` - Mark classes as immutable
- `@JsonSerializable()` - Generate JSON serialization code
- `@freezed` - Generate immutable classes with copyWith

### TypeScript/NestJS Decorators
- `@Injectable()` - Mark class as injectable service
- `@Controller('path')` - Define controller route
- `@Get()`, `@Post()`, `@Put()`, `@Delete()` - HTTP method handlers
- `@Body()`, `@Query()`, `@Param()` - Extract request data
- `@Req()` - Access full request object

## Code Review Checklist

Before submitting code, ensure:
- [ ] Code follows naming conventions
- [ ] Error handling is comprehensive
- [ ] Validation is implemented
- [ ] Logging is appropriate
- [ ] Performance is optimized
- [ ] Tests are written (if applicable)
- [ ] Documentation is updated
- [ ] No sensitive data is exposed
- [ ] Multi-tenancy is respected
- [ ] Database queries are optimized
