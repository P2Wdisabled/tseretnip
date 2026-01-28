# Tseretnip - AI Copilot Instructions

## Project Overview
Tseretnip is a Flutter-based social media app for sharing photos with like functionality, built with Supabase as the backend (auth, database, storage) and adaptive theming support.

## Architecture

### Core Structure
- **Single Repository Pattern**: All backend interactions go through `SupabaseRepository` (`lib/services/core/services/supabase_repository.dart`)
- **Pages**: Stateful widgets in `lib/pages/` for UI (auth, home, profile, likes_page, upload_photos_page)
- **Models Layer**: Proper model classes in `lib/models/` with `fromJson`/`toJson` serialization (Post, Account, Like)
- **Auth-First Navigation**: `AuthGate` in `main.dart` streams auth state to route users to `AuthPage` or `HomePage`
- **Adaptive Theming**: Uses `adaptive_theme` package for system/light/dark theme switching

### Data Flow Pattern
1. Pages call `SupabaseRepository` methods
2. Repository methods use `Supabase.instance.client` singleton
3. Data returns as typed model objects (e.g., `List<Post>`, `Account`)
4. Models handle Supabase JSON parsing with specialized logic (like count aggregation)

## Critical Configuration

### Environment Variables (REQUIRED)
Uses `dart-define-from-file` for Supabase credentials:

```bash
# ALWAYS run/debug with:
flutter run --dart-define-from-file=config.json

# Setup (first time):
# Create config.json with:
# {
#   "SUPABASE_URL": "your_supabase_url",
#   "SUPABASE_ANON_KEY": "your_anon_key", 
#   "SUPABASE_DB_PASSWORD": "your_db_password"
# }
```

Config is loaded via `String.fromEnvironment()` in `lib/services/core/config/app_config.dart`. **Never hardcode credentials**.

### Build Configuration
- `analysis_options.yaml` uses `package:flutter_lints/flutter.yaml` (standard Flutter lints)
- No custom linter rules defined

## Supabase Integration Patterns

### Database Schema (Implicit from Code)
- **accounts**: `id` (UUID, links to auth.users), `username`, `description`, `avatar`, `banner`
- **posts**: `id` (int), `user_id` (UUID), `image_url`, `caption`, `created_at`
- **likes**: `user_id` (UUID), `post_id` (int) - composite unique constraint

### Storage Buckets
- `avatars/`: User profile pictures (`{user_id}/avatar_{timestamp}.jpg`)
- `banner/`: Profile banners (`{user_id}/banner_{timestamp}.jpg`)
- `posts/`: Photo posts (`{user_id}/{timestamp}.jpg`)

All uploads use `fileOptions: FileOptions(cacheControl: '3600', upsert: false)`.

### Query Patterns
**Joins**: Supabase REST API style with `select()`:
```dart
// Get posts with like counts:
.from('posts').select('*, likes(count)')

// Get liked posts with post details:
.from('likes').select('post_id, posts(*, likes(count))')
```

**Current User**: Always access via `Supabase.instance.client.auth.currentUser` (or `_repository.currentUser` getter).

### Image Handling
- **Posts**: Images stored as **base64 strings** in `posts.image` column (non-standard, storage bucket unused for retrieval)
- **Profiles**: Images stored in buckets, URLs stored in `avatar`/`banner` columns
- Decode base64 images with: `Image.memory(base64Decode(base64Image.split(',').last))`

## Development Patterns

### State Management
- **Local State**: `StatefulWidget` with `setState()` - no external state management
- **Optimistic UI**: Like buttons update immediately, rollback on error (see `PostActionsBar._toggleLike()`)
- **Refresh Pattern**: Pull-to-refresh with `RefreshIndicator` calling data load methods

### Error Handling Convention
```dart
try {
  // operation
} catch (e) {
  print('❌ Error message: $e');  // Debug prints with emojis
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'))
    );
  }
}
```

### Profile Creation Flow
- Profiles created **manually** in `signUp()` repository method (inserts into `accounts` table)
- Auto-creates missing profile in `getCurrentProfile()` if user exists but profile doesn't
- Uses `user.email.split('@')[0]` as fallback username

### Navigation Pattern
```dart
// To other user profile:
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ProfilePage(userId: otherUserId)
));

// To own profile:
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ProfilePage()  // userId null
));
```

## Key Files Reference

- **Entry Point**: [lib/main.dart](lib/main.dart) - Supabase initialization, `AuthGate` router
- **Data Layer**: [lib/services/core/services/supabase_repository.dart](lib/services/core/services/supabase_repository.dart) - All backend operations
- **Config**: [lib/services/core/config/app_config.dart](lib/services/core/config/app_config.dart) - Environment variable access
- **Primary UI**: [lib/pages/home.dart](lib/pages/home.dart) - Post feed with likes
- **User Management**: [lib/pages/auth.dart](lib/pages/auth.dart), [lib/pages/profile.dart](lib/pages/profile.dart)
- **Photo Upload**: [lib/pages/upload_photos_page.dart](lib/pages/upload_photos_page.dart) - Multi-image upload functionality

## Testing & Debugging

### Common Commands
```bash
# Run with config
flutter run --dart-define-from-file=config.json

# Clean build (if issues)
flutter clean && flutter pub get

# Hot reload works in development (r key)
```

### Debug Prints
Code uses emoji-prefixed prints for tracking:
- 🔄 Loading operations
- ✅ Success states
- ❌ Errors
- 📡 Network calls
- 📸 Post data

## Project-Specific Quirks

1. **Typed Models**: Despite having `lib/models/` directory with proper model classes, some legacy patterns exist
2. **Base64 image storage**: Posts store images as base64, not using `image_url` from storage
3. **Manual profile sync**: `accounts` table isn't auto-synced via Supabase triggers; done in app code
4. **Like count aggregation**: Uses Supabase's `select('*, likes(count)')` syntax, parsed in `Post.fromJson()` model
5. **Image picker pattern**: Uses `image_picker` package, converts `XFile` to `File` before upload

## Dependencies

Main packages (from [pubspec.yaml](pubspec.yaml)):
- `supabase_flutter: ^2.0.0` - Backend SDK
- `image_picker: ^1.1.2` - Photo selection
- `google_fonts: ^6.1.0` - Typography
- `adaptive_theme: ^3.0.0` - System/light/dark theme switching
- `flutter_lints: ^6.0.0` - Linting (dev)

No state management libraries (Provider, Riverpod, Bloc) used.
- `image_picker: ^1.0.7` - Photo selection
- `google_fonts: ^6.1.0` - Typography
- `flutter_lints: ^6.0.0` - Linting (dev)

No state management libraries (Provider, Riverpod, Bloc) used.
