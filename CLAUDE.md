# Spicy Kill Streaks: working notes for Claude

A WoW Forever addon (interface 16001): announcer sounds, combat text and effects for killing blows, kill streaks and multikills. A GPL v2 rewrite of dG KillShot.

## Layout

| Path | What |
|---|---|
| `SpicyKillStreaks/` | The addon. Only this folder ships. `SpicyKillStreaks.lua` is the whole addon; `libs/` is Ace3 (unchanged). |
| `SpicyKillStreaks/sounds/` | Voice packs (`male` = the folder itself, `female/`, `sexy/`, `baby/`), the default Humiliation (`humiliation/`), `custom/` for players' own files (ships with only a README). |
| `scripts/` | `check-release.sh`, `curseforge-upload.sh`. |
| `tools/make_art.py` | Draws `docs/logo.png` and `docs/logo-400.png` (Pillow). Same tile and chilli as Spicy Side Quests. |
| `docs/curseforge.md` | CurseForge project settings, upload setup and the listing description. |

The game's `Interface/AddOns/SpicyKillStreaks` is a junction to `SpicyKillStreaks/` here, so `/reload` picks up edits directly. New files need a game restart.

## WoW Forever facts (verified in game)

- `COMBAT_LOG_EVENT_UNFILTERED` is blocked for addons.
- `PARTY_KILL(attackerGUID, targetGUID)` works outside instances with readable GUIDs and names the exact killing blow. It may be secret in some content: check `issecretvalue` before comparing.
- Enemy health is a secret value in combat, so "finish him" mostly can't work.
- Characters have a family name: `UnitName("player")` can differ from the addon-message sender. Sync messages carry the sender's GUID for that reason.
- `.toc` files must be UTF-8 **without** a BOM.

## Rules that matter

- **Secret values:** never compare or do arithmetic on a value that may be secret; check `isSecret` first.
- **Untrusted input:** everything from `CHAT_MSG_ADDON` goes through `safeText` / range checks before it is shown.
- **Opt-in sharing:** nothing is sent unless `shareparty` / `shareguild` is on; don't add sends that bypass it.
- **No personal details** (character names, account names) in code, comments or commits.
- The GitHub owner is **zednx** (repo: `zednx/spicy-kill-streaks`).
- Pin GitHub Actions to commit SHAs.

## Versioning and releases

Bump `## Version` in the `.toc` **and** `VERSION` in `SpicyKillStreaks.lua` (CI checks they match the tag), add a `## vX.Y.Z` section to `CHANGELOG.md`, commit, then the user tags: `git tag vX.Y.Z && git push origin vX.Y.Z`. Claude sessions can't push tags.

- **patch**: fixes and small tweaks; **minor**: new features; **major**: breaking changes (saved data or sync message format).
