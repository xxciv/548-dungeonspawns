-- Normal-mode loot and gold for the revamped dungeons (Deadmines, Shadowfang Keep, Scarlet Halls,
-- Scarlet Monastery, Scholomance).
--
-- Why: these dungeons use ONE creature entry for normal and heroic. The level and stats per difficulty
-- come from `creature_difficulty`, but gold (creature_template.mingold/maxgold) and pickpocket loot have no
-- per-difficulty column, and the stored values were captured in heroic (level 85-92). So a level 14
-- Kobold Digger drops 76s 84c (open-world level 14 mobs: ~19c) and rogues pickpocket level-80 items.
--
-- What this does (generated from world_04_03_2023 + updates; 111 creatures):
--   1) Gold: scales mingold/maxgold down by (open-world median gold at the normal level) /
--      (open-world median gold at the heroic level). Bosses keep paying more than trash.
--      Trade-off: heroic runs of these dungeons then also pay the lower amount (the core has no
--      heroic gold column).
--   2) Pickpocket: items far above the normal level (required level > level+5, item level > level+15,
--      or grey junk that sells for 5s+) are re-tagged DUNGEON_HEROIC. Needs
--      tools/pandaria/pickpocket-difficulty.patch to drop in heroic; without the patch they simply stop
--      dropping anywhere, which is fine if you never run these on heroic.
--   3) Corpse loot: the same heroic-level items tagged '' (every difficulty) or DUNGEON_NORMAL are
--      re-tagged DUNGEON_HEROIC, or deleted where a DUNGEON_HEROIC copy of the row already exists.
--
-- Back up first:
--   mysqldump -u root -p world creature_template pickpocketing_loot_template creature_loot_template > loot_gold_backup.sql
-- Revert: 2026_10_01_normal_dungeon_loot_gold_revert.sql
-- Pick up: run against the world DB, then restart worldserver (templates and loot tables load at startup).

-- 1) Gold: scale the heroic-sniffed mingold/maxgold down to the creature's normal level.
--    new = old x (open-world median gold at normal level / open-world median gold at heroic level)

-- Deadmines
UPDATE `creature_template` SET `mingold` = 21, `maxgold` = 21 WHERE `entry` = 48445; -- Oaf Lackey (lvl 10, heroic 85): 71s 41c -> 21c
UPDATE `creature_template` SET `mingold` = 53, `maxgold` = 53 WHERE `entry` = 48229; -- Kobold Digger (lvl 14, heroic 85): 76s 84c -> 53c
UPDATE `creature_template` SET `mingold` = 15, `maxgold` = 15 WHERE `entry` = 48278; -- Mining Monkey (lvl 14, heroic 85): 21s 37c -> 15c
UPDATE `creature_template` SET `mingold` = 54, `maxgold` = 54 WHERE `entry` = 48419; -- Defias Miner (lvl 14, heroic 85): 79s 6c -> 54c
UPDATE `creature_template` SET `mingold` = 54, `maxgold` = 54 WHERE `entry` = 48420; -- Defias Digger (lvl 14, heroic 85): 79s 3c -> 54c
UPDATE `creature_template` SET `mingold` = 16, `maxgold` = 16 WHERE `entry` = 48441; -- Mining Monkey (lvl 14, heroic 85): 22s 85c -> 16c
UPDATE `creature_template` SET `mingold` = 48, `maxgold` = 48 WHERE `entry` = 48230; -- Ogre Henchman (lvl 15, heroic 86): 70s 84c -> 48c
UPDATE `creature_template` SET `mingold` = 33, `maxgold` = 33 WHERE `entry` = 48262; -- Ogre Bodyguard (lvl 15, heroic 86): 48s 19c -> 33c
UPDATE `creature_template` SET `mingold` = 60, `maxgold` = 60 WHERE `entry` = 48279; -- Goblin Overseer (lvl 15, heroic 85): 69s 75c -> 60c
UPDATE `creature_template` SET `mingold` = 71, `maxgold` = 71 WHERE `entry` = 48338; -- Mine Bunny (lvl 15, heroic 85): 82s 44c -> 71c
UPDATE `creature_template` SET `mingold` = 74, `maxgold` = 74 WHERE `entry` = 48417; -- Defias Blood Wizard (lvl 15, heroic 85): 85s 62c -> 74c
UPDATE `creature_template` SET `mingold` = 74, `maxgold` = 74 WHERE `entry` = 48418; -- Defias Envoker (lvl 15, heroic 85): 85s 41c -> 74c
UPDATE `creature_template` SET `mingold` = 62, `maxgold` = 62 WHERE `entry` = 48421; -- Defias Overseer (lvl 15, heroic 85): 71s 65c -> 62c
UPDATE `creature_template` SET `mingold` = 65, `maxgold` = 65 WHERE `entry` = 48502; -- Defias Enforcer (lvl 15, heroic 85): 75s 76c -> 65c
UPDATE `creature_template` SET `mingold` = 64, `maxgold` = 64 WHERE `entry` = 48505; -- Defias Shadowguard (lvl 15, heroic 85): 74s 3c -> 64c
UPDATE `creature_template` SET `mingold` = 51, `maxgold` = 51 WHERE `entry` = 48521; -- Defias Squallshaper (lvl 15, heroic 85): 59s 20c -> 51c
UPDATE `creature_template` SET `mingold` = 52, `maxgold` = 52 WHERE `entry` = 48522; -- Defias Pirate (lvl 15, heroic 85): 60s 28c -> 52c
UPDATE `creature_template` SET `mingold` = 162, `maxgold` = 162 WHERE `entry` = 43778; -- Foe Reaper 5000 (lvl 16, heroic 87): 2g 0s 8c -> 1s 62c
UPDATE `creature_template` SET `mingold` = 107, `maxgold` = 107 WHERE `entry` = 47162; -- Glubtok (lvl 16, heroic 87): 1g 31s 58c -> 1s 7c
UPDATE `creature_template` SET `mingold` = 106, `maxgold` = 106 WHERE `entry` = 47626; -- Admiral Ripsnarl (lvl 16, heroic 87): 1g 30s 29c -> 1s 6c
UPDATE `creature_template` SET `mingold` = 101, `maxgold` = 101 WHERE `entry` = 47739; -- "Captain" Cookie (lvl 16, heroic 87): 1g 24s 90c -> 1s 1c

-- Scarlet Halls
UPDATE `creature_template` SET `mingold` = 113, `maxgold` = 113 WHERE `entry` = 58676; -- Scarlet Defender (lvl 29, heroic 90): 49s 91c -> 1s 13c
UPDATE `creature_template` SET `mingold` = 112, `maxgold` = 112 WHERE `entry` = 58683; -- Scarlet Myrmidon (lvl 29, heroic 90): 49s 71c -> 1s 12c
UPDATE `creature_template` SET `mingold` = 108, `maxgold` = 108 WHERE `entry` = 58684; -- Scarlet Scourge Hewer (lvl 29, heroic 90): 47s 84c -> 1s 8c
UPDATE `creature_template` SET `mingold` = 108, `maxgold` = 108 WHERE `entry` = 58685; -- Scarlet Evangelist (lvl 29, heroic 90): 47s 66c -> 1s 8c
UPDATE `creature_template` SET `mingold` = 115, `maxgold` = 115 WHERE `entry` = 58756; -- Scarlet Evoker (lvl 29, heroic 90): 50s 84c -> 1s 15c
UPDATE `creature_template` SET `mingold` = 231, `maxgold` = 231 WHERE `entry` = 58876; -- Starving Hound (lvl 29, heroic 90): 1g 1s 97c -> 2s 31c
UPDATE `creature_template` SET `mingold` = 93, `maxgold` = 93 WHERE `entry` = 59175; -- Master Archer (lvl 29, heroic 90): 41s 21c -> 93c
UPDATE `creature_template` SET `mingold` = 134, `maxgold` = 134 WHERE `entry` = 59240; -- Scarlet Hall Guardian (lvl 29, heroic 90): 59s 18c -> 1s 34c
UPDATE `creature_template` SET `mingold` = 132, `maxgold` = 132 WHERE `entry` = 59241; -- Scarlet Treasurer (lvl 29, heroic 90): 58s 46c -> 1s 32c
UPDATE `creature_template` SET `mingold` = 133, `maxgold` = 133 WHERE `entry` = 59372; -- Scarlet Scholar (lvl 29, heroic 90): 58s 97c -> 1s 33c
UPDATE `creature_template` SET `mingold` = 124, `maxgold` = 124 WHERE `entry` = 59373; -- Scarlet Pupil (lvl 29, heroic 90): 54s 72c -> 1s 24c
UPDATE `creature_template` SET `mingold` = 307, `maxgold` = 307 WHERE `entry` = 58674; -- Angry Hound (lvl 30, heroic 90): 1g 23s 73c -> 3s 7c
UPDATE `creature_template` SET `mingold` = 70, `maxgold` = 70 WHERE `entry` = 58898; -- Vigilant Watchman (lvl 30, heroic 90): 28s 17c -> 70c
UPDATE `creature_template` SET `mingold` = 253, `maxgold` = 3 WHERE `entry` = 59191; -- Commander Lindon (lvl 30, heroic 91): 1s 1c -> 3c
UPDATE `creature_template` SET `mingold` = 253, `maxgold` = 3 WHERE `entry` = 59299; -- Scarlet Guardian (lvl 30, heroic 90): 1s 1c -> 3c
UPDATE `creature_template` SET `mingold` = 253, `maxgold` = 3 WHERE `entry` = 59302; -- Sergeant Verdone (lvl 30, heroic 90): 1s 1c -> 3c
UPDATE `creature_template` SET `mingold` = 253, `maxgold` = 3 WHERE `entry` = 59309; -- Obedient Hound (lvl 30, heroic 90): 1s 1c -> 3c
UPDATE `creature_template` SET `mingold` = 5986, `maxgold` = 5986 WHERE `entry` = 58632; -- Armsmaster Harlan (lvl 31, heroic 92): 23g 10s 24c -> 59s 86c
UPDATE `creature_template` SET `mingold` = 7684, `maxgold` = 7684 WHERE `entry` = 59150; -- Flameweaver Koegler (lvl 31, heroic 92): 29g 65s 77c -> 76s 84c
UPDATE `creature_template` SET `mingold` = 6250, `maxgold` = 6250 WHERE `entry` = 59303; -- Houndmaster Braun (lvl 31, heroic 92): 24g 12s 31c -> 62s 50c

-- Scarlet Monastery
UPDATE `creature_template` SET `mingold` = 76, `maxgold` = 76 WHERE `entry` = 58783; -- Scarlet Initiate (lvl 30, heroic 90): 30s 79c -> 76c
UPDATE `creature_template` SET `mingold` = 95, `maxgold` = 95 WHERE `entry` = 59705; -- Scarlet Flamethrower (lvl 31, heroic 90): 36s 71c -> 95c
UPDATE `creature_template` SET `mingold` = 264, `maxgold` = 3 WHERE `entry` = 59722; -- Pile of Corpses (lvl 31, heroic 90): 1s 1c -> 3c
UPDATE `creature_template` SET `mingold` = 95, `maxgold` = 95 WHERE `entry` = 59746; -- Scarlet Centurion (lvl 31, heroic 90): 36s 70c -> 95c
UPDATE `creature_template` SET `mingold` = 4, `maxgold` = 4 WHERE `entry` = 60033; -- Frenzied Spirit (lvl 31, heroic 90): 1s 64c -> 4c
UPDATE `creature_template` SET `mingold` = 142, `maxgold` = 142 WHERE `entry` = 58555; -- Scarlet Fanatic (lvl 32, heroic 90): 50s 52c -> 1s 42c
UPDATE `creature_template` SET `mingold` = 143, `maxgold` = 143 WHERE `entry` = 58569; -- Scarlet Purifier (lvl 32, heroic 90): 50s 58c -> 1s 43c
UPDATE `creature_template` SET `mingold` = 134, `maxgold` = 134 WHERE `entry` = 58590; -- Scarlet Zealot (lvl 32, heroic 90): 47s 72c -> 1s 34c
UPDATE `creature_template` SET `mingold` = 122, `maxgold` = 122 WHERE `entry` = 58605; -- Scarlet Judicator (lvl 32, heroic 90): 43s 38c -> 1s 22c
UPDATE `creature_template` SET `mingold` = 8953, `maxgold` = 8953 WHERE `entry` = 59789; -- Thalnos the Soulrender (lvl 33, heroic 92): 28g 96s 64c -> 89s 53c
UPDATE `creature_template` SET `mingold` = 2078, `maxgold` = 2078 WHERE `entry` = 3977; -- High Inquisitor Whitemane (lvl 34, heroic 92): 6g 22s 0c -> 20s 78c
UPDATE `creature_template` SET `mingold` = 10160, `maxgold` = 10160 WHERE `entry` = 59223; -- Brother Korloff (lvl 34, heroic 92): 30g 41s 3c -> 1g 1s 60c
UPDATE `creature_template` SET `mingold` = 3833, `maxgold` = 3833 WHERE `entry` = 60040; -- Commander Durand (lvl 34, heroic 92): 11g 47s 37c -> 38s 33c

-- Scholomance
UPDATE `creature_template` SET `mingold` = 240, `maxgold` = 240 WHERE `entry` = 58757; -- Scholomance Acolyte (lvl 41, heroic 90): 48s 30c -> 2s 40c
UPDATE `creature_template` SET `mingold` = 243, `maxgold` = 243 WHERE `entry` = 58823; -- Scholomance Neophyte (lvl 41, heroic 90): 48s 78c -> 2s 43c
UPDATE `creature_template` SET `mingold` = 305, `maxgold` = 305 WHERE `entry` = 59368; -- Krastinovian Carver (lvl 41, heroic 90): 61s 24c -> 3s 5c
UPDATE `creature_template` SET `mingold` = 303, `maxgold` = 303 WHERE `entry` = 59467; -- Candlestick Mage (lvl 41, heroic 90): 60s 94c -> 3s 3c
UPDATE `creature_template` SET `mingold` = 8, `maxgold` = 8 WHERE `entry` = 59501; -- Reanimated Corpse (lvl 41, heroic 90): 1s 69c -> 8c
UPDATE `creature_template` SET `mingold` = 508, `maxgold` = 5 WHERE `entry` = 59503; -- Brittle Skeleton (lvl 41, heroic 90): 1s 1c -> 5c
UPDATE `creature_template` SET `mingold` = 336, `maxgold` = 336 WHERE `entry` = 59614; -- Bored Student (lvl 41, heroic 90): 67s 49c -> 3s 36c
UPDATE `creature_template` SET `mingold` = 63, `maxgold` = 63 WHERE `entry` = 58822; -- Risen Guard (lvl 42, heroic 91): 11s 91c -> 63c
UPDATE `creature_template` SET `mingold` = 303, `maxgold` = 303 WHERE `entry` = 59193; -- Boneweaver (lvl 42, heroic 91): 56s 97c -> 3s 3c
UPDATE `creature_template` SET `mingold` = 81, `maxgold` = 81 WHERE `entry` = 59359; -- Flesh Horror (lvl 42, heroic 91): 15s 20c -> 81c
UPDATE `creature_template` SET `mingold` = 447, `maxgold` = 447 WHERE `entry` = 59613; -- Professor Slate (lvl 42, heroic 91): 83s 96c -> 4s 47c
UPDATE `creature_template` SET `mingold` = 575, `maxgold` = 6 WHERE `entry` = 58633; -- Instructor Chillheart (lvl 43, heroic 92): 1s 1c -> 6c
UPDATE `creature_template` SET `mingold` = 23060, `maxgold` = 23060 WHERE `entry` = 58664; -- Instructor Chillheart's Phylactery (lvl 43, heroic 92): 40g 91s 21c -> 2g 30s 60c
UPDATE `creature_template` SET `mingold` = 575, `maxgold` = 6 WHERE `entry` = 58875; -- Darkmaster Gandling (lvl 43, heroic 92): 1s 1c -> 6c
UPDATE `creature_template` SET `mingold` = 19658, `maxgold` = 19658 WHERE `entry` = 59080; -- Darkmaster Gandling (lvl 43, heroic 92): 34g 87s 70c -> 1g 96s 58c
UPDATE `creature_template` SET `mingold` = 17017, `maxgold` = 17017 WHERE `entry` = 59153; -- Rattlegore (lvl 43, heroic 92): 30g 19s 16c -> 1g 70s 17c
UPDATE `creature_template` SET `mingold` = 16990, `maxgold` = 16990 WHERE `entry` = 59184; -- Jandice Barov (lvl 43, heroic 92): 30g 14s 36c -> 1g 69s 90c
UPDATE `creature_template` SET `mingold` = 575, `maxgold` = 6 WHERE `entry` = 59200; -- Lilian Voss (lvl 43, heroic 92): 1s 1c -> 6c

-- Shadowfang Keep
UPDATE `creature_template` SET `mingold` = 187, `maxgold` = 187 WHERE `entry` = 3864; -- Fel Steed (lvl 19, heroic 85): 1g 40s 77c -> 1s 87c
UPDATE `creature_template` SET `mingold` = 184, `maxgold` = 184 WHERE `entry` = 3865; -- Shadow Charger (lvl 19, heroic 85): 1g 38s 1c -> 1s 84c
UPDATE `creature_template` SET `mingold` = 90, `maxgold` = 90 WHERE `entry` = 3877; -- Wailing Guardsman (lvl 19, heroic 85): 67s 70c -> 90c
UPDATE `creature_template` SET `mingold` = 113, `maxgold` = 113 WHERE `entry` = 47131; -- Frantic Geist (lvl 19, heroic 85): 84s 90c -> 1s 13c
UPDATE `creature_template` SET `mingold` = 110, `maxgold` = 110 WHERE `entry` = 47134; -- Corpse Eater (lvl 19, heroic 85): 82s 86c -> 1s 10c
UPDATE `creature_template` SET `mingold` = 81, `maxgold` = 81 WHERE `entry` = 47135; -- Fetid Ghoul (lvl 19, heroic 85): 60s 75c -> 81c
UPDATE `creature_template` SET `mingold` = 100, `maxgold` = 100 WHERE `entry` = 47140; -- Sorcerous Skeleton (lvl 19, heroic 85): 75s 28c -> 1s 0c
UPDATE `creature_template` SET `mingold` = 71, `maxgold` = 71 WHERE `entry` = 47143; -- Spitebone Skeleton (lvl 19, heroic 86): 67s 99c -> 71c
UPDATE `creature_template` SET `mingold` = 69, `maxgold` = 69 WHERE `entry` = 47145; -- Spitebone Guardian (lvl 19, heroic 86): 66s 62c -> 69c
UPDATE `creature_template` SET `mingold` = 99, `maxgold` = 99 WHERE `entry` = 47231; -- Shadowy Attendant (lvl 19, heroic 85): 74s 63c -> 99c
UPDATE `creature_template` SET `mingold` = 97, `maxgold` = 97 WHERE `entry` = 47232; -- Ghostly Cook (lvl 19, heroic 85): 73s 2c -> 97c
UPDATE `creature_template` SET `mingold` = 162, `maxgold` = 162 WHERE `entry` = 3869; -- Lesser Gargoyle (lvl 20, heroic 85): 1g 21s 63c -> 1s 62c
UPDATE `creature_template` SET `mingold` = 162, `maxgold` = 162 WHERE `entry` = 3870; -- Stone Sleeper (lvl 20, heroic 85): 1g 21s 90c -> 1s 62c
UPDATE `creature_template` SET `mingold` = 134, `maxgold` = 134 WHERE `entry` = 3873; -- Tormented Officer (lvl 20, heroic 85): 1g 0s 30c -> 1s 34c
UPDATE `creature_template` SET `mingold` = 99, `maxgold` = 99 WHERE `entry` = 3875; -- Haunted Servitor (lvl 20, heroic 85): 74s 31c -> 99c
UPDATE `creature_template` SET `mingold` = 119, `maxgold` = 119 WHERE `entry` = 47132; -- Dark Creeper (lvl 20, heroic 85): 89s 30c -> 1s 19c
UPDATE `creature_template` SET `mingold` = 116, `maxgold` = 116 WHERE `entry` = 47136; -- Unstable Ravager (lvl 20, heroic 85): 86s 87c -> 1s 16c
UPDATE `creature_template` SET `mingold` = 74, `maxgold` = 74 WHERE `entry` = 47137; -- Mindless Horror (lvl 20, heroic 86): 70s 80c -> 74c
UPDATE `creature_template` SET `mingold` = 71, `maxgold` = 71 WHERE `entry` = 47138; -- Pustulant Monstrosity (lvl 20, heroic 86): 68s 24c -> 71c
UPDATE `creature_template` SET `mingold` = 116, `maxgold` = 116 WHERE `entry` = 47141; -- Dread Scryer (lvl 20, heroic 85): 86s 75c -> 1s 16c
UPDATE `creature_template` SET `mingold` = 90, `maxgold` = 90 WHERE `entry` = 47146; -- Spitebone Flayer (lvl 20, heroic 86): 86s 79c -> 90c
UPDATE `creature_template` SET `mingold` = 166, `maxgold` = 166 WHERE `entry` = 3887; -- Baron Silverlaine (lvl 21, heroic 87): 1g 21s 81c -> 1s 66c
UPDATE `creature_template` SET `mingold` = 135, `maxgold` = 135 WHERE `entry` = 4278; -- Commander Springvale (lvl 21, heroic 87): 99s 45c -> 1s 35c
UPDATE `creature_template` SET `mingold` = 173, `maxgold` = 173 WHERE `entry` = 46962; -- Baron Ashbury (lvl 21, heroic 87): 1g 26s 83c -> 1s 73c
UPDATE `creature_template` SET `mingold` = 175, `maxgold` = 175 WHERE `entry` = 46963; -- Lord Walden (lvl 21, heroic 87): 1g 28s 29c -> 1s 75c
UPDATE `creature_template` SET `mingold` = 179, `maxgold` = 179 WHERE `entry` = 46964; -- Lord Godfrey (lvl 21, heroic 87): 1g 31s 27c -> 1s 79c

-- 2) Pickpocket: heroic-level items only drop in heroic (rogue pickpocket)
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 3873 AND `item` = 58267 AND `lootmode` = ''; -- Tormented Officer: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47131 AND `item` = 53010 AND `lootmode` = ''; -- Frantic Geist: Embersilk Cloth
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47131 AND `item` = 58267 AND `lootmode` = ''; -- Frantic Geist: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47131 AND `item` = 63300 AND `lootmode` = ''; -- Frantic Geist: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47131 AND `item` = 63349 AND `lootmode` = ''; -- Frantic Geist: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47132 AND `item` = 58267 AND `lootmode` = ''; -- Dark Creeper: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47132 AND `item` = 63300 AND `lootmode` = ''; -- Dark Creeper: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47132 AND `item` = 63349 AND `lootmode` = ''; -- Dark Creeper: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47134 AND `item` = 58267 AND `lootmode` = ''; -- Corpse Eater: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47134 AND `item` = 63300 AND `lootmode` = ''; -- Corpse Eater: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47134 AND `item` = 63349 AND `lootmode` = ''; -- Corpse Eater: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47135 AND `item` = 58267 AND `lootmode` = ''; -- Fetid Ghoul: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47135 AND `item` = 63300 AND `lootmode` = ''; -- Fetid Ghoul: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47135 AND `item` = 63349 AND `lootmode` = ''; -- Fetid Ghoul: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47136 AND `item` = 58267 AND `lootmode` = ''; -- Unstable Ravager: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47136 AND `item` = 63300 AND `lootmode` = ''; -- Unstable Ravager: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47136 AND `item` = 63349 AND `lootmode` = ''; -- Unstable Ravager: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47137 AND `item` = 58267 AND `lootmode` = ''; -- Mindless Horror: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47137 AND `item` = 63300 AND `lootmode` = ''; -- Mindless Horror: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47137 AND `item` = 63349 AND `lootmode` = ''; -- Mindless Horror: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47138 AND `item` = 58267 AND `lootmode` = ''; -- Pustulant Monstrosity: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47138 AND `item` = 63349 AND `lootmode` = ''; -- Pustulant Monstrosity: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47140 AND `item` = 58267 AND `lootmode` = ''; -- Sorcerous Skeleton: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47140 AND `item` = 63300 AND `lootmode` = ''; -- Sorcerous Skeleton: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47140 AND `item` = 63349 AND `lootmode` = ''; -- Sorcerous Skeleton: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47141 AND `item` = 58267 AND `lootmode` = ''; -- Dread Scryer: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47141 AND `item` = 63300 AND `lootmode` = ''; -- Dread Scryer: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47141 AND `item` = 63349 AND `lootmode` = ''; -- Dread Scryer: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47143 AND `item` = 58267 AND `lootmode` = ''; -- Spitebone Skeleton: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47143 AND `item` = 63300 AND `lootmode` = ''; -- Spitebone Skeleton: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47143 AND `item` = 63349 AND `lootmode` = ''; -- Spitebone Skeleton: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47145 AND `item` = 58267 AND `lootmode` = ''; -- Spitebone Guardian: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47145 AND `item` = 63300 AND `lootmode` = ''; -- Spitebone Guardian: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47145 AND `item` = 63349 AND `lootmode` = ''; -- Spitebone Guardian: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47146 AND `item` = 58267 AND `lootmode` = ''; -- Spitebone Flayer: Scarlet Polypore
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47146 AND `item` = 63300 AND `lootmode` = ''; -- Spitebone Flayer: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47146 AND `item` = 63349 AND `lootmode` = ''; -- Spitebone Flayer: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47297 AND `item` = 63348 AND `lootmode` = ''; -- Lumbering Oaf: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48229 AND `item` = 58269 AND `lootmode` = ''; -- Kobold Digger: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48229 AND `item` = 63300 AND `lootmode` = ''; -- Kobold Digger: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48229 AND `item` = 63348 AND `lootmode` = ''; -- Kobold Digger: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48229 AND `item` = 63349 AND `lootmode` = ''; -- Kobold Digger: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48230 AND `item` = 58269 AND `lootmode` = ''; -- Ogre Henchman: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48230 AND `item` = 63300 AND `lootmode` = ''; -- Ogre Henchman: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48230 AND `item` = 63348 AND `lootmode` = ''; -- Ogre Henchman: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48230 AND `item` = 63349 AND `lootmode` = ''; -- Ogre Henchman: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48262 AND `item` = 58269 AND `lootmode` = ''; -- Ogre Bodyguard: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48262 AND `item` = 63348 AND `lootmode` = ''; -- Ogre Bodyguard: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48262 AND `item` = 63349 AND `lootmode` = ''; -- Ogre Bodyguard: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48278 AND `item` = 63348 AND `lootmode` = ''; -- Mining Monkey: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48278 AND `item` = 63349 AND `lootmode` = ''; -- Mining Monkey: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48279 AND `item` = 58269 AND `lootmode` = ''; -- Goblin Overseer: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48279 AND `item` = 63300 AND `lootmode` = ''; -- Goblin Overseer: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48279 AND `item` = 63348 AND `lootmode` = ''; -- Goblin Overseer: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48279 AND `item` = 63349 AND `lootmode` = ''; -- Goblin Overseer: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48417 AND `item` = 58259 AND `lootmode` = ''; -- Defias Blood Wizard: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48417 AND `item` = 58261 AND `lootmode` = ''; -- Defias Blood Wizard: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48417 AND `item` = 63271 AND `lootmode` = ''; -- Defias Blood Wizard: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48417 AND `item` = 63300 AND `lootmode` = ''; -- Defias Blood Wizard: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48417 AND `item` = 63349 AND `lootmode` = ''; -- Defias Blood Wizard: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48418 AND `item` = 58259 AND `lootmode` = ''; -- Defias Envoker: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48418 AND `item` = 58261 AND `lootmode` = ''; -- Defias Envoker: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48418 AND `item` = 63271 AND `lootmode` = ''; -- Defias Envoker: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48419 AND `item` = 58259 AND `lootmode` = ''; -- Defias Miner: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48419 AND `item` = 58261 AND `lootmode` = ''; -- Defias Miner: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48419 AND `item` = 63271 AND `lootmode` = ''; -- Defias Miner: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48420 AND `item` = 58259 AND `lootmode` = ''; -- Defias Digger: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48420 AND `item` = 58261 AND `lootmode` = ''; -- Defias Digger: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48420 AND `item` = 63271 AND `lootmode` = ''; -- Defias Digger: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48421 AND `item` = 58259 AND `lootmode` = ''; -- Defias Overseer: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48421 AND `item` = 58261 AND `lootmode` = ''; -- Defias Overseer: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48421 AND `item` = 63271 AND `lootmode` = ''; -- Defias Overseer: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48445 AND `item` = 58269 AND `lootmode` = ''; -- Oaf Lackey: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48502 AND `item` = 58259 AND `lootmode` = ''; -- Defias Enforcer: Highland Sheep Cheese
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48502 AND `item` = 58261 AND `lootmode` = ''; -- Defias Enforcer: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48502 AND `item` = 63271 AND `lootmode` = ''; -- Defias Enforcer: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48505 AND `item` = 58261 AND `lootmode` = ''; -- Defias Shadowguard: Buttery Wheat Roll
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48505 AND `item` = 63271 AND `lootmode` = ''; -- Defias Shadowguard: A Steamy Romance Novel: Big Brass Bombs
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48521 AND `item` = 58269 AND `lootmode` = ''; -- Defias Squallshaper: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48521 AND `item` = 63300 AND `lootmode` = ''; -- Defias Squallshaper: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48521 AND `item` = 63348 AND `lootmode` = ''; -- Defias Squallshaper: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48521 AND `item` = 63349 AND `lootmode` = ''; -- Defias Squallshaper: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48522 AND `item` = 58269 AND `lootmode` = ''; -- Defias Pirate: Massive Turkey Leg
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48522 AND `item` = 63300 AND `lootmode` = ''; -- Defias Pirate: Rogue's Draught
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48522 AND `item` = 63348 AND `lootmode` = ''; -- Defias Pirate: Goblin Gentleman's Magazine
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 48522 AND `item` = 63349 AND `lootmode` = ''; -- Defias Pirate: Flame-Scarred Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58555 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Fanatic: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58555 AND `item` = 88154 AND `lootmode` = ''; -- Scarlet Fanatic: Vial of Diluted Herbal Remedy
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58555 AND `item` = 88158 AND `lootmode` = ''; -- Scarlet Fanatic: Jade Infinity Charm
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58555 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Fanatic: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58632 AND `item` = 88165 AND `lootmode` = ''; -- Armsmaster Harlan: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Myrmidon: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 88158 AND `lootmode` = ''; -- Scarlet Myrmidon: Jade Infinity Charm
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Myrmidon: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58685 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Evangelist: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58685 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Evangelist: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58756 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Evoker: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 87530 AND `lootmode` = ''; -- Scholomance Acolyte: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 88165 AND `lootmode` = ''; -- Scholomance Acolyte: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58823 AND `item` = 87530 AND `lootmode` = ''; -- Scholomance Neophyte: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59193 AND `item` = 87530 AND `lootmode` = ''; -- Boneweaver: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59240 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Hall Guardian: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59240 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Hall Guardian: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59241 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Treasurer: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59241 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Treasurer: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59303 AND `item` = 87530 AND `lootmode` = ''; -- Houndmaster Braun: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59368 AND `item` = 87530 AND `lootmode` = ''; -- Krastinovian Carver: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59368 AND `item` = 88165 AND `lootmode` = ''; -- Krastinovian Carver: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59372 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Scholar: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59372 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Scholar: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 87530 AND `lootmode` = ''; -- Scarlet Pupil: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 88154 AND `lootmode` = ''; -- Scarlet Pupil: Vial of Diluted Herbal Remedy
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 88165 AND `lootmode` = ''; -- Scarlet Pupil: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 87530 AND `lootmode` = ''; -- Bored Student: A Steamy Romance Novel: Hot and Misty
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 88154 AND `lootmode` = ''; -- Bored Student: Vial of Diluted Herbal Remedy
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 88165 AND `lootmode` = ''; -- Bored Student: Vine-Cracked Junkbox
UPDATE `pickpocketing_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 60040 AND `item` = 87530 AND `lootmode` = ''; -- Commander Durand: A Steamy Romance Novel: Hot and Misty

-- 3) Corpse loot: heroic-level items tagged for every difficulty or for normal
DELETE FROM `creature_loot_template` WHERE `entry` = 3870 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Stone Sleeper: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 3873 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Tormented Officer: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 3875 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Haunted Servitor: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 3877 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Wailing Guardsman: Fungus Squeezings (heroic row already exists)
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 4278 AND `item` = 71715 AND `lootmode` = 'DUNGEON_NORMAL'; -- Commander Springvale: A Treatise on Strategy
DELETE FROM `creature_loot_template` WHERE `entry` = 47131 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Frantic Geist: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47132 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Dark Creeper: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47134 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Corpse Eater: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47135 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Fetid Ghoul: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47136 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Unstable Ravager: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47137 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Mindless Horror: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47138 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Pustulant Monstrosity: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47140 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Sorcerous Skeleton: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47141 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Dread Scryer: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47143 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Spitebone Skeleton: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47145 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Spitebone Guardian: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47146 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Spitebone Flayer: Fungus Squeezings (heroic row already exists)
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 47231 AND `item` = 14048 AND `lootmode` = 'DUNGEON_NORMAL'; -- Shadowy Attendant: Bolt of Runecloth
DELETE FROM `creature_loot_template` WHERE `entry` = 47231 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Shadowy Attendant: Fungus Squeezings (heroic row already exists)
DELETE FROM `creature_loot_template` WHERE `entry` = 47232 AND `item` = 59230 AND `lootmode` = 'DUNGEON_NORMAL'; -- Ghostly Cook: Fungus Squeezings (heroic row already exists)
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58569 AND `item` = 104221 AND `lootmode` = ''; -- Scarlet Purifier: Technique: Glyph of Sprouting Mushroom
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58674 AND `item` = 81194 AND `lootmode` = ''; -- Angry Hound: Sharp Fangs
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58676 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Defender: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58676 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Defender: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Myrmidon: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Myrmidon: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58683 AND `item` = 104212 AND `lootmode` = ''; -- Scarlet Myrmidon: Technique: Glyph of Divine Shield
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58684 AND `item` = 81406 AND `lootmode` = ''; -- Scarlet Scourge Hewer: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58684 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Scourge Hewer: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58684 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Scourge Hewer: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58684 AND `item` = 104212 AND `lootmode` = ''; -- Scarlet Scourge Hewer: Technique: Glyph of Divine Shield
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58685 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Evangelist: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58685 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Evangelist: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58756 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Evoker: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58756 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Evoker: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 16255 AND `lootmode` = ''; -- Scholomance Acolyte: Formula: Enchant 2H Weapon - Major Spirit
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 81406 AND `lootmode` = ''; -- Scholomance Acolyte: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 95470 AND `lootmode` = ''; -- Scholomance Acolyte: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58757 AND `item` = 95471 AND `lootmode` = ''; -- Scholomance Acolyte: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58822 AND `item` = 82283 AND `lootmode` = ''; -- Risen Guard: Immaculate Ring
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58822 AND `item` = 88567 AND `lootmode` = ''; -- Risen Guard: Ghost Iron Lockbox
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58823 AND `item` = 95470 AND `lootmode` = ''; -- Scholomance Neophyte: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58823 AND `item` = 95471 AND `lootmode` = ''; -- Scholomance Neophyte: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58876 AND `item` = 81194 AND `lootmode` = ''; -- Starving Hound: Sharp Fangs
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58898 AND `item` = 95470 AND `lootmode` = ''; -- Vigilant Watchman: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58898 AND `item` = 95471 AND `lootmode` = ''; -- Vigilant Watchman: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 58898 AND `item` = 104212 AND `lootmode` = ''; -- Vigilant Watchman: Technique: Glyph of Divine Shield
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59175 AND `item` = 81406 AND `lootmode` = ''; -- Master Archer: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59175 AND `item` = 95470 AND `lootmode` = ''; -- Master Archer: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59175 AND `item` = 95471 AND `lootmode` = ''; -- Master Archer: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59193 AND `item` = 95470 AND `lootmode` = ''; -- Boneweaver: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59193 AND `item` = 95471 AND `lootmode` = ''; -- Boneweaver: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59240 AND `item` = 81406 AND `lootmode` = ''; -- Scarlet Hall Guardian: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59240 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Hall Guardian: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59240 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Hall Guardian: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59241 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Treasurer: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59241 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Treasurer: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59359 AND `item` = 82250 AND `lootmode` = ''; -- Flesh Horror: Waterfall Cowl
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59359 AND `item` = 82251 AND `lootmode` = ''; -- Flesh Horror: Waterfall Handwraps
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59359 AND `item` = 82283 AND `lootmode` = ''; -- Flesh Horror: Immaculate Ring
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59359 AND `item` = 88567 AND `lootmode` = ''; -- Flesh Horror: Ghost Iron Lockbox
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59368 AND `item` = 81406 AND `lootmode` = ''; -- Krastinovian Carver: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59368 AND `item` = 95470 AND `lootmode` = ''; -- Krastinovian Carver: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59368 AND `item` = 95471 AND `lootmode` = ''; -- Krastinovian Carver: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59372 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Scholar: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59372 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Scholar: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 95470 AND `lootmode` = ''; -- Scarlet Pupil: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 95471 AND `lootmode` = ''; -- Scarlet Pupil: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59373 AND `item` = 104212 AND `lootmode` = ''; -- Scarlet Pupil: Technique: Glyph of Divine Shield
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59467 AND `item` = 81406 AND `lootmode` = ''; -- Candlestick Mage: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59467 AND `item` = 95470 AND `lootmode` = ''; -- Candlestick Mage: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59467 AND `item` = 95471 AND `lootmode` = ''; -- Candlestick Mage: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59467 AND `item` = 104212 AND `lootmode` = ''; -- Candlestick Mage: Technique: Glyph of Divine Shield
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59501 AND `item` = 88567 AND `lootmode` = ''; -- Reanimated Corpse: Ghost Iron Lockbox
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 81406 AND `lootmode` = ''; -- Bored Student: Roasted Barley Tea
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 95470 AND `lootmode` = ''; -- Bored Student: Design: Serpent's Heart
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 95471 AND `lootmode` = ''; -- Bored Student: Design: Primal Diamond
UPDATE `creature_loot_template` SET `lootmode` = 'DUNGEON_HEROIC' WHERE `entry` = 59614 AND `item` = 104212 AND `lootmode` = ''; -- Bored Student: Technique: Glyph of Divine Shield
