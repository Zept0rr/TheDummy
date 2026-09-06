# Prompts

**Paste exactly one file per session.** Index:

| Agent | Paste | Owns |
|---|---|---|
| A (place / Rojo / Studio) | [NEXT-A.md](NEXT-A.md) | `default.project.json`, `TheDummy.rbxl`, backyard instances |
| B (client) | [NEXT-B.md](NEXT-B.md) | `src/Client/**` |
| C (config) | [NEXT-C.md](NEXT-C.md) | `src/Shared/Config.luau`, `src/Shared/Types.luau` |

Before coding, every agent reads:

1. [STATUS.md](STATUS.md) — current wave, blocked, needs
2. [CONTRACT.md](CONTRACT.md) — remotes, snapshot, Config keys, instance paths
3. Their **NEXT-*.md** only

`AGENTS.md` is game law. `AGENT_*.md` files are archives — do not paste.

```
grok --cwd C:\Users\zepto\worktrees\TheDummy
```

Branch `the-dummy`. Git: `"C:\Program Files\Git\cmd\git.exe"` on PATH. Commit only owned paths.
