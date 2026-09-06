# Prompts — what to paste next

Convention: **`NEXT-<AGENT>.md` is the only file that agent should paste right now.**

Older files (`AGENT_B.md`, `AGENT_B_BOARDS.md`, …) are previous waves. Do not paste those unless a human says to.

| Agent | Paste this | Owns | Do not touch |
|---|---|---|---|
| **B** | [`NEXT-B.md`](NEXT-B.md) | `src/Client/**` | Server, Config, Types, Formulas, `default.project.json` |
| **C** | [`NEXT-C.md`](NEXT-C.md) | `src/Shared/Config.luau`, `src/Shared/Types.luau` | Client, Server, Formulas, place file |

Launch:

```
grok --cwd C:\Users\zepto\worktrees\TheDummy
```

Branch must be `the-dummy`. Git: `"C:\Program Files\Git\cmd\git.exe"` on PATH.

## Instance names (B binds these)

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

Dummy stall SurfaceGui face = **Right**. Gym stall face = **Left**.
