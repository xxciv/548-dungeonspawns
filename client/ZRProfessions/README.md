# ZRProfessions (client addon)

Lets characters learn up to 4 primary professions on a 5.4.8 client, and lists all of them with `/profs`.

## Why an addon is needed

The server already supports more than 2: `MaxPrimaryTradeSkill` in `worldserver.conf` sets how many
"free profession points" a character gets at login, and trainers check those points. The 5.4.8 client has
its own check in `Blizzard_TrainerUI.lua`: if the second Professions-tab slot is filled, it greys out
**Train** for any new profession, whatever the server says. The Professions tab also only has 2 primary slots,
because the client only stores 2 profession skill lines, so a 3rd and 4th profession never appear there.

This addon:
- Re-enables **Train** for a new primary profession while you know fewer than 4. The server still checks
  `MaxPrimaryTradeSkill` when you buy, so it remains the real limit.
- Fixes the "learn this profession?" popup, which has no text for when you already know 2.
- Adds a **Primary Professions** panel (`/profs`, `/zrprofs`, or the **All professions** button under the
  Professions tab) listing every primary profession with its rank. Click a crafting profession to open it
  (Mining opens Smelting). Herbalism and Skinning have no window; they work on nodes and corpses as normal.

## Install

1. Server: `MaxPrimaryTradeSkill = 4` in `worldserver.conf`, then restart `worldserver` (or `.reload config`).
   Existing characters pick it up at their next login.
2. Each player: copy this `ZRProfessions` folder to `World of Warcraft/Interface/AddOns/`, so the files are
   at `Interface/AddOns/ZRProfessions/ZRProfessions.toc` and `ZRProfessions.lua`.
3. At character select, open **AddOns** and make sure ZRProfessions is ticked (tick "Load out of date AddOns"
   if it shows as out of date).

If the server limit is not 4, change `MAX_PRIMARY_PROFESSIONS` at the top of `ZRProfessions.lua` to match.

## Good to know

- A 3rd or 4th profession is not shown on the Professions tab. Use the panel, or a macro such as
  `/cast Alchemy`. Find Herbs / Find Minerals are in the minimap tracking menu as usual.
- If you unlearn one of the 2 professions shown on the tab, a hidden one moves onto the tab after you relog.
- The panel closes when you enter combat and can't be opened during it (its buttons cast spells, which the
  client locks in combat).
