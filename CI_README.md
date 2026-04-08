# Hoosh CI/CD

This repository uses a production-only Flutter deployment pipeline built with Fastlane and GitHub Actions.

## What is included

- `.github/workflows/ci.yml`
- `.github/workflows/deploy-android.yml`
- `.github/workflows/deploy-ios.yml`
- `fastlane/Appfile`
- `fastlane/Fastfile`
- `fastlane/Matchfile`
- `fastlane/gen_release_notes`
- store metadata scaffolding under `fastlane/metadata/`

## Production IDs used

- Android application ID: `com.hoosh.app`
- iOS bundle identifier: `com.hoosh.app`
- Apple Developer Team ID: `2Q3YD93YN8`

## Required prerequisites

Before the deploy workflows can succeed, the team still needs:

- an existing Google Play Console app for `com.hoosh.app`
- an existing App Store Connect app for `com.hoosh.app`
- Google Play Android Developer API enabled in the Cloud project linked to Play Console
- a private `match` repo with App Store signing assets
- real store metadata replacing the placeholder scaffold in `fastlane/metadata/`

## Required GitHub secrets

### Android

- `ANDROID_SERVICE_ACCOUNT_JSON`
- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_ALIAS`
- `KEY_PASSWORD`

### iOS

- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`
- `MATCH_GIT_URL`
- `MATCH_PASSWORD`

### Optional

- `SLACK_WEBHOOK`
- `FIREBASE_TOKEN`

## Recommended GitHub environments

- `android-production`
- `ios-production`

The deploy workflows already reference these names so approvals can be added later.

## Build numbering

The workflows compute a unique build number using:

```bash
APP_BUILD_NUMBER=$((GITHUB_RUN_NUMBER * 100 + GITHUB_RUN_ATTEMPT))
```

This avoids duplicate App Store Connect and Play Console build numbers on reruns.

## Local Fastlane usage

Install Ruby gems:

```bash
bundle install
```

Example Android prerequisites:

```bash
export ANDROID_SERVICE_ACCOUNT_JSON_PATH="$PWD/.secrets/play.json"
export KEYSTORE_PATH="$PWD/.secrets/upload-keystore.jks"
export KEYSTORE_PASSWORD="..."
export KEY_ALIAS="..."
export KEY_PASSWORD="..."
```

Local Android release signing can also use a file-based fallback:

```bash
cp android/key.properties.example android/key.properties
```

Then update `android/key.properties` with your real values:

```properties
storePassword=...
keyPassword=...
keyAlias=hoosh-upload
storeFile=../.secrets/hoosh-upload-keystore.jks
```

Gradle will prefer CI environment variables when present, and otherwise use `android/key.properties` for local release builds.

Example iOS prerequisites:

```bash
export APP_STORE_CONNECT_API_KEY_ID="..."
export APP_STORE_CONNECT_API_ISSUER_ID="..."
export APP_STORE_CONNECT_API_KEY_PATH="$PWD/.secrets/AuthKey.p8"
export MATCH_GIT_URL="https://..."
export MATCH_PASSWORD="..."
```

Run lanes:

```bash
bundle exec fastlane android a_rel
bundle exec fastlane ios prepare_ios_signing
bundle exec fastlane ios i_rel
```

## iOS runner note

The workflow defaults to `macos-latest` because it is the most broadly available GitHub-hosted runner. If Apple’s current App Store submission requirement exceeds the Xcode version on that runner, move iOS deploys to a runner image that satisfies Apple’s rule before shipping production releases.
