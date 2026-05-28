# Android Updates

NovaShop uses two Android update paths:

- GitHub Releases for full APK installs.
- Shorebird for small Flutter patches after a Shorebird release APK is installed.

## One-time GitHub setup

Create a Shorebird app from the Shorebird console, then configure this GitHub
repository:

- Repository secret `SHOREBIRD_TOKEN`: Shorebird API token.
- Repository variable `SHOREBIRD_APP_ID`: Shorebird app id.

Do not commit tokens. The app id is not secret, but CI injects it into
`shorebird.yaml` so local builds cannot accidentally target a production app.

## Create a patchable APK

Run the GitHub Action `Android Shorebird Release` manually and provide a tag,
for example `v0.1.6-test`.

The workflow:

- validates `SHOREBIRD_TOKEN` and `SHOREBIRD_APP_ID`;
- runs dependency fetch, analysis, and tests;
- runs `shorebird release android --artifact apk`;
- publishes the APK to a GitHub Release.

Install that APK on Android devices. Future Dart/UI fixes can then be delivered
with Shorebird patches.

Shorebird `auto_update` is enabled. Patch checks can still be triggered from the
settings screen, but installed release builds also download available patches in
the background on launch. The patch applies after the next app restart.

## Publish a small patch

Run the GitHub Action `Android Shorebird Patch` manually.

Use `latest` for the most recent Shorebird release, or pass a specific
Shorebird release version when needed.

Only use patches for Dart/Flutter changes. Use a full APK release for native
Android changes, permissions, Gradle changes, dependency changes that affect
native code, app icons, signing changes, or other platform-level changes.
