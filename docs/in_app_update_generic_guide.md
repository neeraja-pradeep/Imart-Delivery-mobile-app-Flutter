# In-App Update — Generic Implementation Guide

A project-agnostic guide for adding Android in-app updates to any Flutter app
using the [`in_app_update`](https://pub.dev/packages/in_app_update) package.
Nothing here is tied to a specific codebase — copy the snippets and adapt the
names to your own architecture.

---

## 1. What this package does

`in_app_update` is a thin Flutter wrapper around Android's **Play Core / Play
In-App Update API**. It lets a running app detect that a newer version is
available on the Google Play Store and prompt the user to update **without
leaving the app**.

It supports the two update flows defined by Google:

| Flow | Behaviour | Use when |
|------|-----------|----------|
| **Flexible** | Update downloads in the background; user keeps using the app, then is asked to restart to apply. | Optional / non-critical updates. |
| **Immediate** | Full-screen blocking UI; user must update before continuing. | Critical updates (security, breaking API changes, forced version). |

### Hard limits (important)

- **Android only.** There is no iOS equivalent — Apple does not allow it. On
  iOS you must fall back to a "new version available" dialog that links to the
  App Store (e.g. via the `upgrader` package or a custom version check).
- **Only works for apps installed from the Google Play Store.** Debug builds,
  sideloaded APKs, emulators without Play, and internal-app-sharing builds will
  throw or report "no update available".
- The update an in-app update installs is the version **published on Play**, not
  an arbitrary APK you host.
- Requires the device's Play Store to actually have a higher `versionCode`
  available for the current track the tester is on.

---

## 2. Install

In `pubspec.yaml`:

```yaml
dependencies:
  in_app_update: ^4.2.3   # check pub.dev for the latest version
```

Then:

```bash
flutter pub get
```

### Android configuration

- **`minSdkVersion`**: Play In-App Updates require **API 21+**. Most modern
  Flutter apps already satisfy this.
- No extra permissions or manifest entries are required — the package pulls in
  the Play Core dependency transitively.
- If you use Proguard/R8 with aggressive shrinking and hit issues, ensure Play
  Core classes are kept (the plugin normally ships its own consumer rules, so
  this is rarely needed).

> There is **no iOS setup** because the plugin is a no-op / unsupported there.
> Always guard calls with a platform check (see §6).

---

## 3. Public API surface

The package exposes a small static API via the `InAppUpdate` class:

```dart
// 1. Ask Play whether an update exists.
Future<AppUpdateInfo> InAppUpdate.checkForUpdate();

// 2. Start a blocking, full-screen immediate update.
Future<AppUpdateResult> InAppUpdate.performImmediateUpdate();

// 3. Start a background flexible update download.
Future<AppUpdateResult> InAppUpdate.startFlexibleUpdate();

// 4. After a flexible download finishes, apply & restart.
Future<void> InAppUpdate.completeFlexibleUpdate();
```

### `AppUpdateInfo` fields

| Field | Type | Meaning |
|-------|------|---------|
| `updateAvailability` | `UpdateAvailability` | `updateAvailable`, `updateNotAvailable`, `developerTriggeredUpdateInProgress`, or `unknown`. |
| `immediateUpdateAllowed` | `bool` | Whether Play permits an immediate flow for this update. |
| `flexibleUpdateAllowed` | `bool` | Whether Play permits a flexible flow. |
| `availableVersionCode` | `int?` | The `versionCode` available on Play. |
| `installStatus` | `InstallStatus` | Status of an in-progress flexible install (e.g. `downloaded`, `downloading`, `installing`). |
| `packageName` | `String` | App package name. |
| `clientVersionStalenessDays` | `int?` | How many days since the update became available — useful for deciding *when* to force an update. |
| `updatePriority` | `int` | The Play-console-configured priority (0–5) for this release. |

`AppUpdateResult` is an enum: `success`, `userDeniedUpdate`, `inAppUpdateFailed`.

---

## 4. Minimal usage

### Check, then immediate update

```dart
import 'package:in_app_update/in_app_update.dart';

Future<void> checkForImmediateUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
      // On success Play restarts the app for you.
    }
  } catch (e) {
    // Swallow / log — never block app startup on an update check.
    debugPrint('In-app update check failed: $e');
  }
}
```

### Check, then flexible update

```dart
Future<void> checkForFlexibleUpdate() async {
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability == UpdateAvailability.updateAvailable &&
        info.flexibleUpdateAllowed) {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        // Download finished — prompt the user, then apply.
        await InAppUpdate.completeFlexibleUpdate();
      }
    }
  } catch (e) {
    debugPrint('Flexible update failed: $e');
  }
}
```

---

## 5. A reusable service wrapper

Encapsulate the logic so any screen can trigger it and so policy (when to force
vs. suggest) lives in one place.

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  /// Set this from your Play priority / staleness policy.
  static const int _forceUpdatePriorityThreshold = 4;
  static const int _forceUpdateStalenessDays = 7;

  /// Call from your home screen's initState or first authenticated route.
  Future<void> checkForUpdate() async {
    // Hard guard: the plugin only works on Android + Play installs.
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      if (_shouldForce(info) && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          // Surface a snackbar/banner asking the user to restart,
          // then call complete on their confirmation.
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e, st) {
      debugPrint('AppUpdateService error: $e\n$st');
      // Never rethrow — an update check must not crash the app.
    }
  }

  bool _shouldForce(AppUpdateInfo info) {
    final stale = (info.clientVersionStalenessDays ?? 0) >=
        _forceUpdateStalenessDays;
    final highPriority = info.updatePriority >= _forceUpdatePriorityThreshold;
    return stale || highPriority;
  }
}
```

### Where to call it

- **Good:** after the first authenticated screen mounts, or on app resume.
- **Avoid:** inside `main()` before `runApp`, or on a screen where a sudden
  full-screen Play UI would interrupt a critical flow (checkout, payment).
- Consider throttling — don't check on every single resume; once per session or
  once per N hours is plenty.

---

## 6. Flexible flow with a user-facing "restart" prompt

Because flexible downloads finish silently, you should tell the user before
restarting:

```dart
Future<void> _runFlexibleUpdate(BuildContext context) async {
  final result = await InAppUpdate.startFlexibleUpdate();
  if (result != AppUpdateResult.success) return;

  // Download is ready. Ask before applying so you don't yank the app
  // out from under the user.
  final shouldRestart = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update ready'),
      content: const Text('Restart now to finish updating?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Restart'),
        ),
      ],
    ),
  );

  if (shouldRestart == true) {
    await InAppUpdate.completeFlexibleUpdate();
  }
}
```

---

## 7. Resuming an interrupted immediate update

If an immediate update was interrupted (user backgrounded the app mid-update),
Play reports `developerTriggeredUpdateInProgress` on the next check. Re-trigger
it so the user isn't stuck:

```dart
final info = await InAppUpdate.checkForUpdate();
if (info.updateAvailability ==
    UpdateAvailability.developerTriggeredUpdateInProgress) {
  await InAppUpdate.performImmediateUpdate();
}
```

For flexible updates, check `info.installStatus == InstallStatus.downloaded`
and call `completeFlexibleUpdate()` to apply a download that already finished.

---

## 8. Testing

This is the part that trips everyone up — you **cannot test with a debug build**.

1. **Use a real device** signed into a Google account.
2. Upload your app to a Play track (internal testing is fastest) with a
   **lower** `versionCode` than the build you'll test the update *to*.
3. Install that lower version from Play (via the internal-testing opt-in link or
   internal app sharing).
4. Upload a **higher** `versionCode` build to the same track and let it process.
5. Open the installed (lower) app — `checkForUpdate()` should now report
   `updateAvailable`.

Tips:
- **Internal App Sharing** gives the fastest turnaround for repeated testing.
- `updatePriority` must be set at **publish time** via the Play Developer API
  (the `inappupdatepriority` field on the release) — it cannot be changed for an
  already-published release, and the Play Console UI does not expose it.
- `clientVersionStalenessDays` only grows over real calendar time, so forcing by
  staleness is hard to test quickly — test the priority path instead.

---

## 9. Error handling & edge cases

| Situation | What happens | Handling |
|-----------|--------------|----------|
| Not installed from Play | `checkForUpdate()` throws a `PlatformException`. | Wrap in try/catch; treat as "no update". |
| iOS / web | Plugin unsupported. | Guard with `Platform.isAndroid`. |
| No network | Throws / returns unknown. | Catch and ignore; retry later. |
| User dismisses immediate update | App may close (immediate flow is blocking). | Re-check on next launch. |
| User taps "Later" on flexible | Download stays cached; apply later. | Persist intent; offer again. |
| `performImmediateUpdate` returns `userDeniedUpdate` | User backed out. | Decide whether to re-prompt or allow continued use. |

Golden rule: **an update check must never crash or block the app.** Always
try/catch and fail open.

---

## 10. iOS / cross-platform fallback

Since this package is Android-only, pair it with a manual version check for iOS:

- Query your backend (or the App Store lookup API) for the latest version.
- Compare against the running version (`package_info_plus`).
- Show a dialog linking to the App Store via `url_launcher`.

Or use a cross-platform package such as `upgrader`, and let `in_app_update`
handle the smoother Android experience while `upgrader` covers iOS.

---

## 11. Quick checklist

- [ ] `in_app_update` added to `pubspec.yaml`, `flutter pub get` run.
- [ ] `minSdkVersion >= 21`.
- [ ] All calls guarded with `Platform.isAndroid` and wrapped in try/catch.
- [ ] Decided force (immediate) vs. suggest (flexible) policy.
- [ ] Flexible flow asks the user before restarting.
- [ ] Handles `developerTriggeredUpdateInProgress` resume case.
- [ ] iOS fallback in place (dialog → App Store).
- [ ] Tested via a real Play track (not a debug build).

---

## 12. References

- Package: <https://pub.dev/packages/in_app_update>
- Google docs — In-app updates: <https://developer.android.com/guide/playcore/in-app-updates>
- Update priority (Play Developer API): <https://developer.android.com/guide/playcore/in-app-updates#set-update-priority>
