-- Spicy Kill Streaks: Kudos. When a party or guild member running the addon gets a kill or dies,
-- a small popup offers a reaction: one of nine emoji (laughing, smiling, thumbs up, thumbs down, praying
-- hands, skull and crossbones, skull, heart, party popper), the same for kills and deaths. The reaction travels as a hidden addon message on the channel the kill came
-- from, addressed to that player's GUID, so only they show it (on their own kudos popup).
-- Optionally it is also posted as a normal chat line, which everyone sees.
--
-- Talks to SpicyKillStreaks.lua through ns.core, and borrows the drawing kit from UI.lua.
--
-- Message: "R", version, target GUID, reaction id, "K"/"D", faction ("H"/"A"/"-"), race token ("Orc",
-- "Scourge" ... or "-"), sex ("2"/"3"/"-"), sender GUID
local ADDON, ns = ...

local kudos = {}
ns.kudos = kudos

local function core() return ns.core end
local function cfg() return ns.core.db().profile.kudos end
local function kit() return ns.ui and ns.ui.kit end

local SHOW_FOR = 20        -- seconds a friend's kill or death stays offered
local GOT_FOR = 6          -- seconds a kudos we got stays on screen
local ACCEPT_FOR = 180      -- kudos are accepted this long after our own kill or death (a friend may react after a fight)
local CHAT_COOLDOWN = 15   -- seconds between reaction posts in chat
local MAX_ROWS = 3       -- cards on screen at once (the oldest goes)
local ROW_W = 220        -- the default card width: the nine emoji go in two rows (5 + 4)
local ROW_W_MIN, ROW_W_MAX = 180, 380
local CHIPS_PER_LINE = 5
local PAD = 12          -- inside the card
local TEXT_X = 34       -- the title, right of the icon
local CHIP_H = 24
local CHIP_W = 28
local EMOJI_SIZE = 17
local CHIP_GAP = 4
local ROW_GAP = 5       -- between cards
local SLIDE = 0.18      -- seconds to slide in
local FADE = 0.35       -- seconds to fade out

-- Card colours: the stripe, icon tint and timer bar per kind of card
local TONES = {
	kill = { 0.95, 0.42, 0.18 },
	death = { 0.58, 0.64, 0.78 },
	got = { 1, 0.80, 0.30 },
	sent = { 0.45, 0.85, 0.50 },
	aid = { 1, 0.25, 0.22 },
}
local ICONS = {
	kill = "Interface\\AddOns\\SpicyKillStreaks\\Media\\Chilli",
	death = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
	got = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
	sent = "Interface\\RaidFrame\\ReadyCheck-Ready",
	aid = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
}

-- Reactions are emoji, the same nine for kills and deaths. WoW's fonts can't draw emoji, so each is
-- a Twemoji image in Media\Emoji\ (CC-BY 4.0, see LICENSE-GRAPHICS.txt there). chat: the words a
-- public chat post uses instead, since chat can't show images ({skull} is the raid marker).
local EMOJI_PATH = "Interface\\AddOns\\SpicyKillStreaks\\Media\\Emoji\\"
local REACTIONS = {
	laugh = { chat = "LOL!" },          -- face with tears of joy
	smile = { chat = "Nice!" },         -- grinning face
	thumbsup = { chat = "Thumbs up!" },
	thumbsdown = { chat = "Thumbs down!" },
	pray = { chat = "Respect!" },       -- folded hands
	crossbones = { chat = "RIP" },      -- skull and crossbones
	skull = { chat = "{skull}" },
	heart = { chat = "<3" },
	party = { chat = "GG!" },           -- party popper
}
local ORDER = { "laugh", "smile", "thumbsup", "thumbsdown", "pray", "crossbones", "skull", "heart", "party" }
-- Text reactions from 1.1.x and 1.2.x, still shown when an older version sends one
local LEGACY = { zug = "Zug zug!", hell = "Hell yeah!", thumbs = "Thumbs up!", rip = "RIP", f = "F" }
local FACTION_TEXT = { H = "For the Horde!", A = "For the Alliance!" }
kudos.REACTIONS, kudos.ORDER = REACTIONS, ORDER

-- An emoji as an inline texture; size 0 = the height of the text around it
local function emoji(id, size)
	return "|T" .. EMOJI_PATH .. id .. ":" .. (size or 0) .. "|t"
end
kudos.emoji = emoji

-- Sounds, all the game's own files (by file ID):
-- each kudos for a kill plays the sender's /cheer, for their race and sex (one of two at random)
local CHEERS = {
	Human = { [2] = { 540694, 540707 }, [3] = { 540628, 540610 } },
	Orc = { [2] = { 541435, 541404 }, [3] = { 541328, 541320 } },
	Dwarf = { [2] = { 540024, 540070 }, [3] = { 540014, 539977 } },
	NightElf = { [2] = { 541138, 541126 }, [3] = { 541043, 541055 } },
	Scourge = { [2] = { 542783, 542781 }, [3] = { 542697, 542691 } },
	Tauren = { [2] = { 543078, 543025 }, [3] = { 542976, 542985 } },
	Gnome = { [2] = { 540493, 540463 }, [3] = { 540434, 540445 } },
	Troll = { [2] = { 543331, 543330 }, [3] = { 543253, 543277 } },
	BloodElf = { [2] = { 539228, 539422 }, [3] = { 539322, 539232 } },
	Draenei = { [2] = { 539735, 539639 }, [3] = { 539598, 539601 } },
	Goblin = { [2] = { 541890, 542010 }, [3] = { 541792, 541848 } },
	Worgen = { [2] = { 542207, 542194 }, [3] = { 542062, 542081 } },
	Pandaren = { [2] = { 630064, 630066 }, [3] = { 636413, 636415 } },
}
-- the 3rd and 5th kudos for the same kill add a loot toast; kudos for a death play Shadow Word: Pain
local STACK_SOUNDS = { [3] = 1489461, [5] = 2174248 } -- legendary item toast, Azerite loot toast
local DEATH_SOUND = 568353                             -- shadowwordpain_chest
kudos.CHEERS, kudos.STACK_SOUNDS, kudos.DEATH_SOUND = CHEERS, STACK_SOUNDS, DEATH_SOUND

-- Our own race (the game's English token, "Orc", "Scourge" ...) and sex (2 male, 3 female)
local function myRaceAndSex()
	local race, sex
	if type(UnitRace) == "function" then
		local ok, _, token = pcall(UnitRace, "player")
		if ok and type(token) == "string" and CHEERS[token] then race = token end
	end
	if type(UnitSex) == "function" then
		local ok, value = pcall(UnitSex, "player")
		if ok and (value == 2 or value == 3) then sex = value end
	end
	return race, sex
end

-- A cheer for this race and sex, or nil (an unknown race, or one sent by a broken client)
local function cheerFor(race, sex)
	local voices = CHEERS[race]
	local list = voices and voices[sex]
	return list and list[math.random(#list)]
end
kudos.cheerFor = cheerFor

local MULTI_NAMES = { "Double Kill", "Triple Kill", "Multi Kill", "Mega Kill", "Ultra Kill", "Monster Kill",
	"Ludicrous Kill", "Holy Shit" }

-- Our own faction as "H", "A" or nil (neutral or unknown)
local function myFaction()
	if type(UnitFactionGroup) ~= "function" then return nil end
	local ok, faction = pcall(UnitFactionGroup, "player")
	if not ok then return nil end
	if faction == "Horde" then return "H" elseif faction == "Alliance" then return "A" end
	return nil
end

-- How a reaction shows on screen: its emoji, or an older version's words (faction: the sender's
-- "H"/"A", for its "For the ..."). nil for anything unknown.
local function reactionText(id, faction)
	if REACTIONS[id] then return emoji(id) end
	if id == "faction" then return FACTION_TEXT[faction] end
	return LEGACY[id]
end
kudos.reactionText = reactionText

-- A GUID from another player's message: only a plain "Player-..." string is used
local function cleanGUID(guid)
	if type(guid) ~= "string" or #guid > 40 then return nil end
	if not guid:match("^Player%-[%w%-]+$") then return nil end
	return guid
end

-- What the friend did, in a few words: "Killing Spree", "Double Kill", "killed by Bob"
local function deedText(info)
	if info.kind == "D" then
		if info.pancake then return "pancaked" end
		if info.duel then return "lost a duel to " .. info.other end
		if info.ganked then return "got ganked by " .. info.other end
		return "killed by " .. info.other
	end
	if info.kind == "U" then return "won a duel" end
	if (info.multi or 0) > 0 then return MULTI_NAMES[info.multi] or "a multikill" end
	local names = core().rankNames
	if (info.rank or 0) > 0 and names[info.rank] then return names[info.rank] end
	if (info.streak or 0) > 1 then return info.streak .. " in a row" end
	return "a kill"
end
kudos.deedText = deedText

-- ---------------------------------------------------------------------------------------------
-- The popup: a movable stack of small cards. A friend's card has reaction chips and a timer bar;
-- a kudos we got is one line with a "+n" badge. Cards slide in and fade out.
-- ---------------------------------------------------------------------------------------------
local holder, rows, mover = nil, {}, nil
kudos.rows = rows -- (for the smoke test)

-- The stack grows down from its anchor line (the default), or up from it (cfg().growup): then the
-- newest card sits at the anchor and pushes the older ones up
local function growsUp() return cfg().growup and true or false end

-- The card width the player chose (the Kudos settings page)
local function rowW()
	return math.min(math.max(tonumber(cfg().width) or ROW_W, ROW_W_MIN), ROW_W_MAX)
end

local function place()
	if not holder then return end
	holder:ClearAllPoints()
	-- From the left edge of the screen (lx: to the stack's middle) and its vertical middle (ly), in
	-- screen units; the offsets are in the holder's own (scaled) units
	local scale = tonumber(cfg().scale) or 0.85
	holder:SetScale(scale)
	holder:SetPoint(growsUp() and "BOTTOM" or "TOP", UIParent, "LEFT", (cfg().lx or 150) / scale, (cfg().ly or 120) / scale)
	if kudos.grip then
		-- the move handle sits at the anchor line, on the side away from the cards
		kudos.grip:ClearAllPoints()
		if growsUp() then
			kudos.grip:SetPoint("TOP", holder, "BOTTOM", 0, -2)
		else
			kudos.grip:SetPoint("BOTTOM", holder, "TOP", 0, 2)
		end
	end
	if mover then
		mover:ClearAllPoints()
		-- the drag bar sits on the far side of the anchor line from the cards
		if growsUp() then
			mover:SetPoint("TOP", holder, "BOTTOM", 0, -4)
		else
			mover:SetPoint("BOTTOM", holder, "TOP", 0, 4)
		end
	end
end
kudos.place = place

local function layout()
	local y, up = 0, growsUp()
	for i = up and #rows or 1, up and 1 or #rows, up and -1 or 1 do
		local row = rows[i]
		row:ClearAllPoints()
		if up then
			row:SetPoint("BOTTOM", holder, "BOTTOM", row.dx or 0, y)
		else
			row:SetPoint("TOP", holder, "TOP", row.dx or 0, -y)
		end
		y = y + row.height + ROW_GAP
	end
	holder:SetHeight(math.max(y, 1))
end
kudos.layout = layout

local function removeRow(row)
	for i, r in ipairs(rows) do
		if r == row then
			table.remove(rows, i)
			break
		end
	end
	row:Hide()
	row:SetScript("OnUpdate", nil)
	layout()
end

local function ensureHolder()
	if holder then return holder end
	holder = CreateFrame("Frame", "SpicyKillStreaksKudos", UIParent)
	holder:SetSize(rowW(), 1)
	holder:SetFrameStrata("MEDIUM")
	holder:SetClampedToScreen(true)
	holder:SetMovable(true)
	place()
	kudos.makeGrip()
	return holder
end

local function fontString(parent, size, r, g, b)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "")
	fs:SetShadowOffset(1, -1)
	fs:SetShadowColor(0, 0, 0, 0.8)
	fs:SetTextColor(r or 1, g or 1, b or 1)
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(false) -- one line: a long name is cut off rather than run into the chips
	return fs
end

-- Restyle a card for a kind ("kill", "death", "got", "sent"): stripe, icon and timer colours
local function setTone(row, tone)
	local c = TONES[tone] or TONES.kill
	row.stripe:SetColorTexture(c[1], c[2], c[3], 1)
	row.bar:SetColorTexture(c[1], c[2], c[3], 0.75)
	row.icon:SetTexture(ICONS[tone] or ICONS.kill)
	row.tone = tone
end

local function newRow(height, tone)
	ensureHolder()
	local row = CreateFrame("Frame", nil, holder, "BackdropTemplate")
	row.w = rowW()
	row:SetSize(row.w, height)
	row:EnableMouse(true)
	row.height = height
	row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	row:SetBackdropColor(0.06, 0.05, 0.045, 0.90)
	row:SetBackdropBorderColor(0.24, 0.20, 0.17, 1)
	-- a soft lighter band at the top, for a little depth
	local sheen = row:CreateTexture(nil, "BACKGROUND", nil, 1)
	sheen:SetPoint("TOPLEFT", 1, -1)
	sheen:SetPoint("TOPRIGHT", -1, -1)
	sheen:SetHeight(16)
	sheen:SetColorTexture(1, 1, 1, 0.03)
	row.stripe = row:CreateTexture(nil, "ARTWORK")
	row.stripe:SetPoint("TOPLEFT", 1, -1)
	row.stripe:SetPoint("BOTTOMLEFT", 1, 1)
	row.stripe:SetWidth(3)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(16, 16)
	row.icon:SetPoint("TOPLEFT", PAD, -8)
	row.bar = row:CreateTexture(nil, "ARTWORK")
	row.bar:SetPoint("BOTTOMLEFT", 4, 1)
	row.bar:SetHeight(2)
	row.bar:Hide()
	row.label = fontString(row, 12)
	row.label:SetPoint("TOPLEFT", TEXT_X, -9)
	row.label:SetPoint("RIGHT", -26, 0) -- (further in when the "+n" badge shows)
	-- "+n" badge on the right (kudos we got)
	row.badge = CreateFrame("Frame", nil, row, "BackdropTemplate")
	row.badge:SetSize(30, 18)
	row.badge:SetPoint("TOPRIGHT", -26, -7)
	row.badge:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
	row.badge:SetBackdropColor(1, 0.80, 0.30, 0.95)
	row.badge.text = fontString(row.badge, 11, 0.12, 0.08, 0.04)
	row.badge.text:SetPoint("CENTER", 0, 0)
	row.badge.text:SetJustifyH("CENTER")
	row.badge:Hide()
	-- a small close cross
	local close = CreateFrame("Button", nil, row)
	close:SetSize(18, 18)
	close:SetPoint("TOPRIGHT", -5, -6)
	close.text = fontString(close, 12, 0.55, 0.5, 0.46)
	close.text:SetPoint("CENTER", 0, 0)
	close.text:SetText("x")
	close:SetScript("OnEnter", function() close.text:SetTextColor(1, 1, 1) end)
	close:SetScript("OnLeave", function() close.text:SetTextColor(0.55, 0.5, 0.46) end)
	close:SetScript("OnClick", function() removeRow(row) end)
	setTone(row, tone)
	-- Keep at most MAX_ROWS: the oldest goes
	if #rows >= MAX_ROWS then removeRow(rows[1]) end
	rows[#rows + 1] = row
	row.age, row.dx = 0, 24
	row:SetAlpha(0)
	row:Show()
	layout()
	return row
end

-- The "+n" badge: shown from 2
local function setBadge(row, count)
	if count and count > 1 then
		row.badge.text:SetText("+" .. count)
		row.badge:SetWidth(math.max(26, (row.badge.text:GetStringWidth() or 14) + 12))
		row.badge:Show()
		row.label:SetPoint("RIGHT", -26 - row.badge:GetWidth() - 4, 0)
	else
		row.badge:Hide()
		row.label:SetPoint("RIGHT", -26, 0)
	end
end

-- Slide in, then after `seconds` fade out and go; with a timer bar along the bottom when bar is set
local function expireAfter(row, seconds, bar)
	row.left, row.total = seconds, seconds
	row.bar:SetShown(bar and true or false)
	row:SetScript("OnUpdate", function(self, elapsed)
		elapsed = elapsed or 0
		self.age = (self.age or 0) + elapsed
		self.left = self.left - elapsed
		-- slide in from the right while fading in
		local t = math.min(self.age / SLIDE, 1)
		local dx = 24 * (1 - t) * (1 - t)
		if math.abs(dx - (self.dx or 0)) > 0.1 or (dx == 0 and self.dx ~= 0) then
			self.dx = dx
			layout()
		end
		local alpha = t
		if self.left < FADE then alpha = math.max(self.left / FADE, 0) end
		self:SetAlpha(alpha)
		if self.bar:IsShown() then
			self.bar:SetWidth(math.max(1, ((self.w or ROW_W) - 6) * math.max(self.left, 0) / self.total))
		end
		if self.left <= 0 then removeRow(self) end
	end)
end

-- A reaction chip: a small dark square with the emoji, a warm border and a little pop on hover
local function makeChip(row, id, onClick)
	local b = CreateFrame("Button", nil, row, "BackdropTemplate")
	b:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	b:SetBackdropColor(0.15, 0.12, 0.10, 1)
	b:SetBackdropBorderColor(0.32, 0.26, 0.22, 1)
	b:SetSize(CHIP_W, CHIP_H)
	b.icon = b:CreateTexture(nil, "ARTWORK")
	b.icon:SetTexture(EMOJI_PATH .. id)
	b.icon:SetSize(EMOJI_SIZE, EMOJI_SIZE)
	b.icon:SetPoint("CENTER", 0, 0)
	b:SetScript("OnEnter", function()
		local c = TONES[row.tone] or TONES.kill
		b:SetBackdropBorderColor(c[1], c[2], c[3], 1)
		b:SetBackdropColor(0.22, 0.17, 0.13, 1)
		b.icon:SetSize(EMOJI_SIZE + 4, EMOJI_SIZE + 4)
	end)
	b:SetScript("OnLeave", function()
		b:SetBackdropBorderColor(0.32, 0.26, 0.22, 1)
		b:SetBackdropColor(0.15, 0.12, 0.10, 1)
		b.icon:SetSize(EMOJI_SIZE, EMOJI_SIZE)
	end)
	b:SetScript("OnClick", onClick)
	return b
end

-- ---------------------------------------------------------------------------------------------
-- Giving kudos
-- ---------------------------------------------------------------------------------------------
local lastChatPost = -CHAT_COOLDOWN

-- The chat channel a friend's message came through, for a public post: party/raid/battleground
-- as it is now, or the guild
local function chatChannelFor(info)
	if info.channel == "WHISPER" then return nil end -- a friend's kill: no public post
	if info.channel == "GUILD" then return core().inGuild() and "GUILD" or nil end
	return core().groupChannel()
end

local function send(row, info, id)
	if row.sent then return end
	row.sent = true
	local faction = myFaction()
	local words = REACTIONS[id] and REACTIONS[id].chat or "?"
	if not info.preview then
		local sync = core().db().profile.sync
		local channel
		if info.channel == "GUILD" then
			if sync.shareguild and core().inGuild() then channel = "GUILD" end
		elseif sync.shareparty then
			channel = core().groupChannel()
		end
		local race, sex = myRaceAndSex()
		local message = table.concat({ "R", core().VERSION, info.guid, id, info.kind == "D" and "D" or "K",
			faction or "-", race or "-", sex and tostring(sex) or "-", core().playerGUID() or "" }, "\t")
		if info.channel == "WHISPER" then
			-- a friend's kill: straight back to them (Friends.lua)
			if ns.friends then ns.friends.reply(info.sender, message) end
		elseif channel then
			core().sendAddonMessage(message, channel)
		end
		-- A public line too, when switched on. This runs in the click itself: WoW Forever only lets
		-- an addon post to chat from a click or key press.
		if cfg().chat and GetTime() - lastChatPost >= CHAT_COOLDOWN then
			local chatChannel = chatChannelFor(info)
			if chatChannel then
				lastChatPost = GetTime()
				pcall(SendChatMessage, words .. " (to " .. info.who .. " for " .. deedText(info) .. ")", chatChannel)
			end
		end
	end
	for _, b in ipairs(row.buttons or {}) do b:Hide() end
	setTone(row, "sent")
	row.label:SetText("|cff9a8f86Sent|r " .. emoji(id) .. " |cff9a8f86to|r " .. info.who
		.. (info.preview and " |cff9a8f86(preview)|r" or ""))
	row.height = 32
	row:SetHeight(32)
	layout()
	expireAfter(row, 2.5, false)
end
kudos.send = send

local function offer(info)
	local row = newRow(62, info.kind == "D" and "death" or "kill")
	row.info = info
	local deed = deedText(info)
	if info.kind == "D" then
		row.label:SetText("|cffffffff" .. info.who .. "|r  |cff9aa3b8" .. deed .. "|r")
	else
		row.label:SetText("|cffffffff" .. info.who .. "|r  |cffff8a4a" .. deed .. "!|r")
	end
	row.buttons = {}
	-- Chips flow left to right and wrap onto another line if the card is full
	local x, line = PAD, 0
	for i, id in ipairs(ORDER) do
		local b = makeChip(row, id, function() send(row, info, id) end)
		if i > 1 and ((i - 1) % CHIPS_PER_LINE == 0 or x + CHIP_W > row.w - PAD) then
			x, line = PAD, line + 1
		end
		b:SetPoint("TOPLEFT", x, -31 - line * (CHIP_H + CHIP_GAP))
		x = x + CHIP_W + CHIP_GAP
		row.buttons[#row.buttons + 1] = b
	end
	row.height = 31 + (line + 1) * (CHIP_H + CHIP_GAP) + 5
	row:SetHeight(row.height)
	layout()
	expireAfter(row, SHOW_FOR, true)
	return row
end
kudos.offer = offer

-- A friend killed or died (from SpicyKillStreaks.lua's feed, already checked and de-duplicated)
function kudos.allyEvent(info)
	-- A friend's kill of whoever killed us lately: "AVENGED" (Aid.lua), whatever the Kudos setting
	if ns.aid then pcall(ns.aid.allyKill, info) end
	if not cfg().give then return end
	info.guid = cleanGUID(info.guid)
	if not info.guid or not info.who then return end -- older versions without a GUID: nowhere to send it
	-- Reactions go back the way the kill came, so only offer them where we share
	local sync = core().db().profile.sync
	if info.channel == "GUILD" then
		if not sync.shareguild then return end
	elseif info.channel == "WHISPER" then
		if not sync.sharefriends then return end
	elseif not sync.shareparty then
		return
	end
	info.who = info.who:gsub("%-.*$", "") -- no realm: "Bob", not "Bob-Realm"
	if info.kind == "T" then info.who = info.who .. " (test)" end
	offer(info)
end

-- ---------------------------------------------------------------------------------------------
-- Getting kudos
-- ---------------------------------------------------------------------------------------------
-- Our latest shared kill and death: { at = GetTime(), from = { [sender] = true }, count, what }
local own = {}
kudos.own = own

function kudos.ownEvent(kind, what)
	own[kind] = { at = GetTime(), from = {}, count = 0, what = what }
end

local function ownDeedText(kind, what)
	if kind == "D" then return "death" end
	if type(what) == "string" then
		local m = tonumber(what:match("^m(%d+)$"))
		if m and MULTI_NAMES[m] then return MULTI_NAMES[m] end
		local r = tonumber(what:match("^r(%d+)$"))
		if r and core().rankNames[r] then return core().rankNames[r] end
	end
	return "kill"
end

function kudos.receive(sender, channel, fields)
	if not cfg().receive then return end
	if ns.friends and ns.friends.isMuted(sender) then return end -- muted: nothing from them (Friends.lua)
	if #fields < 7 then return end
	local me = core().playerGUID()
	if not me or fields[3] ~= me then return end -- for someone else
	local id, kind, faction = fields[4], fields[5], fields[6]
	if kind ~= "K" and kind ~= "D" then return end
	if faction ~= "H" and faction ~= "A" then faction = nil end
	local words = reactionText(id, faction)
	if not words then return end
	-- Only for something we just did, and once per player for it
	local event = own[kind]
	if not event or GetTime() - event.at > ACCEPT_FOR then return end
	local key = core().safeText(sender)
	if not key or event.from[key] then return end
	event.from[key] = true
	event.count = event.count + 1
	cfg().got = (tonumber(cfg().got) or 0) + 1
	local who = (core().safeText(core().shortName(sender)) or "Someone"):gsub("%-.*$", "")
	-- The sender's race and sex pick their cheer (only names in CHEERS are used)
	local race, sex = fields[7], tonumber(fields[8])
	if #fields < 9 or not CHEERS[race] then race, sex = nil, nil end
	kudos.showGot(who, words, ownDeedText(kind, event.what), event.count, { kind = kind, race = race, sex = sex })
end

-- The sounds for a kudos we got: their cheer (kill) or Shadow Word: Pain (death), plus a loot toast
-- on the 3rd and 5th kudos for the same kill. forced: a preview, which plays even when muted.
local function playKudosSound(sound, count, forced)
	if not sound or not cfg().sound then return end
	local special = core().special
	local play = forced and special.playForced or core().playSound
	-- Played once, at the game's own volume: kudos are a quiet moment, unlike the announcer
	special.soundOnce = true
	pcall(function()
		if sound.kind == "D" then
			play(DEATH_SOUND)
			return
		end
		local cheer = cheerFor(sound.race, sound.sex)
		if cheer then play(cheer) end
		if STACK_SOUNDS[count] then play(STACK_SOUNDS[count]) end
	end)
	special.soundOnce = false
end
kudos.playKudosSound = playKudosSound

-- One kudos we got: "Bob <emoji> your Rampage +3". sound: { kind, race, sex } or nil
function kudos.showGot(who, words, deed, count, sound, forced)
	playKudosSound(sound, count, forced)
	local row = newRow(32, "got")
	row.label:SetText("|cffffd04d" .. who .. "|r  " .. words .. "  |cff8a8079your " .. deed .. "|r")
	setBadge(row, count)
	expireAfter(row, GOT_FOR, false)
	-- and a line in the combat text: calm for the first, a bit bigger and warmer with each one
	-- after it for the same kill, with a small sparkle burst from the second
	if core().db().profile.doscreen then
		core().showText(who .. ": " .. words .. (count > 1 and ("  +" .. count) or ""), "kudos", count)
		core().celebrate("kudos", count)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Moving it, and a preview
-- ---------------------------------------------------------------------------------------------
function kudos.unlock(on)
	ensureHolder()
	if not mover then
		mover = CreateFrame("Frame", nil, holder, "BackdropTemplate")
		mover:SetSize(rowW(), 24)
		mover:SetFrameLevel((holder:GetFrameLevel() or 1) + 20)
		local k = kit()
		if k then k.paint(mover, k.COLORS.accent, 0.35, k.COLORS.accent) end
		local label = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("CENTER")
		label:SetText("Kudos popup: drag here")
		mover:EnableMouse(true)
		mover:RegisterForDrag("LeftButton")
		mover:SetScript("OnDragStart", kudos.startDrag)
		mover:SetScript("OnDragStop", kudos.stopDrag)
		place()
	end
	mover:SetShown(on and true or false)
end

-- Dragging, from the drag bar or any card: the whole stack moves, and its spot is saved
function kudos.startDrag()
	if holder then
		holder.isMoving = true
		holder:StartMoving()
	end
end

function kudos.stopDrag()
	if not holder then return end
	holder:StopMovingOrSizing()
	holder.isMoving = false
	local x = holder:GetCenter()
	local edge = growsUp() and holder:GetBottom() or holder:GetTop()
	local left, uy = UIParent:GetLeft() or 0, select(2, UIParent:GetCenter())
	local scale = holder:GetScale() or 1
	if x and edge and uy then
		cfg().lx, cfg().ly = math.floor(x * scale - left + 0.5), math.floor(edge * scale - uy + 0.5)
	end
	place()
end

-- The move handle: a slim bar at the spot where cards appear, on the side away from the cards (so it
-- never covers one). Mostly see-through and only while the mouse is over it; there whether or not
-- cards are showing.
function kudos.makeGrip()
	if kudos.grip or not holder then return end
	local grip = CreateFrame("Frame", "SpicyKillStreaksKudosHandle", holder, "BackdropTemplate")
	grip:SetSize(rowW(), 14)
	grip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
	grip:SetBackdropColor(0.95, 0.55, 0.3, 0.35)
	local dots = grip:CreateFontString(nil, "OVERLAY")
	dots:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "")
	dots:SetTextColor(1, 0.9, 0.8)
	dots:SetPoint("CENTER", 0, 0)
	dots:SetText("drag to move kudos")
	grip:SetAlpha(0)
	grip:EnableMouse(true)
	grip:RegisterForDrag("LeftButton")
	grip:SetScript("OnEnter", function(self) self:SetAlpha(0.8) end)
	grip:SetScript("OnLeave", function(self) if not holder.isMoving then self:SetAlpha(0) end end)
	grip:SetScript("OnDragStart", function() kudos.startDrag() end)
	grip:SetScript("OnDragStop", function(self)
		kudos.stopDrag()
		if not self:IsMouseOver() then self:SetAlpha(0) end
	end)
	kudos.grip = grip
	place()
end

-- At login (UI.lua): make the popup and its handle, so the handle is there before any card
function kudos.init()
	ensureHolder()
end

-- The card width (new cards use it; the handle and the drag bar follow at once)
function kudos.setWidth(value)
	cfg().width = math.min(math.max(math.floor(tonumber(value) or ROW_W), ROW_W_MIN), ROW_W_MAX)
	if holder then holder:SetWidth(rowW()) end
	if kudos.grip then kudos.grip:SetWidth(rowW()) end
	if mover then mover:SetWidth(rowW()) end
	place()
end

-- The popup's size (a scale, 0.6 to 1.2)
function kudos.setScale(value)
	cfg().scale = math.min(math.max(tonumber(value) or 0.85, 0.6), 1.2)
	place()
end

-- Switch the growing direction: the anchor line stays where it is
function kudos.setGrowUp(up)
	cfg().growup = up and true or false
	place()
	if holder then layout() end
end

function kudos.isUnlocked() return mover and mover:IsShown() or false end

function kudos.resetPosition()
	local d = core().defaults.profile.kudos
	cfg().lx, cfg().ly = d.lx, d.ly
	place()
end

-- Sample rows: a friend's kill, a friend's death and a kudos we got. Clicks send nothing.
function kudos.preview()
	offer({ kind = "K", who = "Bob", other = "Alice", rank = 2, multi = 0, streak = 3, preview = true })
	offer({ kind = "D", who = "Panda", other = "Orcbro", preview = true })
	kudos.showGot("Bob", emoji("party"), "Rampage", 2)
end

-- What getting kudos looks like: five friends reacting to a Rampage, each one stacking up
function kudos.previewGot()
	local sample = {
		{ "Bob", emoji("thumbsup"), "Orc", 2 },
		{ "Panda", emoji("laugh"), "Pandaren", 3 },
		{ "Alice", emoji("heart"), "Human", 3 },
		{ "Grug", emoji("party"), "Tauren", 2 },
		{ "Mira", emoji("smile"), "Gnome", 3 },
	}
	for i, entry in ipairs(sample) do
		C_Timer.After((i - 1) * 1.4, function()
			kudos.showGot(entry[1], entry[2], "Rampage", i, { kind = "K", race = entry[3], sex = entry[4] }, true)
		end)
	end
end

-- A friend paying respects when we die
function kudos.previewDeath()
	kudos.showGot("Panda", emoji("pray"), "death", 1, { kind = "D" }, true)
end

-- Hidden in combat (cfg().combathide): the whole popup fades out when combat starts, and back
-- in after it. Cards don't count down while hidden (hidden frames don't run their timers), so
-- they pick up where they left off.
local FADE_TIME = 0.3
local fader = CreateFrame("Frame")
local fadeTo, fading
fader:SetScript("OnUpdate", function(self, elapsed)
	if not holder or not fadeTo then self:Hide() return end
	local a = holder:GetAlpha() or 1
	local step = (elapsed or 0) / FADE_TIME
	a = fadeTo > a and math.min(a + step, fadeTo) or math.max(a - step, fadeTo)
	holder:SetAlpha(a)
	if a == fadeTo then
		if fadeTo == 0 then holder:Hide() end
		fadeTo = nil
		self:Hide()
	end
end)
fader:Hide()

local function fadeHolder(target)
	if not holder then return end
	if target > 0 then holder:Show() end
	fadeTo = target
	fader:Show()
end
kudos.fadeHolder = fadeHolder

local combat = CreateFrame("Frame")
combat:RegisterEvent("PLAYER_REGEN_DISABLED")
combat:RegisterEvent("PLAYER_REGEN_ENABLED")
combat:SetScript("OnEvent", function(_, event)
	if not (ns.core and ns.core.db()) then return end
	if event == "PLAYER_REGEN_DISABLED" then
		if cfg().combathide then fadeHolder(0) end
	else
		fadeHolder(1)
	end
end)

function kudos.clear()
	while #rows > 0 do removeRow(rows[1]) end
end

-- The card stack for Aid.lua (help requests share the popup)
kudos.cards = {
	newRow = newRow, setTone = setTone, expireAfter = expireAfter, layout = layout, removeRow = removeRow,
	fontString = fontString, PAD = PAD, TEXT_X = TEXT_X,
}
