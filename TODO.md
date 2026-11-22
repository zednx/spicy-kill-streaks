# Before the next release

Not shipped (only the `SpicyKillStreaks/` folder goes into the release).

## Sounds to add

Use the exact file names. `.ogg` or `.mp3`, ideally mono 22050 Hz like the others, or send WAVs to Claude to convert.

| File | Male `sounds\` | Female `sounds\female\` | Sexy `sounds\sexy\` | Baby `sounds\baby\` |
|---|---|---|---|---|
| `combowhore.ogg` (20 kills in a row) | done | [ ] | [ ] | [ ] |
| `gank.ogg` (you ganked someone 10+ levels lower) | [ ] | [ ] | [ ] | [ ] |
| `ganked.ogg` (a player 10+ levels higher killed you) | Peon (built in) | Peon | Peon | Peon |
| `triplekill.ogg` | done | [ ] | [ ] | [ ] |
| `headshot.ogg` | done | [ ] | [ ] | [ ] |
| `firstblood.ogg` | done | [ ] | done | [ ] |
| `retribution.ogg` | done | [ ] | [ ] | [ ] |
| `pancake.ogg` | done | [ ] | [ ] | [ ] |
| `monsterkill.ogg` | done | done | done | [ ] |

Until a file is added: a pack without it plays the male one; with no male one either, `gank`
stays silent. `ganked` plays the game's own Peon line ("Me not that kind of orc!", file ID 558146).

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
- [ ] New settings window (`/sks`): click through every section, check the live preview with a few fonts
      and voice packs, and that nothing overlaps or runs off the edge
- [ ] New setup (`/sks setup`): all six steps, Skip and Done
- [ ] Minimap button: left/right/Shift-click, drag it around, zZ while snoozed, hide and `/sks minimap`
- [ ] Sound board: every sound plays
- [ ] Guild board: with a guildmate on 1.0.0, check the login line and /sks > Guild board, and try Share

## Release

- [ ] `git pull && git tag v1.0.0 && git push origin v1.0.0` (check the latest tag first)

## Next version

### Kudos

An optional little popup that appears for up to 30 seconds after an ally (party or guild member
running the addon) gets a kill or dies:

- **Kill:** send a thumbs-up / "Hell yeah!" that adds to their flair (they see it pop up on their
  callout, e.g. "+3 hell yeahs").
- **Death:** press **F** to pay respects to the fallen.
- The player chooses where the popup sits (unlock and drag, like the combat text).
- Off by default, with its own switch in Friends, and it follows the party/guild sharing settings.

Notes for building it: the kudos travel as a new addon message type, whispered to the ally (so it
only reaches them), limited to one per kill/death per player and rate-limited like the others.
Older versions just ignore the new type.

#### Kudos: more ideas

- **Kill reactions** (the player picks one, or it rotates): "Zug zug!", "For the Horde!" / "For the
  Alliance!" (the sender's own faction, read from their character so it's always right), "Hell yeah!",
  thumbs up.
- **Death reactions:** "RIP", "F" (pay respects).
- **Where a reaction goes** (chosen in settings):
  - **Private (default):** through the addon, so only the sender and receiver see it, as a popup on
    the receiver's screen that adds to their flair.
  - **Guild or party chat (opt-in):** a normal chat line everyone sees, e.g.
    "Spicy: Zug zug! (to Bob for Killing Spree)".
- To decide: public posting gets its own switch (no accidental guild spam), and a short cooldown on
  chat posts. Chat posts must happen in the click itself (WoW Forever blocks delayed posts).

### Request aid on death

- **The button:** when you die, a small "Need help!" / "Avenge me!" button appears by the death
  callout (or in the Kudos popup's spot). Shown prominently when you got ganked.
- **What it sends:** one press sends e.g. "Spicy needs help in Ashenvale (52.1, 41.3), killed by
  Orcbro (60)".
  - **Through the addon (default):** party/guild members running it get a popup, with an optional
    sound, map pin or waypoint button.
  - **Party or guild chat (opt-in):** a normal chat line.
- **Ties in with Retribution:** allies who answer and kill your killer get a special callout, e.g.
  "AVENGED!".
- **Safeguards:** a cooldown; follows the party/guild sharing settings; the location is only included
  if you turn that on.
- **Check in game:** chat posts only go out from a click/key press. A button click should count, but test it.

### KOS / Nemesis list

- **Adding someone:** when you die to a player who has killed you before, the death popup offers
  "Add to KOS". Also `/sks kos <name>`, or right-click them in the debug log.
- **Nemesis (automatic):** anyone who kills you 3+ times without you killing them back becomes your
  Nemesis, with its own callout and sound ("Your nemesis Orcbro strikes again!").
- **Payback:** killing someone on the list gives "GRUDGE SETTLED!" / "NEMESIS SLAIN!", a stronger
  Retribution with no 60-minute limit.
- **Sightings:** when a listed player is your target, mouseover or on a nameplate, a small alert shows
  ("KOS: Orcbro (60) nearby"). With Request aid, guildmates could optionally get a ping.
- **Tally:** kills each way per player ("Orcbro: killed you 5, you killed them 2"), on a settings page
  where names can be viewed and removed.
- **Sharing (opt-in, off by default):** share the list with your guild so guildmates get the same alerts.
- **Builds on** the killer memory Retribution and the gank checks already keep, made permanent.
- **Stay 100% sure:**
  - Only add or match someone when their GUID is readable (it can be secret in some content).
  - Match by GUID, not by name (family names).
  - Sightings only work when the addon can see the player (target, mouseover, nameplate), not
    across the zone.

#### Adding a KOS name by hand

- **Where:** an "Add name" box on the KOS page, or `/sks kos <name>`.
- **When:** the killer's GUID was hidden, the popup missed them, or you want someone who never killed you.
- **Matching:** a typed name has no GUID, and names can repeat across families, so it's not 100% sure.
  - The entry is "unconfirmed" (greyed out).
  - The first time a player with that name is seen (target, mouseover, nameplate, or a kill either
    way), ask "Is this the Orcbro you added? (Yes / No)", or link automatically if only one player
    with that name has been seen. From then on it matches by GUID.
- **Callouts:** unconfirmed entries still get the sighting alert, worded "possibly" ("KOS? Orcbro
  nearby"). The big payback callout only plays once confirmed by GUID; until then the normal callout plays.
- **Input safety:** typed names go through `safeText` and a length cap; shared lists get the same
  checks as any other addon message.
