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
| File to upload | `SpicyKillStreaks-v1.0.0.zip` from the GitHub Release |
| Game version for the file | WoW Forever |
| Release type | Release (or Beta for a soft launch) |

Screenshots worth adding: a "KILLING SPREE!" callout with sparkles, the options window, and the first-run setup.

## Automatic uploads

Each `v*` tag uploads the addon zip to CurseForge, set to the newest **WoW Forever** game version, with the changelog section as release notes. To turn it on once the project exists:

1. On CurseForge, create an **API token** (your account settings → API tokens).
2. On GitHub, open the repo's **Settings → Secrets and variables → Actions**:
   - **Secrets** tab → New repository secret: name `CF_API_KEY`, value the token.
   - **Variables** tab → New repository variable: name `CF_PROJECT_ID`, value the project id (the number in the project's URL on authors.curseforge.com).
3. If the upload picks the wrong game version, also add a variable `CF_GAME_VERSIONS` with the right version id(s), comma-separated. The workflow log lists them.

Without these, releases still publish on GitHub and just skip CurseForge. For the first release, uploading the zip by hand is fine too.

## Description

Paste everything below the line into the description editor (switch it to Markdown).

---

# 🌶️ Spicy Kill Streaks

**Announcer voices, combat text and sparkles for your killing blows in WoW Forever.** Land a killing blow and hear *Killing Spree!*, *Rampage!*, *Godlike!*. Chain kills for *Double Kill!* all the way up to *Holy Shit!*. Die, and get *Humiliation*.

A rewrite of the classic **dG KillShot**, rebuilt for WoW Forever, which doesn't give addons the combat log the original needed.

## Features

- **Kill streaks**: seven ranks from *Ownage* to *Wicked Sick*, each with its own sound, colour and big on-screen callout. On every kill, or Unreal Tournament style (every few kills).
- **Multikills**: kills within 10 seconds chain into *Double Kill*, *Multi Kill*, *Mega Kill* and beyond.
- **Only your killing blows count**, not kills your group finishes.
- **Four voice packs**: male, female, sexy and baby. Pick a separate voice for *Humiliation*, or drop in your own sound files.
- **Flare** (all optional):
  - Animated combat text that punches in and floats up, coloured by your streak
  - Sparkle bursts: stars, chillies or confetti
  - A screen-edge flash for multikills and big streaks
  - Drag it anywhere, choose the size and font
- **Party and guild sync** (opt-in): share your kills and deaths with friends who run the addon. For party members and guild members separately, choose whether their kills appear in chat, as combat text, with sound, and whether their deaths show too. At login it tells you how many guildmates are using it.
- **Duels**: wins count; losing or fleeing earns a *Humiliation*.
- **Stats**: longest streaks, top prey, top predators and a recent kill log.
- **Quick setup** on first login, plus test buttons and previews for everything.

## Commands

| Command | What it does |
|---|---|
| `/sks` or `/killstreaks` | All options |
| `/sks setup` | Run the first-time setup again |
| `/sks preview` | Show off the effects |
| `/sks test kill` | Simulate a kill |
| `/sks unlock` | Move the text and sparkles (`/sks lock` when done) |
| `/sks who` | See who in your group and guild runs it |

## How it knows you got the kill

WoW Forever keeps the combat log from addons, so kills are read from the battleground and arena **scoreboard**, and everywhere else from the game's own **killing-blow event**. Your killer comes from the **Death Recap**. Creature kills only count if you switch them on (great for trying it out).

> **"Finish him!"** plays when your target gets low, but WoW Forever hides enemy health from addons during combat, so it only works where the game still shows it.

## Privacy

Nothing leaves your game unless you switch on sharing. Shared kills travel as hidden addon messages to your party and/or guild; players without the addon see nothing.

## Credits

Based on **dG KillShot** by Lance Inman, whose voice packs ship with this addon. Uses the **Ace3** libraries. Open source under the GNU GPL v2; the code is on GitHub (linked on this project).

## Feedback

Bugs and ideas are welcome on GitHub Issues. Happy hunting! 🌶️

---

> **Disclaimer:** This is a hobby project, 100% vibe coded with AI for my own use. I'm sharing it in case it's useful to someone else. It's provided as-is, with no guarantees. Feedback and bug reports are welcome!
