# ID Reference

Updated on: 2026-03-15

This folder is the dedicated ID lookup area for day-to-day server operation.

Use this section when you need quick, copy-ready IDs for:

- monsters
- maps
- equipment
- potions
- premium, quest, event, and other non-equipment items

## Files in this section

- `docs/reference/ids/map-ids.md`: map IDs with enum names, map names, short names, and level requirements
- `docs/reference/ids/monster-ids-by-level.md`: monster IDs sorted from the lowest level to the highest level
- `docs/reference/ids/equipment-item-ids.md`: equipment item IDs sorted by required level
- `docs/reference/ids/potion-item-ids.md`: potion item IDs
- `docs/reference/ids/other-item-ids.md`: premium, quest, event, and other item IDs

## How these files are generated

These files are generated automatically by:

- `scripts/export-pt-reference-docs.ps1`

That script reads:

- `shared/map.h`
- `GameDB.dbo.MapList`
- `GameDB.dbo.ItemList`
- `GameDB.dbo.ItemListOld`
- `GameDB.dbo.MonsterList`

## When to regenerate

Run the export again when:

- you restore a different database backup
- you switch to a different runtime pack
- you change item, map, or monster data

Command:

```powershell
.\scripts\export-pt-reference-docs.ps1
```
