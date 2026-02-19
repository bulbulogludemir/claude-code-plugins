---
name: eas-build
description: EAS Build, TestFlight, Play Store, OTA updates
triggers:
  - eas build
  - testflight
  - play store
  - app store
  - ota update
  - expo updates
  - uygulama mağazası
---

# EAS Build & App Store

Build, submit, and update Expo apps.

## 1. eas.json Configuration

```json
{
  "cli": {
    "version": ">= 12.0.0",
    "appVersionSource": "remote"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "ios": {
        "simulator": true
      },
      "env": {
        "APP_ENV": "development"
      }
    },
    "preview": {
      "distribution": "internal",
      "ios": {
        "simulator": false
      },
      "env": {
        "APP_ENV": "preview"
      },
      "channel": "preview"
    },
    "production": {
      "autoIncrement": true,
      "env": {
        "APP_ENV": "production"
      },
      "channel": "production"
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "your@email.com",
        "ascAppId": "1234567890",
        "appleTeamId": "XXXXXXXXXX"
      },
      "android": {
        "serviceAccountKeyPath": "./google-services.json",
        "track": "internal"
      }
    }
  }
}
```

## 2. Build Commands

```bash
# Development (with dev client)
eas build --profile development --platform ios
eas build --profile development --platform android

# Preview (internal testing)
eas build --profile preview --platform all

# Production
eas build --profile production --platform all

# Local build (no EAS servers)
eas build --profile development --platform ios --local
```

## 3. Submit to App Stores

```bash
# iOS — TestFlight
eas submit --platform ios --profile production

# Android — Play Store (internal track)
eas submit --platform android --profile production

# Auto-submit after build
eas build --profile production --platform all --auto-submit
```

## 4. OTA Updates (expo-updates)

### Setup

```bash
npx expo install expo-updates
```

### app.json / app.config.ts

```json
{
  "expo": {
    "updates": {
      "url": "https://u.expo.dev/YOUR_PROJECT_ID",
      "enabled": true,
      "fallbackToCacheTimeout": 0
    },
    "runtimeVersion": {
      "policy": "appVersion"
    }
  }
}
```

### Push OTA Update

```bash
# Update production channel
eas update --branch production --message "Bug fix: login crash"

# Update preview channel
eas update --branch preview --message "New feature: profile page"

# Update with specific platform
eas update --branch production --platform ios --message "iOS-specific fix"
```

### Check for Updates in App

```typescript
import * as Updates from 'expo-updates'

export async function checkForUpdates() {
  if (__DEV__) return

  try {
    const update = await Updates.checkForUpdateAsync()
    if (update.isAvailable) {
      await Updates.fetchUpdateAsync()
      await Updates.reloadAsync()
    }
  } catch (error) {
    console.error('Update check failed:', error)
  }
}
```

## 5. Channel Management

```
production → Live app store builds
preview    → Internal testing (TestFlight/Internal Track)
development → Dev builds with dev client
```

```bash
# List channels
eas channel:list

# Create channel
eas channel:create staging

# Point channel to branch
eas channel:edit staging --branch staging
```

## 6. Environment Variables

```bash
# Set build-time env vars
eas secret:create --name API_URL --value "https://api.example.com" --scope project

# List secrets
eas secret:list
```

## Gotchas

| Issue | Solution |
|-------|----------|
| Build fails with provisioning | Run `eas credentials` to manage |
| OTA update not showing | Check runtimeVersion matches |
| Android keystore issues | `eas credentials --platform android` |
| "expo-updates not configured" | Add updates config to app.json |
| Build queue slow | Use `--local` for local builds |
