# Spicy Kill Streaks: working notes for Claude

A WoW Forever addon (interface 16001): announcer sounds, combat text and effects for killing blows, kill streaks and multikills. A GPL v2 rewrite of dG KillShot.

## Layout

| Path | What |
|---|---|
| `SpicyKillStreaks/` | The addon. Only this folder ships. `SpicyKillStreaks.lua` is the addon's logic; `UI.lua` is the settings window, setup and minimap button (our own flat controls), talking to the logic through `ns.core` (built at the bottom of `SpicyKillStreaks.lua`); `Kudos.lua` is the Kudos popup (reactions to friends' kills and deaths, the `R` addon message), hooked in through `SPECIAL.ownEvent` / `SPECIAL.allyEvent` and `ns.kudos.receive`; `Aid.lua` is Request help (the `A`, `W` and `X` addon messages, AVENGED), using the Kudos card stack (`ns.kudos.cards`); `Friends.lua` is sharing with friends (addon whispers to the friends list and Battle.net friends on our realm and faction, the `F?`/`F!` status question, per-friend prefs and the mute list); `Kos.lua` is the KOS list (rivals tallied by GUID, nemeses, payback via `kos.onKill` from `registerKill`, sightings, typed names confirmed on sight); `PatchNotes.lua` is the in-game patch notes (`ns.patchNotes`, the `news` page, pinned to the bottom of the menu; also `/sks news`); `libs/` is Ace3 (unchanged). |
| `tests/ui_smoke.lua` | Headless smoke test: fake WoW API, the real addon and Ace3, drives every settings page, the setup and the minimap button. `lua5.1 tests/ui_smoke.lua SpicyKillStreaks` (CI runs it). |
| `SpicyKillStreaks/sounds/` | Voice packs (`male` = the folder itself, `female/`, `sexy/`, `baby/`, `flamboyant/`, `zealot/`, `trailer/`; extra clips a pack rotates through are listed in `SPECIAL.ROTATION`), the default Humiliation (`humiliation/`), `custom/` for players' own files (ships with only a README), and `quiet/`: 75% copies of all of them for friends' kills and deaths. **After adding or changing a sound, run `tools/make_quiet.sh`** (CI checks every sound has its quiet copy). |
| `scripts/` | `check-release.sh`, `curseforge-upload.sh`. |
| `tools/make_art.py` | Draws `docs/logo.png` and `docs/logo-400.png` (Pillow). Same tile and chilli as Spicy Side Quests. |
| `docs/curseforge.md` | CurseForge project settings, upload setup and the listing description. |

The game's `Interface/AddOns/SpicyKillStreaks` is installed and updated by WowUp from the releases (it used to be a junction to this folder, but WowUp can't update over a junction). To try an edit in game before releasing, copy `SpicyKillStreaks/` over the installed folder and `/reload`; new files need a game restart.

## WoW Forever facts (verified in game)

- `COMBAT_LOG_EVENT_UNFILTERED` is blocked for addons.
- `PARTY_KILL(attackerGUID, targetGUID)` works outside instances with readable GUIDs and names the exact killing blow. It may be secret in some content: check `issecretvalue` before comparing.
- Enemy health is a secret value in combat, so "finish him" mostly can't work.
- Addon whispers (`SendAddonMessage(..., "WHISPER", name)`) work outside instances (the guild's `V!` answers arrive by whisper). Battlegrounds/arenas lock all addon messages (result 11).
- Characters have a family name: `UnitName("player")` can differ from the addon-message sender. Sync messages carry the sender's GUID for that reason.
- `.toc` files must be UTF-8 **without** a BOM.

## Rules that matter

- **200 locals:** `SpicyKillStreaks.lua` is at Lua 5.1's limit of 200 locals in the main chunk. Put new helpers in the `SPECIAL` table (or a `do` block) instead of new top-level locals.

- **Secret values:** never compare or do arithmetic on a value that may be secret; check `isSecret` first.
- **Untrusted input:** everything from `CHAT_MSG_ADDON` goes through `safeText` / range checks before it is shown.
- **Sharing:** `shareparty` / `shareguild` are on by default (since 0.2.0; the setup's "Better with friends" screen says so, and 0.1.x users see that screen once). `sharefriends` (whispers to friends) is **off** by default. Nothing is sent while they are off; don't add sends that bypass them. Whispered messages are only accepted from friends (`ns.friends.acceptsFeed`).
- **No personal details** (character names, account names) in code, comments or commits. One exception the user chose: the author credit **Spicy Bubbletea** (their public in-game name) in the About section and docs.
- The GitHub owner is **zednx** (repo: `zednx/spicy-kill-streaks`).
- Pin GitHub Actions to commit SHAs.

## Versioning and releases

Bump `## Version` in the `.toc` **and** `VERSION` in `SpicyKillStreaks.lua` (CI checks they match the tag), add a `## vX.Y.Z` section to `CHANGELOG.md` and the same version (short `{ area, line }` entries, newest first) to `SpicyKillStreaks/PatchNotes.lua` (the in-game Patch notes page; CI and the smoke test check it), commit, then the user tags: `git tag vX.Y.Z && git push origin vX.Y.Z`. Claude sessions can't push tags.

- **patch**: fixes and small tweaks; **minor**: new features; **major**: breaking changes (saved data or sync message format).
