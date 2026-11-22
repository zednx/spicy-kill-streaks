# CurseForge listing

Everything to fill in when creating the project at <https://authors.curseforge.com> (Create Project → World of Warcraft → Addon).

## Project settings

| Field | Value |
|---|---|
| Name | Spicy Kill Streaks |
| Summary (one line) | Announcer voices, combat text and sparkles for your killing blows, kill streaks and multikills. Built for WoW Forever. |
| Primary category | PvP |
| Other categories | Audio & Video, Combat, Battleground |
| License | GNU General Public License version 2 (GPLv2) |
| Source | GitHub: `https://github.com/zednx/spicy-kill-streaks` |
| Issues | `https://github.com/zednx/spicy-kill-streaks/issues` |
| Logo / avatar | `docs/logo.png` (1024×1024), or `docs/logo-400.png` if the uploader wants a smaller file |
| File to upload | `SpicyKillStreaks-vX.Y.Z.zip` from the GitHub Release |
| Game version for the file | WoW Forever |
| Release type | Release (or Beta for a soft launch) |

Screenshots worth adding: a "KILLING SPREE!" callout with sparkles, a Flamboyant rainbow callout, the settings window with its live preview, the setup, and the guild board.

## Automatic uploads

Each `v*` tag uploads the addon zip to CurseForge, set to the newest **WoW Forever** game version, with the changelog section as release notes. To turn it on once the project exists:

1. On CurseForge, create an **API token** (your account settings → API tokens).
2. On GitHub, open the repo's **Settings → Secrets and variables → Actions**:
   - **Secrets** tab → New repository secret: name `CF_API_KEY`, value the token.
   - **Variables** tab → New repository variable: name `CF_PROJECT_ID`, value the project id (the number in the project's URL on authors.curseforge.com). A secret with that name works too.
3. If the upload picks the wrong game version, also add a variable `CF_GAME_VERSIONS` with the right version id(s), comma-separated. The workflow log lists them.

Without these, releases still publish on GitHub and just skip CurseForge. For the first release, uploading the zip by hand is fine too.

## Description

Paste everything below the line into the description editor (switch it to Markdown).

---

# 🌶️ Spicy Kill Streaks

**Announcer voices, combat text and sparkles for your killing blows in WoW Forever.** Land a killing blow and hear *Killing Spree!*, *Rampage!*, *Godlike!*. Chain kills for *Double Kill!* all the way up to *Holy Shit!*. Die, and get *Humiliation*.

A rewrite of the classic **dG KillShot**, rebuilt for WoW Forever, which doesn't give addons the combat log the original needed.

## What's new in 1.0.0

A brand new **settings window** with a live preview, a new **setup** (everyone sees it once after updating), a **minimap button**, the **Flamboyant** voice pack, a **guild board**, **gank shaming**, comebacks, more fonts and a **sound board**. The full list is in the changelog.

## Features

- **Kill streaks**: a rank for every kill in a row: *Headshot* (1), *Ownage* (2), *Killing Spree* (3), *Rampage*, *Dominating*, *Unstoppable*, *Wicked Sick*, then *Godlike* from 8 on, each with its own sound, colour and big on-screen callout. Keep going for a couple of secrets...
- **Multikills**: kills within 30 seconds chain into *Double Kill*, *Triple Kill*, *Multi Kill*, *Mega Kill* and beyond, all the way to *Holy Shit!*
- **Special callouts** (only when the addon is sure; otherwise you get the normal one):
  - *First Blood* on your first kill of the day
  - *Retribution* when you kill someone who killed you in the last hour. Sometimes the Candle King turns up: "You no take candle!"
  - *Comeback*: your first kill after dying 3+ times in a row gets the Butcher: "Looks like meat's back on the menu, boys!"
  - *Pancake* when you (or a friend) die from falling or drowning
  - **Ganks**: kill a player 10+ levels below you and get shamed instead ("Bully!"), with no streak credit. Die to someone 10+ levels above you and the Peon says it for you.
- **Voice packs**: Male, Female, Sexy, Baby and **Flamboyant** (the Heroes of Newerth announcer: *Cherry Poppah*, *Rainbow Warrior*, *Unicorn Stampede*... with rainbow callouts to match). Pick a separate voice for *Humiliation*, or drop in your own sound files.
- **Only your killing blows count**, not kills your group finishes.
- **Flair** (all optional):
  - Animated combat text that punches in and floats up, coloured by your streak
  - A dozen fonts to pick from, plus any font your other addons share (ElvUI, Details...)
  - Sparkle bursts: stars, chillies or confetti
  - A screen-edge flash for multikills and big streaks
  - Drag it anywhere, choose the size
- **Settings window** with a live preview, and a **Sound board** that plays every sound and tells you when it plays.
- **Minimap button**: left-click for settings, right-click for a quick menu, Shift-click to snooze.
- **Mute** it in battlegrounds, dungeons or raids, or `/sks snooze` for 30 minutes.
- **Guild board**: the month's top kill streaks and most deaths in your guild, shown at login and in the settings. Post it to guild or party chat to brag (or shame).
- **Party and guild sync** (on by default, part of the fun): share your kills and deaths with friends who run the addon. For party members and guild members separately, choose whether their kills appear in chat, as combat text, with sound, and whether their deaths show too. At login it tells you how many guildmates are using it, and if one of them has a newer version, it tells you an update is out. Battlegrounds and arenas are just for you: nothing is shared from them, and they don't count on the guild board.
- **Kudos** (opt-in): when a friend running the addon gets a kill, or dies, send them an emoji: 😂 😃 👍 👎 🙏 ☠️ 💀 ❤️ 🎉. It pops up on their screen with a running count, or goes in party or guild chat if you prefer.
- **Duels**: wins count; losing or fleeing earns a *Humiliation*.
- **Stats**: longest streaks, top prey, top predators and a recent kill log.

## Commands

| Command | What it does |
|---|---|
| `/sks` or `/killstreaks` | Settings |
| `/sks setup` | Run the setup again |
| `/sks preview` | Show off the effects |
| `/sks test kill` | Simulate a kill |
| `/sks unlock` | Move the text and sparkles (`/sks lock` when done) |
| `/sks who` | See who in your group and guild runs it |
| `/sks snooze` | Mute the sounds for 30 minutes (`/sks snooze off` to undo) |
| `/sks kudos` | Preview the Kudos popup and drag it into place (`/sks kudos got`: what friends send you) |
| `/sks minimap` | Show or hide the minimap button |
| `/sks debug` | Open the debug log (handy for bug reports) |

## How it knows you got the kill

WoW Forever keeps the combat log from addons, so kills are read from the battleground and arena **scoreboard**, and everywhere else from the game's own **killing-blow event**. Your killer comes from the **Death Recap**. Creature kills only count if you switch them on (great for trying it out).

## Privacy

Sharing with your party and guild is on by default, and the first-run setup says so with a box to untick. Shared kills travel as hidden addon messages to your party and/or guild; players without the addon see nothing. Switch sharing off under `/sks` > Sync and nothing leaves your game.

## Credits

Made by **Spicy Bubbletea** (Horde, WoW Forever PvP). Inspired by **dG KillShot** by Lance Inman, whose voice packs ship with this addon. Uses the **Ace3** libraries. The code is open source under the GNU GPL v2 and on GitHub (linked on this project).

**Sounds and fonts:** the announcer voices are not covered by the GPL. They belong to their owners (the Unreal Tournament announcers are © Epic Games) and are included as they were in dG KillShot; `sounds/CREDITS.txt` lists where each comes from, and rights holders can ask for removal on GitHub. The combat text fonts are from Google Fonts under the SIL Open Font License 1.1 and the Apache License 2.0, with their licences in `Media/Fonts`. The Kudos emoji are from Twemoji (Twitter, Inc and contributors) under CC-BY 4.0.

## Feedback

Message **Spicy Bubbletea** in game (Horde, WoW Forever PvP) or open a GitHub issue. A `/sks debug` log helps with bugs. Happy hunting! 🌶️

---

> **Disclaimer:** This is a hobby project, 100% vibe coded with AI for my own use. I'm sharing it in case it's useful to someone else. It's provided as-is, with no guarantees. Feedback and bug reports are welcome!
