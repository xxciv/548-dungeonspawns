# Patch notes

Newest first. Each entry says what changed, which files it touches, and what you need to do to pick it up
(rebuild, restart, re-run SQL, edit config).

## 2026-09-29

**DungeonScale: loot fix** (`tools/pandaria/dungeon-scale.patch`)
- Scaled dungeon mobs dropped no loot, gold or honor. The core only rewards a kill once players have dealt
  half the mob's health, and that amount was set from the mob's unscaled health, so a mob shrunk to 30% could
  never meet it. `DungeonScale.cpp` now resets that requirement whenever it scales a mob's health.
- To pick up on a source tree that already has the earlier version: add the line with
  `sed -i 's|^\(\s*\)creature->SetHealth(std::max(1u, std::min(health, maxHealth)));|&\n\1creature->ResetPlayerDamageReq();|' src/server/scripts/Custom/DungeonScale/DungeonScale.cpp`,
  then `make install` in `build` (only that file recompiles) and restart `worldserver`. Re-applying the whole
  patch also works but rewrites `ScriptMgr.h`, which forces a near-full rebuild.

**DungeonScale playtest** (live server, solo, Deadmines up to and including the first boss)
- Checked and working: scaled trash and first boss, loot and gold from kills, rogue pickpocketing,
  no kill XP (`Rate.XP.Kill = 0`). The first boss's difficulty felt right at the default multipliers.
- Solocraft is now neutral (`SoloCraft.Stats.Mult = 0`, `SoloCraft.Spellpower.Mult = 0`,
  `SoloCraft.DamageTaken.Pct = 100`) and only applies its gold penalty (`SoloCraft.Money.Pct`).
- Still to test: the rest of the dungeon (end boss, the 35% hit cap on big hits), a MoP dungeon, and a
  second player joining mid-run.

## 2026-09-28

**DungeonScale: dungeon mobs scale to the group** (`tools/pandaria/dungeon-scale.patch`, guide section 12)
- New script scales 5-man dungeon creatures to the number of players inside: health and damage per rank
  (solo trash 30% / 30%, mini-bosses 35% / 35%, end bosses 40% / 35%, straight line to 100% at 5 players).
  Boss adds use the boss's values. Replaces Solocraft's stat buffs, which should now be set to neutral.
- When someone joins or leaves, only mobs out of combat are rescaled.
- No single hit or DoT tick from a scaled mob takes more than 35% of your max health (`DungeonScale.HitCap.Pct`).
- Honor per dungeon kill: 1 trash / 5 elite / 10 mini-boss / 25 end boss.
- GM commands `.dungeonscale info` and `.dungeonscale creature`.
- New files: `src/server/scripts/Custom/DungeonScale/` (`DungeonScale.h`, `DungeonScale.cpp`, `DungeonScaleScripts.cpp`).
- Core files touched: `ScriptMgr.h` / `ScriptMgr.cpp` (new `AllCreatureScript` hooks: creature added,
  removed, level set, killed), `Creature.cpp` (calls the first three), `Unit.cpp` (calls the kill hook after
  kill rewards), `ScriptLoader.cpp` (registers the script), `worldserver.conf.dist` (new `DungeonScale.*` settings).
- Fix to the Solocraft patch: `SpellAuraEffects.cpp` called the DoT damage hook twice per tick, so
  `SoloCraft.DamageTaken.Pct` hit DoTs twice (30% became 9%). The duplicate call is removed.
- To pick up: apply the patch after the Solocraft patch, run `cmake .` in `build` (new source files), rebuild (near-full rebuild, because `ScriptMgr.h` changed),
  copy the `DUNGEON SCALE` block into `worldserver.conf`, set Solocraft's stat and damage settings to neutral
  (guide section 12), restart `worldserver`. The Helix SQL can stay: his damage works out about the same.

**Deadmines: Helix Gearbreaker melee** (`tools/pandaria/sql/2026_09_28_deadmines_helix_melee.sql`)
- Normal-mode Helix (entry 47296) swings every 0.5 s with a 57.5× damage multiplier, which burns a solo
  character down. The SQL lowers the multiplier to 20 (about 35% of stock). Heroic is untouched.
- To pick up: back up the row, run the SQL on the world DB, restart `worldserver`
  and respawn him. The revert line is in the file.

**Solocraft tuning for solo dungeon runs** (`tools/pandaria/solocraft-solo-tuning.patch`, guide section 11)
- New `worldserver.conf` settings: `SoloCraft.Stats.Stamina` (keep your health pool normal),
  `SoloCraft.DamageTaken.Pct` (less NPC damage inside Solocraft instances) and `SoloCraft.Money.Pct`
  (less creature gold). Both percentages rise to 100 with a full group. Defaults change nothing.
- Core files touched: `ScriptMgr.h` / `ScriptMgr.cpp` (new `OnCreatureLootMoney` hook), `Unit.cpp`
  (calls it after a killed creature's gold is rolled), `SpellAuraEffects.cpp` (DoT and leech ticks now
  call the existing `ModifyPeriodicDamageAurasTick` hook). Script: `solocraft_system.cpp`.
  Config: `worldserver.conf.dist`.
- To pick up: apply the patch, rebuild (near-full rebuild, because `ScriptMgr.h` is in the precompiled
  headers), add the settings, restart `worldserver`. `.reload config` does not reload Solocraft.
- Also checked: the world DB matched upstream exactly. Mobs are not nerfed, and low-level MoP really is that easy.

## 2026-09-27

**Holiday calendar and world events**
- `tools/pandaria/holiday_dates.py` regenerates `holiday_dates` so events stop drifting and double-listing
  (`--dump` shows what `Holidays.dbc` says). The Darkmoon Faire is covered for about 2 years; the script
  prints the date to re-run it.
- `CalendarHandler.cpp` fix (in `pandaria-fixes.patch`, or `calendar-fix.patch` on its own): no more
  ghost holidays 26 days early.
- Guide: cap command security at 3 so administrators can use GM commands; document the daily restart loop.

## 2026-09-26

**Debian 13 build guide for pandaria_5.4.8** (`docs/pandaria-debian13.md`)
- Build guide plus database installer (`tools/pandaria/install_databases.sh`).
- `pandaria-fixes.patch` for GCC 14: `std::atomic` init, Hallow's End tables, `PATH_MAX` and
  `inet_addr` includes, mapextractor backslash in DBC/DB2 names, and a shutdown segfault in
  `ScriptMgr::Unload`.
- Guide fixes: install gnupg before mysql-apt-config, MySQL root login, startup check, repo rename.

## 2026-09-25

**spawncompare** (`tools/spawncompare`)
- Compares a SkyFire world DB against a 4.3.4 or 5.4.8 reference and generates SQL for missing spawns.
- Options `--skip-mop-changes`, `--exclude-maps`, `--exclude-zones`; handles old-style `phaseMask`.
