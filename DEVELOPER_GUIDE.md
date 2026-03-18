# SkillBid - Developer Guide

## Project Overview

SkillBid is a Flutter mobile application that connects clients with service providers. Clients can post jobs and service providers can bid on those jobs. Once a bid is accepted, a contract is created and messaging is enabled between the client and provider.

**Key Features:**
- User authentication with email/password
- Dual-role system (Client/Provider)
- Job posting and bidding system
- Real-time messaging after bid acceptance
- Portfolio management for providers
- Rating and review system
- Skills-based job categorization

---

## Architecture Overview

SkillBid follows a **clean, layered architecture** for maximum scalability and maintainability:

```
Presentation Layer (UI)
    ↓ (consumes)
State Management Layer (Riverpod Providers)
    ↓ (calls)
Repository Layer (Business Logic)
    ↓ (calls)
Service Layer (Supabase SDK Wrapper)
    ↓ (interacts with)
Database & Storage (Supabase)
```

### Layer Responsibilities

1. **Presentation Layer (`screens/`, `widgets/`)**
   - Flutter UI components and screens
   - Display data to users
   - Handle user input
   - Use `ref.watch()` to consume providers

2. **State Management Layer (`providers/`)**
   - Riverpod providers for reactive state
   - Caching and automatic refetching
   - Provider invalidation on data changes
   - Single source of truth for app state

3. **Repository Layer (`repositories/`)**
   - Business logic and data orchestration
   - Combine multiple services
   - Data transformation
   - Error handling

4. **Service Layer (`services/`)**
   - Low-level Supabase SDK interactions
   - Generic functions (no business logic)
   - Database queries, image uploads, real-time subscriptions
   - Error propagation

5. **Models Layer (`models/`)**
   - Data classes using Freezed (immutable)
   - JSON serialization/deserialization
   - Type safety

---

## Folder Structure

```
lib/
├── main.dart                    # App entry point
├── config/                      # Configuration
│   ├── app_constants.dart
│   └── supabase_config.dart
├── models/                      # Data models (Freezed)
│   ├── user/
│   ├── job/
│   ├── portfolio/
│   ├── chat/
│   ├── skill_model.dart
│   ├── bid_model.dart
│   └── contract_model.dart
├── services/                    # Low-level Supabase interactions
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── storage_service.dart
│   └── realtime_service.dart
├── repositories/                # Business logic
│   ├── auth_repository.dart
│   ├── user_repository.dart
│   ├── job_repository.dart
│   ├── bid_repository.dart
│   ├── contract_repository.dart
│   ├── portfolio_repository.dart
│   └── chat_repository.dart
├── providers/                   # Riverpod state management
│   ├── auth_provider.dart
│   ├── user_provider.dart
│   ├── job_provider.dart
│   ├── bid_provider.dart
│   ├── contract_provider.dart
│   ├── portfolio_provider.dart
│   └── chat_provider.dart
├── screens/                     # UI Screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   └── role_selection_screen.dart
│   ├── client/
│   │   ├── client_shell.dart
│   │   ├── home_screen.dart
│   │   ├── active_jobs_screen.dart
│   │   └── profile_screen.dart
│   ├── worker/
│   │   ├── worker_shell.dart
│   │   ├── home_screen.dart
│   │   └── (other worker screens)
│   └── common/
│       ├── splash_screen.dart
│       └── chat_screen.dart
├── widgets/                     # Reusable UI components
│   ├── common/
│   │   ├── custom_button.dart
│   │   ├── custom_text_field.dart
│   │   ├── loading_widget.dart
│   │   ├── error_widget.dart
│   │   └── empty_state_widget.dart
│   └── specific/               # Features-specific widgets
├── utils/                       # Utilities
│   ├── validators.dart
│   ├── formatters.dart
│   ├── extensions.dart
│   ├── exceptions.dart
│   └── app_logger.dart
├── theme/                       # Design tokens
│   ├── app_colors.dart
│   ├── app_typography.dart
│   └── app_theme.dart
└── routes/                      # Navigation
    └── app_router.dart          # GoRouter configuration
```

---

## Supabase Integration

### Database Tables

The Supabase schema includes the following tables:

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `profiles` | User accounts | id, full_name, phone, avatar_url, last_role, created_at |
| `roles` | Role definitions | id, name (client/provider) |
| `user_roles` | User role assignments | user_id, role_id |
| `provider_profiles` | Extended provider info | user_id, bio, experience_years, hourly_rate, verified |
| `skills` | Job categories | id, name |
| `provider_skills` | Provider expertise | provider_id, skill_id |
| `jobs` | Job postings | id, client_id, title, description, budget, location, skill_id, status |
| `job_images` | Job photos | id, job_id, image_url |
| `bids` | Provider bids | id, job_id, provider_id, amount, estimated_days, message, status |
| `contracts` | Accepted bids | id, job_id, bid_id, client_id, provider_id, status, start_date, end_date, rating, review_text |
| `provider_portfolio` | Provider work samples | id, provider_id, title, description, cost |
| `portfolio_images` | Portfolio photos | id, portfolio_id, image_url |
| `chats` | Job discussion rooms | id, job_id, contract_id, last_message_at |
| `chat_participants` | Chat members | chat_id, user_id |
| `messages` | Chat messages | id, chat_id, sender_id, content, message_type, is_read, created_at |

### Running the SQL Migration

1. Go to Supabase Dashboard → SQL Editor
2. Create New Query
3. Copy the entire content from `supabase_migration.sql`
4. Run the query

This will create all tables, indexes, triggers, and seed data (skills, roles).

### Storage Buckets

Create these public buckets in Supabase Storage:
- `avatars` - User profile pictures
- `job-images` - Job post images
- `portfolio-images` - Provider portfolio images

---

## How the App Works

### 1. **Authentication Flow**

```
Splash Screen
    ↓
Check if user is logged in
    ├─ No: LoginScreen → SignupScreen → RoleSelectionScreen
    └─ Yes: Load user role → ClientShell or WorkerShell
```

**Key Providers:**
- `authStateProvider` - Check if user is authenticated
- `currentUserIdProvider` - Get current user's ID
- `userRoleProvider` - Get user's selected role

### 2. **Client Workflow**

1. **Browse Jobs** (ClientHomeScreen)
   - View available jobs filtered by skill
   - Tap to see job details
   - View bids received

2. **Create Job**
   - Fill form with title, description, budget, location, skill
   - Upload job images
   - Job created with "open" status

3. **Manage Bids**
   - View bids received on each job
   - Accept best bid → Contract created → Chat enabled
   - Reject other bids

4. **Chat & Complete**
   - Communicate with accepted provider
   - Mark job complete from contract view
   - Rate provider (1-5 stars)

### 3. **Provider Workflow**

1. **Browse Jobs** (WorkerHomeScreen)
   - View open jobs matching their skills
   - Filter by skill, budget, location

2. **Submit Bid**
   - View job details
   - Submit bid with amount, estimated days, message
   - Check bid status

3. **Manage Bids**
   - View all submitted bids
   - Status tracking: pending → accepted → rejected/withdrawn
   - Only 1 bid per provider per job

4. **Work & Chat**
   - After bid acceptance, chat enabled
   - Communicate with client
   - Complete contract when done

5. **Portfolio**
   - Create portfolio items with images
   - Showcase past work to attract clients

### 4. **Data Flow Example: Posting a Job**

```
ClientHomeScreen
  └─ calls ref.read(createJobProvider(...))
    └─ CreateJobProvider
      └─ calls JobRepository.createJob()
        └─ JobService.insertData(table: 'jobs')
          └─ supabase.from('jobs').insert()
            └─ Database
              └─ Response: new JobModel
                └─ Provider invalidates related providers
                  └─ UI rebuilds with new job
```

---

## Using Riverpod Providers

### Watch vs Read

```dart
// In build method - rebuilds when provider changes
final jobs = ref.watch(availableJobsProvider);

// In button callback - no rebuild, just fetch once
ref.read(createJobProvider(params)).whenData((_) {
  // Do something after creation
});
```

### Invalidating Provider

```dart
// After creating a job, refresh the jobs list
ref.refresh(availableJobsProvider);
ref.refresh(clientJobsProvider);
```

### Creating New Providers

```dart
final myProvider = FutureProvider<DataType>((ref) async {
  final repo = ref.watch(myRepositoryProvider);
  return repo.getData();
});
```

---

## Common Tasks & Code Examples

### 1. Get Current User Profile

```dart
final currentUser = await ref.watch(currentUserProvider).whenData((user) {
  print('User: ${user?.fullName}');
});
```

### 2. Create a Job

```dart
final job = ref.read(createJobProvider((
  title: 'Kitchen Remodel',
  description: 'Need kitchen renovation',
  budget: 50000,
  location: 'Mumbai',
  skillId: 9,
  desiredCompletionDays: 30,
))).whenData((job) {
  print('Job created: ${job.id}');
});
```

### 3. Submit a Bid

```dart
ref.read(createBidProvider((
  jobId: jobId,
  amount: 40000,
  estimatedDays: 25,
  message: 'I can complete this efficiently',
))).whenData((bid) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Bid submitted successfully!')),
  );
});
```

### 4. Accept a Bid

```dart
ref.read(acceptBidAndCreateContractProvider((
  bidId: bidId,
  jobId: jobId,
  clientId: clientId,
))).whenData((contract) {
  // Chat is now available with provider
  Navigator.of(context).pushNamed('/chat/${contract.jobId}');
});
```

### 5. Send Message

```dart
ref.read(sendMessageProvider((
  chatId: chatId,
  content: 'When can you start?',
  messageType: 'text',
))).whenData((message) {
  print('Message sent: ${message.id}');
});
```

### 6. Upload Image

```dart
final imageFile = await _imagePicker.pickImage(source: ImageSource.gallery);
await jobRepository.addJobImage(jobId: jobId, imageFile: imageFile);
```

---

## Form Validation

Use validators from `utils/validators.dart`:

```dart
CustomTextField(
  labelText: 'Email',
  validator: Validators.validateEmail,
),

CustomTextField(
  labelText: 'Amount',
  validator: Validators.validateAmount,
),
```

---

## Error Handling

Services throw custom exceptions:

```dart
try {
  await bidRepo.createBid(...);
} on AppException catch (e) {
  showSnackBar(e.message);
}
```

---

## Extending the App

### Adding a New Entity

1. **Create Model** (`models/my_model.dart`)
   ```dart
   @freezed
   class MyModel with _$MyModel {
     const factory MyModel({
       required String id,
       required String name,
     }) = _MyModel;
     factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
   }
   ```

2. **Create Service** (`services/my_service.dart`)
   ```dart
   Future<MyModel> getMyData() async {
     return supabase.from('my_table').select().single();
   }
   ```

3. **Create Repository** (`repositories/my_repository.dart`)
   ```dart
   Future<MyModel> getData() async {
     return _databaseService.fetchData(table: 'my_table');
   }
   ```

4. **Create Providers** (`providers/my_provider.dart`)
   ```dart
   final myDataProvider = FutureProvider<MyModel>((ref) async {
     final repo = ref.watch(myRepositoryProvider);
     return repo.getData();
   });
   ```

5. **Use in Screens**
   ```dart
   final data = ref.watch(myDataProvider);
   ```

---

## Running the App

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run Freezed code generation:**
   ```bash
   dart run build_runner build
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

---

## Useful Commands

```bash
# Format code
dart format lib/

# Analyze code
dart analyze lib/

# Generate Freezed models
dart run build_runner build --delete-conflicting-outputs

# Watch for changes
dart run build_runner watch

# Clean and rebuild
flutter clean && flutter pub get && dart run build_runner build
```

---

## Next Steps for Developers

1. **Complete Screen Implementations**
   - Implement screens in `screens/client/` and `screens/worker/`
   - Use the existing providers to fetch and display data

2. **Add More Widgets**
   - Create job cards, bid cards, contract cards in `widgets/specific/`
   - Reuse common widgets from `widgets/common/`

3. **Real-time Chat**
   - Implement `RealtimeService` subscriptions to `messages` table
   - Use `StreamBuilder` in chat UI for real-time updates

4. **Image Handling**
   - Implement image picking and uploading in relevant screens
   - Use `StorageService` for Supabase Storage integration

5. **Testing**
   - Add unit tests for repositories and services
   - Add widget tests for UI components
   - Add integration tests for complete user flows

6. **Performance Optimization**
   - Implement pagination for lists
   - Use caching and provider dependencies
   - Lazy load images with `CachedNetworkImage`

7. **Push Notifications**
   - Integrate Firebase Cloud Messaging
   - Send notifications for new bids, messages, contract updates

8. **Analytics**
   - Add analytics for user actions
   - Track job creation, bids, completed projects

---

## Important Notes

- **Never commit Supabase credentials** - use environment variables in production
- **Soft deletes only** - use `is_deleted` flag instead of hard deletes
- **Freezed models** - Always use Freezed for immutability and safety
- **Provider invalidation** - Remember to refresh providers after mutations
- **Error messages** - Show user-friendly error messages, log details for debugging
- **Images in Cloud Storage** - Store only URLs in database, actual files in Supabase Storage

---

## Support & Debugging

Use `AppLogger` for debugging:
```dart
AppLogger.log('User created successfully');
AppLogger.logError('Failed to create user', error);
AppLogger.logDebug('Job data: $jobData');
```

---

**Happy coding! 🚀**
