# Spicy Kill Streaks: working notes for Claude

A WoW Forever addon (interface 16001): announcer sounds, combat text and effects for killing blows, kill streaks and multikills. A GPL v2 rewrite of dG KillShot.

## Layout

| Path | What |
|---|---|
| `SpicyKillStreaks/` | The addon. Only this folder ships. `SpicyKillStreaks.lua` is the addon's logic; `UI.lua` is the settings window, setup and minimap button (AceGUI widgets in our own frames), talking to the logic through `ns.core` (built at the bottom of `SpicyKillStreaks.lua`); `libs/` is Ace3 (unchanged). |
| `tests/ui_smoke.lua` | Headless smoke test: fake WoW API, the real addon and Ace3, drives every settings page, the setup and the minimap button. `lua5.1 tests/ui_smoke.lua SpicyKillStreaks` (CI runs it). |
| `SpicyKillStreaks/sounds/` | Voice packs (`male` = the folder itself, `female/`, `sexy/`, `baby/`), the default Humiliation (`humiliation/`), `custom/` for players' own files (ships with only a README). |
| `scripts/` | `check-release.sh`, `curseforge-upload.sh`. |
| `tools/make_art.py` | Draws `docs/logo.png` and `docs/logo-400.png` (Pillow). Same tile and chilli as Spicy Side Quests. |
| `docs/curseforge.md` | CurseForge project settings, upload setup and the listing description. |

The game's `Interface/AddOns/SpicyKillStreaks` is installed and updated by WowUp from the releases (it used to be a junction to this folder, but WowUp can't update over a junction). To try an edit in game before releasing, copy `SpicyKillStreaks/` over the installed folder and `/reload`; new files need a game restart.

## WoW Forever facts (verified in game)

- `COMBAT_LOG_EVENT_UNFILTERED` is blocked for addons.
- `PARTY_KILL(attackerGUID, targetGUID)` works outside instances with readable GUIDs and names the exact killing blow. It may be secret in some content: check `issecretvalue` before comparing.
- Enemy health is a secret value in combat, so "finish him" mostly can't work.
- Characters have a family name: `UnitName("player")` can differ from the addon-message sender. Sync messages carry the sender's GUID for that reason.
- `.toc` files must be UTF-8 **without** a BOM.

## Rules that matter

- **200 locals:** `SpicyKillStreaks.lua` is at Lua 5.1's limit of 200 locals in the main chunk. Put new helpers in the `SPECIAL` table (or a `do` block) instead of new top-level locals.

- **Secret values:** never compare or do arithmetic on a value that may be secret; check `isSecret` first.
- **Untrusted input:** everything from `CHAT_MSG_ADDON` goes through `safeText` / range checks before it is shown.
- **Sharing:** `shareparty` / `shareguild` are on by default (since 0.2.0; the setup's "Better with friends" screen says so, and 0.1.x users see that screen once). Nothing is sent while they are off; don't add sends that bypass them.
- **No personal details** (character names, account names) in code, comments or commits. One exception the user chose: the author credit **Spicy Bubbletea** (their public in-game name) in the About section and docs.
- The GitHub owner is **zednx** (repo: `zednx/spicy-kill-streaks`).
- Pin GitHub Actions to commit SHAs.

## Versioning and releases

Bump `## Version` in the `.toc` **and** `VERSION` in `SpicyKillStreaks.lua` (CI checks they match the tag), add a `## vX.Y.Z` section to `CHANGELOG.md`, commit, then the user tags: `git tag vX.Y.Z && git push origin vX.Y.Z`. Claude sessions can't push tags.

- **patch**: fixes and small tweaks; **minor**: new features; **major**: breaking changes (saved data or sync message format).
