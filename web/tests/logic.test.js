// Run with: node --test web/tests
const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const L = require("../logic.js");

const root = path.join(__dirname, "..", "..");
const catalog = JSON.parse(fs.readFileSync(path.join(root, "ios", "InterAIct", "Resources", "scenarios.json"), "utf8"));
const byID = (id) => catalog.scenarios.find((s) => s.id === id);

test("bundled scenarios are valid", () => {
  assert.deepEqual(L.validate(catalog.scenarios), []);
  assert.equal(catalog.scenarios.length, 8);
});

test("web/content.js matches scenarios.json", () => {
  const window = {};
  new Function("window", fs.readFileSync(path.join(root, "web", "content.js"), "utf8"))(window);
  assert.deepEqual(window.INTERAICT_CONTENT, catalog, "run python3 web/build_content.py");
});

test("validate reports broken content", () => {
  const broken = structuredClone(byID("saying-hello"));
  broken.phases[0].choices.forEach((c) => { c.kind = "okay"; });
  broken.phases[0].choices[0].next = "missing";
  const problems = L.validate([broken, broken]);
  assert.ok(problems.some((p) => p.includes("Duplicate scenario id")));
  assert.ok(problems.some((p) => p.includes("needs at least one great choice")));
  assert.ok(problems.some((p) => p.includes("next phase missing not found")));
});

test("great choices lead to the end of every scenario", () => {
  for (const scenario of catalog.scenarios) {
    const session = new L.ScenarioSession(scenario, true);
    let steps = 0;
    while (!session.isFinished && steps++ < 50) {
      const great = session.currentPhase.choices.find((c) => c.kind === "great");
      assert.ok(session.choose(great));
      assert.ok(session.canContinue);
      session.advance();
    }
    assert.ok(session.isFinished, scenario.id);
  }
});

test("retry-until-great blocks moving on after a less helpful choice", () => {
  const scenario = byID("taking-turns");
  const session = new L.ScenarioSession(scenario, true);
  const other = session.currentPhase.choices.find((c) => c.kind !== "great");
  const record = session.choose(other);
  assert.equal(record.attempt, 1);
  assert.equal(session.canContinue, false);
  assert.equal(session.canTryAgain, true);
  assert.equal(session.choose(other), null, "cannot pick twice before trying again");
  session.tryAgain();
  assert.ok(session.isTried(other));
  const great = session.currentPhase.choices.find((c) => c.kind === "great");
  assert.equal(session.choose(great).attempt, 2);
  assert.equal(session.canTryAgain, false);
  session.advance();
  assert.equal(session.attemptsInPhase, 0);
  assert.equal(session.triedChoiceIDs.size, 0);
});

test("okay choices can continue when retry-until-great is off", () => {
  const session = new L.ScenarioSession(byID("taking-turns"), false);
  const okay = session.currentPhase.choices.find((c) => c.kind !== "great");
  session.choose(okay);
  assert.ok(session.canContinue);
});

test("stats count plays, completions, and first-try great answers", () => {
  const progress = L.emptyProgress();
  assert.equal(L.stats(progress, "x").firstTryGreatRate, null);
  progress.plays.push(
    { scenarioID: "x", finishedAt: "2026-01-01", choices: [
      { phaseID: "a", kind: "great", attempt: 1 },
      { phaseID: "b", kind: "okay", attempt: 1 },
      { phaseID: "b", kind: "great", attempt: 2 },
    ] },
    { scenarioID: "x", finishedAt: null, choices: [] },
  );
  assert.deepEqual(L.stats(progress, "x"), { plays: 2, completions: 1, firstTryGreatRate: 0.5 });
  assert.deepEqual([...L.completedScenarioIDs(progress)], ["x"]);
});

test("gentle palette never uses red", () => {
  for (const { tint } of Object.values(L.KINDS)) {
    const [r, g, b] = [1, 3, 5].map((i) => parseInt(tint.slice(i, i + 2), 16));
    assert.ok(!(r > 180 && g < 120 && b < 120), tint);
  }
});

test("referenced videos exist", () => {
  for (const scenario of catalog.scenarios) {
    for (const phase of scenario.phases) {
      if (!phase.video) continue;
      assert.ok(fs.existsSync(path.join(root, "src", "interAIct", "videos", `${phase.video}.mp4`)), phase.video);
    }
  }
});
