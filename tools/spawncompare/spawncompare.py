#!/usr/bin/env python3
"""Compare creature and gameobject spawns between two TrinityCore-style world databases.

Typical use: a Cataclysm 4.3.4 reference database (The Cataclysm Preservation Project)
against a Mists of Pandaria 5.4.8 SkyFire database, for zones that did not change in MoP.

Reports (CSV) are written for:
  * spawns present in the reference but missing from the target
  * spawns present only in the target
  * stacked duplicate spawns in the target
  * movement differences (should wander / should not wander / missing patrol path),
    phase and respawn-time differences between matched spawns

With --emit-sql it also writes reviewable SQL to import the missing spawns and to fix
wander settings. Nothing is ever written to either database by this tool.
"""

import argparse
import csv
import math
import os
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass

# Eastern Kingdoms, Kalimdor, Outland, Northrend, Deepholm, Tol Barad.
DEFAULT_MAPS = "0,1,530,571,646,732"

# Areas Mists of Pandaria rebuilt or re-populated, so 4.3.4 data there is outdated.
# Maps: old Scarlet Monastery and Scholomance (replaced by maps 1001/1004/1007), Ragefire Chasm (redone in 5.0).
MOP_CHANGED_MAPS = {189, 289, 389}
# Zones: Durotar and Orgrimmar (Darkspear rebellion, Kor'kron), Dustwallow Marsh (Theramore's Fall),
# Northern Barrens (Crossroads escalation), Western Plaguelands (Scholomance), Tirisfal Glades (Scarlet Monastery).
MOP_CHANGED_ZONES = {14, 1637, 15, 17, 28, 85}
KINDS = ("creature", "gameobject")
IDENTIFIER = re.compile(r"^[A-Za-z0-9_$]+$")


@dataclass(slots=True)
class Spawn:
    guid: int
    entry: int
    map: int
    x: float
    y: float
    z: float
    o: float
    mask: int = 1
    phase: int = 0
    phase_group: int = 0
    zone: int = 0
    respawn: int = 0
    # creature only
    wander: float = 0.0
    move: int = 0
    equip: int = 0
    path: int = 0
    # gameobject only
    rot: tuple = (0.0, 0.0, 0.0, 0.0)
    anim: int = 0
    state: int = 0
    # set after loading
    pooled: bool = False
    event: bool = False

    def dist(self, other):
        return math.sqrt((self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2)

    @property
    def wanders(self):
        return self.move == 1 and self.wander > 0

    @property
    def phase_key(self):
        return (self.phase, self.phase_group)


# --------------------------------------------------------------------------- database access

def table_columns(cur, schema, table):
    """Return {lowercase name: actual name} for a table, or {} if it does not exist."""
    cur.execute(
        "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=%s AND TABLE_NAME=%s",
        (schema, table),
    )
    return {row[0].lower(): row[0] for row in cur.fetchall()}


def pick(cols, *names):
    for name in names:
        if name.lower() in cols:
            return cols[name.lower()]
    return None


def spawn_columns(cur, schema, kind):
    """Map logical field -> actual column name (or None) for the creature/gameobject table."""
    cols = table_columns(cur, schema, kind)
    if not cols:
        raise SystemExit(f"error: table `{schema}`.`{kind}` not found")
    fields = {
        "guid": pick(cols, "guid"),
        "id": pick(cols, "id", "id1"),
        "map": pick(cols, "map"),
        "x": pick(cols, "position_x"),
        "y": pick(cols, "position_y"),
        "z": pick(cols, "position_z"),
        "o": pick(cols, "orientation"),
        "mask": pick(cols, "spawnMask"),
        "phase": pick(cols, "phaseId"),
        "phase_group": pick(cols, "phaseGroup"),
        "zone": pick(cols, "zoneId"),
        "respawn": pick(cols, "spawntimesecs"),
        "modelid": pick(cols, "modelid"),
    }
    if kind == "creature":
        fields.update(
            wander=pick(cols, "wander_distance", "spawndist"),
            move=pick(cols, "MovementType", "movement_type"),
            equip=pick(cols, "equipment_id"),
        )
    else:
        fields.update(
            rot0=pick(cols, "rotation0"),
            rot1=pick(cols, "rotation1"),
            rot2=pick(cols, "rotation2"),
            rot3=pick(cols, "rotation3"),
            anim=pick(cols, "animprogress"),
            state=pick(cols, "state"),
        )
    for required in ("guid", "id", "map", "x", "y", "z", "o"):
        if not fields[required]:
            raise SystemExit(f"error: `{schema}`.`{kind}` has no column for '{required}'")
    return fields


def load_spawns(cur, schema, kind, maps):
    f = spawn_columns(cur, schema, kind)

    def col(key, default="0"):
        return f"s.`{f[key]}`" if f.get(key) else default

    select = [col("guid"), col("id"), col("map"), col("x"), col("y"), col("z"), col("o"),
              col("mask", "1"), col("phase"), col("phase_group"), col("zone"), col("respawn")]
    join = ""
    if kind == "creature":
        select += [col("wander"), col("move"), col("equip")]
        addon = table_columns(cur, schema, "creature_addon")
        path_col = pick(addon, "path_id", "waypointPathId")
        if path_col:
            join = f" LEFT JOIN `{schema}`.`creature_addon` a ON a.`guid` = s.`{f['guid']}`"
            select.append(f"COALESCE(a.`{path_col}`, 0)")
        else:
            select.append("0")
    else:
        select += [col("rot0"), col("rot1"), col("rot2"), col("rot3"), col("anim", "100"), col("state", "1")]

    sql = f"SELECT {', '.join(select)} FROM `{schema}`.`{kind}` s{join}"
    params = ()
    if maps is not None:
        sql += f" WHERE s.`{f['map']}` IN ({', '.join(['%s'] * len(maps))})"
        params = tuple(maps)
    cur.execute(sql, params)

    spawns = []
    for r in cur.fetchall():
        s = Spawn(guid=int(r[0]), entry=int(r[1]), map=int(r[2]), x=float(r[3]), y=float(r[4]),
                  z=float(r[5]), o=float(r[6]), mask=int(r[7] or 0), phase=int(r[8] or 0),
                  phase_group=int(r[9] or 0), zone=int(r[10] or 0), respawn=int(r[11] or 0))
        if kind == "creature":
            s.wander, s.move, s.equip, s.path = float(r[12] or 0), int(r[13] or 0), int(r[14] or 0), int(r[15] or 0)
        else:
            s.rot = (float(r[12] or 0), float(r[13] or 0), float(r[14] or 0), float(r[15] or 0))
            s.anim, s.state = int(r[16] or 0), int(r[17] or 0)
        spawns.append(s)
    return spawns, f


def load_linked_guids(cur, schema, kind):
    """Guids that belong to a pool or a game event (their spawning is conditional)."""
    pooled, event = set(), set()
    if table_columns(cur, schema, "pool_members"):
        cur.execute(f"SELECT spawnId FROM `{schema}`.`pool_members` WHERE type = %s",
                    (0 if kind == "creature" else 1,))
        pooled.update(int(r[0]) for r in cur.fetchall())
    if table_columns(cur, schema, f"pool_{kind}"):
        cur.execute(f"SELECT guid FROM `{schema}`.`pool_{kind}`")
        pooled.update(int(r[0]) for r in cur.fetchall())
    if table_columns(cur, schema, f"game_event_{kind}"):
        cur.execute(f"SELECT guid FROM `{schema}`.`game_event_{kind}`")
        event.update(int(r[0]) for r in cur.fetchall())
    return pooled, event


def load_template_names(cur, schema, kind):
    cols = table_columns(cur, schema, f"{kind}_template")
    if not cols or "entry" not in cols:
        return {}
    name = pick(cols, "name")
    name_expr = f"`{name}`" if name else "''"
    cur.execute(f"SELECT entry, {name_expr} FROM `{schema}`.`{kind}_template`")
    return {int(r[0]): (r[1] or "") for r in cur.fetchall()}


def load_instance_maps(cur, schema):
    if not table_columns(cur, schema, "instance_template"):
        return set()
    cur.execute(f"SELECT map FROM `{schema}`.`instance_template`")
    return {int(r[0]) for r in cur.fetchall()}


def load_map_list(cur, schema, kinds):
    maps = set()
    for kind in kinds:
        cur.execute(f"SELECT DISTINCT map FROM `{schema}`.`{kind}`")
        maps.update(int(r[0]) for r in cur.fetchall())
    return sorted(maps)


# --------------------------------------------------------------------------- comparison logic

def grid_index(spawns, cell):
    grid = defaultdict(list)
    for i, s in enumerate(spawns):
        grid[(math.floor(s.x / cell), math.floor(s.y / cell))].append(i)
    return grid


def neighbours(grid, s, cell):
    cx, cy = math.floor(s.x / cell), math.floor(s.y / cell)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            yield from grid.get((cx + dx, cy + dy), ())


def group_by_entry(spawns):
    groups = defaultdict(list)
    for s in spawns:
        groups[(s.map, s.entry)].append(s)
    return groups


def match_spawns(ref, tgt, radius):
    """Pair reference and target spawns of the same entry, nearest first, each used once.

    Returns (pairs, missing, extra) where pairs is a list of (ref, tgt, distance)."""
    ref_groups, tgt_groups = group_by_entry(ref), group_by_entry(tgt)
    pairs, matched_r, matched_t = [], set(), set()
    for key, rlist in ref_groups.items():
        tlist = tgt_groups.get(key)
        if not tlist:
            continue
        grid = grid_index(tlist, radius)
        candidates = []
        for ri, r in enumerate(rlist):
            for ti in neighbours(grid, r, radius):
                d = r.dist(tlist[ti])
                if d <= radius:
                    candidates.append((d, ri, ti))
        candidates.sort()
        used_r, used_t = set(), set()
        for d, ri, ti in candidates:
            if ri in used_r or ti in used_t:
                continue
            used_r.add(ri)
            used_t.add(ti)
            pairs.append((rlist[ri], tlist[ti], d))
            matched_r.add(id(rlist[ri]))
            matched_t.add(id(tlist[ti]))
    missing = [r for r in ref if id(r) not in matched_r]
    extra = [t for t in tgt if id(t) not in matched_t]
    return pairs, missing, extra


def compatible(a, b):
    masks_overlap = a.mask == 0 or b.mask == 0 or (a.mask & b.mask) != 0
    return masks_overlap and a.phase_key == b.phase_key


def find_duplicates(tgt, ref, radius, matched_tgt_ids):
    """Clusters of same-entry target spawns stacked within `radius` of each other.

    Pooled and game-event spawns are ignored (stacking them is normal). A cluster is only
    reported when it holds more spawns than the reference has at the same spot."""
    ref_groups = group_by_entry(ref)
    results = []
    for key, members in group_by_entry([t for t in tgt if not t.pooled and not t.event]).items():
        if len(members) < 2:
            continue
        parent = list(range(len(members)))

        def find(i):
            while parent[i] != i:
                parent[i] = parent[parent[i]]
                i = parent[i]
            return i

        grid = grid_index(members, radius)
        for i, s in enumerate(members):
            for j in neighbours(grid, s, radius):
                if j > i and s.dist(members[j]) <= radius and compatible(s, members[j]):
                    parent[find(i)] = find(j)
        clusters = defaultdict(list)
        for i in range(len(members)):
            clusters[find(i)].append(members[i])

        rlist = ref_groups.get(key, [])
        rgrid = grid_index(rlist, radius) if rlist else {}
        for cluster in clusters.values():
            if len(cluster) < 2:
                continue
            near_ref = set()
            for s in cluster:
                for ri in neighbours(rgrid, s, radius):
                    if s.dist(rlist[ri]) <= radius:
                        near_ref.add(ri)
            allowed = max(len(near_ref), 1)
            if len(cluster) <= allowed:
                continue
            ordered = sorted(cluster, key=lambda s: (id(s) not in matched_tgt_ids, s.guid))
            results.append({"members": cluster, "ref_count": len(near_ref),
                            "keep": ordered[:allowed], "extra": ordered[allowed:]})
    return results


def movement_issues(r, t):
    issues = []
    # Judge both sides the same way: a waypoint path only matters with MovementType 2, and the path
    # itself may live outside creature_addon (e.g. creature_template_addon), so only the type is compared.
    ref_path = r.move == 2
    tgt_path = t.move == 2
    if ref_path and not tgt_path:
        issues.append("missing_path")
    elif r.wanders and not t.wanders and not tgt_path:
        issues.append("not_wandering")
    elif t.wanders and not r.wanders and not ref_path:
        issues.append("should_not_wander")
    elif r.wanders and t.wanders and abs(r.wander - t.wander) > max(1.0, 0.25 * r.wander):
        issues.append("wander_distance")
    return issues


def spawn_issues(kind, r, t):
    issues = movement_issues(r, t) if kind == "creature" else []
    if r.phase_key != t.phase_key:
        issues.append("phase")
    if r.respawn > 0 and t.respawn > 0 and (t.respawn > 2 * r.respawn or 2 * t.respawn < r.respawn):
        issues.append("respawn_time")
    return issues


def assign_zones(ref, tgt, pairs, cell=100.0):
    """Give target spawns a zone: their own zoneId, the matched reference spawn's zone,
    or the zone of the nearest zoned reference spawn on the same map."""
    zone_of = {}
    for r, t, _ in pairs:
        if r.zone:
            zone_of[id(t)] = r.zone
    by_map = defaultdict(list)
    for r in ref:
        if r.zone:
            by_map[r.map].append(r)
    grids = {m: grid_index(lst, cell) for m, lst in by_map.items()}
    for t in tgt:
        if t.zone:
            zone_of[id(t)] = t.zone
            continue
        if id(t) in zone_of or t.map not in grids:
            continue
        best, best_d = 0, None
        lst = by_map[t.map]
        for i in neighbours(grids[t.map], t, cell):
            d = t.dist(lst[i])
            if best_d is None or d < best_d:
                best, best_d = lst[i].zone, d
        zone_of[id(t)] = best
    return zone_of


def learn_mask_map(pairs):
    """Per map, the most common target spawnMask for each reference spawnMask."""
    seen = defaultdict(Counter)
    for r, t, _ in pairs:
        seen[(r.map, r.mask)][t.mask] += 1
    return {key: counter.most_common(1)[0][0] for key, counter in seen.items()}


def old_numbering_maps(ref, instance_maps):
    """Instance maps whose reference spawnMasks use pre-MoP difficulty numbering.

    Before 5.x, difficulty 0 was normal, so instance masks set bit 0 (1 = normal, 3 = normal+heroic).
    From 5.x on, difficulty 0 is unused in instances and masks never set bit 0 (2 = normal, 6 = both)."""
    return {s.map for s in ref if s.map in instance_maps and s.mask & 1}


def target_mask(r, mask_map, instance_maps, shift, old_maps):
    """Returns (mask, how) where how is None (learned or open world), 'shifted' or 'kept'."""
    if (r.map, r.mask) in mask_map:
        return mask_map[(r.map, r.mask)], None
    if r.map not in instance_maps:
        return r.mask, None
    if r.map in old_maps:
        return r.mask << shift, "shifted"
    return r.mask, "kept"


@dataclass
class Result:
    kind: str
    ref: list
    tgt: list
    pairs: list
    missing: list
    extra: list
    duplicates: list
    diffs: list
    zone_of: dict


def compare(kind, ref, tgt, match_radius, dup_radius):
    pairs, missing, extra = match_spawns(ref, tgt, match_radius)
    matched_tgt = {id(t) for _, t, _ in pairs}
    duplicates = find_duplicates(tgt, ref, dup_radius, matched_tgt)
    diffs = []
    for r, t, d in pairs:
        issues = spawn_issues(kind, r, t)
        if issues:
            diffs.append((r, t, d, issues))
    zone_of = assign_zones(ref, tgt, pairs)
    for r in ref:
        zone_of[id(r)] = r.zone
    return Result(kind, ref, tgt, pairs, missing, extra, duplicates, diffs, zone_of)


def filter_zones(result, include=None, exclude=()):
    z = result.zone_of

    def keep(s):
        zone = z.get(id(s), 0)
        return (include is None or zone in include) and zone not in exclude

    result.ref = [s for s in result.ref if keep(s)]
    result.tgt = [s for s in result.tgt if keep(s)]
    result.pairs = [p for p in result.pairs if keep(p[0]) or keep(p[1])]
    result.missing = [s for s in result.missing if keep(s)]
    result.extra = [s for s in result.extra if keep(s)]
    result.duplicates = [d for d in result.duplicates if any(keep(s) for s in d["members"])]
    result.diffs = [d for d in result.diffs if keep(d[0]) or keep(d[1])]


# --------------------------------------------------------------------------- reports

def fmt(v):
    return f"{v:.4f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def movement_label(s):
    return {0: "idle", 1: "random", 2: "waypoint"}.get(s.move, str(s.move))


def write_csv(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(header)
        for row in rows:
            w.writerow([fmt(v) for v in row])


def nearest_same_entry(s, tgt_groups):
    others = tgt_groups.get((s.map, s.entry), ())
    return min((s.dist(o) for o in others), default=None)


def write_reports(res, out_dir, names, tgt_entries):
    k = res.kind
    z = res.zone_of
    tgt_groups = group_by_entry(res.tgt)

    rows = []
    for s in sorted(res.missing, key=lambda s: (s.map, z.get(id(s), 0), s.entry, s.guid)):
        near = nearest_same_entry(s, tgt_groups)
        row = [s.map, z.get(id(s), 0), s.entry, names.get(s.entry, ""), s.guid, s.x, s.y, s.z, s.o,
               s.mask, s.phase, s.phase_group]
        if k == "creature":
            row += [movement_label(s), s.wander, s.path]
        row += [int(s.pooled), int(s.event), int(s.entry in tgt_entries), "" if near is None else round(near, 1)]
        rows.append(row)
    header = ["map", "zone", "entry", "name", "ref_guid", "x", "y", "z", "o", "spawnMask", "phaseId", "phaseGroup"]
    if k == "creature":
        header += ["movement", "wander_distance", "path_id"]
    header += ["pooled", "game_event", "target_has_template", "nearest_same_entry_in_target_yd"]
    write_csv(os.path.join(out_dir, f"missing_{k}.csv"), header, rows)

    rows = []
    for s in sorted(res.extra, key=lambda s: (s.map, z.get(id(s), 0), s.entry, s.guid)):
        row = [s.map, z.get(id(s), 0), s.entry, names.get(s.entry, ""), s.guid, s.x, s.y, s.z,
               s.mask, s.phase, s.phase_group]
        if k == "creature":
            row += [movement_label(s), s.wander]
        rows.append(row + [int(s.pooled), int(s.event)])
    header = ["map", "zone", "entry", "name", "target_guid", "x", "y", "z", "spawnMask", "phaseId", "phaseGroup"]
    if k == "creature":
        header += ["movement", "wander_distance"]
    write_csv(os.path.join(out_dir, f"extra_{k}.csv"), header + ["pooled", "game_event"], rows)

    rows = []
    for d in sorted(res.duplicates, key=lambda d: (d["keep"][0].map, d["keep"][0].entry)):
        s = d["keep"][0]
        rows.append([s.map, z.get(id(s), 0), s.entry, names.get(s.entry, ""), len(d["members"]), d["ref_count"],
                     " ".join(str(m.guid) for m in d["keep"]), " ".join(str(m.guid) for m in d["extra"]),
                     s.x, s.y, s.z])
    write_csv(os.path.join(out_dir, f"duplicates_{k}.csv"),
              ["map", "zone", "entry", "name", "count_in_target", "count_in_reference",
               "keep_guids", "extra_guids", "x", "y", "z"], rows)

    rows = []
    for r, t, dist, issues in sorted(res.diffs, key=lambda d: (d[1].map, z.get(id(d[1]), 0), d[1].entry)):
        row = [t.map, z.get(id(t), 0), t.entry, names.get(t.entry, ""), r.guid, t.guid, round(dist, 2),
               ";".join(issues)]
        if k == "creature":
            row += [movement_label(r), r.wander, r.path, movement_label(t), t.wander, t.path]
        row += [f"{r.phase}/{r.phase_group}", f"{t.phase}/{t.phase_group}", r.respawn, t.respawn]
        rows.append(row)
    header = ["map", "zone", "entry", "name", "ref_guid", "target_guid", "distance", "issues"]
    if k == "creature":
        header += ["ref_movement", "ref_wander", "ref_path", "target_movement", "target_wander", "target_path"]
    header += ["ref_phase", "target_phase", "ref_respawn", "target_respawn"]
    write_csv(os.path.join(out_dir, f"diffs_{k}.csv"), header, rows)


def zone_summary(res):
    z = res.zone_of
    stats = defaultdict(lambda: Counter())
    for s in res.ref:
        stats[(s.map, z.get(id(s), 0))]["reference"] += 1
    for s in res.tgt:
        stats[(s.map, z.get(id(s), 0))]["target"] += 1
    for r, t, _ in res.pairs:
        stats[(t.map, z.get(id(t), 0))]["matched"] += 1
    for s in res.missing:
        stats[(s.map, z.get(id(s), 0))]["missing"] += 1
    for s in res.extra:
        stats[(s.map, z.get(id(s), 0))]["extra"] += 1
    for d in res.duplicates:
        s = d["keep"][0]
        stats[(s.map, z.get(id(s), 0))]["duplicate_extras"] += len(d["extra"])
    for r, t, _, issues in res.diffs:
        for issue in issues:
            stats[(t.map, z.get(id(t), 0))][issue] += 1
    return stats


SUMMARY_COLUMNS = ["reference", "target", "matched", "missing", "extra", "duplicate_extras",
                   "not_wandering", "should_not_wander", "wander_distance", "missing_path",
                   "phase", "respawn_time"]


def write_summary(results, out_dir):
    rows = []
    for res in results:
        for (m, zone), c in zone_summary(res).items():
            rows.append([res.kind, m, zone] + [c[col] for col in SUMMARY_COLUMNS])
    rows.sort(key=lambda r: (r[0], -r[6], r[1], r[2]))
    write_csv(os.path.join(out_dir, "summary.csv"), ["table", "map", "zone"] + SUMMARY_COLUMNS, rows)
    return rows


def print_summary(results, rows, top):
    for res in results:
        dup_extra = sum(len(d["extra"]) for d in res.duplicates)
        issue_counts = Counter(i for *_, issues in res.diffs for i in issues)
        print(f"\n== {res.kind}")
        print(f"  reference spawns: {len(res.ref):>8}   target spawns: {len(res.tgt):>8}   matched: {len(res.pairs):>8}")
        print(f"  missing in target: {len(res.missing):>7}   only in target: {len(res.extra):>7}   "
              f"duplicate extras: {dup_extra}")
        if issue_counts:
            print("  matched-spawn issues: " + ", ".join(f"{k}={v}" for k, v in sorted(issue_counts.items())))
        kind_rows = [r for r in rows if r[0] == res.kind and r[6] > 0][:top]
        if kind_rows:
            print(f"  zones with the most missing spawns (map/zone: missing of reference):")
            for r in kind_rows:
                print(f"    {r[1]:>4}/{r[2]:<5}  {r[6]:>6} of {r[3]:<6}")


# --------------------------------------------------------------------------- SQL generation

def sql_num(v):
    if isinstance(v, float):
        return f"{v:.6f}".rstrip("0").rstrip(".") or "0"
    return str(v)


def write_import_sql(path, res, tgt_fields, tgt_entries, mask_map, instance_maps, shift, old_maps, names,
                     ref_schema):
    kind = res.kind
    var = "@CGUID" if kind == "creature" else "@OGUID"
    skipped_template, skipped_linked = Counter(), 0
    guessed = {"shifted": set(), "kept": set()}
    rows_by_map = defaultdict(list)
    for s in sorted(res.missing, key=lambda s: (s.map, s.entry, s.guid)):
        if s.pooled or s.event:
            skipped_linked += 1
            continue
        if s.entry not in tgt_entries:
            skipped_template[s.entry] += 1
            continue
        mask, how = target_mask(s, mask_map, instance_maps, shift, old_maps)
        if how:
            guessed[how].add(s.map)
        rows_by_map[s.map].append((s, mask))

    cols = ["guid", "id", "map", "mask", "phase", "phase_group", "modelid", "x", "y", "z", "o", "respawn"]
    if kind == "creature":
        cols += ["equip", "wander", "move"]
    else:
        cols += ["rot0", "rot1", "rot2", "rot3", "anim", "state"]
    cols = [c for c in cols if tgt_fields.get(c)]
    col_list = ", ".join(f"`{tgt_fields[c]}`" for c in cols)

    n = 0
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"-- Missing {kind} spawns copied from `{ref_schema}` by spawncompare.py.\n")
        fh.write("-- Review before applying, back up your world database first, and apply only once.\n")
        if kind == "creature":
            fh.write("-- Not copied: pool/game_event links, creature_addon (auras, emotes, mounts), waypoint paths,\n")
            fh.write("-- formations, SmartAI rows keyed by guid. Patrolling spawns are inserted standing still.\n")
        else:
            fh.write("-- Not copied: pool/game_event links, gameobject_addon, SmartAI rows keyed by guid.\n")
        if skipped_linked:
            fh.write(f"-- Skipped {skipped_linked} spawns that belong to a pool or game event in the reference.\n")
        if skipped_template:
            fh.write(f"-- Skipped {sum(skipped_template.values())} spawns whose entry has no {kind}_template in the "
                     f"target: {', '.join(str(e) for e in sorted(skipped_template))}\n")
        if guessed["shifted"]:
            fh.write(f"-- WARNING: spawnMask for instance maps {', '.join(map(str, sorted(guessed['shifted'])))} was "
                     f"guessed as reference mask << {shift}: the reference uses pre-MoP difficulty numbering and\n"
                     f"-- there were no matched spawns to learn from. Right for 5-player dungeons; raids use "
                     f"different bits, so check a working raid in your database first.\n")
        if guessed["kept"]:
            fh.write(f"-- NOTE: spawnMask for instance maps {', '.join(map(str, sorted(guessed['kept'])))} was copied "
                     f"unchanged: the reference already uses MoP difficulty numbering there.\n")
        fh.write(f"\nSET {var} := (SELECT COALESCE(MAX(`{tgt_fields['guid']}`), 0) FROM `{kind}`);\n")
        for m, items in sorted(rows_by_map.items()):
            fh.write(f"\n-- map {m}: {len(items)} spawns\n")
            fh.write(f"INSERT INTO `{kind}` ({col_list}) VALUES\n")
            for i, (s, mask) in enumerate(items):
                n += 1
                patrol = kind == "creature" and s.move == 2
                v = {"guid": f"{var}+{n}", "id": s.entry, "map": s.map, "mask": mask, "phase": s.phase,
                     "phase_group": s.phase_group, "modelid": 0, "x": s.x, "y": s.y, "z": s.z, "o": s.o,
                     "respawn": s.respawn, "equip": s.equip,
                     "wander": 0.0 if patrol else s.wander, "move": 0 if patrol else s.move,
                     "rot0": s.rot[0], "rot1": s.rot[1], "rot2": s.rot[2], "rot3": s.rot[3],
                     "anim": s.anim, "state": s.state}
                sep = ";" if i == len(items) - 1 else ","
                comment = names.get(s.entry, "").replace("\n", " ")
                if patrol:
                    comment += " (patrol path not copied)"
                fh.write("(" + ", ".join(sql_num(v[c]) for c in cols) + ")" + sep
                         + (f" -- {comment.strip()}" if comment.strip() else "") + "\n")
    return n, skipped_linked, sum(skipped_template.values())


def write_wander_sql(path, res, tgt_fields):
    wander_col, move_col, guid_col = tgt_fields.get("wander"), tgt_fields.get("move"), tgt_fields["guid"]
    n = 0
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("-- Wander fixes for matched creature spawns, taken from the reference database.\n")
        fh.write("-- Review before applying and back up your world database first.\n")
        if not wander_col or not move_col:
            fh.write("-- Target creature table has no MovementType/wander column; nothing to do.\n")
            return 0
        for r, t, _, issues in res.diffs:
            if not {"not_wandering", "should_not_wander", "wander_distance"} & set(issues):
                continue
            move, wander = (1, r.wander) if r.wanders else (0, 0.0)
            fh.write(f"UPDATE `creature` SET `{move_col}` = {move}, `{wander_col}` = {sql_num(float(wander))} "
                     f"WHERE `{guid_col}` = {t.guid}; -- entry {t.entry}, {';'.join(issues)}\n")
            n += 1
    return n


# --------------------------------------------------------------------------- main

def parse_int_list(text):
    return [int(x) for x in text.replace(" ", "").split(",") if x]


def build_parser():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--reference", required=True, help="schema of the reference world DB (e.g. world434)")
    p.add_argument("--target", required=True, help="schema of the world DB to check (e.g. world)")
    p.add_argument("--host", default="127.0.0.1")
    p.add_argument("--port", type=int, default=3306)
    p.add_argument("--user", default="root")
    p.add_argument("--password", help="MySQL password (default: $MYSQL_PWD, otherwise prompt)")
    p.add_argument("--maps", default=DEFAULT_MAPS,
                   help=f"comma separated map ids, or 'all' for every map in the reference (default {DEFAULT_MAPS})")
    p.add_argument("--zones", help="only report these zone ids (comma separated)")
    p.add_argument("--exclude-maps", help="leave out these map ids (comma separated)")
    p.add_argument("--exclude-zones", help="leave out these zone ids (comma separated)")
    p.add_argument("--skip-mop-changes", action="store_true",
                   help="leave out maps and zones Mists of Pandaria changed: maps "
                        f"{','.join(map(str, sorted(MOP_CHANGED_MAPS)))}, zones "
                        f"{','.join(map(str, sorted(MOP_CHANGED_ZONES)))}")
    p.add_argument("--tables", default="creature,gameobject", help="creature, gameobject or both")
    p.add_argument("--match-radius", type=float, default=10.0,
                   help="max distance in yards for a target spawn to count as the same spawn (default 10)")
    p.add_argument("--duplicate-radius", type=float, default=1.0,
                   help="same-entry spawns closer than this are stacked duplicates (default 1)")
    p.add_argument("--out", default="spawn_report", help="output directory (default spawn_report)")
    p.add_argument("--emit-sql", action="store_true", help="also write import/fix SQL files for review")
    p.add_argument("--instance-mask-shift", type=int, default=1,
                   help="spawnMask shift for instance maps whose reference masks use pre-MoP numbering, when it "
                        "cannot be learned from matched spawns (default 1: 4.3.4 dungeon masks -> 5.4.8)")
    p.add_argument("--top", type=int, default=25, help="zones to list in the console summary")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    for schema in (args.reference, args.target):
        if not IDENTIFIER.match(schema):
            raise SystemExit(f"error: invalid schema name {schema!r}")
    kinds = [k.strip() for k in args.tables.split(",") if k.strip()]
    for k in kinds:
        if k not in KINDS:
            raise SystemExit(f"error: unknown table {k!r} (use creature and/or gameobject)")

    try:
        import pymysql
    except ImportError:
        raise SystemExit("error: PyMySQL is required: pip install pymysql")
    password = args.password
    if password is None:
        password = os.environ.get("MYSQL_PWD")
    if password is None:
        import getpass
        password = getpass.getpass(f"MySQL password for {args.user}@{args.host}: ")
    conn = pymysql.connect(host=args.host, port=args.port, user=args.user, password=password, charset="utf8mb4")
    cur = conn.cursor()

    maps = load_map_list(cur, args.reference, kinds) if args.maps.strip().lower() == "all" else parse_int_list(args.maps)
    zones = set(parse_int_list(args.zones)) if args.zones else None
    exclude_maps = set(parse_int_list(args.exclude_maps)) if args.exclude_maps else set()
    exclude_zones = set(parse_int_list(args.exclude_zones)) if args.exclude_zones else set()
    if args.skip_mop_changes:
        exclude_maps |= MOP_CHANGED_MAPS
        exclude_zones |= MOP_CHANGED_ZONES
    maps = [m for m in maps if m not in exclude_maps]
    if not maps:
        raise SystemExit("error: no maps left to compare")
    instance_maps = load_instance_maps(cur, args.target) | load_instance_maps(cur, args.reference)
    os.makedirs(args.out, exist_ok=True)
    print(f"Comparing `{args.reference}` (reference) with `{args.target}` (target) on maps: "
          f"{', '.join(map(str, maps))}")
    if exclude_zones:
        print(f"Leaving out zones: {', '.join(map(str, sorted(exclude_zones)))}")

    results = []
    for kind in kinds:
        ref, _ = load_spawns(cur, args.reference, kind, maps)
        tgt, tgt_fields = load_spawns(cur, args.target, kind, maps)
        for schema, spawns in ((args.reference, ref), (args.target, tgt)):
            pooled, event = load_linked_guids(cur, schema, kind)
            for s in spawns:
                s.pooled, s.event = s.guid in pooled, s.guid in event
        ref_names = load_template_names(cur, args.reference, kind)
        tgt_names = load_template_names(cur, args.target, kind)
        names = {**ref_names, **tgt_names}

        res = compare(kind, ref, tgt, args.match_radius, args.duplicate_radius)
        mask_map = learn_mask_map(res.pairs)
        if zones is not None or exclude_zones:
            unzoned = sum(1 for r in ref if not r.zone)
            if ref and unzoned > len(ref) // 2:
                print(f"  warning: {unzoned} of {len(ref)} reference {kind} spawns have no zoneId, "
                      f"so zone filters can't place them")
            filter_zones(res, zones, exclude_zones)
        write_reports(res, args.out, names, set(tgt_names))
        results.append(res)

        if args.emit_sql:
            n, linked, no_tpl = write_import_sql(os.path.join(args.out, f"import_missing_{kind}.sql"), res, tgt_fields,
                                                 set(tgt_names), mask_map, instance_maps, args.instance_mask_shift,
                                                 old_numbering_maps(ref, instance_maps),
                                                 names, args.reference)
            print(f"  {kind}: wrote {n} inserts to import_missing_{kind}.sql "
                  f"(skipped {linked} pooled/event, {no_tpl} without template)")
            if kind == "creature":
                n = write_wander_sql(os.path.join(args.out, "fix_wander_creature.sql"), res, tgt_fields)
                print(f"  creature: wrote {n} wander fixes to fix_wander_creature.sql")

    rows = write_summary(results, args.out)
    print_summary(results, rows, args.top)
    print(f"\nReports written to {os.path.abspath(args.out)}")
    conn.close()


if __name__ == "__main__":
    sys.exit(main())
