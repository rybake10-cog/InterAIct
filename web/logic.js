/* Content validation, play state, and progress math for the InterAIct web app.
   Plain script: attaches to `window.InterAIct` in the browser and exports for Node tests. */
(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  else root.InterAIctLogic = api;
})(typeof self !== "undefined" ? self : this, function () {
  "use strict";

  const AVATARS = [
    { id: "cat", name: "Whiskers the Cat", emoji: "🐱", color: "#FF9FF3" },
    { id: "dog", name: "Buddy the Dog", emoji: "🐶", color: "#FECA57" },
    { id: "rabbit", name: "Hoppy the Rabbit", emoji: "🐰", color: "#FF6B6B" },
    { id: "bear", name: "Berry the Bear", emoji: "🐻", color: "#48DBFB" },
  ];

  const FEELINGS = [
    { id: "happy", emoji: "😀", label: "Happy" },
    { id: "calm", emoji: "😌", label: "Calm" },
    { id: "okay", emoji: "🙂", label: "Okay" },
    { id: "worried", emoji: "😟", label: "Worried", suggestsCalmCorner: true },
    { id: "sad", emoji: "😢", label: "Sad", suggestsCalmCorner: true },
    { id: "angry", emoji: "😠", label: "Angry", suggestsCalmCorner: true },
    { id: "tired", emoji: "🥱", label: "Tired" },
  ];

  const MOMENTS = {
    beforeScenario: "Before practice",
    afterScenario: "After practice",
    calmCorner: "Calm Corner",
  };

  /** Gentle colors only: green, gold, and blue. Never red. */
  const KINDS = {
    great: { headline: "Great choice!", tint: "#3E9B6B" },
    okay: { headline: "Good thinking!", tint: "#C98C1B" },
    tryAgain: { headline: "Let's think about it.", tint: "#4F7CAC" },
  };

  const shortName = (avatar) => avatar.name.split(" ")[0];
  const avatarWithId = (id) => AVATARS.find((a) => a.id === id) || null;
  const feelingWithId = (id) => FEELINGS.find((f) => f.id === id) || null;
  const findPhase = (scenario, id) => scenario.phases.find((p) => p.id === id) || null;

  /** Returns human-readable problems; an empty array means the content is playable. */
  function validate(scenarios) {
    const problems = [];
    const scenarioIDs = new Set();
    for (const scenario of scenarios) {
      const name = scenario.id;
      if (scenarioIDs.has(name)) problems.push(`Duplicate scenario id ${name}`);
      scenarioIDs.add(name);
      const phaseIDs = scenario.phases.map((p) => p.id);
      if (new Set(phaseIDs).size !== phaseIDs.length) problems.push(`${name}: duplicate phase ids`);
      if (!findPhase(scenario, scenario.startPhaseID)) {
        problems.push(`${name}: start phase ${scenario.startPhaseID} not found`);
      }
      for (const phase of scenario.phases) {
        const where = `${name}/${phase.id}`;
        if (!phase.choices.length) problems.push(`${where}: no choices`);
        if (!phase.choices.some((c) => c.kind === "great")) problems.push(`${where}: needs at least one great choice`);
        const choiceIDs = phase.choices.map((c) => c.id);
        if (new Set(choiceIDs).size !== choiceIDs.length) problems.push(`${where}: duplicate choice ids`);
        for (const choice of phase.choices) {
          if (!(choice.kind in KINDS)) problems.push(`${where}/${choice.id}: unknown kind ${choice.kind}`);
          if (choice.next != null && !findPhase(scenario, choice.next)) {
            problems.push(`${where}/${choice.id}: next phase ${choice.next} not found`);
          }
        }
      }
      const reachable = new Set();
      const queue = [scenario.startPhaseID];
      let reachesEnd = false;
      while (queue.length) {
        const id = queue.pop();
        if (reachable.has(id)) continue;
        reachable.add(id);
        const phase = findPhase(scenario, id);
        if (!phase) continue;
        for (const choice of phase.choices) {
          if (choice.next != null) queue.push(choice.next);
          else reachesEnd = true;
        }
      }
      if (!reachesEnd) problems.push(`${name}: no path to the end`);
      for (const id of phaseIDs) if (!reachable.has(id)) problems.push(`${name}/${id}: unreachable phase`);
    }
    return problems;
  }

  /** Runtime state for one play-through of a scenario. */
  class ScenarioSession {
    constructor(scenario, retryUntilGreat, now = () => new Date()) {
      this.scenario = scenario;
      this.retryUntilGreat = retryUntilGreat;
      this.now = now;
      this.currentPhaseID = scenario.startPhaseID;
      this.selectedChoice = null;
      this.triedChoiceIDs = new Set();
      this.records = [];
      this.isFinished = false;
      this.attemptsInPhase = 0;
    }

    get currentPhase() { return findPhase(this.scenario, this.currentPhaseID); }
    get phaseNumber() { return this.scenario.phases.findIndex((p) => p.id === this.currentPhaseID) + 1; }
    get phaseCount() { return this.scenario.phases.length; }

    /** Whether the feedback for the selected choice lets the child move on. */
    get canContinue() {
      return !!this.selectedChoice && (this.selectedChoice.kind === "great" || !this.retryUntilGreat);
    }

    /** Whether the child may pick another choice in the current phase. */
    get canTryAgain() { return !!this.selectedChoice && this.selectedChoice.kind !== "great"; }

    isTried(choice) { return this.triedChoiceIDs.has(choice.id); }

    choose(choice) {
      const phase = this.currentPhase;
      if (this.isFinished || this.selectedChoice || !phase || !phase.choices.includes(choice)) return null;
      this.attemptsInPhase += 1;
      this.selectedChoice = choice;
      const record = {
        phaseID: this.currentPhaseID,
        choiceID: choice.id,
        kind: choice.kind,
        attempt: this.attemptsInPhase,
        date: this.now().toISOString(),
      };
      this.records.push(record);
      return record;
    }

    tryAgain() {
      if (!this.canTryAgain) return;
      this.triedChoiceIDs.add(this.selectedChoice.id);
      this.selectedChoice = null;
    }

    advance() {
      if (!this.canContinue) return;
      const next = this.selectedChoice.next;
      this.selectedChoice = null;
      this.triedChoiceIDs = new Set();
      this.attemptsInPhase = 0;
      if (next != null) this.currentPhaseID = next;
      else this.isFinished = true;
    }
  }

  const emptyProgress = () => ({ plays: [], feelings: [], stars: 0 });

  // Combines two copies of saved progress (e.g. from two browser tabs) by record ID.
  function mergeProgress(stored, local) {
    const unionByID = (a, b, prefer) => {
      const byID = new Map(a.map((r) => [r.id, r]));
      b.forEach((r) => {
        const existing = byID.get(r.id);
        byID.set(r.id, existing && prefer ? prefer(existing, r) : r);
      });
      return [...byID.values()];
    };
    const morePlayed = (x, y) =>
      (!!x.finishedAt !== !!y.finishedAt ? (x.finishedAt ? x : y) : (x.choices.length > y.choices.length ? x : y));
    const plays = unionByID(stored.plays || [], local.plays || [], morePlayed)
      .sort((x, y) => String(x.startedAt).localeCompare(String(y.startedAt)));
    const feelings = unionByID(stored.feelings || [], local.feelings || [])
      .sort((x, y) => String(x.date).localeCompare(String(y.date)));
    return { plays, feelings, stars: plays.filter((p) => p.finishedAt).length };
  }

  const completedScenarioIDs = (progress) =>
    new Set(progress.plays.filter((p) => p.finishedAt).map((p) => p.scenarioID));

  /** Plays, completions, and how often the first answer in a phase was the most helpful one. */
  function stats(progress, scenarioID) {
    const plays = progress.plays.filter((p) => p.scenarioID === scenarioID);
    let answered = 0;
    let great = 0;
    for (const play of plays) {
      answered += new Set(play.choices.map((c) => c.phaseID)).size;
      great += play.choices.filter((c) => c.attempt === 1 && c.kind === "great").length;
    }
    return {
      plays: plays.length,
      completions: plays.filter((p) => p.finishedAt).length,
      firstTryGreatRate: answered === 0 ? null : great / answered,
    };
  }

  return {
    AVATARS, FEELINGS, MOMENTS, KINDS,
    shortName, avatarWithId, feelingWithId, findPhase,
    validate, ScenarioSession, emptyProgress, mergeProgress, completedScenarioIDs, stats,
  };
});
