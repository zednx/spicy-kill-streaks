# Before the next release

Not shipped (only the `SpicyKillStreaks/` folder goes into the release).

## Sounds to add

Use the exact file names. `.ogg` or `.mp3`, ideally mono 22050 Hz like the others, or send WAVs to Claude to convert. After adding one, run `tools/make_quiet.sh` (friends' 75% copies).

| File | Male `sounds\` | Female `sounds\female\` | Sexy `sounds\sexy\` | Baby `sounds\baby\` |
|---|---|---|---|---|
| `secret15.ogg` (15 in a row, male only) | done | - | - | - |
| `secret20.ogg` (20 kills in a row; was combowhore.ogg) | done | [ ] | [ ] | [ ] |
| `gank.ogg` (you ganked someone 10+ levels lower) | done ("Pint sized!") | male | male | male |
| `ganked.ogg` (a player 10+ levels higher killed you) | Peon (built in) | Peon | Peon | Peon |
| `triplekill.ogg` | done | [ ] | [ ] | [ ] |
| `headshot.ogg` | done | [ ] | [ ] | [ ] |
| `firstblood.ogg` | done | [ ] | done | [ ] |
| `retribution.ogg` | done | [ ] | [ ] | [ ] |
| `pancake.ogg` | done | [ ] | [ ] | [ ] |
| `monsterkill.ogg` | done | done | done | [ ] |

Until a file is added: a pack without it plays the male one. `gank` plays at most once a minute
(Headshot and Ownage in between). `ganked` plays the game's own Peon line ("Me not that kind of orc!", file ID 558146).

The **Flamboyant** pack (`sounds\flamboyant\`) is complete apart from `secret20` and `prepare`,
which use the male voice.

- [ ] Listen to the HKSounds / MegaKill packs Claude sent ("Announcer sounds to review.zip"); MegaKill's
      Unreal pack has a `triple_kill.wav`
- Secrets: 10 holyshit, 15 secret15 (male only), 20 secret20, 25 secret25, 30 secret30 (GLaDOS, also the 5th gank in 5 min); 3rd gank in 5 min: secretgank, 40 secret40
- [ ] Tell Claude where `headshot`, `firstblood`, `pancake` and `gank` ("Pint sized") came from, for `sounds/CREDITS.txt`

### Where the current sounds came from

- Every voice pack except the four new male sounds came with **dG KillShot** (WowAce/CurseForge
  project `dgks`, by Lance Inman). The files carry no source tags. Its page describes them as
  "Unreal Tournament, DoTA, Mortal Kombat" sounds. The male and female packs sound like the Unreal
  Tournament announcers, but that isn't confirmed. "Sexy" and "Baby" have no stated source.
- `retribution.ogg` was encoded by Unreal Engine 3 (it's in the file), so it's from an UE3 game
  such as Unreal Tournament 3.
- `headshot`, `firstblood` and `pancake` came from your WAV files.
- The announcer recordings are the game makers' copyright (Epic for Unreal Tournament).

## Test in game

- [ ] Restart WoW after updating (new fonts and sounds need a restart, not just /reload)
- [ ] Battleground: `/sks score` says your row was found
- [ ] `/sks debug`: die to a player and get a kill in the open world and in a battleground,
      then Select all, Ctrl+C and paste the log to Claude (for exact Retribution matching)
- [ ] New settings window (`/sks`): click through every section, check the live preview with a few fonts
      and voice packs, and that nothing overlaps or runs off the edge
- [ ] New setup (`/sks setup`): all six steps, Skip and Done
- [ ] Minimap button: left/right/Shift-click, drag it around, zZ while snoozed, hide and `/sks minimap`
- [ ] Sound board: every sound plays
- [ ] Guild board: with a guildmate on 1.0.0, check the login line and /sks > Guild board, and try Share

## Release

- [ ] `git pull && git tag v1.0.0 && git push origin v1.0.0` (check the latest tag first)

## Kudos (built in 1.1.0, test in game)

- [ ] With a friend on 1.1.0 (same party or guild, sharing on): switch on Friends > Kudos, then one of
      you gets a kill (or uses Friends > Send a test kill): the other sees the popup, clicks a reaction,
      and it pops up on the killer's screen
- [ ] A death: the emoji row there too
- [ ] "Also post my reactions in chat": the line appears in party/guild chat (no "interface action failed")
- [ ] `/sks kudos`: drag the popup, `/sks kudos` again to lock; it stays there after /reload
- [ ] In a battleground (the popup shouldn't get in the way; the reply goes through battleground chat)

Built as planned, apart from: reactions travel on the channel the kill came from (party or guild),
addressed to the friend's GUID, rather than as a whisper. That channel is known to work on WoW
Forever; addon whispers aren't tested there yet.

## Next version

### Request aid on death (built in 1.5.0, test in game)

- [ ] Die to a player in the open world with a friend on 1.5.0 in your party or guild: "Need help!", then
      their card (On my way, Waypoint with "Include where I died" on), and "X is on the way!" back
- [ ] The friend kills your killer: "AVENGED <you>!" for them, "<friend> AVENGED YOU!" for you
- [ ] "Also post my request in chat" posts without "interface action failed"
- [ ] Waypoint: the map pin appears (C_Map.SetUserWaypoint) or the position is printed instead

### Planned features: tracked as GitHub issues

- [#1 Share with friends (friends list and Battle.net), with a per-friend list](https://github.com/zednx/spicy-kill-streaks/issues/1)
- [#2 DaylightUI theme](https://github.com/zednx/spicy-kill-streaks/issues/2)
- [#3 KOS / Nemesis list](https://github.com/zednx/spicy-kill-streaks/issues/3)
- [#4 Flag sounds in capture-the-flag battlegrounds](https://github.com/zednx/spicy-kill-streaks/issues/4)
- [#5 Spicy Kill Streaks Theme (DaylightUI Plugin)](https://github.com/zednx/spicy-kill-streaks/issues/5)
