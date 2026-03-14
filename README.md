# EmbyPulse iOS

SwiftUI `iOS 16+` client for Emby Pulse.

Current project includes:

- Login and invite registration
- Dashboard, live sessions, trends, and recent playback
- Calendar, requests, feedback, and request portal
- User management and invite code management
- Client control, quality insight, and gap management
- Bot config, system settings, tasks center, and report workshop

## Build

```bash
xcodebuild -project EmbyPulseiOS.xcodeproj -scheme EmbyPulseiOS -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

## Project Generation

```bash
xcodegen generate
```

## Self Test

- Manual checklist: `docs/integration-self-test.md`
- API smoke script: `scripts/api_smoke_test.sh`

Read-only smoke example:

```bash
BASE_URL=http://127.0.0.1:10307 ADMIN_USER=admin ADMIN_PASS=yourpass \
./scripts/api_smoke_test.sh
```

## Unsigned IPA via GitHub Actions

This repo includes `.github/workflows/build-unsigned-ipa.yml`.

After pushing to GitHub:

1. Open the repository `Actions` tab.
2. Run `Build Unsigned IPA`.
3. Download the `EmbyPulseiOS-unsigned-ipa` artifact.

Note: the generated IPA is unsigned and is intended for packaging/output workflows, not direct installation on stock iOS devices.
