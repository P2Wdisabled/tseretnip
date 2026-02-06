# Changelog

This file documents notable changes to the project.

## 2026-02-04
- **Documentation**: Finalized README, added screenshots to showcase the application.
- **Internationalization**: Fixed language switching bugs and added remaining missing translations.

## 2026-02-03
- **Design & UX**: Complete style overhaul based on graphic assets. Added Lottie animations and SVG icons to make the interface more dynamic.
- **Internationalization**: Finalized the integration of the `flutter_i18n` module.

## 2026-02-02
- **Internationalization**: Initial implementation of the translation system (English / French).

## 2026-02-01
- **UI**: Specific styling work on the image upload/creation page.

## 2026-01-29
- **Feature**: Improved photo publishing logic (SupabaseRepository.publishPhoto integration).
- **Fix**: Various fixes related to uploads.

## 2026-01-28
- **Photos**: Full implementation of photo taking, uploading to Supabase Storage, and deletion.
- **Feed**: Added infinite scrolling and pagination to load posts progressively.
- **Performance**: Implemented `cached_network_image` to optimize image loading.
- **Business Logic**: Post sorting (Recent vs. Ranked) and filtering by user profile.
- **Architecture**: Created data models and initialized the global theme.
- **Fix**: Resolved merge conflicts and restored profile and authentication features.

## 2026-01-27
- **Likes**: Created the "Likes" page and managed optimistic updates for the like counter.
- **Refactoring**: Extracted `PostCard` and `PostActionsBar` components for more modular code.
- **Users**: Implemented Login/Register screens and profile personalization (avatar, bio).
- **Style**: First design pass (banner, Dribbble-inspired).

## 2026-01-26
- **Initialization**: Created the Flutter project (multi-platform boilerplate).
- **Backend**: Full Supabase configuration (Authentication, Database, Storage).
- **DevOps**: Set up environment variables via `dart-define-from-file`.
