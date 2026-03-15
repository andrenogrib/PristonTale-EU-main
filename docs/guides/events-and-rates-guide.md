# Events And Rates Guide

Updated on: 2026-03-15

This guide explains how to manage EXP bonuses, drop bonuses, seasonal events, and maintenance operations.

## Two ways to control rates

In this project, rates can be controlled in two main places:

- fixed startup configuration in `Files/Server/game-server/server.ini`
- live runtime changes through GM commands inside the game

## Rates in `server.ini`

The main rate-related keys currently live under the `[Event]` section.

Examples from the local setup:

- `RateExp=1`
- `EventExp=0`
- `WantedMoriph=Off`
- `WantedWolf=Off`
- `Easter=Off`
- `Xmas=Off`
- `Halloween=Off`
- `ValentineDay=Off`

Practical reading:

- `RateExp=1` is the base EXP rate
- `On` / `Off` values define the startup state
- GM commands can still change runtime state after the server is already online

## Global EXP bonus

Command:

```text
/expevent <0-1000>
```

Examples:

```text
/expevent 0
/expevent 100
/expevent 300
```

Meaning:

- `0` = no extra EXP bonus
- `100` = `+100%`
- `300` = `+300%`

## Extra drop count

Command:

```text
/extradrop <count>
```

Examples:

```text
/extradrop 0
/extradrop 1
/extradrop 2
```

Meaning:

- this changes the extra number of drops generated
- it does not necessarily change the base chance weight in the database tables

## Premium buffs for every online player

Command:

```text
/BONUSALL
```

This applies premium-style buffs to every online player, including:

- HP regen
- MP regen
- SP regen
- damage bonus
- absorb bonus
- movement speed
- EXP buff
- drop buff

## Simple on/off events

Many event commands follow this pattern:

```text
/command true
/command false
```

### Aging-related events

```text
/event_agingfree true
/event_agingnobreak true
/event_aginghalfprice true
```

Meaning:

- `agingfree`: no cost for aging
- `agingnobreak`: no break chance
- `aginghalfprice`: reduced aging cost

### Seasonal and themed events

```text
/event_Halloween true
/event_Christmas true
/event_Easter true
/event_Valentine true
/event_StarWars true
/event_Bee true
/event_Mimic true
/event_girl true
```

To turn them off, replace `true` with `false`.

### Other live toggles

```text
/event_reducemondmg true
/event_crystal true
/event_treasurehunting true
```

## Wanted events

These two commands support more advanced syntax:

- `/event_WantedMoriph`
- `/event_WantedWolf`

Accepted patterns found in the source:

```text
/event_WantedMoriph true
/event_WantedMoriph false
/event_WantedMoriph true <spawn count> <spawn delay>
/event_WantedMoriph reset
/event_WantedMoriph titles
```

```text
/event_WantedWolf true
/event_WantedWolf false
/event_WantedWolf true <spawn count> <spawn delay>
/event_WantedWolf reset
/event_WantedWolf titles
```

Meaning:

- `true`: enable the event
- `false`: disable the event
- `true <spawn count> <spawn delay>`: enable with spawn tuning
- `reset`: reset kill statistics
- `titles`: distribute title rewards based on kills

## PvP runtime controls

### Set the PvP map

```text
/PVPMap <mapId>
```

The source also accepts `-1` to disable it.

### Adjust PvP scaling values

Base syntax:

```text
/pvp <key> <value>
```

Examples found in the source:

```text
/pvp dmg_scale_lvl 1.20
/pvp abs_scale_lvl 0.80
/pvp global_dmg_reduction 0.10
```

This block supports multiple keys, so use the full command reference if you need fine-grained PvP tuning.

## Maintenance mode

Start a countdown:

```text
/StartMaintenance 300
```

Cancel it:

```text
/StopMaintenance
```

What happens:

- the game server sends global notices
- the login server is notified too
- the countdown is started on both sides

## When to use the INI and when to use live commands

Use `server.ini` when:

- you want the default startup state
- you want the setting applied every time the server boots

Use GM commands when:

- you want to change behavior live
- you want to test an event without restarting
- you want a temporary event window

## Ready-to-use examples

### Turn on an EXP event

```text
/expevent 100
```

### Turn on extra drops and premium buffs

```text
/extradrop 2
/BONUSALL
```

### Run an aging weekend

```text
/event_agingfree true
/event_agingnobreak true
/event_aginghalfprice true
```

### Run a seasonal event

```text
/event_Halloween true
```

or

```text
/event_Christmas true
```

### Stop maintenance

```text
/StopMaintenance
```

## Good operational habits

- write down the previous value before changing a global setting
- change one thing at a time
- announce global event changes to players if the server is live
- test on a development account first when the event changes EXP or drop behavior
- if you change `server.ini`, restart the server so the fixed startup state takes effect

## Related docs

- `docs/guides/gm-handbook.md`
- `docs/reference/server-commands-reference.md`
- `docs/reference/ids/README.md`
