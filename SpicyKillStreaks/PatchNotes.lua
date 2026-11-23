-- Spicy Kill Streaks: the in-game patch notes (the Patch notes page, /sks news).
-- Newest first. Every release adds its notes here too: scripts/check-release.sh checks the
-- version is listed. Each line is { area, what changed }, short and in plain words.
local _, ns = ...

ns.patchNotes = {
	{
		version = "1.9.0", date = "2026-11-23",
		summary = "A KOS list with nemeses, the Zealot voice pack, BIG GAME HUNTER and patch notes in game.",
		new = {
			{ "KOS list", "Your kill-on-sight list, on its own page. Kill someone on it for GRUDGE SETTLED!" },
			{ "KOS list", "A player who kills you 3 times in a row becomes your nemesis: NEMESIS SLAIN! when you get them back" },
			{ "KOS list", "After a player kills you twice, a card offers Add to KOS; or /sks kos <name>" },
			{ "KOS list", "A warning when a listed player is your target, mouseover or on a nameplate" },
			{ "Zealot", "A new voice pack of holy-warrior taunts, as callouts too" },
			{ "Callouts", "BIG GAME HUNTER! for killing a player 10+ levels above you" },
			{ "Kudos", "New emoji: crying and clapping (the second skull is gone)" },
			{ "Guild board", "Mute and Unmute buttons next to each player" },
			{ "Patch notes", "This page: what changed in each version" },
		},
		fixed = {
			{ "Guild board", "Players with a family name are on it once, not twice" },
			{ "Tests", "Test a kill and Test death no longer change the kill streak you're on" },
			{ "Preview", "Show in game shows the sample you picked, in your voice pack's words" },
			{ "Muting", "A muted player's Kudos and help requests are hidden too" },
			{ "Friends", "Friends who are also guildmates aren't whispered while you share with the guild" },
			{ "Friends", "Questions to friends at login go out one every 2 seconds instead of all at once" },
		},
	},
	{
		version = "1.8.3", date = "2026-11-23",
		summary = "Your kills reach every friend who runs the addon.",
		new = {
			{ "Friends", "Kills go to every online friend with Spicy Kill Streaks, with no limit of 10" },
			{ "Friends", "The addon finds them by itself at login and when they come online" },
			{ "Friends", "Battle.net friends count too; /sks friends says why anyone is left out" },
		},
	},
	{
		version = "1.8.2", date = "2026-11-23",
		new = {
			{ "Kudos", "The popup fades out in combat and comes back after, so you can still react" },
		},
	},
	{
		version = "1.8.1", date = "2026-11-23",
		new = {
			{ "Setup", "The sharing step offers Share with my friends too" },
			{ "Friends", "/sks who asks your online friends as well" },
		},
	},
	{
		version = "1.8.0", date = "2026-11-23",
		summary = "Share your kills with friends, not just party and guild.",
		new = {
			{ "Friends", "My friends: share kills and deaths with friends on your realm and faction (off by default)" },
			{ "Friends", "A list of friends online, who runs the addon, and per-friend switches" },
			{ "Muting", "/sks mute <name> hides anyone's shared kills and deaths" },
		},
		fixed = {
			{ "Screenshots", "Ganks take one too, and kill screenshots wait so the callout is in the picture" },
		},
	},
	{
		version = "1.7.0", date = "2026-11-22",
		new = {
			{ "Battlegrounds", "Flag sounds in Warsong Gulch: taken, dropped, returned and scores" },
			{ "Kudos", "Its own settings page, and a Card width slider" },
			{ "Battlegrounds", "A nicer end-of-match summary" },
		},
	},
	{
		version = "1.6.1", date = "2026-11-22",
		fixed = {
			{ "Ganks", "Killing a much lower player counts as a gank in a group too" },
		},
	},
	{
		version = "1.6.0", date = "2026-11-22",
		new = {
			{ "Request help", "Avenging a friend who asked for help plays as a Retribution, and they're told" },
			{ "Secrets", "New secrets for long kill streaks (find them in game)" },
			{ "Guild board", "The board stays in sync between guildmates" },
		},
	},
	{
		version = "1.5.0", date = "2026-11-22",
		new = {
			{ "Request help", "Killed in the open world? Need help! asks your party and guild to come" },
			{ "Request help", "AVENGED! when you kill the player who killed a friend" },
			{ "Kudos", "Smaller, on the left of the screen, quicker to go, and on by default" },
		},
	},
	{
		version = "1.4.0", date = "2026-11-22",
		new = {
			{ "Battlegrounds", "FLAG CAPTURED! when you capture a flag" },
			{ "Battlegrounds", "A summary card at the end of a match, to share if you like" },
			{ "Kudos", "The popup can grow upwards" },
		},
		fixed = {
			{ "Battlegrounds", "Kills there are counted more carefully, and the victim is named" },
		},
	},
	{
		version = "1.3.0", date = "2026-11-22",
		new = {
			{ "Kudos", "Kudos are emoji now" },
		},
	},
	{
		version = "1.2.0", date = "2026-11-22",
		new = {
			{ "Sound", "Friends' sounds play a little quieter than yours" },
			{ "Battlegrounds", "Kills there count again (best guess, as the game hides them)" },
		},
		fixed = {
			{ "Battlegrounds", "Nothing is shared from battlegrounds and arenas any more" },
			{ "Retribution", "An unknown victim can't set it off" },
		},
	},
	{
		version = "1.1.0", date = "2026-11-22",
		new = {
			{ "Ganks", "Killing a player 10+ levels below you has its own sound" },
			{ "Kudos", "React to friends' kills and deaths with one click" },
		},
	},
	{
		version = "1.0.1", date = "2026-11-22",
		fixed = {
			{ "Ganks", "A gank plays a sound (it was silent)" },
		},
	},
	{
		version = "1.0.0", date = "2026-11-22",
		summary = "A new settings window, setup and minimap button.",
		new = {
			{ "Settings", "A new settings window with a live preview" },
			{ "Setup", "A quick setup to pick a voice, text and sharing" },
			{ "Flamboyant", "A new voice pack with rainbow callouts" },
			{ "Guild board", "This month's top killers in your guild" },
			{ "Sound board", "Hear every sound" },
		},
	},
}
