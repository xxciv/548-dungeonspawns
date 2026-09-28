-- Deadmines (normal): soften Helix Gearbreaker's melee for solo play.
-- Stock: 5-7 weapon damage x 57.5 multiplier on a 0.5 s swing (~700 DPS before Solocraft).
-- New:   multiplier 20 (~35% of stock, ~245 DPS; ~75 DPS with SoloCraft.DamageTaken.Pct = 30).
-- Only entry 47296 (the scripted normal-mode boss). Heroic uses creature_difficulty and is untouched.
--
-- Back up first:
--   mysqldump -u root -p world creature_template --where="entry=47296" > helix_backup.sql
-- Revert:
--   UPDATE creature_template SET dmg_multiplier = 57.5 WHERE entry = 47296;

UPDATE `creature_template` SET `dmg_multiplier` = 20 WHERE `entry` = 47296;
