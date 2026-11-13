# Security

## What the addon can touch

It runs inside WoW's addon sandbox. It has no network access and reads only its own saved data (`SpicyKillStreaksDB`).

| | When |
|---|---|
| **Addon messages** to your party/raid/battleground and guild | Only after you switch on sharing (off by default). They carry your kills and deaths: victim or killer name, streak, multikill level, your character's GUID and the addon version. |
| **Version answers** (whispered addon message) | Only when someone asks "who runs this addon?" **and** you share with someone. |
| **Emotes and an emote chat message** | Only if you pick one in the options. |
| **Screenshots** | Only if you switch them on. |

## What it accepts from others

Messages from other players are treated as untrusted data: names are stripped of WoW's `|` escape codes (no fake links, colours or textures) and cut to 60 characters, numbers are range-checked, and each sender is limited to 12 messages per 10 seconds. They only ever show text or play one of the addon's own sounds, and never change your stats.

## Reporting a problem

Open an issue at https://github.com/zednx/spicy-kill-streaks/issues. For anything that could be abused, say so in the issue title without the details, and they can be shared privately.
