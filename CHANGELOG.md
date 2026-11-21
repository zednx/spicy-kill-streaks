# Changelog

## v0.6.0

- **First Blood** on your first kill of the day (per character). After that, a streak's first kill is Headshot as before.
- **Retribution** when you kill someone who killed you in the last hour. It plays instead of the other kill sounds.
- **Pancake** when you die with no killer (falling, drowning, lava): "You just PANCAKED from falling or drowning." instead of "killed by an unknown enemy", with its own sound instead of Humiliation. Friends' deaths like that show as "Bob just PANCAKED from falling or drowning." (also from friends on older versions).
- All three can be turned off under General. They use `firstblood.ogg`, `retribution.ogg` and `pancake.ogg` from `sounds\`.
- Removed the **"Finish him!"** option: WoW Forever hides enemy health from addons in combat, so it never worked.

## v0.5.0

- **Mute sounds** in battlegrounds and arenas, dungeons or raids: three new boxes under Sounds. Text and effects still show.
- **`/sks snooze`** mutes the sounds for 30 minutes (`/sks snooze 60` for an hour, `/sks snooze off` to undo). It lasts through a /reload and says when it's over.

## v0.4.0

- **Update notice:** when a guildmate or party member runs a newer version, a chat line says so (once per session). Only players on 0.4.0 or later get the notice, so 0.3.0 users need to update once by hand. Turn it off under Sync.

## v0.3.0

- **Battlegrounds:** kills are found again when the scoreboard lists you with your family name ("Name Family") or hides GUIDs. New `/sks score` (in a battleground or arena) shows how the addon finds your row on the scoreboard.
- **Headshot** on the first kill of a streak. The ranks now start at the second kill: Ownage 2, Killing Spree 3, Rampage 5, Dominating 7, Unstoppable 9, Godlike 11, Wicked Sick 13 (change them under Streak ranks). Turn Headshot off under General. The sound isn't included: put a `headshot.ogg` (or `.mp3`) in `sounds\` or your voice pack's folder.
- **Multikills:** kills within **30 seconds** (was 10) chain, and there's a new **Triple Kill** between Double and Multi: Double, Triple, Multi, Mega, Ultra, Monster, Ludicrous, Holy Shit. Add a `triplekill.ogg` to `sounds\` for its voice; until then it plays the Multi Kill sound. Friends still on 0.2.0 see your multikills one step lower (your Triple shows as their Multi).

## v0.2.0

- Party and guild sharing is now **on by default**: it's what makes the addon fun with friends. The setup has a new "Better with friends" screen that explains it, previews a friend's kill and has the boxes to switch it off. Players who set up 0.1.x see that screen once.
- Added /pulse to the emotes you can pick for kills and duels.

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
