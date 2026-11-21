# Changelog

## v0.7.0

- **New rank ladder, one rank per kill:** Headshot 1 (First Blood once a day), Ownage 2, Killing Spree 3, Rampage 4, Dominating 5, Unstoppable 6, Wicked Sick 7, then **Godlike** from 8, the top tier with the biggest effects, on every kill after. The kill counts are fixed; the sliders are gone.
- **Ganks:** killing a player 10+ levels below you gets a bit of shame ("Bob ganked a level 12 Alice. Bully!") instead of a callout, and doesn't count towards your streak. Dying to a player 10+ levels above you (or "??") says "You got ganked by Bob (60)". Both only happen when the addon is sure: the levels were seen in the last few minutes, the other side is a player, and for your kill no honor came. Anything unclear plays as normal. Friends see your ganks too (with 0.7.0+). Both can be turned off under General.
- **Comeback:** your first kill after dying 3+ times in a row gets the Butcher: "Looks like meat's back on the menu, boys!" (the game's own sound). Turn it off under General.
- One Retribution in three is the Candle King: "You no take candle!" (the game's own sound).
- Getting ganked plays the Peon's "Me not that kind of orc!" (the game's own sound; Flamboyant has its own line).
- **About:** who makes the addon and where to send feedback.
- A couple of secrets at 10 and 20 kills in a row.
- **New voice pack: Flamboyant**, the Heroes of Newerth announcer. Cherry Poppah, Rainbow Warrior, Unicorn Stampede, It's a three-way... The callout text changes to match, in rainbow letters, and Godlike takes turns between Super Star, Diva and Fabulous.
- **Triple Kill** has its own voice in the male pack now.
- **Guild board:** your best kill streak and kills this month are shared with guildmates who run the addon (and share with the guild). At login, after the guildmate count, the top 3 killers of the month are listed. **Guild board** in the settings shows the top 10, with buttons to post the top 3 in guild or party chat. The board starts again on the 1st of each month. Turn the login line off under Sync.
- **More fonts for the combat text:** eight bundled fonts (Bangers, Luckiest Guy, Anton, Bebas Neue, Russo One, Black Ops One, Permanent Marker, Teko), WoW's Narrow, and every font your other addons share through SharedMedia (ElvUI, Details...). Picking one shows a preview. The Fancy font is gone (it falls back to Classic). Restart the game after updating so WoW sees the new font files.
- **Debug log window:** `/sks debug` (or the box under Tests > Troubleshooting) opens a small, movable, resizable window where the detection details are written, with timestamps and the client version at the top. The text can be selected: **Select all**, then Ctrl+C to copy it (addons can't write to the clipboard themselves). **Clear** empties it; closing the window turns debug off.
- `/sks debug` now also shows who the Death Recap names when you die, how each kill's victim was found, and the Retribution check. `/sks recap` prints your last Death Recap.

## v0.6.0

- **First Blood** on your first kill of the day (per character). After that, a streak's first kill is Headshot as before.
- **Retribution** when you kill someone who killed you in the last hour. It plays instead of the other kill sounds.
- **Pancake** when you die with no killer (falling, drowning, lava): "You just PANCAKED from falling or drowning." instead of "killed by an unknown enemy", with its own sound instead of Humiliation. Friends' deaths like that show as "Bob just PANCAKED from falling or drowning." (also from friends on older versions).
- All three can be turned off under General. Their sounds are included now, and so is **Headshot**'s (other voice packs use these too).
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
