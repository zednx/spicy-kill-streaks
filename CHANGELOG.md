# Changelog

## v0.1.1

- Kill and duel emotes work again. Built-in emotes (/cheer, /bow ...) play by themselves, after combat if you are fighting.
- WoW Forever only lets a custom emote message go out from a key press, so a kill now gets it ready and `/sks emote` sends it (put it in a macro on a key). This stops the "Interface action failed because of an addon" error.
- `/sks test emote` sends your kill emote for real.
- Party and guild kill lines start with a chilli and a skull, show the killer in an accent colour, and give levels: "Bob (10) was killed by Hogger (11)". Your level shows below max level, the other's when it differs from yours. Both sides need 0.1.1 for levels; 0.1.0 users still see the kills.

## v0.1.0

First release: a rewrite of dG KillShot for WoW Forever.

- Kill detection that works without the combat log: the battleground and arena scoreboard, the game's killing-blow event everywhere else, and the Death Recap for your own deaths. Only your own killing blows count.
- Seven streak ranks and seven multikill levels with sounds, colours and on-screen callouts; every-kill or Unreal Tournament style.
- Four voice packs, a separate Humiliation voice, and a folder for your own sounds.
- Optional effects: animated combat text, sparkle bursts (stars, chillies, confetti) and a screen-edge flash. Movable.
- Opt-in party and guild sync, with separate chat, combat text, sound and death settings for party members and guild members, plus a login line saying how many guildmates use the addon.
- Duel wins, losses and fleeing.
- Stats: streaks, top prey, top predators, recent log.
- First-run setup, test buttons and effect previews.
