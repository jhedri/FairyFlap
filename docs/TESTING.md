# Fairy Flap — Testing Documentation

Documentation for **App Store review**, **QA**, and **pre-submission verification**.

---

## App summary (for reviewers)

| Item | Value |
|------|-------|
| **App name** | Fairy Flap |
| **Bundle ID** | `com.jeffhedrick.FairyFlap` |
| **Platform** | iPhone only |
| **Minimum iOS** | 17.6 |
| **Orientation** | Portrait |
| **Login / account** | Not required |
| **Network** | Not required (fully offline) |
| **In-app purchases** | None |
| **Ads** | None |
| **Encryption** | Standard iOS only (`ITSAppUsesNonExemptEncryption = false`) |

---

## How to use the app (manual review steps)

Apple reviewers can verify the app in under two minutes with no setup:

1. **Launch** — Open Fairy Flap. The home screen shows the title, last score, top score, and a green **PLAY** button.
2. **Start** — Tap anywhere on the screen (or the PLAY button).
3. **Play** — Tap to flap the fairy upward. Avoid stone obstacles. Pass through gaps to increase score.
4. **Collectibles** — Fairy dust grants temporary invincibility. Spike balls transform the fairy into a unicorn briefly and add bonus points.
5. **Game over** — Hitting an obstacle or the ground ends the run. The screen flashes red briefly, then returns to the home screen automatically.
6. **Restart** — Tap anywhere on the home screen to start a new run.

No permissions, sign-in, or network connection are needed.

---

## Automated UI tests

Fairy Flap includes an **XCUITest** target (`FairyFlapUITests`) with smoke tests that mirror what App Store review checks: launch stability, gameplay input, sustained play, game-over flow, restart, and portrait orientation.

### Test targets

| Target | Type | Purpose |
|--------|------|---------|
| `FairyFlapUITests` | UI (XCUITest) | Core smoke tests — launch, gameplay, game over, restart |
| `FairyFlapDeviceUITests` | UI (XCUITest) | Same flows validated on small and large simulators |
| `FairyFlapUITestsLaunchTests` | UI (XCUITest) | Launch screenshots across UI configurations |
| `FairyFlapTests` | Unit | Infrastructure / logic tests |

### Core test cases (`FairyFlapUITests`)

| Test | Verifies |
|------|----------|
| `testAppLaunchesSuccessfully` | App reaches foreground without crashing |
| `testMainGameSceneLoadsWithoutCrashing` | Transition from home → gameplay works |
| `testTapStartsGameplay` | Tap input starts a session |
| `testMultipleTapsDoNotCrash` | Repeated taps during gameplay are stable |
| `testGameRunsForSeveralSecondsWithoutCrashing` | Sustained play (~5 s) does not crash |
| `testGameOverReturnsWithoutCrashing` | Death → return home completes without crash |
| `testRestartAfterGameOverStartsNewRun` | New session starts after game over |
| `testPortraitOrientationRemainsStable` | Portrait orientation is stable |
| `testRelaunchAfterGameplayShowsHomeScreen` | Terminate and relaunch returns to home |

### Device tests (`FairyFlapDeviceUITests`)

| Test | Verifies |
|------|----------|
| `testHomeScreenLoadsOnCurrentDevice` | Home screen on current simulator size |
| `testGameplayAndTapsOnCurrentDevice` | Gameplay and taps on current simulator |
| `testGameOverFlowOnCurrentDevice` | Game-over cycle on current simulator |

---

## Supported devices and iOS versions

### Minimum OS

- **iOS 17.6** (deployment target in Xcode)

### Recommended test matrix (App Store review coverage)

| Category | Simulator | Logical size | Role |
|----------|-----------|--------------|------|
| Small | iPhone 16e | 375 × 667 class | SE / compact phone substitute |
| Standard | iPhone 16 | 393 × 852 | Modern standard iPhone |
| Large | iPhone 17 Pro Max | 440 × 956 | Largest iPhone layout |

> **Note:** If iPhone SE (3rd gen) or iPhone 15 simulators are installed, they can be substituted in the run script. The project uses the closest available runtime when older simulators are not present.

### Physical device tested

- iPhone 17 Pro (development device)

---

## Running tests

### Prerequisites

- Xcode 16 or later
- iOS Simulator runtimes for iOS 17.6+
- Open `FairyFlap.xcodeproj`

### Run all UI tests in Xcode

1. Select a simulator (e.g. **iPhone 17 Pro**).
2. **Product → Test** (⌘U), or click the diamond next to `FairyFlapUITests`.

### Run UI tests from Terminal (single device)

```bash
cd /path/to/FairyFlap-master

xcodebuild test \
  -scheme FairyFlap \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:FairyFlapUITests
```

### Run UI tests on small + standard + large simulators

```bash
./scripts/run-ui-tests.sh
```

This runs the full `FairyFlapUITests` suite on:

- iPhone 16e (small)
- iPhone 16 (standard)
- iPhone 17 Pro Max (large)

### Expected result

```
** TEST SUCCEEDED **
Executed 14 tests, with 0 failures
```

(14 tests = 9 core + 3 device + 2 launch screenshot tests)

---

## Pre-submission checklist

Use this before uploading a build to App Store Connect:

- [ ] App builds in **Release** configuration
- [ ] Version and build number incremented in Xcode
- [ ] `./scripts/run-ui-tests.sh` passes on all three simulators
- [ ] Manual smoke test on a physical iPhone (launch → play → die → restart)
- [ ] Portrait-only gameplay confirmed on device
- [ ] No crash on launch with airplane mode enabled (offline)
- [ ] App icon and launch screen display correctly
- [ ] Privacy policy URL live (if required)
- [ ] Review video updated if gameplay changed (`docs/fairy-flap-review-video.mp4`)

---

## App Store Connect — Review Notes (copy/paste)

Paste the following into **App Store Connect → App Review Information → Notes**:

```
Fairy Flap is an offline SpriteKit game. No login, account, or network access is required.

HOW TO TEST:
1. Launch the app.
2. Tap anywhere to start.
3. Tap repeatedly to flap and avoid obstacles.
4. When the fairy hits an obstacle, the app returns to the home screen automatically.
5. Tap again to restart.

ORIENTATION: Portrait only on iPhone.
MINIMUM iOS: 17.6

Automated UI tests (XCUITest) cover launch, gameplay taps, sustained play,
game-over/restart, and portrait stability on small and large iPhone simulators.

Testing documentation: [YOUR_GITHUB_PAGES_URL]/testing.html
Review video: [YOUR_GITHUB_PAGES_URL]/review.html
Support: [YOUR_GITHUB_PAGES_URL]/
Contact: jhedri@icloud.com
```

Replace `[YOUR_GITHUB_PAGES_URL]` with your hosted docs URL (e.g. `https://jhedri.github.io/FairyFlap/docs`).

---

## Test implementation notes

- UI tests launch the app with `-UITesting`, which resets local scores for deterministic runs.
- SpriteKit nodes are not fully visible to XCUITest; tests use **normalized coordinate taps** (center of screen) rather than fixed pixel positions, so they work across device sizes.
- Accessibility identifiers are set on home-screen labels and the score label for VoiceOver and future test improvements.
- Game over is automatic — there is no separate restart button; the home screen accepts taps anywhere to start again.

---

## Contact

Questions about testing or review: **jhedri@icloud.com**
