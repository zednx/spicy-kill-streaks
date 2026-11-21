# Before the next release

Not shipped (only the `SpicyKillStreaks/` folder goes into the release).

## Sounds to add

Use the exact file names. `.ogg` or `.mp3`, ideally mono 22050 Hz like the others, or send WAVs to Claude to convert.

| File | Male `sounds\` | Female `sounds\female\` | Sexy `sounds\sexy\` | Baby `sounds\baby\` |
|---|---|---|---|---|
| `combowhore.ogg` (20 kills in a row) | done | [ ] | [ ] | [ ] |
| `gank.ogg` (you ganked someone 10+ levels lower) | [ ] | [ ] | [ ] | [ ] |
| `ganked.ogg` (a player 10+ levels higher killed you) | [ ] | [ ] | [ ] | [ ] |
| `triplekill.ogg` | done | [ ] | [ ] | [ ] |
| `headshot.ogg` | done | [ ] | [ ] | [ ] |
| `firstblood.ogg` | done | [ ] | done | [ ] |
| `retribution.ogg` | done | [ ] | [ ] | [ ] |
| `pancake.ogg` | done | [ ] | [ ] | [ ] |
| `monsterkill.ogg` | done | done | done | [ ] |

Until a file is added: a pack without it plays the male one; with no male one either, `ganked`
plays Humiliation and `gank` stays silent.

The **Flamboyant** pack (`sounds\flamboyant\`) is complete apart from `combowhore` and `prepare`,
which use the male voice.

- [ ] Listen to the HKSounds / MegaKill packs Claude sent ("Announcer sounds to review.zip"); MegaKill's
      Unreal pack has a `triple_kill.wav`
- [ ] Tell Claude where `headshot`, `firstblood` and `pancake` came from, for `sounds/CREDITS.txt`

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
- [ ] Try a few of the new fonts (/sks > Effects > Font)
- [ ] Guild board: with a guildmate on 0.7.0, check the login line and /sks > Guild board, and try Share

## Release

- [ ] `git pull && git tag v0.7.0 && git push origin v0.7.0` (check the latest tag first)
