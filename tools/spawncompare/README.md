# spawncompare

Compares creature and gameobject spawns in your SkyFire 5.4.8 world database against a
Cataclysm 4.3.4 reference database. It reports:

- **missing spawns**: in the reference but not in your database
- **extra spawns**: only in your database (often legitimate MoP additions, such as pet tamers)
- **double spawns**: the same creature or object stacked on one spot more times than the reference has it
- **movement problems**: mobs that should wander but stand still, mobs that wander but
  shouldn't, a wander radius that's wrong, or a patrol path that's missing
- **phase and respawn-time differences** between spawns that exist in both databases

With `--emit-sql` it also writes SQL that imports the missing spawns and fixes wander settings.
The tool itself never writes to either database; you review the SQL and apply it yourself.

## 1. Get a 4.3.4 reference database

Use **The Cataclysm Preservation Project (TCPP)**, the actively maintained TrinityCore 4.3.4 fork. It
has full spawns for the Cataclysm-era dungeons, including the Cataclysm Deadmines.

1. Download the latest full world database from
   <https://github.com/The-Cataclysm-Preservation-Project/TrinityCore/releases>. As of September 2026
   that's **TDB 434.22011** (tag `TDB434.22011`). Take the `TDB_full_world_…sql` file from the release archive.
2. Import it into its **own schema** next to your SkyFire one, on the same MySQL/MariaDB server:
   ```sh
   mysql -u root -p -e "CREATE DATABASE world434"
   mysql -u root -p world434 < TDB_full_world_434.22011_*.sql
   ```
3. Optional but recommended: apply the world updates made since that release. They're in the
   TCPP source under `sql/updates/world/4.3.4/`. Apply them in filename order:
   ```sh
   git clone --depth 1 https://github.com/The-Cataclysm-Preservation-Project/TrinityCore.git tcpp
   for f in tcpp/sql/updates/world/4.3.4/*.sql; do mysql -u root -pYOURPASS world434 < "$f"; done
   ```
   PowerShell:
   ```powershell
   Get-ChildItem tcpp\sql\updates\world\4.3.4\*.sql | Sort-Object Name |
     ForEach-Object { Get-Content $_.FullName -Raw | mysql -u root -pYOURPASS world434 }
   ```

You don't need to compile or run the TCPP server. The database is only used as a reference.

## 2. Run the comparison

Requires Python 3.10+ and PyMySQL:

```sh
pip install pymysql
python spawncompare.py --reference world434 --target world --user root
```

On Debian/Ubuntu, `pip install` fails with `externally-managed-environment`. Use the distribution's package,
or a virtual environment:

```sh
sudo apt install python3-pymysql
# or
python3 -m venv .venv && .venv/bin/pip install pymysql
.venv/bin/python spawncompare.py --reference world434 --target world --user root
```

The password comes from `--password`, then `$MYSQL_PWD`, and otherwise you're prompted for it.

Useful options:

| Option | Default | Meaning |
|---|---|---|
| `--maps` | `0,1,530,571,646,732` | Eastern Kingdoms, Kalimdor, Outland, Northrend, Deepholm, Tol Barad. `all` = every map in the reference, dungeons included |
| `--zones` | all | Only report these zone IDs, e.g. `--zones 40` for Westfall |
| `--tables` | `creature,gameobject` | Which spawn tables to compare |
| `--match-radius` | `10` | How far (yards) a spawn may have moved and still count as the same spawn |
| `--duplicate-radius` | `1` | Same-entry spawns closer than this count as stacked |
| `--emit-sql` | off | Also write the import/fix SQL |
| `--out` | `spawn_report` | Output folder |

Only the missing Deadmines spawns (map 36), with SQL:

```sh
python spawncompare.py --reference world434 --target world --maps 36 --emit-sql
```

## 3. Read the reports

All reports are CSV files in the `--out` folder. They open fine in Excel or LibreOffice.

| File | What it lists |
|---|---|
| `summary.csv` | One row per map and zone with counts of each problem, sorted by missing spawns. Look up a zone ID at `wowhead.com/zone=<id>` |
| `missing_creature.csv` / `missing_gameobject.csv` | Reference spawns with no counterpart. `target_has_template=0` means your DB doesn't know the NPC or object at all. `nearest_same_entry_in_target_yd` shows how far away the closest spawn of the same NPC is, if it exists |
| `extra_*.csv` | Spawns only in your database |
| `duplicates_*.csv` | Stacked spawns. `keep_guids` are the ones matched to the reference; `extra_guids` are the candidates to delete |
| `diffs_*.csv` | Spawns that exist in both databases but differ: `not_wandering`, `should_not_wander`, `wander_distance`, `missing_path`, `phase`, `respawn_time` |

Zones are taken from the reference's `zoneId` column. SkyFire spawns get the zone of the nearest
reference spawn.

### Expect noise in areas MoP changed
The 5.x client changed some old-world areas, so differences there are often correct:
Theramore/Dustwallow Marsh (5.1), the Scarlet Monastery and Scholomance exteriors, Durotar and
the Northern Barrens (5.1 to 5.3 story), Brawler's Guild areas, Pandaren NPCs in the capital cities,
and pet battle tamers and wild pets everywhere. Pandaria itself (map 870) isn't in the reference.

## 4. Applying the generated SQL

`--emit-sql` writes these files:

- `import_missing_creature.sql` / `import_missing_gameobject.sql`: inserts new GUIDs above your current maximum.
- `fix_wander_creature.sql`: `UPDATE`s `MovementType` and `spawndist` on matched spawns.

Before applying:

- **Back up your world database** (`mysqldump -u root -p world > world_backup.sql`).
- **Apply each import once.** Running it again adds a second copy of every spawn.
- **spawnMask.** The tool learns how reference masks map to yours from spawns both databases share
  on that map. For an instance with no spawns at all (like the Deadmines), it guesses
  `reference mask << 1`, which is right for 5-player dungeons (SkyFire's own Stockade uses 2 for
  normal). The file marks every guessed map with a WARNING. **Raids need different bits.** Check a
  working raid in your DB before importing raid spawns.
- **Not copied:** pool and game-event membership (those spawns are skipped entirely, so rares and holiday
  NPCs don't become permanent), `creature_addon` (auras, emotes, mounts), waypoint paths,
  formations and guid-based SmartAI. Patrolling mobs are imported standing still, and the missing
  paths show up in `diffs_creature.csv` on the next run.
- **Scripts.** SkyFire's Deadmines instance script is still the pre-Cataclysm one (Rhahk'zor, Mr. Smite).
  The Cataclysm bosses will spawn, but they'll have no encounter mechanics until someone writes scripts for them.
- **Duplicates** aren't deleted automatically. Deleting a guid that pools, formations or SmartAI refer to
  leaves broken rows behind, so review `duplicates_*.csv` and remove them by hand.

## Tests

```sh
python -m unittest discover -s tests
# end-to-end against a scratch MySQL/MariaDB server (creates and drops sc_test_ref / sc_test_tgt)
SPAWNCOMPARE_TEST_MYSQL=1 MYSQL_USER=root MYSQL_PWD=... python -m unittest discover -s tests
```
