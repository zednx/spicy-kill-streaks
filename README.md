# 🌶️ Spicy Kill Streaks

**Announcer voices, combat text and sparkles for your killing blows in WoW Forever.** Land a killing blow and hear *Killing Spree!*, *Rampage!*, *Godlike!*; chain kills for *Double Kill!* up to *Holy Shit!*. Die and get *Humiliation*.

A rewrite of **dG KillShot** for WoW Forever, which does not give addons the combat log that the original relied on.

## Features

- **Kill streaks**: seven ranks from *Ownage* to *Wicked Sick*, with their own sounds, colours and on-screen callouts. Every kill, or Unreal Tournament style (every few kills).
- **Multikills**: kills within 10 seconds of each other chain into *Double Kill*, *Multi Kill*, *Mega Kill* and on.
- **Only your killing blows count**, not kills your group finishes.
- **Four voice packs**: male, female, sexy and baby. Pick a separate voice for *Humiliation*, or add your own sound files.
- **Effects** (all optional): animated combat text that punches in and floats up, sparkle bursts (stars, chillies or confetti), and a screen-edge flash for big moments. Drag them anywhere.
- **Party and guild sync** (opt-in): share your kills and deaths with friends who run the addon. For party members and guild members separately, choose whether their kills show in chat, as combat text, with sound, and whether their deaths show too.
- **Duels**: wins count, losses and fleeing get a *Humiliation*.
- **Stats**: longest streaks, top prey, top predators and a recent log.
- **First-run setup** that walks you through voice, effects and sharing in about 30 seconds.
- **Tests and previews** for everything, so you can try it without a fight.

## Install

Install from CurseForge, or download `SpicyKillStreaks-vX.Y.Z.zip` from [Releases](https://github.com/zednx/spicy-kill-streaks/releases). Extract it into `World of Warcraft/_forever_/Interface/AddOns/`, then restart the game.

## Commands

| Command | What it does |
|---|---|
| `/sks` or `/killstreaks` | All options |
| `/sks setup` | The first-run setup again |
| `/sks preview` | Show off the effects (`kill`, `rank`, `multi`, `big`, `death`, `other`) |
| `/sks test kill` | Simulate a kill (also `death`, `execute`, `prepare`) |
| `/sks unlock` / `/sks lock` | Move the text and sparkles |
| `/sks who` | Who in your group and guild runs the addon |
| `/sks synctest` | Send a test kill to your party/guild |
| `/sks debug` | Print what the kill detection sees |

## How kills are detected

WoW Forever keeps the combat log from addons, so:

| Where | How |
|---|---|
| Battlegrounds and arenas | Your killing blows on the scoreboard |
| Everywhere else | The game's own killing-blow event (`PARTY_KILL`) |
| Your deaths | The Death Recap names your killer |
| Duels | The duel result in chat |

Creature kills only count if you switch on **Count NPC kills too** (handy for trying it out).

**"Finish him!"** plays when your target drops below a health threshold, but WoW Forever hides enemy health from addons during combat, so it only works where the game still shows it.

## Privacy

Nothing leaves your game unless you switch on sharing. With sharing on, the addon sends your kills and deaths (victim, killer, streak) as hidden addon messages to your party and/or guild; players without the addon see nothing. See [SECURITY.md](SECURITY.md).

## Credits and license

- Based on **dG KillShot** by Lance Inman. Its voice packs ship with this addon.
- Uses the **Ace3** libraries.
- Licensed under the **GNU GPL v2** (see [LICENSE](LICENSE)), as dG KillShot is.
