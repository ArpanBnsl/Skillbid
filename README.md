# SkillBid 🎯

A Flutter mobile application connecting clients with skilled service providers. Post jobs, bid on projects, collaborate, and complete work - all in one app.

## Features

✨ **For Clients:**
- Post detailed job requirements with images
- Receive bids from qualified providers
- Compare bids and select the best fit
- Communicate directly with accepted providers
- Rate and review completed work
- Track project status in real-time

🔧 **For Providers:**
- Browse available jobs matching your skills
- Submit competitive bids
- Showcase your portfolio
- Communicate with clients
- Build your reputation through ratings
- Grow your client base

💬 **For Everyone:**
- Real-time messaging after bid acceptance
- Secure authentication
- Image uploads
- Portfolio management
- Review and rating system

---

## Tech Stack

- **Frontend:** Flutter 3.x + Dart
- **State Management:** Riverpod 2.x
- **Navigation:** GoRouter
- **Data Persistence:** Supabase (PostgreSQL)
- **Authentication:** Supabase Auth
- **Cloud Storage:** Supabase Storage
- **Code Generation:** Freezed (immutable models)

---

## Project Structure

```
lib/
├── main.dart                # App entry point
├── config/                  # Configuration & constants
├── models/                  # Data models (Freezed)
├── services/                # Supabase SDK wrappers
├── repositories/            # Business logic layer
├── providers/               # Riverpod state management
├── screens/                 # UI screens (organized by role)
├── widgets/                 # Reusable UI components
├── utils/                   # Validators, formatters, extensions
├── theme/                   # Design tokens & styling
└── routes/                  # Navigation routing
```

**For detailed documentation, see [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)**

---

## Getting Started

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK 3.10+
- Supabase Project

### Setup

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate code**
   ```bash
   dart run build_runner build
   ```

3. **Create Supabase tables**
   - Run `supabase_migration.sql` in Supabase SQL Editor
   - Create storage buckets: `avatars`, `job-images`, `portfolio-images`

4. **Run the app**
   ```bash
   flutter run
   ```

---

## Architecture

Clean, layered architecture for scalability:
- **Presentation Layer** (UI)
- **State Management** (Riverpod providers)
- **Repository Layer** (Business logic)
- **Service Layer** (Supabase interactions)
- **Data Layer** (Models + Database)

See **DEVELOPER_GUIDE.md** for detailed architecture explanation and examples.

---

## Quick Feature Overview

### Client Workflow
1. Browse jobs by skill/location
2. Post new jobs with images
3. Receive and compare bids
4. Accept best bid → Chat enabled
5. Rate work when complete

### Provider Workflow
1. Browse available jobs
2. Submit competitive bid
3. Track bid status
4. Chat with client after acceptance
5. Build portfolio with samples

---

## Development

### Format & Analyze
```bash
dart format lib/
dart analyze lib/
```

### Watch for Changes
```bash
dart run build_runner watch
```

### Run Tests
```bash
flutter test
```

---

## Database

SkillBid uses Supabase PostgreSQL with these core tables:
- `profiles` - User accounts
- `provider_profiles` - Provider info
- `jobs` - Job postings
- `bids` - Provider bids
- `contracts` - Accepted bids
- `messages` - Chat messages
- `chats` - Chat rooms
- And more (see schema in supabase_migration.sql)

---

## Documentation

- **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** - Comprehensive guide for developers
- **[supabase_migration.sql](./supabase_migration.sql)** - Database schema

---

## License

MIT License - See LICENSE file for details

---

**Made with ❤️ in Flutter**
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
