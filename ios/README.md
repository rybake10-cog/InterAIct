# InterAIct for iPhone & iPad

A native SwiftUI version of InterAIct that autistic children can use on an iPhone or iPad to practice everyday social situations. It runs fully on the device: no camera, microphone, accounts, or internet.

## Features

- **Companion friends**: Whiskers the Cat, Buddy the Dog, Hoppy the Rabbit, and Berry the Bear guide the child, as in the Streamlit app.
- **8 social situations**: Taking Turns (ported from the original app, with its videos), Saying Hello, Joining a Game, When Plans Change, Too Loud!, Losing a Game, Asking for Help, and Personal Space.
- **Gentle feedback**: choices are marked *Great choice*, *Good thinking*, or *Let's think about it*. There is no red, no buzzer, and no timer. By default the child tries again until they find the most helpful choice. Choices already tried are dimmed.
- **Read aloud**: every prompt, choice, and piece of feedback has a speaker button. Text can also be read automatically using on-device text-to-speech (`AVSpeechSynthesizer`).
- **Feelings check-in** before and after each situation. If the child picks worried, sad, or angry, the app offers the Calm Corner.
- **Calm Corner**: a breathing balloon (4 seconds in, 4 seconds out) and a 5-4-3-2-1 senses exercise. You can open it from any screen.
- **Stars** for each finished situation.
- **Grown-ups area** behind a simple math question: progress for each situation, a log of recent feelings, and settings (read aloud, voice speed, videos, check-ins, retry mode, name, companion), plus reset.
- Large tap targets, Dynamic Type, VoiceOver labels, and Reduce Motion support. The layout adapts to iPhone and iPad in portrait or landscape. On Apple silicon Macs the app also runs as "Designed for iPad".

## Requirements

- macOS with **Xcode 16 or later** (the project uses Xcode 16 synchronized folders)
- iOS / iPadOS **17.0+**

## Run it

1. Open `ios/InterAIct.xcodeproj` in Xcode.
2. Choose the **InterAIct** scheme and an iPhone or iPad simulator, then press **Run** (⌘R).
3. To install on a real device: select the **InterAIct** target, open *Signing & Capabilities*, choose your Team, and if needed change the bundle identifier (`org.interaict.InterAIct`) to one you own.

Run the tests with ⌘U, or from the command line:

```bash
cd ios
xcodebuild test -project InterAIct.xcodeproj -scheme InterAIct \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)'
```

To check the scenario content without Xcode, run `python3 tests/test_ios_scenarios.py` from the repo root.

## Project layout

```
ios/
  InterAIct.xcodeproj
  InterAIct/
    App/          App entry point and environment setup
    Models/       Avatar, Scenario/Phase/Choice, Feeling, progress records
    Logic/        ScenarioLibrary (loading + validation), ScenarioSession (play state machine),
                  ProgressStore (on-device JSON), AppSettings (UserDefaults)
    Services/     Speaker (text-to-speech)
    Views/        SwiftUI screens and components
    Resources/    scenarios.json  <- all situation content lives here
    Assets.xcassets
  InterAIctTests/ XCTest unit tests
```

The Taking Turns videos come straight from `src/interAIct/videos` through a synchronized folder, so they are not copied into the app folder.

## Adding or editing situations

All content is in `InterAIct/Resources/scenarios.json`. Each scenario has phases. Each phase has a `prompt`, an emoji `scene`, an optional `video` (an `.mp4` name in `src/interAIct/videos`), and `choices`. Each choice has:

| field      | meaning |
|------------|---------|
| `kind`     | `great` (most helpful), `okay`, or `tryAgain` |
| `feedback` | what the companion says after this choice |
| `next`     | id of the next phase, or `null` to finish |

Every phase needs at least one `great` choice. The app validates the content when it loads, and the tests check the same rules.
