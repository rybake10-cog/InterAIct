/* InterAIct web app: screens, speech, and browser-local storage. */
(function () {
  "use strict";

  const L = window.InterAIctLogic;
  const catalog = window.INTERAICT_CONTENT;
  const VIDEO_BASE = "../src/interAIct/videos/";
  const SETTINGS_KEY = "interaict.settings";
  const PROGRESS_KEY = "interaict.progress";
  const DEFAULT_SETTINGS = {
    avatarID: null,
    childName: "",
    readAloud: true,
    speechRate: 0.42,
    showVideos: true,
    feelingsCheckIn: true,
    retryUntilGreat: true,
  };
  const GENTLE_GREEN = "#3E9B6B";

  const $screen = document.getElementById("screen");
  const $topbar = document.getElementById("topbar");
  const $calm = document.getElementById("calm-corner");
  const $grownUps = document.getElementById("grown-ups");

  // MARK: Storage (everything stays in this browser)

  function load(key, fallback) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? Object.assign(fallback, JSON.parse(raw)) : fallback;
    } catch (_) {
      return fallback;
    }
  }
  function save(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch (_) { /* private mode: keep in memory */ }
  }

  const settings = load(SETTINGS_KEY, Object.assign({}, DEFAULT_SETTINGS));
  let progress = load(PROGRESS_KEY, L.emptyProgress());
  const saveSettings = () => save(SETTINGS_KEY, settings);
  const saveProgress = () => save(PROGRESS_KEY, progress);
  const trimmedName = () => settings.childName.trim();
  const currentAvatar = () => L.avatarWithId(settings.avatarID) || L.AVATARS[0];
  const starsText = () => (progress.stars === 1 ? "1 star" : `${progress.stars} stars`);

  const newID = () =>
    (window.crypto && crypto.randomUUID) ? crypto.randomUUID() : `${Date.now()}-${Math.random().toString(16).slice(2)}`;

  function startPlay(scenarioID) {
    const play = { id: newID(), scenarioID, avatarID: settings.avatarID, startedAt: new Date().toISOString(), finishedAt: null, choices: [] };
    progress.plays.push(play);
    saveProgress();
    return play.id;
  }
  function recordChoice(playID, record) {
    const play = progress.plays.find((p) => p.id === playID);
    if (!play) return;
    play.choices.push(record);
    saveProgress();
  }
  function finishPlay(playID) {
    const play = progress.plays.find((p) => p.id === playID);
    if (!play || play.finishedAt) return;
    play.finishedAt = new Date().toISOString();
    progress.stars += 1;
    saveProgress();
  }
  function logFeeling(feelingID, moment, scenarioID) {
    progress.feelings.push({ id: newID(), feeling: feelingID, moment, scenarioID: scenarioID || null, date: new Date().toISOString() });
    saveProgress();
  }

  // MARK: Read aloud

  const speaker = {
    supported: "speechSynthesis" in window,
    speak(text) {
      if (!this.supported || !text) return;
      speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = settings.speechRate / 0.5;
      utterance.pitch = 1.1;
      utterance.lang = navigator.language || "en-US";
      speechSynthesis.speak(utterance);
    },
    autoSpeak(text) { if (settings.readAloud) this.speak(text); },
    stop() { if (this.supported) speechSynthesis.cancel(); },
  };

  const reduceMotion = () => window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // MARK: Markup helpers

  const esc = (value) => String(value).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

  const ICON_PATHS = {
    speaker: "M3 9v6h4l5 5V4L7 9H3zm13.5 3A4.5 4.5 0 0 0 14 8v8a4.5 4.5 0 0 0 2.5-4zM14 3.2v2.1a7 7 0 0 1 0 13.4v2.1a9 9 0 0 0 0-17.6z",
    leaf: "M17 8C8 10 5.9 16.2 3.8 21.3l1.9.7.9-2.3c.5.2 1 .3 1.4.3C19 20 22 3 22 3c-1 2-8 2.3-13 3.3S2 11.5 2 13.5s1.8 3.8 1.8 3.8C7 8 17 8 17 8z",
    lock: "M12 1a5 5 0 0 0-5 5v4H5v13h14V10h-2V6a5 5 0 0 0-5-5zm-3 9V6a3 3 0 0 1 6 0v4H9z",
    star: "M12 17.3 18.2 21l-1.6-7L22 9.2l-7.2-.6L12 2 9.2 8.6 2 9.2 7.5 14l-1.7 7z",
    arrow: "M12 4 10.6 5.4 16.2 11H4v2h12.2l-5.6 5.6L12 20l8-8z",
    back: "M15.4 7.4 14 6l-6 6 6 6 1.4-1.4L10.8 12z",
    check: "M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z",
    again: "M17.7 6.3A8 8 0 1 0 19.7 14h-2.1A6 6 0 1 1 12 6c1.7 0 3.1.7 4.2 1.8L13 11h7V4z",
    undo: "M12.5 8c-2.7 0-5.1 1-7 2.6L2 7v9h9l-3.6-3.6A8 8 0 0 1 20.1 16l2.4-.8A10.5 10.5 0 0 0 12.5 8z",
  };
  const icon = (name) => `<svg class="icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="${ICON_PATHS[name]}"/></svg>`;

  const speakButton = (text, label = "Read aloud") =>
    `<button type="button" class="speak" data-speak="${esc(text)}" aria-label="${esc(label)}">${icon("speaker")}</button>`;

  const companionBubble = (avatar, text) => `
    <div class="bubble-row">
      <div class="avatar-circle" style="--c:${avatar.color}" aria-hidden="true">${avatar.emoji}</div>
      <div class="card bubble">
        <div class="bubble-name">${esc(L.shortName(avatar))}</div>
        <p class="bubble-text">${esc(text)}</p>
        <div class="bubble-actions">${speakButton(text, `Read aloud: ${text}`)}</div>
      </div>
    </div>`;

  function setTopbar({ left = "", title = "", right = "" }) {
    $topbar.innerHTML = `<div class="topbar-left">${left}</div><div class="topbar-title">${esc(title)}</div><div class="topbar-right">${right}</div>`;
  }

  function showScreen(html, { narrow = false, centered = false } = {}) {
    speaker.stop();
    $screen.className = `screen${narrow ? " narrow" : ""}${centered ? " centered" : ""}`;
    $screen.innerHTML = html;
    window.scrollTo(0, 0);
    const heading = $screen.querySelector("[data-focus]");
    if (heading) heading.focus({ preventScroll: true });
  }

  // MARK: Onboarding

  let onboardingPick = null;

  function renderOnboarding() {
    setTopbar({});
    onboardingPick = L.avatarWithId(settings.avatarID);
    const tiles = L.AVATARS.map((a) => `
      <button type="button" class="avatar-tile" style="--c:${a.color}" data-action="pick-avatar" data-id="${a.id}"
        aria-pressed="${onboardingPick && onboardingPick.id === a.id}">
        <span class="emoji" aria-hidden="true">${a.emoji}</span><span>${esc(a.name)}</span>
      </button>`).join("");
    showScreen(`
      <div class="stack center" style="max-width:720px;margin:0 auto;width:100%">
        <div class="big-emoji" aria-hidden="true">💬🤝😊</div>
        <h1 class="title-xl" tabindex="-1" data-focus>Choose Your Friend!</h1>
        <p class="subtitle">Pick a friend who will help you practice feelings and making friends.</p>
        <div class="avatar-grid" role="group" aria-label="Companions">${tiles}</div>
        <div class="field">
          <label for="child-name">What is your name? (You can skip this.)</label>
          <input id="child-name" class="text-input" type="text" autocomplete="off" placeholder="Your name" value="${esc(settings.childName)}">
        </div>
        <button type="button" class="big-button" id="lets-go" data-action="finish-onboarding"
          style="--c:${onboardingPick ? onboardingPick.color : "var(--accent)"}" ${onboardingPick ? "" : "disabled"}>
          ${icon("arrow")} Let's go!
        </button>
      </div>`, { centered: true });
  }

  // MARK: Home

  function renderHome() {
    const avatar = currentAvatar();
    const name = trimmedName();
    const greeting = `${name ? `Hi, ${name}!` : "Hi!"} I'm ${L.shortName(avatar)}. What would you like to practice today?`;
    const completed = L.completedScenarioIDs(progress);
    setTopbar({
      title: "InterAIct",
      right: `<button type="button" class="round-button" data-action="open-grown-ups" aria-label="Grown-ups">${icon("lock")}</button>`,
    });
    const cards = catalog.scenarios.map((s) => `
      <button type="button" class="card scenario-card" style="--c:${s.color}" data-action="open-scenario" data-id="${s.id}"
        aria-label="${esc(`${s.title}. ${s.summary}. Skill: ${s.skill}${completed.has(s.id) ? ". Completed" : ""}`)}">
        <span class="scenario-icon" aria-hidden="true">${s.icon}</span>
        <span class="scenario-text">
          <span class="scenario-title">${esc(s.title)}</span>
          <span class="scenario-summary">${esc(s.summary)}</span>
          <span class="skill-chip">${esc(s.skill)}</span>
        </span>
        ${completed.has(s.id) ? `<span class="done-star">${icon("star")}</span>` : ""}
      </button>`).join("");
    showScreen(`
      <div class="stack">
        <h1 class="visually-hidden" tabindex="-1" data-focus>InterAIct home</h1>
        ${companionBubble(avatar, greeting)}
        <div class="home-actions">
          <span class="star-pill" role="img" aria-label="You have ${starsText()}">${icon("star")} ${starsText()}</span>
          <button type="button" class="big-button" style="--c:${GENTLE_GREEN}" data-action="open-calm">${icon("leaf")} Calm Corner</button>
        </div>
        <h2 class="title-m">Choose a situation to practice</h2>
        <div class="scenario-grid">${cards}</div>
      </div>`);
    speaker.autoSpeak(greeting);
  }

  // MARK: Scenario flow

  const play = { scenario: null, session: null, playID: null, stage: null, pickedFeeling: null };
  const failedVideos = new Set();

  function startScenario(scenario) {
    play.scenario = scenario;
    play.session = new L.ScenarioSession(scenario, settings.retryUntilGreat);
    play.playID = startPlay(scenario.id);
    enterStage(settings.feelingsCheckIn ? "checkInBefore" : "playing");
  }

  function enterStage(stage) {
    play.stage = stage;
    play.pickedFeeling = null;
    renderScenario();
  }

  function renderScenario() {
    const s = play.scenario;
    setTopbar({
      left: `<button type="button" class="round-button" data-action="go-home" aria-label="Back to home">${icon("back")}<span class="label">Home</span></button>`,
      title: s.title,
      right: `<button type="button" class="round-button" data-action="open-calm" aria-label="Calm Corner" style="color:${GENTLE_GREEN}">${icon("leaf")}</button>`,
    });
    switch (play.stage) {
      case "checkInBefore": return renderCheckIn("Before we start, how do you feel right now?");
      case "checkInAfter": return renderCheckIn("How do you feel now?");
      case "celebrate": return renderCompletion();
      default: return renderPhase();
    }
  }

  function renderCheckIn(prompt) {
    const avatar = currentAvatar();
    const feelings = L.FEELINGS.map((f) => `
      <button type="button" class="card feeling" style="--c:${avatar.color}" data-action="pick-feeling" data-id="${f.id}" aria-pressed="false">
        <span class="emoji" aria-hidden="true">${f.emoji}</span><span>${f.label}</span>
      </button>`).join("");
    showScreen(`
      <div class="stack">
        <h1 class="visually-hidden" tabindex="-1" data-focus>Feelings check-in</h1>
        ${companionBubble(avatar, prompt)}
        <div class="feeling-grid" role="group" aria-label="Feelings">${feelings}</div>
        <div id="support"></div>
        <button type="button" class="text-button" data-action="skip-feeling">Skip</button>
      </div>`, { narrow: true });
    speaker.autoSpeak(prompt);
  }

  function pickFeeling(feeling) {
    if (!feeling.suggestsCalmCorner) return finishCheckIn(feeling);
    play.pickedFeeling = feeling;
    $screen.querySelectorAll(".feeling").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.id === feeling.id)));
    const message = `It is okay to feel ${feeling.label.toLowerCase()}. Would you like to visit the Calm Corner first?`;
    const support = document.getElementById("support");
    support.innerHTML = `
      <div class="card support-card" role="status">
        <p>${esc(message)}</p>
        <div class="button-row wrap">
          <button type="button" class="big-button" style="--c:${GENTLE_GREEN}" data-action="open-calm">${icon("leaf")} Calm Corner</button>
          <button type="button" class="big-button soft" data-action="ready">${icon("arrow")} I'm ready</button>
        </div>
      </div>`;
    support.scrollIntoView({ behavior: reduceMotion() ? "auto" : "smooth", block: "center" });
    speaker.autoSpeak(message);
  }

  function finishCheckIn(feeling) {
    if (play.stage === "checkInBefore") {
      if (feeling) logFeeling(feeling.id, "beforeScenario", play.scenario.id);
      enterStage("playing");
    } else {
      if (feeling) logFeeling(feeling.id, "afterScenario", play.scenario.id);
      goHome();
    }
  }

  function sceneMarkup(phase, color) {
    const emoji = `<div class="scene emoji" style="--c:${color}" aria-hidden="true">${esc(phase.scene)}</div>`;
    if (!settings.showVideos || !phase.video || failedVideos.has(phase.video)) return emoji;
    return `<div class="scene video" data-scene="${esc(phase.scene)}" data-color="${color}" aria-hidden="true">
      <video src="${VIDEO_BASE}${encodeURIComponent(phase.video)}.mp4" data-video="${esc(phase.video)}"
        autoplay muted playsinline ${reduceMotion() ? "" : "loop"} disablepictureinpicture></video></div>`;
  }

  function watchVideos() {
    $screen.querySelectorAll("video[data-video]").forEach((video) => {
      const fallback = () => {
        failedVideos.add(video.dataset.video);
        const box = video.parentElement;
        if (!box || !box.isConnected) return;
        box.outerHTML = `<div class="scene emoji" style="--c:${box.dataset.color}" aria-hidden="true">${esc(box.dataset.scene)}</div>`;
      };
      video.addEventListener("error", fallback);
      if (video.error) fallback();
      const attempt = video.play();
      if (attempt && attempt.catch) attempt.catch(() => {});
    });
  }

  function renderPhase() {
    const { scenario: s, session } = play;
    const phase = session.currentPhase;
    const dots = Array.from({ length: session.phaseCount }, (_, i) => {
      const state = i + 1 < session.phaseNumber ? "done" : i + 1 === session.phaseNumber ? "current" : "";
      return `<span class="dot ${state}"></span>`;
    }).join("");
    showScreen(`
      <div class="stack">
        <div class="dots" style="--c:${s.color}" role="img" aria-label="Step ${session.phaseNumber} of ${session.phaseCount}">${dots}</div>
        <h1 class="title-l" tabindex="-1" data-focus>${esc(phase.title)}</h1>
        <div class="phase-layout">
          ${sceneMarkup(phase, s.color)}
          ${companionBubble(currentAvatar(), phase.prompt)}
        </div>
        <div class="choices" id="choices" role="group" aria-label="Choices"></div>
      </div>
      <div id="feedback-dock"></div>`);
    watchVideos();
    renderInteractive();
    speaker.autoSpeak(phase.prompt);
  }

  function renderInteractive() {
    const { session } = play;
    const phase = session.currentPhase;
    const picked = session.selectedChoice;
    document.getElementById("choices").innerHTML = phase.choices.map((c) => {
      const tried = session.isTried(c);
      const selected = picked && picked.id === c.id;
      const label = `${c.text}${tried ? ". Already tried" : ""}`;
      return `
        <div class="choice-row">
          <button type="button" class="choice${selected ? " selected" : ""}${tried ? " tried" : ""}"
            style="--tint:${L.KINDS[c.kind].tint}" data-action="choose" data-id="${esc(c.id)}"
            aria-label="${esc(label)}" ${picked || tried ? "disabled" : ""}>
            <span class="emoji" aria-hidden="true">${c.icon}</span>
            <span class="text">${esc(c.text)}</span>
            ${tried ? `<span class="tried-mark" aria-hidden="true">${icon("undo")}</span>` : ""}
          </button>
          ${speakButton(c.text, `Read aloud: ${c.text}`)}
        </div>`;
    }).join("");

    const dock = document.getElementById("feedback-dock");
    if (!picked) {
      dock.className = "";
      dock.innerHTML = "";
      return;
    }
    const kind = L.KINDS[picked.kind];
    const isLast = picked.next == null;
    const tryAgain = session.canTryAgain
      ? `<button type="button" class="big-button${session.canContinue ? " soft" : ""}" style="--c:${L.KINDS.tryAgain.tint}" data-action="try-again">${icon("undo")} Try another way</button>`
      : "";
    const next = session.canContinue
      ? `<button type="button" class="big-button" style="--c:${picked.kind === "great" ? L.KINDS.great.tint : L.KINDS.tryAgain.tint}" data-action="advance">${icon(isLast ? "check" : "arrow")} ${isLast ? "Finish" : "Next"}</button>`
      : "";
    dock.className = "feedback-dock";
    dock.innerHTML = `
      <div class="feedback" role="status" aria-live="polite" style="--tint:${kind.tint}">
        <div class="feedback-body">
          <span class="emoji" aria-hidden="true">${currentAvatar().emoji}</span>
          <div class="feedback-text">
            <p class="feedback-headline">${kind.headline}</p>
            <p class="feedback-message">${esc(picked.feedback)}</p>
          </div>
          ${speakButton(`${kind.headline} ${picked.feedback}`, "Read feedback aloud")}
        </div>
        <div class="button-row wrap">${tryAgain}${next}</div>
      </div>`;
  }

  function choose(choiceID) {
    const { session } = play;
    const choice = session.currentPhase.choices.find((c) => c.id === choiceID);
    const record = choice && session.choose(choice);
    if (!record) return;
    recordChoice(play.playID, record);
    renderInteractive();
    const dock = document.getElementById("feedback-dock");
    if (getComputedStyle(dock).position !== "sticky") {
      dock.scrollIntoView({ behavior: reduceMotion() ? "auto" : "smooth", block: "end" });
    }
    const primary = dock.querySelector('[data-action="advance"], [data-action="try-again"]');
    if (primary) primary.focus({ preventScroll: true });
    speaker.autoSpeak(`${L.KINDS[choice.kind].headline} ${choice.feedback}`);
  }

  function tryAgain() {
    play.session.tryAgain();
    renderInteractive();
    const first = document.querySelector("#choices .choice:not(:disabled)");
    if (first) first.focus();
  }

  function advance() {
    const { session } = play;
    session.advance();
    if (session.isFinished) {
      finishPlay(play.playID);
      enterStage("celebrate");
    } else {
      renderPhase();
    }
  }

  function renderCompletion() {
    const s = play.scenario;
    const name = trimmedName();
    const proud = name ? `I'm so proud of you, ${name}!` : "I'm so proud of you!";
    const message = `You did it! ${proud} You practiced ${s.title.toLowerCase()}. You earned a star!`;
    showScreen(`
      <div class="stack center">
        <div class="celebrate" aria-hidden="true">🌟</div>
        <h1 class="title-xl" tabindex="-1" data-focus>You did it!</h1>
        <p class="star-line">${icon("star")} +1 star · ${progress.stars} total</p>
        <div style="width:100%;text-align:left">${companionBubble(currentAvatar(), message)}</div>
        <div class="button-row wrap" style="width:100%">
          <button type="button" class="big-button soft" data-action="play-again">${icon("again")} Play again</button>
          <button type="button" class="big-button" style="--c:${GENTLE_GREEN}" data-action="all-done">${icon("check")} All done</button>
        </div>
      </div>`, { narrow: true, centered: true });
    speaker.autoSpeak(message);
  }

  // MARK: Calm Corner

  const SENSES = [
    { count: 5, emoji: "👀", text: "Find 5 things you can see." },
    { count: 4, emoji: "✋", text: "Find 4 things you can touch." },
    { count: 3, emoji: "👂", text: "Listen for 3 things you can hear." },
    { count: 2, emoji: "👃", text: "Find 2 things you can smell." },
    { count: 1, emoji: "👅", text: "Think of 1 thing you can taste." },
  ];
  const calm = { tool: "breathe", timer: null, ticks: 0, sensesIndex: 0 };

  function openCalm() {
    speaker.stop();
    calm.tool = "breathe";
    renderCalm();
    $calm.showModal();
    startBreathing();
  }

  function renderCalm() {
    const tab = (id, label) => `<button type="button" role="tab" aria-selected="${calm.tool === id}" data-action="calm-tool" data-id="${id}">${label}</button>`;
    $calm.innerHTML = `
      <div class="sheet-header">
        <span class="start"></span>
        <h2 id="calm-title">Calm Corner</h2>
        <button type="button" class="round-button end" data-action="close-calm">Done</button>
      </div>
      <div class="sheet-body">
        <div class="segmented" role="tablist" aria-label="Calm tool">${tab("breathe", "Breathing")}${tab("senses", "5 Senses")}</div>
        <div id="calm-tool" class="calm-tool"></div>
      </div>`;
    if (calm.tool === "breathe") renderBreathing();
    else renderSenses();
  }

  function renderBreathing() {
    document.getElementById("calm-tool").innerHTML = `
      <div class="balloon-wrap" aria-hidden="true"><div class="balloon-halo"></div><div class="balloon" id="balloon"></div></div>
      <p class="breath-label" id="breath-label" aria-live="polite">Breathe in…</p>
      <p class="breath-help">Watch the balloon. Breathe in while it grows. Breathe out while it shrinks.</p>
      <p class="breath-count" id="breath-count">Breaths: 0</p>`;
  }

  function startBreathing() {
    stopBreathing();
    calm.ticks = 0;
    const tick = () => {
      calm.ticks += 1;
      const inhaling = calm.ticks % 2 === 1;
      const balloon = document.getElementById("balloon");
      if (!balloon) return stopBreathing();
      balloon.classList.toggle("in", inhaling);
      document.getElementById("breath-label").textContent = inhaling ? "Breathe in…" : "Breathe out…";
      document.getElementById("breath-count").textContent = `Breaths: ${Math.floor((calm.ticks - 1) / 2)}`;
      speaker.autoSpeak(inhaling ? "Breathe in" : "Breathe out");
    };
    calm.timer = setTimeout(function loop() {
      tick();
      calm.timer = setTimeout(loop, 4000);
    }, 60);
  }

  function stopBreathing() {
    clearTimeout(calm.timer);
    calm.timer = null;
  }

  function renderSenses() {
    const done = calm.sensesIndex >= SENSES.length;
    const step = SENSES[calm.sensesIndex];
    const text = done ? "You did it! Your body and brain are noticing the world around you." : step.text;
    document.getElementById("calm-tool").innerHTML = `
      <div class="senses-emoji" aria-hidden="true">${done ? "🌈" : step.emoji}</div>
      ${done ? "" : `<div class="senses-count" aria-hidden="true">${step.count}</div>`}
      <div class="senses-line"><p aria-live="polite">${esc(text)}</p>${speakButton(text)}</div>
      <button type="button" class="big-button" style="--c:${GENTLE_GREEN}" data-action="${done ? "senses-restart" : "senses-next"}">
        ${icon(done ? "again" : "arrow")} ${done ? "Start again" : "Next"}
      </button>`;
    speaker.autoSpeak(text);
  }

  function setCalmTool(tool) {
    stopBreathing();
    speaker.stop();
    calm.tool = tool;
    calm.sensesIndex = 0;
    renderCalm();
    if (tool === "breathe") startBreathing();
  }

  $calm.addEventListener("close", () => { stopBreathing(); speaker.stop(); });

  // MARK: Grown-ups

  const gate = { first: 0, second: 0, entry: "", wrong: false };

  function newQuestion() {
    gate.first = 6 + Math.floor(Math.random() * 4);
    gate.second = 4 + Math.floor(Math.random() * 6);
    gate.entry = "";
  }

  function openGrownUps() {
    speaker.stop();
    newQuestion();
    gate.wrong = false;
    renderGate();
    $grownUps.showModal();
  }

  function sheetHeader(title, right) {
    return `
      <div class="sheet-header">
        <span class="start"></span>
        <h2 id="grown-ups-title">${esc(title)}</h2>
        <span class="end">${right}</span>
      </div>`;
  }

  function renderGate() {
    const keys = [1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => `<button type="button" class="card" data-action="gate-key" data-key="${n}">${n}</button>`).join("");
    $grownUps.innerHTML = `
      ${sheetHeader("Grown-ups", '<button type="button" class="round-button" data-action="close-grown-ups">Close</button>')}
      <div class="sheet-body">
        <div class="gate">
          <div class="lock">${icon("lock")}</div>
          <p class="title-m">Grown-ups only</p>
          <p class="subtitle" id="gate-question">What is ${gate.first} + ${gate.second}?</p>
          <div class="card gate-entry" id="gate-entry" aria-live="polite" aria-label="Answer">${esc(gate.entry || " ")}</div>
          <p class="gate-hint" id="gate-hint">${gate.wrong ? "Not quite. Try this one." : " "}</p>
          <div class="keypad" role="group" aria-labelledby="gate-question">
            ${keys}
            <button type="button" class="card" data-action="gate-clear" aria-label="Delete">⌫</button>
            <button type="button" class="card" data-action="gate-key" data-key="0">0</button>
            <button type="button" class="card" data-action="gate-submit" aria-label="Check answer" style="color:var(--great)">${icon("check")}</button>
          </div>
        </div>
      </div>`;
  }

  function gateKey(key) {
    if (gate.entry.length >= 3) return;
    gate.entry += key;
    document.getElementById("gate-entry").textContent = gate.entry;
  }

  function gateSubmit() {
    if (Number(gate.entry) === gate.first + gate.second) return renderDashboard();
    gate.wrong = true;
    newQuestion();
    renderGate();
  }

  function renderDashboard() {
    const completed = L.completedScenarioIDs(progress);
    const percent = (rate) => (rate == null ? "–" : `${Math.round(rate * 100)}%`);
    const when = (iso) => new Date(iso).toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
    const situationRows = catalog.scenarios.map((s) => {
      const st = L.stats(progress, s.id);
      return `<div class="row"><span class="emoji" aria-hidden="true">${s.icon}</span>
        <div class="grow"><div class="value">${esc(s.title)}</div><div class="detail">${st.completions} completed · ${st.plays} started</div></div>
        <span class="value" aria-label="First try most helpful: ${percent(st.firstTryGreatRate)}">${percent(st.firstTryGreatRate)}</span></div>`;
    }).join("");
    const feelings = progress.feelings.slice(-20).reverse();
    const feelingRows = feelings.length
      ? feelings.map((r) => {
        const f = L.feelingWithId(r.feeling) || { emoji: "🙂", label: r.feeling };
        const scenario = catalog.scenarios.find((s) => s.id === r.scenarioID);
        const detail = scenario ? `${L.MOMENTS[r.moment]} · ${scenario.title}` : L.MOMENTS[r.moment];
        return `<div class="row"><span class="emoji" aria-hidden="true">${f.emoji}</span>
          <div class="grow"><div class="value">${f.label}</div><div class="detail">${esc(detail)}</div></div>
          <span class="detail">${when(r.date)}</span></div>`;
      }).join("")
      : `<div class="row"><span class="detail">No check-ins yet.</span></div>`;
    const toggle = (key, label) => `
      <div class="row"><label class="grow" for="set-${key}">${label}</label>
        <input class="switch" type="checkbox" role="switch" id="set-${key}" data-setting="${key}" ${settings[key] ? "checked" : ""}></div>`;
    const companionOptions = L.AVATARS.map((a) => `<option value="${a.id}" ${a.id === settings.avatarID ? "selected" : ""}>${a.emoji} ${esc(a.name)}</option>`).join("");

    $grownUps.innerHTML = `
      ${sheetHeader("Grown-ups", '<button type="button" class="round-button" data-action="close-grown-ups">Done</button>')}
      <div class="sheet-body">
        <div class="dash">
          <section aria-labelledby="dash-overview"><h3 id="dash-overview">Overview</h3>
            <div class="card group">
              <div class="row"><span class="grow">Stars earned</span><span class="value">${progress.stars}</span></div>
              <div class="row"><span class="grow">Situations completed</span><span class="value">${completed.size} of ${catalog.scenarios.length}</span></div>
              <div class="row"><span class="grow">Practice sessions started</span><span class="value">${progress.plays.length}</span></div>
            </div></section>
          <section aria-labelledby="dash-situations"><h3 id="dash-situations">Situations</h3>
            <div class="card group">${situationRows}</div>
            <p class="footnote">The percentage shows how often the child's first answer was the most helpful choice.</p></section>
          <section aria-labelledby="dash-feelings"><h3 id="dash-feelings">Recent feelings</h3>
            <div class="card group">${feelingRows}</div></section>
          <section aria-labelledby="dash-settings"><h3 id="dash-settings">Child settings</h3>
            <div class="card group">
              <div class="row"><input class="text-input" type="text" id="set-childName" data-setting="childName" placeholder="Child's name" aria-label="Child's name" value="${esc(settings.childName)}"></div>
              <div class="row"><label class="grow" for="set-avatarID">Companion</label><select id="set-avatarID" data-setting="avatarID">${companionOptions}</select></div>
              ${toggle("readAloud", "Read aloud automatically")}
              <div class="row" style="flex-direction:column;align-items:flex-start">
                <label for="set-speechRate">Voice speed</label>
                <div class="range-row"><span aria-hidden="true">🐢</span>
                  <input type="range" id="set-speechRate" data-setting="speechRate" min="0.3" max="0.55" step="0.01" value="${settings.speechRate}">
                  <span aria-hidden="true">🐇</span></div>
              </div>
              ${toggle("showVideos", "Show videos")}
              ${toggle("feelingsCheckIn", "Feelings check-in")}
              ${toggle("retryUntilGreat", "Keep trying until the most helpful choice")}
            </div></section>
          <section>
            <div class="card group"><button type="button" class="reset-button" data-action="reset-progress">Reset all progress</button></div>
            <p class="footnote">All progress stays in this browser on this device. InterAIct does not use the camera, microphone, accounts, or send anything over the internet.</p>
          </section>
        </div>
      </div>`;
    const heading = document.getElementById("grown-ups-title");
    if (heading) { heading.tabIndex = -1; heading.focus(); }
  }

  $grownUps.addEventListener("input", (event) => {
    const el = event.target.closest("[data-setting]");
    if (!el) return;
    const key = el.dataset.setting;
    if (el.type === "checkbox") settings[key] = el.checked;
    else if (el.type === "range") settings[key] = Number(el.value);
    else settings[key] = el.value;
    saveSettings();
  });
  $grownUps.addEventListener("change", (event) => {
    if (event.target.id === "set-speechRate") speaker.speak("This is how fast I talk.");
  });
  $grownUps.addEventListener("close", () => { speaker.stop(); if (currentRoute().name === "home") renderHome(); });

  // MARK: Routing and events

  function currentRoute() {
    const match = location.hash.match(/^#\/play\/([\w-]+)/);
    return match ? { name: "play", id: match[1] } : { name: "home" };
  }

  function goHome() {
    if (location.hash && location.hash !== "#/") location.hash = "#/";
    else route();
  }

  function route() {
    if (!settings.avatarID) return renderOnboarding();
    const r = currentRoute();
    if (r.name === "play") {
      const scenario = catalog.scenarios.find((s) => s.id === r.id);
      if (scenario) return startScenario(scenario);
    }
    play.scenario = null;
    renderHome();
  }

  const actions = {
    "pick-avatar"(el) {
      onboardingPick = L.avatarWithId(el.dataset.id);
      $screen.querySelectorAll(".avatar-tile").forEach((t) => t.setAttribute("aria-pressed", String(t === el)));
      const go = document.getElementById("lets-go");
      go.disabled = false;
      go.style.setProperty("--c", onboardingPick.color);
      speaker.autoSpeak(`Hi! I'm ${onboardingPick.name}.`);
    },
    "finish-onboarding"() {
      if (!onboardingPick) return;
      settings.childName = document.getElementById("child-name").value;
      settings.avatarID = onboardingPick.id;
      saveSettings();
      route();
    },
    "open-scenario"(el) {
      const target = `#/play/${el.dataset.id}`;
      if (location.hash === target) route();
      else location.hash = target;
    },
    "go-home": goHome,
    "pick-feeling"(el) { pickFeeling(L.feelingWithId(el.dataset.id)); },
    "skip-feeling"() { finishCheckIn(null); },
    ready() { finishCheckIn(play.pickedFeeling); },
    choose(el) { choose(el.dataset.id); },
    "try-again": tryAgain,
    advance,
    "play-again"() { startScenario(play.scenario); },
    "all-done"() { settings.feelingsCheckIn ? enterStage("checkInAfter") : goHome(); },
    "open-calm": openCalm,
    "close-calm"() { $calm.close(); },
    "calm-tool"(el) { setCalmTool(el.dataset.id); },
    "senses-next"() { calm.sensesIndex += 1; renderSenses(); },
    "senses-restart"() { calm.sensesIndex = 0; renderSenses(); },
    "open-grown-ups": openGrownUps,
    "close-grown-ups"() { $grownUps.close(); },
    "gate-key"(el) { gateKey(el.dataset.key); },
    "gate-clear"() { gate.entry = gate.entry.slice(0, -1); document.getElementById("gate-entry").textContent = gate.entry || " "; },
    "gate-submit": gateSubmit,
    "reset-progress"() {
      if (!window.confirm("Reset all progress? Stars, practice history, and feelings check-ins will be deleted.")) return;
      progress = L.emptyProgress();
      saveProgress();
      renderDashboard();
    },
  };

  document.addEventListener("click", (event) => {
    const speak = event.target.closest("[data-speak]");
    if (speak) return speaker.speak(speak.dataset.speak);
    const el = event.target.closest("[data-action]");
    if (el && !el.disabled && actions[el.dataset.action]) actions[el.dataset.action](el);
  });

  document.addEventListener("keydown", (event) => {
    if (!$grownUps.open || !document.getElementById("gate-entry")) return;
    if (/^\d$/.test(event.key)) gateKey(event.key);
    else if (event.key === "Backspace") actions["gate-clear"]();
    else if (event.key === "Enter" && (gate.entry || !event.target.closest("button"))) {
      event.preventDefault();
      gateSubmit();
    }
  });

  window.addEventListener("hashchange", route);

  // MARK: Start

  const problems = catalog && Array.isArray(catalog.scenarios) ? L.validate(catalog.scenarios) : ["content.js is missing"];
  if (problems.length) {
    setTopbar({ title: "InterAIct" });
    $screen.innerHTML = `<div class="card notice stack"><h1 class="title-m">The practice stories need a quick fix.</h1>
      <p>A grown-up can check <code>scenarios.json</code> and run <code>python3 web/build_content.py</code>.</p>
      <pre>${esc(problems.join("\n"))}</pre></div>`;
  } else {
    route();
  }
})();
