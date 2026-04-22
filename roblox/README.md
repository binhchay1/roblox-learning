# Roblox Map Workspace (Step 3)

Project is file-based so you can code locally and package for client testing.

## Folder layout

- `default.project.json`: Rojo map between files and Roblox DataModel
- `src/ServerScriptService`: server bootstrap + services
- `src/ReplicatedStorage/Shared`: shared quest data and constants
- `src/StarterPlayer/StarterPlayerScripts`: local client bootstrap
- `src/StarterGui/MainHUD`: HUD prototype script

## Suggested workflow

1. Install Rojo (once): [https://rojo.space/docs](https://rojo.space/docs)
   - Windows quick install: `winget install Rojo.Rojo`
2. Start project sync:
   - `rojo serve roblox/default.project.json`
3. In Roblox Studio:
   - Install Rojo plugin
   - Connect to localhost project
4. Edit code in this repo, Studio auto-syncs.

## Packaging options for client testing

- **Option A (recommended):** Publish private Roblox place and share test access.
- **Option B:** Export place file from Studio (`.rbxlx`) and send to client machine.

Build snapshot command (from repo root):

```bash
rojo build roblox/default.project.json --output roblox/build/EduRPGVietnam.rbxlx
```

Then open the exported `.rbxlx` in Roblox Studio for final terrain/art setup.

## Step 4 API bridge (implemented)

- Server module: `src/ServerScriptService/Services/ApiService.luau`
  - `CheckAccess(robloxUserId, questCode)`
  - `SubmitScore(payload)`
  - retry + timeout + secure header `x-game-secret`
- Secret config kept server-only at `src/ServerStorage/Config/ApiConfig.server.luau`
- `Bootstrap.server.luau` now tests API access check when player joins.

## Step 5 gameplay slice (implemented)

- Server flow:
  - `Bootstrap.server.luau` creates remote events:
    - `RequestQuest`
    - `SubmitAnswer`
    - `SyncState`
  - Keeps in-memory player profile (HP, EXP, Lv, money, power, stat points, subject points)
  - Generates question by subject and validates answer on server
  - On correct answer:
    - update EXP / Level / Power / Quest progress
    - call backend `POST /submit-score`
  - On wrong answer:
    - reduce HP, reset streak

- New modules:
  - `Services/QuestionService.luau`: question generator per subject
  - `Services/PlayerProgressService.luau`: progression + breakthrough conditions

- Client HUD:
  - `StarterGui/MainHUD/MainHUD.client.luau`
  - shows stats + current quest progress + question + 3 answer buttons
  - button "Nhan Quest" requests server question

## Test checklist in Roblox Studio

1. Enable `Game Settings -> Security -> Allow HTTP Requests`.
2. Ensure backend API + PostgreSQL are running (`docker compose up --build` from repo root).
3. In `ServerStorage/Config/ApiConfig.server.luau`:
   - `BaseUrl` matches your backend URL
   - `GameSecret` matches `GAME_API_SECRET` in backend environment.
4. Run Play in Studio:
   - Press `Nhan Quest`
   - Answer options
   - Observe stat updates in HUD
   - Check backend receives `/submit-score` calls.

## If npm/rojo not recognized

Run:

```bat
roblox\scripts\doctor.cmd
```

If missing:
- Install Node LTS from [https://nodejs.org](https://nodejs.org)
- Install Rojo via `winget install Rojo.Rojo`
- Restart terminal/Cursor to reload PATH
