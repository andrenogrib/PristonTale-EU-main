# Server Commands Reference

Updated on: 2026-03-15

This document maps the commands defined in `Server/server/servercommand.cpp` and `Server/server/servercommand.h`.
Its goal is to make three things easier:

- identify which command exists and which GM level can use it
- find the fastest way to adjust items, drop data, EXP, monsters, and maintenance behavior
- jump to the correct source location when you need to investigate further

If you want the most practical in-game usage guide first, read:

- `docs/guides/gm-handbook.md`
- `docs/guides/events-and-rates-guide.md`
- `docs/guides/account-and-character-management.md`

If you need `mapId`, `itemCode`, or `MonsterID` values to use with those commands, check:

- `docs/reference/map-id-reference.md`
- `docs/reference/item-id-reference.md`
- `docs/reference/monster-id-reference.md`

## Source Of Truth

- Chat commands: `Server/server/servercommand.cpp`
- Internal SQL queue commands: `Server/server/servercommand.h`
- GM levels: `shared/user.h`
- Command activation and dispatch: `Server/server/servercommand.cpp`

The handlers are organized like this:

- `OnGameMasterAdminCommand`: Admin / GM4 block
- `OnGameMasterLevel1Command`: GM1
- `OnGameMasterLevel2Command`: GM2
- `OnGameMasterLevel3Command`: GM3
- `OnPlayerCommand`: player commands
- `OnGameMasterCommand`: global dispatcher

## How To Activate Commands

In the local environment documented in this repository, the `admin` account is configured with `GameMasterType=1` and `GameMasterLevel=4`.

Normal flow:

1. open the game
2. log in with `admin` / `admin`
3. select the `Administrador` character
4. run `/activategm`

To leave GM mode:

- `/deactivategm`

## GM Hierarchy

The levels are defined in `shared/user.h`:

- `GAMELEVEL_None = 0`
- `GAMELEVEL_One = 1`
- `GAMELEVEL_Two = 2`
- `GAMELEVEL_Three = 3`
- `GAMELEVEL_Four = 4`

The dispatcher applies inheritance like this:

- GM4 inherits GM1 + GM2 + GM3 + Admin
- GM3 inherits GM1 + GM2 + GM3
- GM2 inherits GM1 + GM2
- GM1 inherits GM1

## Most Common Day-To-Day Commands

### Item, Gold, And Inventory

- `/getitem <itemCode> [classShort] [specAtk 1-3] [age 1-20] [rarity 0-5] [perfect 1]`
  - creates the item directly in the GM inventory
- `/getitemold <...>`
  - same idea, but resolves through `ItemListOld`
- `/giveitem <accountLogin> <itemCode>`
  - sends the item to the account item distributor
  - even though the old message says `account id`, the code uses the account login
- `/getitemperf <itemCode> <spec>`
  - creates a perfect item
- `/getitemspec <itemCode> <spec> <lvatk>`
  - creates an item with custom spec values
- `/GetGold <valor>`
  - adds gold to the current character
- `/getmpg`, `/gethpg`, `/getspg`, `/getmp`, `/gethp`, `/getsp`
  - generate potion items

### EXP, Level, And Server-Wide Rates

- `/!giveexp <valor>`
  - adds raw EXP to the current character
- `/!levelup <level>`
  - raises the character to the EXP value for that level
- `/expevent <0-1000>`
  - changes the global EXP bonus percentage
- `/extradrop <qtd>`
  - increases the extra drop count per monster
- `/BONUSALL`
  - applies premium-style buffs to all online players, including EXP and drop buffs

### Map, Teleport, And GM Tools

- `/wrap <mapId> <x> <z>`
- `/near <char>`
- `/call <char>`
- `/mapusers`
- `/mapchars`
- `/hide`
- `/show`

### Maintenance And Moderation

- `/!mute <char> "<reason>"`
- `/!unmute <char>`
- `/kickch <char>` ou `/!kickch <char>`
- `/banacc <char> <reason>`
- `/unbanacc <account>`
- `/StartMaintenance`
- `/StopMaintenance`

## Internal SQL Queue Commands

These are not chat commands. They appear in the `ESQLServerCommand` enum in `Server/server/servercommand.h` and represent internal operations consumed from the database:

- `10`: `SQLSERVERCOMMAND_ChangeCharacterName`
- `11`: `SQLSERVERCOMMAND_ChangeCharacterLevel`
- `12`: `SQLSERVERCOMMAND_ChangeCharacterAccount`
- `13`: `SQLSERVERCOMMAND_ChangeCharacterClass`
- `20`: `SQLSERVERCOMMAND_ChangeAccountName`
- `30`: `SQLSERVERCOMMAND_KickAccountName`
- `31`: `SQLSERVERCOMMAND_KickCharacterName`
- `101`: `SQLSERVERCOMMAND_LoadCoinShop`
- `111`: `SQLSERVERCOMMAND_LoadCheatList`
- `121`: `SQLSERVERCOMMAND_LoadMixFormula`

## Full Index By Scope

The goal of this section is to be the fast command catalog. For exact syntax, always inspect the corresponding block in `Server/server/servercommand.cpp`.

### GM4 Admin

#### Admin, Utilities, And Debug

- `/!unmute_and_reset`
- `/rarity_update`, `/Rarity_Update`
- `/specmod_update`, `/SpecMod_Update`
- `/baseline_update`, `/Baseline_Update`
- `/rarity_mod_update`, `/Rarity_Mod_Update`
- `/rarity_get`, `/Rarity_Get`
- `/rarity_set`, `/Rarity_Set`
- `/affix_update`, `/Affix_Update`
- `/quest_npc_reload`
- `/force_night_mode`
- `/force_day_mode`
- `/testmap_hp`
- `/testmap_mon`
- `/testmap_dps`
- `/testmap_reset`
- `/skills_update_everyone`
- `/viewsocket`, `/!viewsocket`
- `/SetToggleSocketFull`, `/!SetToggleSocketFull`
- `/SetUsersOnlineMax`
- `/LeakMonsterTest`
- `/GetTickCount`
- `/!DanceAll`
- `/TestItem`
- `/!EditItemTest`
- `/testmsgbox`
- `/test_roll_bosskill_item`
- `/test_command_polling`
- `/test_user_ranking`
- `/serverfps`
- `/SQLSkill`
- `/SQLCALCMON`
- `/debug`
- `/disable_errors_relay`
- `/print_clan_id`
- `/SetPacketUnit`
- `/SetMaskUnit`
- `/SetFrameCounterUnit`
- `/!HWCombination`

#### Item, Potion, Distributor, And Temp Item

- `/giveitem`
- `/getquestitem`
- `/getitem`
- `/getitemold`
- `/getmpg`
- `/gethpg`
- `/getspg`
- `/getmp`
- `/gethp`
- `/getsp`
- `/GetGold`
- `/tempitemget`
- `/tempitemset`
- `/tempitem_dmg`
- `/tempitem_age`
- `/tempitem_name`
- `/tempitem_atkspeed`
- `/tempitem_socket`
- `/tempitem_crit`
- `/tempitem_mixflag`
- `/tempitem_atkrtg`
- `/tempitem_def`
- `/tempitem_block`
- `/tempitem_abs`
- `/tempitem_changespec`
- `/tempitem_strength`
- `/tempitem_level`
- `/tempitem_spirit`
- `/tempitem_talent`
- `/tempitem_agility`
- `/tempitem_health`
- `/tempitem_specdef`
- `/tempitem_specblock`
- `/tempitem_specabs`
- `/tempitem_spechpregen`
- `/tempitem_specmovspeed`
- `/tempitem_specmpregen`
- `/tempitem_specspregen`
- `/tempitem_speccritical`
- `/tempitem_specdivatkpow`
- `/tempitem_specdivatkpowmin`
- `/tempitem_specdivatkrtg`
- `/tempitem_specatkspeed`
- `/tempitem_specatkrange`
- `/tempitem_specaddhpdiv`
- `/tempitem_specaddmpdiv`
- `/tempitem_addhp`
- `/tempitem_addmp`
- `/tempitem_addsp`
- `/tempitem_hpregen`
- `/tempitem_mpregen`
- `/tempitem_spregen`
- `/getitemspec`
- `/ItemSemiPerf`
- `/getitemperf`

#### EXP, Drop, PvP, And Global Events

- `/!giveexp`
- `/!levelup`
- `/extradrop`
- `/expevent`
- `/PVPMap`
- `/pvp`, `/PVP`, `/PvP`
- `/event_agingfree`
- `/event_agingnobreak`
- `/event_aginghalfprice`
- `/event_girl`
- `/event_Halloween`
- `/event_MimicReload`
- `/event_Mimic`
- `/event_Christmas`
- `/event_Easter`
- `/event_StarWars`
- `/event_Bee`
- `/event_Valentine`
- `/event_HuntMinSpawnDist`
- `/event_WantedMoriph`
- `/event_WantedWolf`
- `/event_reducemondmg`
- `/event_crystal`
- `/!tradechat_free`

#### SoD, Bellatra, Bless Castle, And Arenas

- `/SetOwnerBC`
- `/ClearOwnerBC`
- `/EventBC`
- `/StartSiegeWar`
- `/EndSiegeWar`
- `/EndWinSiegeWar`
- `/EasySiegeWar`
- `/ClearTickRO`
- `/ClearTickChristmas`
- `/sod_room_score_scale`
- `/sod_performance_gold_scale`
- `/sod_update_all_solo_ranking`
- `/sod_update_class_solo_ranking`
- `/sod_crown_humor`
- `/sod_skipround`
- `/sod_force_start`
- `/sod_force_end`
- `/sod_force_reset_scores`
- `/sod_scores_reset_disallowed`
- `/sod_scores_reset_allowed`
- `/sod_test_drops`
- `/sod_reload_rewards_from_sql`
- `/sod_status`
- `/sod_enable`
- `/sod_update_crowns`
- `/FuryArena_EnableEvent`
- `/FuryArena_ClearRewardTracker`
- `/FuryArena_ForceStartTestMode`
- `/FuryArena_ForceStart`
- `/FuryArena_End`
- `/gf_call`
- `/gf_time`
- `/gf_gettick`
- `/gf_getstone`
- `/gf_timeminion`
- `/gf_boss`
- `/gf_minion`
- `/gf_monevent`
- `/gf_kick`

#### World, Teleport, NPC, Live Monster, And Maintenance

- `/add_map_indicator_script`
- `/remove_map_indicator`
- `/remove_map_icon`
- `/UpdateQuestActiveEvent`
- `/MonAnim`
- `/WarpAll`
- `/WarpGarden`
- `/WarpEvent`
- `/QuestArenaT5`
- `/QuestT5Cry`
- `/QuestT5TestID`
- `/!QuestT5TestID`
- `/shutdowncancel`
- `/set_spawn`
- `/setversion`
- `/GetBossCrystal`
- `/ReloadCoinShop`
- `/recoveritem`
- `/ReloadMonsterDropTable`
- `/ReloadItemDef`
- `/TestMonsterDropTable`
- `/setbosstime`
- `/spawnbosses`
- `/shiftgametime`
- `/remove_npc`
- `/add_npc`
- `/set_pos`
- `/set_ang`
- `/test_gold_drop`
- `/test_MovetoMe`
- `/killmon`
- `/set_hp`
- `/set_abs`
- `/set_dmg`
- `/killch`, `/!killch`
- `/!ResetPVPRank`
- `/set_def`
- `/set_lvl`
- `/petwh`
- `/Summon_pet`
- `/TestCrash`
- `/!getfield`
- `/Meteor`
- `/kickall`
- `/StartMaintenance`
- `/StopMaintenance`
- `/KillUnitsMap`

#### Live Monster SQL Editing

These commands read or change a monster that is already spawned and persist the change back to the database:

- `/sql_HP`
- `/sql_Size`
- `/sql_Type`
- `/sql_EXP`
- `/sql_Absorb`
- `/sql_Block`
- `/sql_StunChance`
- `/sql_Defense`
- `/sql_Potion`
- `/sql_Organic`
- `/sql_Lightning`
- `/sql_Ice`
- `/sql_Fire`
- `/sql_Poison`
- `/sql_Magic`
- `/sql_NumDrops`
- `/sql_PublicDrop`
- `/sql_SpawnMin`
- `/sql_SpawnMax`
- `/sql_MoveSpeed`
- `/sql_ViewSight`
- `/sql_AttackMinMax`
- `/sql_AttackSpeed`
- `/sql_AttackRange`
- `/sql_AttackRating`
- `/sql_PerfectAttackRate`
- `/sql_SkillMinMax`
- `/sql_SkillType`
- `/sql_SkillChance`
- `/sql_SkillHitRange`
- `/sql_SkillHitBoxLeft`
- `/sql_SkillHitBoxRight`
- `/sql_SkillHitBoxTop`
- `/sql_SkillHitBoxBottom`
- `/sql_Glow`
- `/sql_SkillArea`
- `/sql_Level`

#### Bots, Sockets, And Network

- `/BotCreate`
- `/BotDelete`
- `/BotLHand`
- `/BotRHand`
- `/BotBHand`
- `/BotSay`
- `/ServerCrash`, `/!ServerCrash`
- `/NetServerDC`, `/!NetServerDC`

#### Social And Observation

- `/spymember`
- `/notspymember`
- `/!wholoves`
- `/getclan`

### GM1

- `/event_treasurehunting`
- `/mute`
- `/unmute`
- `/!mute`
- `/!unmute`

Notes:

- `/mute` and `/unmute` only redirect the operator to the `!/login-server` format
- the actual mute handling is performed through the login server

### GM2

- `/exprate`
- `/BONUSALL`
- `/fieldlist1`
- `/fieldlist2`
- `/field`
- `/wrap`
- `/get_party_view`
- `/near`
- `/mapusers`
- `/mapchars`
- `/kickch`, `/!kickch`
- `/grant_title`

Note:

- `/field` appears in the source, but the block is commented out. Treat it as disabled in the current build.

### GM3

- `/call`
- `/hide`
- `/show`
- `/banacc`
- `/unbanacc`

### Player

- `/request_party`, `/party`, `//party`, `//PARTY`
- `/request_raid`, `/raid`, `//raid`, `//RAID`
- `/titles`
- `/title_clear`
- `/title_set`
- `/solo`
- `/leave_party`
- `/lot`, `/lottery`
- `/kick_party`
- `/CLAN>`
- `/TRADE>`

### Dispatcher

- `/activategm`
- `/deactivategm`

## Where To Find The Exact Syntax

Practical recipe:

1. search for the command in `Server/server/servercommand.cpp`
2. open the corresponding `if ( COMMAND("...", pszBuff) )` block
3. read the `GetParameterString(...)` calls
4. verify whether the command:
   - runs on the game server
   - runs on the login server
   - redirects through `NETSERVER->SendGMCommandToLoginServer(...)`

Useful searches:

```powershell
rg -n 'COMMAND\\(' Server/server/servercommand.cpp
rg -n '/getitem|/giveitem|/expevent|/extradrop' Server/server/servercommand.cpp
rg -n 'OnGameMasterAdminCommand|OnGameMasterLevel1Command|OnGameMasterLevel2Command|OnGameMasterLevel3Command' Server/server/servercommand.cpp
```

## Important Notes

- The `COMMAND` macro uses `StrCmpPT`, so the source is still the final authority for the exact accepted name.
- Some commands exist in multiple upper/lowercase aliases.
- Some commands operate on a currently spawned monster, not the base monster definition by name.
- Some commands were clearly built for dev/testing and can be dangerous on a public server.
- For item and drop lookup, the companion document is `docs/reference/item-code-and-data-reference.md`.
