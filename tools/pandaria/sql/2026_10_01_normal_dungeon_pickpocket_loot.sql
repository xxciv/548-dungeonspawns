-- Normal-mode pickpocket (and corpse) loot for the revamped dungeons: Deadmines, Shadowfang Keep,
-- Scarlet Halls, Scarlet Monastery, Scholomance.
--
-- Why: these dungeons use ONE creature entry for normal and heroic (levels/stats per difficulty come from
-- `creature_difficulty`). The pickpocket tables were captured in heroic and every row is tagged '' (all
-- difficulties), so a level 14 Kobold Digger gives a Rogue's Draught (req. 80) and a Flame-Scarred
-- Junkbox (Lockpicking 400).
--
-- REQUIRES tools/pandaria/pickpocket-difficulty.patch. The stock core rolls pickpocket loot without the
-- dungeon difficulty, so rows tagged DUNGEON_NORMAL or DUNGEON_HEROIC would never drop.
--
-- What this does (generated from world_04_03_2023 + updates):
--   1) Pickpocket: items far above the normal level (required level > level+5, item level > level+15,
--      or grey junk selling for 5s+) are re-tagged DUNGEON_HEROIC. Heroic keeps them.
--   2) Pickpocket: where the heroic junkbox was the creature's only junkbox, adds a normal-mode one:
--      level <= 24 Battered Junkbox 22%, 25-38 Worn Junkbox 18%, 39-48 Sturdy Junkbox 12%
--      (the median chance each has on open-world mobs of those levels).
--   3) Corpse loot: the same kind of heroic-level items tagged '' or DUNGEON_NORMAL are re-tagged
--      DUNGEON_HEROIC, or deleted where a DUNGEON_HEROIC copy of the row already exists.
-- Gold is not touched.
--
-- Back up first:
--   mysqldump -u root -p world pickpocketing_loot_template creature_loot_template > pickpocket_backup.sql
-- Revert: 2026_10_01_normal_dungeon_pickpocket_loot_revert.sql
-- Pick up: build with the patch, run this on the world DB, restart worldserver.

-- 1) Pickpocket: heroic-level items (level 80-90 junkboxes, potions, food, pricey grey junk) only in heroic
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

-- 2) Pickpocket: a level-appropriate junkbox for normal mode where the heroic one was the only junkbox.
--    Chance = the median chance the same junkbox has on open-world mobs of that level range.
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47131, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Frantic Geist (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47132, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Dark Creeper (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47134, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Corpse Eater (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47135, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Fetid Ghoul (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47136, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Unstable Ravager (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47137, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Mindless Horror (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47138, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Pustulant Monstrosity (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47140, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Sorcerous Skeleton (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47141, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Dread Scryer (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47143, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Spitebone Skeleton (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47145, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Spitebone Guardian (lvl 19): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (47146, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Spitebone Flayer (lvl 20): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48229, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Kobold Digger (lvl 14): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48230, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Ogre Henchman (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48262, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Ogre Bodyguard (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48278, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Mining Monkey (lvl 14): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48279, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Goblin Overseer (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48417, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Defias Blood Wizard (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48521, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Defias Squallshaper (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (48522, 16882, 22, 'DUNGEON_NORMAL', 0, 1, 1); -- Defias Pirate (lvl 15): Battered Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (58555, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Scarlet Fanatic (lvl 32): Worn Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (58632, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Armsmaster Harlan (lvl 31): Worn Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (58683, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Scarlet Myrmidon (lvl 29): Worn Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (58685, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Scarlet Evangelist (lvl 29): Worn Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (58757, 16884, 12, 'DUNGEON_NORMAL', 0, 1, 1); -- Scholomance Acolyte (lvl 41): Sturdy Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (59240, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Scarlet Hall Guardian (lvl 29): Worn Junkbox
INSERT INTO `pickpocketing_loot_template` (`entry`, `item`, `ChanceOrQuestChance`, `lootmode`, `groupid`, `mincountOrRef`, `maxcount`) VALUES (59241, 16883, 18, 'DUNGEON_NORMAL', 0, 1, 1); -- Scarlet Treasurer (lvl 29): Worn Junkbox

-- 3) Corpse loot: heroic-level items that were tagged for every difficulty or for normal
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
