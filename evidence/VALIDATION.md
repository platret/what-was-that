# Validation

Validation performed on 11 September 2026 with Xcode 26.0.

## Native app

- iOS 26 iPhone 17 Pro simulator build succeeds.
- All 10 tests passed: 6 unit tests and 4 UI tests (`verified-tests.xcresult`).
- Model tests cover atomic persistence, filtering, idempotent collection imports, unsafe URL rejection, edit/delete persistence, and corrupt-file protection.
- UI tests exercise onboarding, save/search/relaunch, choosing an untried suggestion, collection creation, tried status, and the native collection share sheet.
- The final picker layout and share sheet also passed a focused UI run with freshly built test binaries (`whatwasthat-layout-verified.xcresult`).
- Actual simulator screenshots are checked in under `site/assets/`.
- Signed app and WidgetKit extension build successfully with the configured development team. Both targets carry the same App Group entitlement.
- The app was installed on the connected physical iPhone 17 Pro running iOS 27. The initial launch request was blocked by the phone's lock screen. Physical interaction and widget refresh verification remain pending until it is unlocked.

## Website

- GitHub Pages deployment completed successfully and the live site returned HTTP 200. The live demo, images, and privacy link were also checked.
- Desktop visual review and mobile layouts at 390 px and 320 px.
- No horizontal overflow at the checked mobile widths.
- Category-specific demo picker produces the matching category.
- Installation disclosure expands, assets load, and no JavaScript console errors were observed locally.

## Practical limits

- Collection sharing transfers a snapshot. Live cross-device collaboration is not implemented.
- Widgets depend on the signed App Group and iOS scheduling. Unsigned simulator builds fall back to app-local storage and do not prove app-to-widget data exchange.
- StoreKit purchases, App Store submission, and TestFlight distribution are not configured. Widgets and sharing are included in this developer edition.
- Xcode's iOS 26 beta SDK emits a simulator asset trait warning for the iPhone 17 Pro and standard XCTest framework stripping messages. These are SDK diagnostics, separate from application test results.
- Device builds use Derived Data outside the synced Documents folder to avoid file-provider Finder metadata interfering with code signing.
