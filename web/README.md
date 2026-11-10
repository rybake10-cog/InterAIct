# InterAIct on the web

A plain HTML, CSS and JavaScript version of InterAIct that autistic children can use in any modern browser, including Safari on iPhone and iPad, to practice everyday social situations. It has the same features as the iOS app in `ios/`:

- Companion friends (Whiskers, Buddy, Hoppy and Berry) and an optional child name.
- The 8 social situations from `ios/InterAIct/Resources/scenarios.json`, with branching choices and gentle feedback (green, gold and blue, never red).
- "Try another way", with an optional "keep trying until the most helpful choice" mode.
- Taking Turns videos from `src/interAIct/videos/`; if a video can't play, the scene's emoji picture is shown instead.
- Read aloud with the browser's built-in voice.
- Feelings check-ins before and after each situation, with a gentle Calm Corner suggestion for worried, sad or angry.
- Calm Corner: a breathing balloon (4 seconds in, 4 seconds out) and the 5-4-3-2-1 senses exercise.
- Stars, plus a grown-ups area behind a math question with progress, recent feelings and settings.

Everything is stored in the browser's `localStorage` on that device. There are no accounts, no camera or microphone, and nothing is sent over the network.

## Run it

Serve the repository root (the site loads videos from `../src/interAIct/videos/`) and open `/web/`:

```bash
python3 -m http.server 8000
# then open http://localhost:8000/web/
```

Opening `web/index.html` directly from disk also works.

## Files

- `index.html`: page shell.
- `styles.css`: layout and theme; respects Reduce Motion.
- `logic.js`: content validation, the scenario state machine and progress stats (shared with the tests).
- `app.js`: screens, read aloud and storage.
- `content.js`: generated copy of `scenarios.json`, so the site works without a server.

## Editing scenarios

Edit `ios/InterAIct/Resources/scenarios.json`, then regenerate the web copy and run the tests:

```bash
python3 web/build_content.py
node --test web/tests/*.test.js
```
