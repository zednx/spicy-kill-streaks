# Changelog

## v1.13.2

- **NPC kills are just for you** (with **Count NPC kills** on): their callouts, sounds and effects play with a streak of their own, but they're no longer sent to your party, guild or friends, don't count in your stats or on the guild board, and leave your real kill streak alone. Dying resets the NPC streak too.

## v1.13.1

- **Fixed: killing the same player again wasn't counted.** Once you'd killed a player, every later kill on them was ignored until you changed zone (no callout, no streak, no KOS payback). In world PvP, where you meet the same players again and again, that missed a lot. Now a repeat only counts once if the game reports it twice within a few seconds.
- **Your kill line in chat shows your streak:** "Spicy killed Bob! (4 streak)", from the 2nd kill in a row (not if your own Kill text already has `$s`). Friends' kills in your feed say it the same way now ("(4 streak)" instead of "(streak 4)").

## v1.13.0

- **Share your KOS and Do not kill lists with the guild** (optional, off by default: **Share with the guild** on the KOS list page, with guild sharing on). Your players go to guildmates who share too, and theirs show on your tooltips: **Guild KOS (Bob)** or **Guild: Do not kill (Bob)**, when the player isn't on your own lists. Only players you've seen (matched by their unique ID) are shared, up to 40 each. Lists go out at login and when you add or remove someone; nothing is sent from battlegrounds. A guildmate's list only shows on tooltips: payback, sightings and reminders stay yours. Guildmates need 1.13.0.

## v1.12.0

- **Do not kill list** at the bottom of the KOS list page: players you'd rather leave alone (friends on the other faction...). Target one and you're reminded, once per session: "<name> is on your Do not kill list." Add your target (matched exactly) or a name, on the page or with `/sks dnk <name>`. Someone on it never becomes a nemesis or gets an "Add to KOS" offer, and adding them to one list takes them off the other.
- **Tooltips:** a player's tooltip says **KOS list**, **Nemesis (KOS list)** or **Do not kill**.

## v1.11.2

- **No more "No player named 'Name' is currently playing."** At login the addon asks your online friends whether they run it. WoW Forever doesn't say which realm a Battle.net friend is on, so it asks them all, and the game answered for those on another realm with that line. It's hidden now, and a friend the game can't reach isn't asked again that session (`/sks friends` lists them as left out).

## v1.11.1

- **Trailer:** the line it says now shows under the callout, smaller and in white (like Zealot), for the ranks, First Blood, Retribution and the multikills.
- **Trailer is louder**, about as loud as Zealot (it was well under the other packs).
- Packs with their own lines can show them under multikills too, also in the settings preview.

## v1.11.0

- **New voice pack: Trailer**, a movie-trailer narrator who slowly loses it. Foreboding one-liners for every rank and multikill (*Three bodies. One survivor.*, *This summer, fear has a name.*), breaking into laughter as your streak climbs, plus its own First Blood, Retribution, Pancake, Prepare, Gank and Ganked lines. Pick it under `/sks` > Sound or in the setup.
- **Fresh lines:** Trailer takes turns through two Humiliation lines, three Gank lines and two Ganked lines, so they don't repeat every time.
- **Setup:** the voice step shows the seven packs in a row of four and a row of three.

## v1.10.1

- **Settings:** buttons next to a dropdown or text box (Play, Add...) line up with the box instead of its label.
- **Zealot:** the taunt now shows under the callout in game, smaller and in white, like in the live preview (it was as big as the callout).

## v1.10.0

- **KOS list: add your target.** Target an enemy player and their name is already filled in on the KOS page: **Add** puts them on the list for sure (by their unique ID). `/sks kos <their name>` does the same.
- **KOS sighting sound:** pick Raid warning, Boss warning, Alarm clock, Ready check, PvP queue pop, Whisper, Alarm drum, Chime, "Eternal agony awaits you!" or None, with a Play button (KOS list page).
- **Tidier Announcer page:** the callout switches are split into Callouts, Ganks, Battlegrounds and Streaks, with shorter descriptions.
- **Your kill streak survives a `/reload`** (and a disconnect or quick relog, within 10 minutes). Before, reloading the UI started it again from 0.

## v1.9.0

- **`/sks who` says when it's done:** once everyone had time to answer, one line with how many other players run it ("Done: 3 other players run Spicy Kill Streaks."), or that nobody did. Friends' answers count too.
- **Guild board: one row per player.** A guildmate could be on it twice, once with their family name ("Cora Nado") and once without ("Cora"), as different messages name them differently. The board now keeps one row per player, shows the full name, and merges the doubles it already has (keeping the higher numbers). Muting someone covers them with or without the family name too.
- **Test a kill and Test death leave your streak alone:** a test kill added one to the kill streak you were on, and a test death reset it to 0. They never touched your saved stats, and still don't.
- **Show in game** (under the live preview) now shows the sample you picked (Kill, Rank, Multi, Payback, Godlike or Gank), with its text, colours and sound, in your voice pack's words. Before, only three of them matched.
- **Patch notes in game:** open **Patch notes** at the bottom of the settings window's menu (or `/sks news`) to see what changed in each version; click a version to open or close it. After an update, one chat line says where to find them.
- **Zealot voice pack:** holy-warrior taunts. The taunt is the big callout ("HIS JUSTICE IS SWIFT!") with the usual name above it ("RAMPAGE!"); chat and the log keep the usual names. Its own lines for First Blood, Headshot, every rank, Retribution, GRUDGE SETTLED!, NEMESIS SLAIN!, BIG GAME HUNTER!, comebacks, avenging a friend, duel wins, ganks, being ganked, falling to your death and Prepare. Godlike takes turns between three lines and Humiliation between three. Multikills and secrets use the Male voice.
- **BIG GAME HUNTER!** Kill a player 10+ levels above you (or a ??) for its own callout and announcer line, with "You took down a level 60 <name>!" in chat. As sure as the gank checks: their level was seen in the last few minutes and they're a player. Friends on 1.9.0 see it in their feed too. Switch it off under Announcer > Callouts; it's on the Sound board.
- **Kudos emoji:** ☠️ is gone (💀 is enough), and 😭 (posted in chat as "Noooo!") and 👏 ("Well played!") are new: ten emoji, two rows of five. A ☠️ from an older version still shows.
- **Muting is easier and covers everything:** a **Mute** button next to each player on the Guild board (and **Unmute**), and a muted player's Kudos and help requests are hidden too, not just their kills and deaths. The Friends page says how to mute.
- **Friends who are also guildmates** aren't whispered any more while you share with the guild (they get everything through the guild), and the "do you run it?" questions to friends go out one every 2 seconds instead of all at once at login (a burst of whispers could make the server hold back the addon's messages for a while).
- **KOS list:** your kill-on-sight list, on its own **KOS list** page.
  - After a player kills you for the second time, a card offers **Add to KOS**.
  - **Nemesis:** a player who kills you 3 times in a row (without you killing them back) becomes your nemesis by themselves: "<name> IS NOW YOUR NEMESIS!", and "Your nemesis <name> strikes again!" after that.
  - **Payback:** killing someone on the list plays **GRUDGE SETTLED!** (**NEMESIS SLAIN!** for a nemesis), each with its own announcer line (a surprise) and the big effects, with no time limit.
  - **Sightings:** when a listed player is your target, mouseover or on a nameplate: "KOS: <name> (60) nearby!" with the raid warning sound (once every 2 minutes per player).
  - Add anyone by name with `/sks kos <name>` or on the page. A typed name stays *unconfirmed* until you see a player with that name and confirm it's them; only then does payback play.
  - The page lists everyone on it with kills each way, and your other rivals with an **Add to KOS** button. Players are always matched exactly (by their unique ID), never by name alone.

## v1.8.3

- **Friends:** your kills now go to **every online friend who runs Spicy Kill Streaks** (no limit of 10), and only to them. With My friends on, the addon finds them by itself: it asks at login and when a friend comes online (each friend at most every 5 minutes). The Friends page lists just the friends with Spicy Kill Streaks. Battle.net friends count too, even though WoW Forever doesn't tell addons which realm they're on: answering proves they're reachable. `/sks friends` lists every friend the addon can see and why any is left out (offline, another game or realm, other faction).

## v1.8.2

- **The Kudos popup fades out in combat** and comes back after the fight. Its cards don't count down while hidden, so you can still react after the fight (friends now accept kudos up to 3 minutes after their kill). Kudos you get during a fight still flash in your combat text. Switch it off with **Hide in combat** on the Kudos page.

## v1.8.1

- The setup's sharing step has a third choice: **Share with my friends** (friends list and Battle.net friends on your realm), next to party and guild.
- `/sks who` asks your online friends too, and prints each friend's answer (their version, and whether they share with friends).

## v1.8.0

- **Share with friends:** a new **My friends** switch (Friends page, off by default) shares your kills and deaths with characters on your friends list and Battle.net friends playing on your realm (or a connected one) and faction, one hidden addon whisper each (at most 10). Their kills show with their own **Friends' kills** settings (chat, combat text, sounds, deaths), and Kudos and Request help work with friends too. Only whispers from actual friends are shown.
- **Friends online** list on the Friends page: who's online, **Who runs it?** to see who has Spicy Kill Streaks (and whether they share), and per friend **Share with them** and **Show their kills**.
- **Mute players:** `/sks mute <name>` hides anyone's shared kills and deaths (party, guild or friends); the Friends page lists them with Unmute buttons.
- **Kill screenshots:** ganks now take one too when "Every kill" is on (they didn't), and every kill screenshot waits a moment so your callout and sparkles are in the picture.
- Debug log: screenshots now write whether the call worked and whether the game reports the screenshot as taken or failed (for tracking down kill screenshots not being taken).

## v1.7.0

- **Flag sounds** in Warsong Gulch (and captures in Eye of the Storm): Unreal Tournament style announcer lines when a flag is taken, dropped or returned (blue = Alliance, red = Horde), and "Blue team scores!" / "Red team scores!" on a capture. Only when the battleground's own lines are readable to addons. Switch them off under Announcer > Callouts; all eight are on the Sound board.
- **Kudos has its own settings page** (between Friends and Guild board), with a note at the top that it needs party or guild sharing on.
- **Kudos card width:** a **Card width** slider on the Kudos page makes the cards wider (or narrower), so longer names and text fit.
- **A nicer battleground summary:** a proper header with the chilli, bigger numbers in tiles with a coloured strip, the note under them, and the share buttons in a footer (no more text running into a button).

## v1.6.1

- **Ganks in a group:** killing a player 10+ levels below you now counts as a gank when you're in a group too. Before, a lower-level party member earning honor from the kill made it count as a normal kill.

## v1.6.0

- **Avenging is a Retribution:** kill the player who killed a guildmate who asked you for help, and it plays as a Retribution, with "You avenged <name>!". They get told straight away: "<you> avenged you! <killer> is down", once, even if your kill also reaches them in the feed.
- **More surprises:** a few special moments are no longer named or playable on the Sound board or in the settings (their switches stay, with neutral names), so you find out what they are in game.
- **New secrets** for long kill streaks (and one more for a certain kind of player). The Sound board says there are bonuses, not what they are.
- **The guild board stays in sync:** at login your board goes to the guild, and guildmates merge it, keeping the highest best streak, kills and deaths seen for each player (they only ever rise within a month, so the highest is the latest). They answer with just the entries where they know more, so everyone ends up with the same board, including players you were never online with. Your own numbers always come from you. Needs guild sharing on; nothing is sent from battlegrounds. Guildmates need 1.6.0 to take part.

## v1.5.0

- **The Kudos popup is smaller and gets out of the way sooner:** smaller cards and emoji, at most 3 cards at once, a friend's kill stays 20 seconds (was 30) and kudos you get 6 (was 8). A **Popup size** slider under Friends > Kudos makes it smaller or bigger still.
- **The Kudos popup sits on the left side of the screen** by default now, with a see-through move handle at the spot where cards appear: mouse over it and it shows, drag it to move the popup, any time (no cards or unlocking needed). Its spot is saved; Reset position puts it back on the left.
- **Kudos are on by default** now: the popup with emoji shows for your party and guild members' kills and deaths unless you switch it off under Friends > Kudos. (If you switched it off yourself before, it stays off.)
- **Request help:** when a player kills you in the open world, a card offers **Need help!**. One click asks your party and guild (as far as you share with them): friends running the addon get a card with who killed you and where (the zone; your map position too if you switch that on), a raid warning sound, and **On my way** and **Waypoint** buttons. You see who's coming. Once a minute at most. Optionally also posted as a chat line. Settings under Friends > Request help; `/sks aid` previews it.
- **AVENGED!** Kill the player who killed a friend who asked you for help, and you get an "AVENGED <friend>!" callout. When a friend kills whoever killed you lately, you see that they avenged you.
- Nothing is sent from battlegrounds or arenas, so help requests work in the open world only.

## v1.4.0

- The Kudos popup is narrower: the nine emoji sit in two rows (5 + 4).
- **Flag captures:** when the battleground announces that you captured a flag (Warsong Gulch, Eye of the Storm), you get a "FLAG CAPTURED!" callout and sparkles (no sound: the game plays its own), and the match summary counts it. Only when the game's line is readable and names you. Switch it off under Announcer > Callouts.
- **Kudos popup can grow upwards:** Friends > Kudos > **Grow upwards** stacks new cards up from the popup's spot instead of down (handy near the bottom of the screen).
- **Battleground kills are stricter, and named:** the best guess now counts a hidden killing blow only when your target, an enemy player you saw alive a moment before, disappears with it (the game clears a target the moment it dies). The victim is named, so Retribution and the rest work there too. A kill on someone you weren't targeting is missed; a party member's killing blow on your own target can still count (the game doesn't say which of you it was).
- **Battleground summary:** at the end of a battleground or arena match, a small card shows your killing blows and your best kill streak in that match. **Share to battleground** and **Share to guild** post it as one chat line ("{skull} Warsong Gulch: 11 killing blows, best kill streak 5"); nothing is posted unless you click. When the match ends, the killing blows come from the scoreboard; if you leave before the end, they're the addon's own count. Turn the card off under Announcer > Callouts; `/sks summary` shows a sample.

## v1.3.0

- **Kudos are emoji now:** 😂 😃 👍 👎 🙏 ☠️ 💀 ❤️ 🎉, the same nine for a friend's kill or death, in one row of icons. They show as pictures in the popup and in the combat text (WoW's fonts can't draw emoji, so they ship as images, from Twemoji). A kudos posted in chat uses words instead ("LOL!", "GG!", "<3", a {skull} marker...). Kudos from 1.1 and 1.2 still show; friends need 1.3.0 to see emoji kudos.

## v1.2.0

- **Friends' sounds are a little quieter:** sounds for party and guild members' kills and deaths play at about 75% of the volume of your own, so yours stand out.
- **Battlegrounds and arenas are just for you:** nothing is shared from them any more (WoW Forever blocks addon messages there for the whole match anyway, and it was spammy), Kudos included, and kills and deaths there don't count on the guild board. Your own announcer works as before.
- Elsewhere, a message the game refuses because of a short lock is held and sent when it lifts (for up to a minute). The debug log says why a message was refused.
- A kill with an unknown victim ("an enemy") can no longer set off Retribution.
- **Battleground kills are back (best guess).** WoW Forever now hides who landed a killing blow in battlegrounds, and the killing blows on the scoreboard. The addon now counts the hidden killing-blow event as your kill when you're alive, in combat, and an honorable kill for you comes with it. It may now and then count a party member's killing blow. The victim is your dead target, or "an enemy". Switch it off under Announcer > Callouts ("Battleground kills"). The debug log numbers each one, so you can compare with your killing blows on the scoreboard.
- Debug log: in battlegrounds it also writes what the game still lets addons read when the killing blows are hidden (your scoreboard row, honor, the hidden killing-blow event). `/sks note <text>` adds a marker to the log. It also reads your killing-blow character statistics; `/sks stats` shows them.

## v1.1.0

- **Ganks have a sound:** killing a player 10+ levels below you plays "Pint sized!", at most once a minute. Ganks in between play Headshot and Ownage in turn. Flamboyant keeps its own gank line.
- **Kudos:** react to your friends' kills and deaths. When a party or guild member running the addon gets a kill, a small popup offers **Zug zug!**, **For the Horde!** (or Alliance, your own faction), **Hell yeah!** and **Thumbs up!**; when they die, **RIP** and **F**. One click sends it to them only: it pops up on their screen with a running count ("+3"), and flashes in their combat text too (smaller and calmer than a kill). Kudos stack: each one after the first for the same kill comes in a bit bigger and warmer, with a small sparkle burst that grows too.
- **Kudos sounds** (the game's own): each kudos plays the sender's own `/cheer` (their race and sex), the 3rd for the same kill adds the legendary loot toast and the 5th the Azerite loot toast. RIP and F play Shadow Word: Pain. Switch them off under Friends > Kudos; **Preview kudos I get** and **Preview RIP / F** play them. Off by default: switch it on under Friends > Kudos. Getting kudos is on by default.
- Kudos can also be posted as a normal line in party or guild chat ("Zug zug! (to Bob for Rampage)"), which everyone sees. Off by default, at most one post every 15 seconds.
- Kudos follow your sharing settings: they go back the way the kill came (party or guild), only for kills and deaths from the last 30 seconds, one per kill or death, and only kudos for something you just did are shown.
- `/sks kudos` (or Friends > Kudos > Unlock to move) shows sample rows so you can drag the popup where you want it. **Preview kudos I get** (or `/sks kudos got`) shows what it looks like when friends send you some.

## v1.0.1

- Ganking someone plays Headshot until it has its own sound (it was silent). Flamboyant keeps its own.

Everything new in 1.0.0:

- **New settings window** (`/sks`): sections on the left (Announcer, Sound, Screen, Friends, Guild board, Extras, Sound board, About), a **live preview** at the top that shows your font, size and voice pack's words, and buttons for Test a kill, Stats and the Debug log. The old options window is still there: `/sks classic`.
- **New setup**: Welcome, Voice (click to hear each pack), Flair and font, Callouts, Friends, Ready. It opens once for everyone on their first login with 1.0.0, including players who set up an older version.
- **Minimap button** (the chilli): left-click for settings, right-click for a menu (snooze, settings, test, debug log), Shift-click to snooze or wake up, drag to move. It shows zZ while snoozed. Hide it from its menu or About; `/sks minimap` brings it back.
- **New rank ladder, one rank per kill:** Headshot 1 (First Blood once a day), Ownage 2, Killing Spree 3, Rampage 4, Dominating 5, Unstoppable 6, Wicked Sick 7, then **Godlike** from 8, the top tier with the biggest effects, on every kill after. The kill counts are fixed; the sliders are gone.
- **Ganks:** killing a player 10+ levels below you gets a bit of shame ("Bob ganked a level 12 Alice. Bully!") instead of a callout, and doesn't count towards your streak. Dying to a player 10+ levels above you (or "??") says "You got ganked by Bob (60)". Both only happen when the addon is sure: the levels were seen in the last few minutes, the other side is a player, and for your kill no honor came. Anything unclear plays as normal. Friends see your ganks too (with 1.0.0+). Both can be turned off under General.
- **Comeback:** your first kill after dying 3+ times in a row gets the Butcher: "Looks like meat's back on the menu, boys!" (the game's own sound). Turn it off under General.
- One Retribution in three is the Candle King: "You no take candle!" (the game's own sound).
- The game's own sounds (the Peon, the Candle King, the Butcher) play louder, to match the others.
- Getting ganked plays the Peon's "Me not that kind of orc!" (the game's own sound; Flamboyant has its own line).
- **Sound board** (`/sks` > Sound board): every sound with a play button, what it is and when it plays, in your voice pack. It plays even with sounds off, muted or snoozed.
- **About:** who makes the addon and where to send feedback.
- A couple of secrets at 10 and 20 kills in a row.
- **New voice pack: Flamboyant**, the Heroes of Newerth announcer. Cherry Poppah, Rainbow Warrior, Unicorn Stampede, It's a three-way... The callout text changes to match, in rainbow letters, and Godlike takes turns between Super Star, Diva and Fabulous.
- **Triple Kill** has its own voice in the male pack now.
- **Guild board:** your best kill streak and kills this month are shared with guildmates who run the addon (and share with the guild). At login, after the guildmate count, the top 3 killers of the month are listed. **Guild board** in the settings shows the top 10, with buttons to post the top 3 in guild or party chat. The board starts again on the 1st of each month. Turn the login line off under Sync. The board also counts deaths, and **Post to guild chat** sends one line with the top killers ("1. Panda (12)") and the most deaths (one line, because WoW Forever only lets an addon post once per click).
- **More fonts for the combat text:** eleven bundled fonts (Bangers, Luckiest Guy, Anton, Bebas Neue, Russo One, Black Ops One, Permanent Marker, Teko, Grandstander, Orbitron, Press Start 2P), Expressway when Daylight UI is installed, WoW's Narrow, and every font your other addons share through SharedMedia (ElvUI, Details...). Picking one shows a preview. The Fancy font is gone (it falls back to Classic). Restart the game after updating so WoW sees the new font files.
- **Debug log window:** `/sks debug` (or the box under Tests > Troubleshooting) opens a small, movable, resizable window where the detection details are written, with timestamps and the client version at the top. The text can be selected: **Select all**, then Ctrl+C to copy it (addons can't write to the clipboard themselves). **Clear** empties it; closing the window turns debug off.
- `/sks debug` now also shows who the Death Recap names when you die, how each kill's victim was found, and the Retribution check. `/sks recap` prints your last Death Recap.

## v1.0.0

- **New settings window** (`/sks`): sections on the left (Announcer, Sound, Screen, Friends, Guild board, Extras, Sound board, About), a **live preview** at the top that shows your font, size and voice pack's words, and buttons for Test a kill, Stats and the Debug log. The old options window is still there: `/sks classic`.
- **New setup**: Welcome, Voice (click to hear each pack), Flair and font, Callouts, Friends, Ready. It opens once for everyone on their first login with 1.0.0, including players who set up an older version.
- **Minimap button** (the chilli): left-click for settings, right-click for a menu (snooze, settings, test, debug log), Shift-click to snooze or wake up, drag to move. It shows zZ while snoozed. Hide it from its menu or About; `/sks minimap` brings it back.
- **New rank ladder, one rank per kill:** Headshot 1 (First Blood once a day), Ownage 2, Killing Spree 3, Rampage 4, Dominating 5, Unstoppable 6, Wicked Sick 7, then **Godlike** from 8, the top tier with the biggest effects, on every kill after. The kill counts are fixed; the sliders are gone.
- **Ganks:** killing a player 10+ levels below you gets a bit of shame ("Bob ganked a level 12 Alice. Bully!") instead of a callout, and doesn't count towards your streak. Dying to a player 10+ levels above you (or "??") says "You got ganked by Bob (60)". Both only happen when the addon is sure: the levels were seen in the last few minutes, the other side is a player, and for your kill no honor came. Anything unclear plays as normal. Friends see your ganks too (with 1.0.0+). Both can be turned off under General.
- **Comeback:** your first kill after dying 3+ times in a row gets the Butcher: "Looks like meat's back on the menu, boys!" (the game's own sound). Turn it off under General.
- One Retribution in three is the Candle King: "You no take candle!" (the game's own sound).
- The game's own sounds (the Peon, the Candle King, the Butcher) play louder, to match the others.
- Getting ganked plays the Peon's "Me not that kind of orc!" (the game's own sound; Flamboyant has its own line).
- **Sound board** (`/sks` > Sound board): every sound with a play button, what it is and when it plays, in your voice pack. It plays even with sounds off, muted or snoozed.
- **About:** who makes the addon and where to send feedback.
- A couple of secrets at 10 and 20 kills in a row.
- **New voice pack: Flamboyant**, the Heroes of Newerth announcer. Cherry Poppah, Rainbow Warrior, Unicorn Stampede, It's a three-way... The callout text changes to match, in rainbow letters, and Godlike takes turns between Super Star, Diva and Fabulous.
- **Triple Kill** has its own voice in the male pack now.
- **Guild board:** your best kill streak and kills this month are shared with guildmates who run the addon (and share with the guild). At login, after the guildmate count, the top 3 killers of the month are listed. **Guild board** in the settings shows the top 10, with buttons to post the top 3 in guild or party chat. The board starts again on the 1st of each month. Turn the login line off under Sync. The board also counts deaths, and **Post to guild chat** sends one line with the top killers ("1. Panda (12)") and the most deaths (one line, because WoW Forever only lets an addon post once per click).
- **More fonts for the combat text:** eleven bundled fonts (Bangers, Luckiest Guy, Anton, Bebas Neue, Russo One, Black Ops One, Permanent Marker, Teko, Grandstander, Orbitron, Press Start 2P), Expressway when Daylight UI is installed, WoW's Narrow, and every font your other addons share through SharedMedia (ElvUI, Details...). Picking one shows a preview. The Fancy font is gone (it falls back to Classic). Restart the game after updating so WoW sees the new font files.
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
