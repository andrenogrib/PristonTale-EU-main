# Server Commands Reference

Atualizado em: 2026-03-15

Esta doc mapeia os comandos definidos em `Server/server/servercommand.cpp` e `Server/server/servercommand.h`.
O foco aqui e facilitar tres coisas:

- saber qual comando existe e em qual nivel de GM ele entra
- descobrir rapidamente onde mexer em item, drop, EXP, monstro e manutencao
- achar o ponto de source certo quando voce precisar aprofundar

## Fonte de verdade

- Chat commands: `Server/server/servercommand.cpp`
- Comandos internos em fila SQL: `Server/server/servercommand.h`
- Niveis de GM: `shared/user.h`
- Ativacao e despacho dos comandos: `Server/server/servercommand.cpp`

Os handlers ficam organizados assim:

- `OnGameMasterAdminCommand`: bloco Admin / GM4
- `OnGameMasterLevel1Command`: GM1
- `OnGameMasterLevel2Command`: GM2
- `OnGameMasterLevel3Command`: GM3
- `OnPlayerCommand`: comandos de player
- `OnGameMasterCommand`: dispatcher geral

## Como ativar os comandos

No ambiente local que montamos, a conta `admin` esta configurada com `GameMasterType=1` e `GameMasterLevel=4`.

Fluxo normal:

1. abra o jogo
2. logue com `admin` / `admin`
3. escolha o personagem `Administrador`
4. rode `/activategm`

Para sair do modo GM:

- `/deactivategm`

## Hierarquia de GM

Os niveis estao em `shared/user.h`:

- `GAMELEVEL_None = 0`
- `GAMELEVEL_One = 1`
- `GAMELEVEL_Two = 2`
- `GAMELEVEL_Three = 3`
- `GAMELEVEL_Four = 4`

O dispatcher aplica a heranca assim:

- GM4 herda GM1 + GM2 + GM3 + Admin
- GM3 herda GM1 + GM2 + GM3
- GM2 herda GM1 + GM2
- GM1 herda GM1

## Comandos mais usados no dia a dia

### Item, gold e inventario

- `/getitem <itemCode> [classShort] [specAtk 1-3] [age 1-20] [rarity 0-5] [perfect 1]`
  - cria o item direto no inventario do GM
- `/getitemold <...>`
  - igual ao anterior, mas busca definicao em `ItemListOld`
- `/giveitem <loginDaConta> <itemCode>`
  - envia o item para o Item Distributor da conta
  - apesar da mensagem antiga falar `account id`, o codigo usa o login da conta
- `/getitemperf <itemCode> <spec>`
  - cria item perfeito
- `/getitemspec <itemCode> <spec> <lvatk>`
  - cria item com spec custom
- `/GetGold <valor>`
  - adiciona gold ao personagem atual
- `/getmpg`, `/gethpg`, `/getspg`, `/getmp`, `/gethp`, `/getsp`
  - geram potions

### EXP, level e taxa do servidor

- `/!giveexp <valor>`
  - adiciona EXP bruta ao personagem atual
- `/!levelup <level>`
  - sobe para o EXP daquele level
- `/expevent <0-1000>`
  - altera o bonus global de EXP em porcentagem
- `/extradrop <qtd>`
  - aumenta a quantidade extra de drops por monstro
- `/BONUSALL`
  - aplica buffs premium em todos os players, incluindo EXP buff e Drop buff

### Mapa, teleport e GM tools

- `/wrap <mapId> <x> <z>`
- `/near <char>`
- `/call <char>`
- `/mapusers`
- `/mapchars`
- `/hide`
- `/show`

### Manutencao e moderacao

- `/!mute <char> "<reason>"`
- `/!unmute <char>`
- `/kickch <char>` ou `/!kickch <char>`
- `/banacc <char> <reason>`
- `/unbanacc <account>`
- `/StartMaintenance`
- `/StopMaintenance`

## Comandos internos em fila SQL

Esses nao sao chat commands. Eles aparecem no enum `ESQLServerCommand` em `Server/server/servercommand.h` e representam operacoes internas lidas do banco:

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

## Indice completo por escopo

O objetivo desta secao e ser o catalogo rapido. Para sintaxe detalhada, sempre confira o bloco do comando em `Server/server/servercommand.cpp`.

### GM4 Admin

#### Admin, utilitarios e debug

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

#### Item, potion, item distributor e temp item

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

#### EXP, drop, PVP e eventos globais

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

#### SoD, Bellatra, Bless Castle e arenas

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

#### Mundo, teleport, NPC, monstro vivo e manutencao

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

#### SQL live edit de monstro

Esses comandos consultam ou alteram um monstro ja spawnado e persistem a alteracao no banco:

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

#### Bots, sockets e rede

- `/BotCreate`
- `/BotDelete`
- `/BotLHand`
- `/BotRHand`
- `/BotBHand`
- `/BotSay`
- `/ServerCrash`, `/!ServerCrash`
- `/NetServerDC`, `/!NetServerDC`

#### Social e observacao

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

Notas:

- `/mute` e `/unmute` servem so para redirecionar o operador ao formato `!/login-server`
- o mute real entra via login server

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

Nota:

- `/field` aparece no source, mas o bloco esta comentado. Trate como comando desativado na build atual.

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

## Onde procurar a sintaxe exata

Receita pratica:

1. procure o comando em `Server/server/servercommand.cpp`
2. abra o bloco do `if ( COMMAND("...", pszBuff) )`
3. leia os `GetParameterString(...)`
4. veja se o comando:
   - roda no game server
   - roda no login server
   - redireciona via `NETSERVER->SendGMCommandToLoginServer(...)`

Comandos uteis para procurar no repo:

```powershell
rg -n 'COMMAND\\(' Server/server/servercommand.cpp
rg -n '/getitem|/giveitem|/expevent|/extradrop' Server/server/servercommand.cpp
rg -n 'OnGameMasterAdminCommand|OnGameMasterLevel1Command|OnGameMasterLevel2Command|OnGameMasterLevel3Command' Server/server/servercommand.cpp
```

## Observacoes importantes

- O macro `COMMAND` usa `StrCmpPT`, entao o source e a referencia final para o nome exato aceito.
- Alguns comandos existem em alias de caixa alta/baixa.
- Alguns comandos mexem em monstro spawnado no mapa, nao no cadastro base por nome.
- Alguns comandos foram feitos para dev/teste e podem ser perigosos em servidor aberto.
- Para item e drop, a outra doc util e `docs/reference/item-code-and-data-reference.md`.
