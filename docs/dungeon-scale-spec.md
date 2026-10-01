# Solo Dungeon Scaling: Design Spec (phase 1 shipped 2026-10-01)

## Goal
A single well-prepared player (green/blue gear, buffed, potions ready) can clear any 5-man dungeon. Bosses should feel challenging, but a cooldown used too early shouldn't lose the fight. Deaths should come from player choices like greedy pulls or starting a fight unready. Dungeons are for farming loot and materials; mob kills give no XP and little gold.

## Approach: shrink the mobs, don't inflate the player
We stop using Solocraft's stat buffs and scale **creatures** to the number of players in the instance. We don't need to write this from scratch, because `mod-dungeon-scale` in the 548DS repo already does most of it:

| Already built in mod-dungeon-scale | Still to add |
|---|---|
| Separate health and damage multipliers | Rescale only mobs that are out of combat |
| Tiers by rank: Normal, Elite, MiniBoss, EndBoss | Cap on how hard a single hit can land |
| Linear curve from solo up to 1.0 at 5 players | Solo enrage-timer handling (phase 2) |
| Adds summoned by a boss use the boss's scaling | Retuned defaults (below) |
| Mob-on-mob heals scaled down too | Port from SkyFire to the alexkulya core |
| Per-dungeon overrides, `.dungeonscale info` GM command | |
| Honor per kill: 1 Normal / 5 Elite / 10 MiniBoss / 25 EndBoss (kept on) | |

## Rules
1. **Group size.** Count players inside the instance, not group members elsewhere. GMs in GM mode don't count. A full group of 5 always faces stock mobs.
2. **Health and damage** scale separately by rank (defaults below). Health changes keep the mob's current health %.
3. **Rescale timing.** When someone joins or leaves, only mobs **out of combat** are rescaled. Mobs in a fight keep their numbers and are rescaled once they leave combat or reset.
4. **Single-hit cap.** No single hit from a scaled mob can deal more than **35% of the player's max health**. DoTs are capped per tick. This removes one-shots from abilities tuned for tanks.
5. **Enrage timers** (phase 2). A config list of berserk/enrage spell IDs is blocked when there are fewer than 3 players.
6. **Scope.** 5-man dungeons only. Raids, scenarios and Challenge Modes stay off.
7. **Honor.** Dungeon kills award honor by rank: Normal 1, Elite 5, MiniBoss 10, EndBoss 25 (decided by Four 2026-09-28; these match the module defaults).
8. **Kill XP** stays off globally with the core's `Rate.XP.Kill = 0`, independent of this mod.

## Starting numbers (solo; the curve reaches 1.0 at 5 players)
| Rank | Health | Damage |
|---|---|---|
| Normal / Elite trash | 0.30 | 0.30 |
| MiniBoss | 0.35 | 0.35 |
| EndBoss | 0.40 | 0.35 |

For two players this works out to about 0.47 health and damage for trash. The damage value matches the Deadmines playtest, where 30% felt right. Health is a guess, because that playtest still had Solocraft's stat buffs making the player hit harder. Bosses get tuned against a **60 to 90 second** solo fight for a geared, buffed player. The Helix SQL fix stays: 20 × 0.35 gives about the same effective damage as the tuning that felt right.

## What happens to Solocraft
- Phase 1: keep Solocraft installed only for **Money.Pct** (the gold penalty). Set its stat buffs and DamageTaken to neutral so mobs aren't scaled twice:

  | Setting | Value | Why |
  |---|---|---|
  | `SoloCraft.Stats.Mult` | 0 | Removes the stat buff. |
  | `SoloCraft.Spellpower.Mult` | 0 | Removes the bonus spell power. |
  | `SoloCraft.Stats.Stamina` | 0 | Does nothing while Stats.Mult is 0. Set to 0 so Stamina stays out if the buff comes back. |
  | `SoloCraft.DamageTaken.Pct` | 100 | DungeonScale already cuts mob damage. Lower would cut it twice. |
  | `SoloCraft.Money.Pct` | Four's choice (live: 5) | Gold penalty only. |

  Difficulty offsets can stay. Solocraft reads these only at startup, so changing them needs a `worldserver` restart (`.reload config` won't work).
- Phase 2: move the gold penalty into this mod and remove Solocraft entirely.

## Build impact
- **New files:** the module source in `src/server/scripts/Custom/DungeonScale/`. Settings live in `worldserver.conf` (the `DUNGEON SCALE` block), not a separate conf file. New files mean running `cmake .` once before `make`.
- **Core patch:** adds creature spawn, despawn and level hooks. This edits `ScriptMgr.h`, which forces a **near-full rebuild** once.
- The alexkulya core already had the damage hooks (our PR #1 added the DoT-tick one). The port added an `AllCreatureScript` with spawn, despawn, level and kill hooks.
- No database changes. Tuning lives in the config file. `.reload config` works for DungeonScale settings, but not for Solocraft's.

## Phases
1. Port the module, apply rules 1 to 4 and the defaults, and neutralize Solocraft. Playtest Deadmines and one MoP dungeon.
2. Add enrage handling, move the gold penalty over and remove Solocraft.
3. Per-dungeon tuning passes, using the overrides only where one dungeon is an outlier.

## Decisions (2026-09-28)
- Honor on kills: yes, 1 / 5 / 10 / 25 by rank.
- 35% single-hit cap and a 60 to 90 second solo boss fight target: confirmed by Four.
- Status: built as PR xxciv/zrpandaria548#2 (2026-09-28); full worldserver build passes.
- 2026-09-29: installed on the live server. Phase 1 playtest (Deadmines to the first boss) passed after the loot fix. Loot, pickpocket and no kill XP all work, and the first boss felt right. Still to test: end boss, the hit cap, a MoP dungeon, and a second player joining mid-run.
- 2026-09-29: fix: scaled mobs dropped no loot, because the core's damage-for-loot requirement was based on unscaled health. It is now reset after scaling.
- 2026-10-01: fix: honor is stored in hundredths, so kills now convert whole points. Confirmed in game (1 trash / 5 elite). Several full solo Deadmines runs felt good. Phase 1 signed off by Four; PRs #1 and #2 merged into main. Phases 2 and 3 are still open.
- 2026-10-01: Solocraft settings to run alongside DungeonScale recorded (table above): restart required.
- Still untested: end boss with the hit cap on a big hit, a MoP dungeon, a second player joining mid-run.
