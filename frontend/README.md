# StoreLink Frontend

Indian MSME Business Management SaaS Platform - Flutter Frontend

## Tech Stack
- Flutter 3.16+
- Provider for state management
- Clean Architecture
- Dio for HTTP requests

## Getting Started

### Prerequisites
- Flutter SDK 3.16 or higher
- Dart SDK 3.0 or higher

### Installation

```bash
flutter pub get
```

### Run
```bash
flutter run -d chrome  # For web
flutter run -d android  # For Android
flutter run -d ios      # For iOS
```

### Build
```bash
flutter build web
flutter build apk
flutter build ios
```

## Project Structure
- `lib/core/` - Core utilities, constants, theme
- `lib/data/` - Data layer (models, repositories, data sources)
- `lib/domain/` - Domain layer (entities, use cases)
- `lib/presentation/` - Presentation layer (UI, providers, widgets)
- `lib/routes/` - App routing configuration
