import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import spawncompare as sc  # noqa: E402


def spawn(guid, entry, x, y, z=0.0, map=0, **kw):
    return sc.Spawn(guid=guid, entry=entry, map=map, x=x, y=y, z=z, o=0.0, **kw)


class MatchTests(unittest.TestCase):
    def test_nearest_pairs_and_leftovers(self):
        ref = [spawn(1, 100, 0, 0), spawn(2, 100, 20, 0), spawn(3, 200, 50, 50)]
        tgt = [spawn(11, 100, 1, 0), spawn(12, 100, 60, 0), spawn(13, 300, 0, 0)]
        pairs, missing, extra = sc.match_spawns(ref, tgt, radius=10)
        self.assertEqual([(r.guid, t.guid) for r, t, _ in pairs], [(1, 11)])
        self.assertEqual(sorted(s.guid for s in missing), [2, 3])
        self.assertEqual(sorted(s.guid for s in extra), [12, 13])

    def test_pack_matches_nearest_first(self):
        # two reference mobs, the closer target should pair with the closer reference
        ref = [spawn(1, 100, 0, 0), spawn(2, 100, 4, 0)]
        tgt = [spawn(11, 100, 3.5, 0)]
        pairs, missing, _ = sc.match_spawns(ref, tgt, radius=10)
        self.assertEqual([(r.guid, t.guid) for r, t, _ in pairs], [(2, 11)])
        self.assertEqual([s.guid for s in missing], [1])

    def test_different_maps_never_match(self):
        pairs, missing, extra = sc.match_spawns([spawn(1, 100, 0, 0, map=0)], [spawn(2, 100, 0, 0, map=1)], 10)
        self.assertEqual((len(pairs), len(missing), len(extra)), (0, 1, 1))

    def test_height_counts(self):
        # same x/y on another floor is not the same spawn
        pairs, _, _ = sc.match_spawns([spawn(1, 100, 0, 0, z=0)], [spawn(2, 100, 0, 0, z=30)], 10)
        self.assertEqual(pairs, [])


class DuplicateTests(unittest.TestCase):
    def run_dups(self, ref, tgt):
        pairs, _, _ = sc.match_spawns(ref, tgt, 10)
        return sc.find_duplicates(tgt, ref, 1.0, {id(t) for _, t, _ in pairs})

    def test_stacked_spawn_reported_and_matched_one_kept(self):
        ref = [spawn(1, 100, 0, 0)]
        tgt = [spawn(20, 100, 0.2, 0), spawn(10, 100, 0, 0)]
        dups = self.run_dups(ref, tgt)
        self.assertEqual(len(dups), 1)
        self.assertEqual([s.guid for s in dups[0]["keep"]], [10])
        self.assertEqual([s.guid for s in dups[0]["extra"]], [20])

    def test_reference_stack_is_allowed(self):
        ref = [spawn(1, 100, 0, 0), spawn(2, 100, 0.3, 0)]
        tgt = [spawn(10, 100, 0, 0), spawn(11, 100, 0.3, 0)]
        self.assertEqual(self.run_dups(ref, tgt), [])

    def test_pooled_and_phased_ignored(self):
        tgt = [spawn(10, 100, 0, 0, pooled=True), spawn(11, 100, 0, 0, pooled=True)]
        self.assertEqual(self.run_dups([], tgt), [])
        tgt = [spawn(10, 100, 0, 0, phase=1), spawn(11, 100, 0, 0, phase=2)]
        self.assertEqual(self.run_dups([], tgt), [])

    def test_chain_forms_one_cluster(self):
        tgt = [spawn(10, 100, 0, 0), spawn(11, 100, 0.8, 0), spawn(12, 100, 1.6, 0)]
        dups = self.run_dups([], tgt)
        self.assertEqual(len(dups), 1)
        self.assertEqual(len(dups[0]["extra"]), 2)


class IssueTests(unittest.TestCase):
    def test_movement_issues(self):
        wander = dict(move=1, wander=5.0)
        idle = dict(move=0, wander=0.0)
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, **wander), spawn(2, 1, 0, 0, **idle)), ["not_wandering"])
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, **idle), spawn(2, 1, 0, 0, **wander)),
                         ["should_not_wander"])
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, move=2, path=10), spawn(2, 1, 0, 0, **idle)),
                         ["missing_path"])
        # both patrol; the path may come from creature_template_addon, so a missing addon row is not an issue
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, move=2, path=10), spawn(2, 1, 0, 0, move=2)), [])
        # a path row on a wandering spawn is unused: identical spawns are never reported
        same = dict(move=1, wander=5.0, path=7)
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, **same), spawn(2, 1, 0, 0, **same)), [])
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, move=2), spawn(2, 1, 0, 0, move=2)), [])
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, move=1, wander=10.0),
                                            spawn(2, 1, 0, 0, move=1, wander=3.0)), ["wander_distance"])
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, **wander), spawn(2, 1, 0, 0, **wander)), [])
        # MovementType 1 with a zero radius does not wander
        self.assertEqual(sc.movement_issues(spawn(1, 1, 0, 0, **wander), spawn(2, 1, 0, 0, move=1)),
                         ["not_wandering"])

    def test_phase_and_respawn(self):
        r = spawn(1, 1, 0, 0, phase=100, respawn=300)
        t = spawn(2, 1, 0, 0, respawn=900)
        self.assertEqual(sc.spawn_issues("gameobject", r, t), ["phase", "respawn_time"])


class MaskTests(unittest.TestCase):
    def test_learned_then_guessed(self):
        pairs = [(spawn(1, 1, 0, 0, map=34, mask=1), spawn(2, 1, 0, 0, map=34, mask=2), 0)] * 3
        mask_map = sc.learn_mask_map(pairs)
        instances = {34, 36}
        cata_ref = [spawn(1, 1, 0, 0, map=36, mask=3), spawn(2, 1, 0, 0, map=36, mask=2)]
        old = sc.old_numbering_maps(cata_ref, instances)
        self.assertEqual(old, {36})
        self.assertEqual(sc.target_mask(spawn(3, 1, 0, 0, map=34, mask=1), mask_map, instances, 1, old), (2, None))
        self.assertEqual(sc.target_mask(cata_ref[0], mask_map, instances, 1, old), (6, "shifted"))
        self.assertEqual(sc.target_mask(cata_ref[1], mask_map, instances, 1, old), (4, "shifted"))
        self.assertEqual(sc.target_mask(spawn(3, 1, 0, 0, map=0, mask=1), mask_map, instances, 1, old), (1, None))

    def test_mop_numbered_reference_is_kept(self):
        mop_ref = [spawn(1, 1, 0, 0, map=36, mask=6), spawn(2, 1, 0, 0, map=36, mask=4), spawn(3, 1, 0, 0, map=36, mask=0)]
        old = sc.old_numbering_maps(mop_ref, {36})
        self.assertEqual(old, set())
        self.assertEqual([sc.target_mask(s, {}, {36}, 1, old) for s in mop_ref], [(6, "kept"), (4, "kept"), (0, "kept")])


class PhaseTests(unittest.TestCase):
    def test_default_phase(self):
        for mask, expected in ((0, True), (1, True), (3, True), (65535, True), (4294967295, True),
                               (2, False), (4, False), (192, False)):
            self.assertEqual(sc.in_default_phase(spawn(1, 1, 0, 0, phase_mask=mask)), expected, mask)


class ZoneTests(unittest.TestCase):
    def test_filter_include_and_exclude(self):
        ref = [spawn(1, 1, 0, 0, zone=12), spawn(2, 1, 500, 0, zone=14)]
        tgt = [spawn(10, 1, 0, 0)]
        res = sc.compare("creature", ref, tgt, 10, 1)
        sc.filter_zones(res, exclude={14})
        self.assertEqual([s.guid for s in res.ref], [1])
        self.assertEqual(res.missing, [])
        res = sc.compare("creature", ref, tgt, 10, 1)
        sc.filter_zones(res, include={14})
        self.assertEqual([s.guid for s in res.missing], [2])
        self.assertEqual(res.tgt, [])

    def test_zone_from_nearest_reference(self):
        ref = [spawn(1, 1, 0, 0, zone=12), spawn(2, 1, 150, 0, zone=40)]
        tgt = [spawn(10, 9, 10, 0), spawn(11, 9, 140, 0), spawn(12, 9, 5000, 0)]
        zone_of = sc.assign_zones(ref, tgt, [])
        self.assertEqual([zone_of[id(t)] for t in tgt], [12, 40, 0])


if __name__ == "__main__":
    unittest.main()
