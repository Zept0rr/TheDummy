# Agent C — board copy + world numbers (this pass)

You are Agent C for **The Dummy**. `AGENTS.md` is source of truth. Read `src/Shared/Config.luau`, `src/Shared/Types.luau`, and `src/Shared/Formulas.luau` (do not edit Formulas).

## Git

Work only in `C:\Users\zepto\worktrees\TheDummy` on branch `the-dummy`.
`$env:Path = "C:\Program Files\Git\cmd;" + $env:Path`
Do not `git init`. Do not checkout `master`. Only `git add src/Shared/Config.luau src/Shared/Types.luau`.

Agent B is adding 3D boards. Give them copy + a few world numbers. **Do not retune dummy/gym costs.**

## Do

1. `Config.copy` — add (keep existing keys):

```
buy, upgrade, gymBuy, cantAfford, locked, maxed, needsRep
```

Example values: `"Buy"`, `"Upgrade"`, `"Buy gym level"`, `"Can't afford"`, `"Locked"`, `"Max"`, `"Needs Gym Rep"`.

2. `Config.world`:

```
promptDistance   -- e.g. 10
maxPenDummies    -- e.g. 12  (visible stand-ins, not owned cap)
```

3. `Types.luau`: extend `CopyConfig`; add `WorldConfig`; add `world: WorldConfig` on `Config`. Keep dummy `tint`.

## Don’t

Client, Server, Formulas, place file, changing `baseCost` / gym costs / prestige this pass.

## Stop when

B can `require` Config and read `copy.buy` and `world.maxPenDummies` with types that compile.
