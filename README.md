# 548-dungeonspawns

Tools and notes for fixing missing or broken spawns in a Project SkyFire 5.4.8 world database.

- [`tools/spawncompare`](tools/spawncompare/README.md) compares your world DB against a reference world DB,
  either another 5.4.8 database (alexkulya/pandaria_5.4.8) or a Cataclysm 4.3.4 one (The Cataclysm
  Preservation Project). It reports missing spawns, double spawns and wander/patrol problems, and can
  generate SQL to import the missing spawns.

- [`docs/pandaria-debian13.md`](docs/pandaria-debian13.md): building the
  [pandaria_5.4.8](https://github.com/alexkulya/pandaria_5.4.8) core on Debian 13, with a database
  installer (`tools/pandaria/install_databases.sh`) and the source fixes GCC 14 needs.

## Why some dungeons are empty

Stock SkyFire ships these instances with no creature spawns: Deadmines (36), Ragefire Chasm (389),
Throne of the Tides (643), Blackrock Caverns (645), Vortex Pinnacle (657), Blackwing Descent (669),
Bastion of Twilight (671), Well of Eternity (939), Hour of Twilight (940), Dragon Soul (967),
Mogu'shan Palace (994), Scarlet Halls (1001), Scarlet Monastery (1004), Scholomance (1007),
Mogu'shan Vaults (1008), Heart of Fear (1009), Siege of Niuzao Temple (1011) and Throne of Thunder (1098).

- The Deadmines was cleared on purpose by SkyFire's
  `sql/old/5.4.8/world/SFDB_release_23.00_to_23.01/2023_10_27_world_01.sql`
  (`DELETE FROM creature/gameobject WHERE map=36`). The Stockade was cleared in the same batch and
  rebuilt the same day; the Deadmines never was.
- No SkyFire world update since then has added spawns for any of the maps above, and the core has no
  boss scripts for them. Its Deadmines script is still the pre-Cataclysm version.
- Ragefire Chasm, Scarlet Halls/Monastery, Scholomance and the MoP instances can't be filled from a
  4.3.4 database, because MoP rebuilt or added them. Use `spawncompare --skip-mop-changes` to keep them out.
  The 5.4.8 world DB shipped with alexkulya/pandaria_5.4.8 has spawns for all of them.
- The spawns alone won't bring boss encounters: SkyFire has no scripts for these instances.
