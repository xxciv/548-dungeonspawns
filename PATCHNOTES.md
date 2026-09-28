# Patch notes

Newest first. Each entry says what changed, which files it touches, and what you need to do to pick it up
(rebuild, restart, re-run SQL, edit config).

## 2026-09-28

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
