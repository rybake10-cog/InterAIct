"""Checks the iOS app's bundled scenario content (ios/InterAIct/Resources/scenarios.json).

Run with: python3 -m pytest tests/test_ios_scenarios.py  (or: python3 tests/test_ios_scenarios.py)
"""
import json
import os
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "ios", "InterAIct", "Resources", "scenarios.json")
VIDEOS = os.path.join(ROOT, "src", "interAIct", "videos")
KINDS = {"great", "okay", "tryAgain"}


class ScenarioContentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with open(CONTENT, encoding="utf-8") as f:
            cls.scenarios = json.load(f)["scenarios"]

    def test_ids_are_unique(self):
        ids = [s["id"] for s in self.scenarios]
        self.assertEqual(len(ids), len(set(ids)))

    def test_every_scenario_is_playable(self):
        for s in self.scenarios:
            phases = {p["id"]: p for p in s["phases"]}
            self.assertEqual(len(phases), len(s["phases"]), s["id"])
            self.assertIn(s["startPhaseID"], phases, s["id"])
            reachable, queue, ends = set(), [s["startPhaseID"]], False
            while queue:
                pid = queue.pop()
                if pid in reachable:
                    continue
                reachable.add(pid)
                for c in phases[pid]["choices"]:
                    if c["next"] is None:
                        ends = True
                    else:
                        queue.append(c["next"])
            self.assertTrue(ends, f"{s['id']} never finishes")
            self.assertEqual(reachable, set(phases), f"{s['id']} has unreachable phases")

    def test_choices_are_well_formed(self):
        for s in self.scenarios:
            phase_ids = {p["id"] for p in s["phases"]}
            for p in s["phases"]:
                where = f"{s['id']}/{p['id']}"
                self.assertTrue(p["prompt"].strip(), where)
                self.assertTrue(any(c["kind"] == "great" for c in p["choices"]), where)
                self.assertEqual(len({c["id"] for c in p["choices"]}), len(p["choices"]), where)
                for c in p["choices"]:
                    self.assertIn(c["kind"], KINDS, where)
                    self.assertTrue(c["text"].strip() and c["feedback"].strip(), where)
                    if c["next"] is not None:
                        self.assertIn(c["next"], phase_ids, where)

    def test_referenced_videos_exist(self):
        for s in self.scenarios:
            for p in s["phases"]:
                if p.get("video"):
                    path = os.path.join(VIDEOS, p["video"] + ".mp4")
                    self.assertTrue(os.path.exists(path), path)


if __name__ == "__main__":
    unittest.main()
