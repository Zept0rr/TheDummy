# Contract — names only

If a name is not here, do not invent it. Set `needs:` in STATUS.md and stop that part.

## Remotes (`ReplicatedStorage.Remotes`)

Wave 1 (exist):

| Name | Direction | Args |
|---|---|---|
| BuyDummy | C→S | `id: string` |
| BuyDummyUpgrade | C→S | `id: string` |
| BuyGymLevel | C→S | none |
| RequestSync | C→S FireServer; S→C FireClient snapshot | none / snapshot |

Wave 2 (do not add until STATUS says so): CloseDojo, BuyRepNode.

No GrantBonk.

## Decimal wire

Bonk fields are `{ m: number, e: number }`. Not raw `number`. Client: `Formulas.Decimal.from`.

## Snapshot (RequestSync payload)

`bonk`, `bonkPerSec`, `lifetimeBonk`, `peakBonkThisRun` — Decimal  
`dummies`, `dummyUpgrades` — `{ [string]: number }`  
`gymLevel`, `gymRep`, `lifetimeGymRep`, `lastTick` — number  
`venueId` — string  
`unlockedVenues` — `{ string }`  
`persistOk` — boolean

## Dummy ids

`yellow` `fat` `gold` `crowd`

Upgrade ids (Config): `yellow_power` `fat_stay` `gold_power` `crowd_power`

## Config keys B may read

`copy.bonk` `copy.bonkPerSec` `copy.buy` `copy.upgrade` `copy.gymBuy` `copy.cantAfford` `copy.locked` `copy.maxed` `copy.needsRep` `copy.hitPopupPrefix`  
`copy.level` — exists (`"Lv"`)  
`world.promptDistance` `world.maxPenDummies`  
`world.cardPixelsPerStud` — optional  
`dummies[id].tint` `{ r, g, b }`  
`dummyOrder` `dummyUpgradeOrder`

Costs: Formulas + Config only. B never hardcodes prices.

## Workspace paths

```
Workspace.Backyard.DummyBoard.Stalls.yellow
Workspace.Backyard.DummyBoard.Stalls.yellow.Stand
Workspace.Backyard.DummyBoard.Stalls.fat
Workspace.Backyard.DummyBoard.Stalls.fat.Stand
Workspace.Backyard.DummyBoard.Stalls.gold
Workspace.Backyard.DummyBoard.Stalls.gold.Stand
Workspace.Backyard.DummyBoard.Stalls.crowd
Workspace.Backyard.DummyBoard.Stalls.crowd.Stand
Workspace.Backyard.GymBoard.Stall
Workspace.Backyard.GymBoard.Stall.Stand
Workspace.Backyard.PenDummies
```

Dummy stall SurfaceGui **Face = Right**. Gym stall **Face = Left**.
