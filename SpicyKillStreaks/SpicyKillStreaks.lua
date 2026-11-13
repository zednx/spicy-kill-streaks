-- Spicy Kill Streaks
--
-- Announcer sounds and text for killing blows, killing sprees and multikills on WoW Forever
-- (interface 16001). Based on dG KillShot by Lance Inman (GPL v2, see LICENSE.txt); the voice packs
-- in sounds\ come from that addon.
--
-- WoW Forever does not give addons the combat log, so kills are detected like this:
--   Battlegrounds and arenas  PLAYER_PVP_KILLS_CHANGED asks for the scoreboard, and a rise in our
--                             killing blows on it is a kill.
--   Elsewhere                 PARTY_KILL, which names who landed the killing blow. Where it does
--                             not arrive, our target dying while we fight it counts (NPC option).
--   Our own death             PLAYER_DEAD, with the killer taken from the Death Recap.
--   Duels                     the system chat lines "X has defeated Y in a duel" / "Y has fled".

local ADDON = "SpicyKillStreaks"
local TITLE = "Spicy Kill Streaks"
local VERSION = "0.1.1"

local SOUND_ROOT = "Interface\\AddOns\\" .. ADDON .. "\\sounds\\"
-- Voice pack -> folder under sounds\ ("" = sounds\ itself)
-- "custom" holds files the player adds (sounds\custom\humiliation.ogg, ...); anything missing
-- there falls back to sounds\
-- "humiliation" only has humiliation (the default humiliation voice).
local PACK_FOLDER = { male = "", female = "female\\", sexy = "sexy\\", baby = "baby\\", humiliation = "humiliation\\", custom = "custom\\" }
-- Files a voice pack does not ship; these are played from sounds\ instead
local PACK_MISSING = { baby = { ["monsterkill.ogg"] = true } }

local RANK_NAMES = { "Ownage", "Killing Spree", "Rampage", "Dominating", "Unstoppable", "Godlike", "Wicked Sick" }
local RANK_SOUNDS = { "ownage.ogg", "killingspree.ogg", "rampage.ogg", "dominating.ogg", "unstoppable.ogg", "godlike.ogg", "whickedsick.ogg" }
local MULTI_TEXTS = { "DOUBLE KILL!", "MULTI KILL!", "MEGA KILL!", "ULTRA KILL!!!", "MONSTER KILL!!!", "LUDICROUS KILL!!!", "H O L Y  S H I T!!!" }
local MULTI_SOUNDS = { "doublekill.ogg", "multikill.ogg", "megakill.ogg", "ultrakill.ogg", "monsterkill.ogg", "ludicrouskill.ogg", "holyshit.ogg" }
local SOUND_PREPARE = "prepare.ogg"
local SOUND_EXECUTE = "finishhim.ogg"
local SOUND_HUMILIATION = "humiliation.ogg"

local MULTIKILL_WINDOW = 10       -- seconds between kills that still chain into a multikill
local LOG_LIMIT = 20
local UNKNOWN_VICTIM = "an enemy" -- the scoreboard says that we killed, not whom

local EMOTES = {
	none = "None", APPLAUD = "Applaud", BOW = "Bow", BYE = "Bye", CACKLE = "Cackle", CHEER = "Cheer",
	CHICKEN = "Chicken", CHUCKLE = "Chuckle", CLAP = "Clap", CRY = "Cry", DANCE = "Dance", FLEX = "Flex",
	GLOAT = "Gloat", GOLFCLAP = "Golf Clap", GRIN = "Grin", GUFFAW = "Guffaw", INSULT = "Insult",
	KISS = "Kiss", LAUGH = "Laugh", MOCK = "Mock", MOURN = "Mourn", NO = "No", PITY = "Pity", POINT = "Point",
	ROAR = "Roar", ROFL = "ROFL", RUDE = "Rude", SALUTE = "Salute", SHRUG = "Shrug", SIGH = "Sigh",
	SPIT = "Spit", TAUNT = "Taunt", THANK = "Thank", VICTORY = "Victory", VIOLIN = "Violin", WAVE = "Wave",
	YAWN = "Yawn",
}

local defaults = {
	global = {
		setupDone = false, -- the first-run setup has been finished or skipped (account-wide)
	},
	profile = {
		-- kills
		style = "dota",          -- "dota": a sound on every kill, "ut": on the first kill and every utrank kills
		utrank = 3,
		ksrank = { 1, 2, 4, 6, 8, 10, 12 }, -- kills needed for each rank (0 = rank off)
		dopve = false,
		dozonechange = false,
		-- sound
		dosound = true,
		soundpack = "male",
		soundchannel = "Master",
		doprepare = false,
		dodeathsound = true, -- "humiliation" when we die
		humiliationvoice = "humiliation", -- the bundled one, or "pack" = the chosen voice pack, or male / female / sexy / baby / custom
		doexecute = false,
		doexecutepve = false,
		executepercent = 25,
		-- text
		dochat = true,
		doscreen = true,
		kstext = "$k killed $v!",
		dueltext = "$k has defeated $v!",
		-- emotes
		doemote = "none",
		dotxtemote = false,
		ksemote = "has killed $v! Streak of $s!",
		duelemotewin = "BOW",
		duelemoteloss = "BOW",
		duelhumiliation = true,
		-- screenshots
		shotkill = false,
		shotstreak = false,
		shotmultikill = false,
		shotduelwin = false,
		shotduelloss = false,
		shotdeath = false,
		-- on-screen effects
		fx = {
			fancytext = true,   -- animated text (off: plain red lines)
			font = "impact",
			sparkles = true,
			sparklestyle = "mix",
			sparklecount = 30,
			flash = true,       -- screen-edge flash on multikills and big streaks
			scale = 1,
			x = 0,
			y = 180,
		},
		-- party and guild sync with other Spicy Kill Streaks users
		sync = {
			-- Sharing is opt-in: nothing is sent until one of these is switched on
			shareparty = false, -- party, raid, battleground and arena
			shareguild = false,
			logincount = true,  -- at login, one chat line: how many guildmates use the addon
			-- What to do with kills and deaths shared by others
			--   feed: a line in the chat window   sound: their streak / multikill sound
			--   text: on-screen combat text       deaths: also show when they die
			party = { feed = true, sound = true, text = true, deaths = false },
			guild = { feed = true, sound = false, text = false, deaths = false },
		},
		-- stats
		maxstreak = 0,
		maxdeathstreak = 0,
		log = {},
		kills = {},  -- victim -> { count, last }
		deaths = {}, -- killer -> { count, last }
	},
}

-- ---------------------------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------------------------
local db
local frame = CreateFrame("Frame")
local events = {}

local playerGUID, playerName
local inBG, inArena = false, false

local streak = 0
local deathstreak = 0
local multikill = 0
local lastKillTime
local lastRank -- the streak rank last announced, so "KILLING SPREE!" shows once per rank

-- First-run setup (the window is built in the setup section further down)
local openSetup
local setupShownThisSession = false

local debugOn = false
local testing = false -- a simulated kill or death: no emotes, no screenshots, no stats

-- ---------------------------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------------------------
local function isSecret(value)
	return issecretvalue ~= nil and issecretvalue(value) == true
end

local function usableString(value)
	return not isSecret(value) and type(value) == "string" and value ~= ""
end

local function usableNumber(value)
	return not isSecret(value) and type(value) == "number"
end

local function chat(text)
	print("|cffff5533" .. TITLE .. "|r: " .. tostring(text))
end

local function debugPrint(...)
	if not debugOn then return end
	local parts = {}
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		parts[i] = isSecret(value) and "<secret>" or tostring(value)
	end
	chat("debug: " .. table.concat(parts, " "))
end

-- "$k killed $v!" with { k = ..., v = ..., s = ... }
local function fill(template, values)
	return (tostring(template):gsub("%$([kvs])", function(letter)
		local value = values[letter]
		return value ~= nil and tostring(value) or nil
	end))
end

local function later(fn)
	-- Chat sends, emotes and screenshots run outside the event handler
	C_Timer.After(0, fn)
end

-- Emotes. WoW Forever treats the two kinds differently:
--   * Built-in emotes (/cheer, /bow ...) can be sent by an addon, but not in combat: they wait
--     until combat ends.
--   * A custom emote message (free text) only goes out from a key press or click ("Interface
--     action failed because of an addon" otherwise): a kill gets it ready and /sks emote (typed,
--     or in a macro on a key) sends it.
local pendingEmotes = {} -- built-in emotes waiting for combat to end: { emote, target }
local readyText = nil    -- the custom emote message waiting for /sks emote
local textHinted = false

local function performEmote(emote, target)
	if target then target = strmatch(target, "^([^%-]+)") end -- the emote wants the plain name
	local ok, restricted
	if C_ChatInfo and C_ChatInfo.PerformEmote then
		ok, restricted = pcall(C_ChatInfo.PerformEmote, emote, target)
		ok = ok and not (not isSecret(restricted) and restricted)
	elseif DoEmote then
		ok = pcall(DoEmote, emote, target)
	end
	if not ok then debugPrint("the game did not allow the emote", emote) end
end

local function flushEmotes()
	if InCombatLockdown() then return end
	local queue = pendingEmotes
	pendingEmotes = {}
	for i, item in ipairs(queue) do
		C_Timer.After(i * 1.5, function() performEmote(item[1], item[2]) end)
	end
end

-- kind "emote": a built-in emote token (a = token, b = target name); kind "text": a = message
local function social(kind, a, b)
	if kind == "text" then
		readyText = a
		if not textHinted then
			textHinted = true
			chat("Custom emote ready: type /sks emote, or put it in a macro on a key, to send it. "
				.. "(WoW Forever only lets addons send typed messages from a key press.)")
		end
		return
	end
	if #pendingEmotes < 3 then pendingEmotes[#pendingEmotes + 1] = { a, b } end
	if not InCombatLockdown() then C_Timer.After(0.5, flushEmotes) end
end

-- Call only straight from a slash command or click, never from a timer or event
local function sendReadyEmote()
	local text = readyText
	readyText = nil
	if not text then
		chat("No custom emote waiting.")
		return
	end
	local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
	if send then send(text, "EMOTE") end
end

-- ---------------------------------------------------------------------------------------------
-- Sound
-- ---------------------------------------------------------------------------------------------
-- pack: play from this voice pack instead of the chosen one (nil = the chosen one)
local function playSound(file, pack)
	if not file or not db.profile.dosound then return end
	pack = pack or db.profile.soundpack
	local folder = PACK_FOLDER[pack] or ""
	local missing = PACK_MISSING[pack]
	if missing and missing[file] then folder = "" end
	local channel = db.profile.soundchannel or "Master"
	local willPlay = PlaySoundFile(SOUND_ROOT .. folder .. file, channel)
	-- A sound may be MP3 as well as Ogg (the default humiliation, custom ones)
	if not willPlay and folder ~= "" then
		willPlay = PlaySoundFile(SOUND_ROOT .. folder .. file:gsub("%.ogg$", ".mp3"), channel)
	end
	-- The pack lacks this file: play the one in sounds\
	if not willPlay and folder ~= "" then
		PlaySoundFile(SOUND_ROOT .. file, channel)
	end
end

-- "Humiliation" in the voice picked for it (Sounds tab), which can differ from the main pack
local function playHumiliation()
	local voice = db.profile.humiliationvoice
	playSound(SOUND_HUMILIATION, (voice and voice ~= "pack") and voice or nil)
end

-- The rank a streak has reached by the rank thresholds (1..7)
local function rankForStreak(count)
	for rank = #RANK_SOUNDS, 1, -1 do
		local needed = db.profile.ksrank[rank] or 0
		if needed > 0 and count >= needed then return rank end
	end
	return 1
end

-- The rank whose sound plays for this kill, or nil for no sound (Unreal Tournament style
-- between its steps)
local function soundRank(count)
	local profile = db.profile
	if profile.style == "ut" then
		if count == 1 then return 1 end
		if count % profile.utrank ~= 0 then return nil end
		return math.min(count / profile.utrank, #RANK_SOUNDS)
	end
	return rankForStreak(count)
end

-- ---------------------------------------------------------------------------------------------
-- On-screen effects
--   Plain text   up to three red lines (the "animated text" option off)
--   Fancy text   punches in, floats up and fades; its colour follows the streak rank
--   Sparkles     a burst of stars, chillies or confetti
--   Flash        a coloured glow around the screen edges on multikills and big streaks
-- Everything hangs off one anchor that can be dragged. One OnUpdate runs only while
-- something is moving.
-- ---------------------------------------------------------------------------------------------
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local STAR = "Interface\\Cooldown\\star4"
local CHILLI = MEDIA .. "Chilli"
local VIGNETTE = "Interface\\FullScreenTextures\\LowHealth"

local FONTS = {
	impact = { name = "Impact (combat text)", path = "Fonts\\SKURRI.TTF" },
	classic = { name = "Classic", path = "Fonts\\FRIZQT__.TTF" },
	fancy = { name = "Fancy", path = "Fonts\\MORPHEUS.TTF" },
}
local FONT_NAMES = {}
for key, font in pairs(FONTS) do FONT_NAMES[key] = font.name end

local RANK_COLORS = {
	{ 1, 0.85, 0.3 },  -- Ownage: gold
	{ 1, 0.6, 0.15 },  -- Killing Spree: orange
	{ 1, 0.35, 0.1 },  -- Rampage: red-orange
	{ 1, 0.12, 0.12 }, -- Dominating: red
	{ 1, 0.25, 0.65 }, -- Unstoppable: pink
	{ 0.75, 0.35, 1 }, -- Godlike: purple
	{ 0.3, 0.9, 1 },   -- Wicked Sick: cyan
}
local MULTI_COLOR = { 1, 0.85, 0.2 }
local DEATH_COLOR = { 0.6, 0.65, 0.75 }
local OTHER_COLOR = { 0.55, 0.8, 1 }
local CONFETTI_COLORS = { { 1, 0.25, 0.25 }, { 1, 0.75, 0.2 }, { 0.3, 0.9, 0.4 }, { 0.3, 0.6, 1 }, { 0.85, 0.4, 1 } }

local function fxConfig() return db.profile.fx end

local function clamp01(x)
	if x < 0 then return 0 elseif x > 1 then return 1 end
	return x
end

-- Overshoots a little before settling: the "punch"
local function easeOutBack(x)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

-- Anchor ------------------------------------------------------------------------------------
local anchor = CreateFrame("Frame", "SpicyKillStreaksAnchor", UIParent)
anchor:SetSize(320, 44)
anchor:SetFrameStrata("HIGH")
anchor:SetClampedToScreen(true)
anchor:SetMovable(true)
anchor:RegisterForDrag("LeftButton")
anchor:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
local anchorBox = anchor:CreateTexture(nil, "BACKGROUND")
anchorBox:SetAllPoints()
anchorBox:SetColorTexture(1, 0.35, 0.15, 0.35)
anchorBox:Hide()
local anchorLabel = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
anchorLabel:SetPoint("CENTER")
anchorLabel:SetText(TITLE .. ": drag me")
anchorLabel:Hide()
local anchorUnlocked = false

local function placeAnchor()
	local cfg = fxConfig()
	anchor:ClearAllPoints()
	anchor:SetPoint("CENTER", UIParent, "CENTER", cfg.x, cfg.y)
end

local function setAnchorUnlocked(unlocked)
	anchorUnlocked = unlocked and true or false
	anchor:EnableMouse(anchorUnlocked)
	anchorBox:SetShown(anchorUnlocked)
	anchorLabel:SetShown(anchorUnlocked)
end

anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local x, y = self:GetCenter()
	local ux, uy = UIParent:GetCenter()
	local cfg = fxConfig()
	cfg.x, cfg.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
	placeAnchor()
end)

-- Animation driver --------------------------------------------------------------------------
-- Each running effect has update(self, t, dt) -> true while it is still going, and finish(self).
local driver = CreateFrame("Frame")
driver:Hide()
local running = {}

local function startEffect(effect)
	effect.t = 0
	running[#running + 1] = effect
	driver:Show()
end

driver:SetScript("OnUpdate", function(self, elapsed)
	for i = #running, 1, -1 do
		local effect = running[i]
		effect.t = effect.t + elapsed
		local ok, alive = pcall(effect.update, effect, effect.t, elapsed)
		if not ok or not alive then
			pcall(effect.finish, effect)
			table.remove(running, i)
		end
	end
	if #running == 0 then self:Hide() end
end)

-- Fancy text --------------------------------------------------------------------------------
local TEXT_STYLES = {
	kill  = { size = 26, punch = 2.2, life = 2.4 },
	rank  = { size = 36, punch = 3.0, life = 3.0 },
	multi = { size = 42, punch = 3.2, life = 3.2, pulse = true },
	death = { size = 26, punch = 1, life = 2.6, sink = true },
	other = { size = 20, punch = 1.6, life = 2.4 },
}
local LINE_GAP = 6
local MAX_LINES = 5
local textPool, liveTexts = {}, {}

local function setFont(fontString, size)
	fontString:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "THICKOUTLINE")
	local font = FONTS[fxConfig().font]
	-- A font the client lacks leaves the standard font in place
	if font then pcall(fontString.SetFont, fontString, font.path, size, "THICKOUTLINE") end
end

local function acquireTextHolder()
	local holder = table.remove(textPool)
	if not holder then
		holder = CreateFrame("Frame", nil, anchor)
		holder:SetSize(1200, 80)
		holder.text = holder:CreateFontString(nil, "OVERLAY")
		holder.text:SetPoint("CENTER")
		holder.text:SetShadowOffset(2, -2)
		holder.text:SetShadowColor(0, 0, 0, 0.9)
	end
	holder:SetFrameLevel(anchor:GetFrameLevel() + 5)
	holder:Show()
	return holder
end

local function fancyText(text, kind, level)
	local style = TEXT_STYLES[kind] or TEXT_STYLES.kill
	local color = (kind == "multi" and MULTI_COLOR) or (kind == "death" and DEATH_COLOR)
		or (kind == "other" and OTHER_COLOR) or RANK_COLORS[level or 1] or RANK_COLORS[1]
	local size = style.size * fxConfig().scale
	local holder = acquireTextHolder()
	setFont(holder.text, size)
	holder.text:SetText(text)
	holder.text:SetTextColor(color[1], color[2], color[3])

	-- New lines appear at the anchor and push the ones already showing up
	for _, other in ipairs(liveTexts) do other.lift = other.lift + size + LINE_GAP end
	-- Too many at once: hurry the oldest out
	if #liveTexts >= MAX_LINES then
		local oldest = liveTexts[1]
		oldest.t = math.max(oldest.t or 0, oldest.style.life - 0.25)
	end

	local effect = { holder = holder, style = style, color = color, lift = 0, liftNow = 0 }
	liveTexts[#liveTexts + 1] = effect

	function effect:update(t, dt)
		local s = self.style
		if t >= s.life then return false end
		self.liftNow = self.liftNow + (self.lift - self.liftNow) * clamp01(dt * 12)
		local scale, alpha = 1, 1
		local punchTime = 0.35
		if t < punchTime then
			local x = t / punchTime
			scale = s.punch + (1 - s.punch) * easeOutBack(x)
			alpha = clamp01(x * 3)
		end
		local fadeTime = 0.7
		if t > s.life - fadeTime then alpha = clamp01((s.life - t) / fadeTime) end
		-- Scrolls slowly up (or down for deaths) the whole time
		local drift = (s.sink and -40 or 45) * (t / s.life)
		if s.pulse then
			local p = (0.5 + 0.5 * math.sin(t * 14)) * 0.6
			local c = self.color
			self.holder.text:SetTextColor(c[1] + (1 - c[1]) * p, c[2] + (1 - c[2]) * p, c[3] + (1 - c[3]) * p)
		end
		if scale < 0.05 then scale = 0.05 end
		self.holder:SetScale(scale)
		self.holder:SetAlpha(alpha)
		self.holder:ClearAllPoints()
		-- Offsets are in the holder's own (scaled) units
		self.holder:SetPoint("CENTER", anchor, "CENTER", 0, (self.liftNow + drift) / scale)
		return true
	end

	function effect:finish()
		self.holder:Hide()
		textPool[#textPool + 1] = self.holder
		for i, live in ipairs(liveTexts) do
			if live == self then
				table.remove(liveTexts, i)
				break
			end
		end
	end

	effect:update(0, 0)
	startEffect(effect)
end

-- Sparkles ----------------------------------------------------------------------------------
local sparkLayer = CreateFrame("Frame", nil, anchor)
sparkLayer:SetAllPoints()
sparkLayer:SetFrameLevel(anchor:GetFrameLevel() + 2) -- under the text
local sparkPool = {}

local function acquireSpark()
	return table.remove(sparkPool) or sparkLayer:CreateTexture(nil, "ARTWORK")
end

local function releaseSpark(texture)
	texture:Hide()
	sparkPool[#sparkPool + 1] = texture
end

local function pickShape(style)
	if style ~= "mix" then return style end
	local roll = math.random(5)
	if roll <= 3 then return "star" elseif roll == 4 then return "chilli" end
	return "confetti"
end

local function dressSpark(texture, shape, color)
	texture:SetTexCoord(0, 1, 0, 1)
	if shape == "chilli" then
		texture:SetTexture(CHILLI)
		texture:SetBlendMode("BLEND")
		texture:SetVertexColor(1, 1, 1, 1)
	elseif shape == "confetti" then
		texture:SetTexture(WHITE)
		texture:SetBlendMode("BLEND")
		local c = CONFETTI_COLORS[math.random(#CONFETTI_COLORS)]
		texture:SetVertexColor(c[1], c[2], c[3], 1)
	else
		texture:SetTexture(STAR)
		texture:SetBlendMode("ADD")
		-- Half the stars in the rank colour, half nearly white
		local w = math.random() < 0.5 and 0.7 or 0
		texture:SetVertexColor(color[1] + (1 - color[1]) * w, color[2] + (1 - color[2]) * w, color[3] + (1 - color[3]) * w, 1)
	end
end

local function sparkleBurst(color, amount, withFlare)
	local scale = fxConfig().scale
	local count = math.min(math.floor(amount + 0.5), 120)
	if count < 1 then return end
	local style = fxConfig().sparklestyle

	local sparks = {}
	for i = 1, count do
		local shape = pickShape(style)
		local texture = acquireSpark()
		texture:Hide()
		dressSpark(texture, shape, color)
		local angle = math.random() * 2 * math.pi
		local speed = (90 + math.random() * 260) * scale
		local size
		if shape == "chilli" then size = 18 + math.random() * 8
		elseif shape == "confetti" then size = 7 + math.random() * 5
		else size = 14 + math.random() * 14 end
		sparks[i] = {
			texture = texture, shape = shape,
			x0 = (math.random() - 0.5) * 160 * scale,
			y0 = (math.random() - 0.5) * 20 * scale,
			vx = math.cos(angle) * speed,
			vy = math.sin(angle) * speed * 0.8 + 140 * scale,
			gravity = (shape == "confetti" and -200 or -520) * scale,
			life = 0.8 + math.random() * 0.8,
			size = size * scale,
			rot = math.random() * 6.28,
			spin = (math.random() - 0.5) * 12,
			delay = math.random() * 0.12,
		}
	end

	-- One big star flaring out at the centre for the big moments
	local flare
	if withFlare then
		flare = acquireSpark()
		dressSpark(flare, "star", color)
		flare:ClearAllPoints()
		flare:SetPoint("CENTER", sparkLayer, "CENTER", 0, 0)
	end

	local effect = {}
	function effect:update(t)
		local alive = false
		for _, s in ipairs(sparks) do
			local lt = t - s.delay
			local texture = s.texture
			if lt < 0 then
				alive = true
			elseif lt < s.life then
				alive = true
				local x = s.x0 + s.vx * lt
				local y = s.y0 + s.vy * lt + 0.5 * s.gravity * lt * lt
				local width, height = s.size, s.size
				if s.shape == "confetti" then
					-- Flutters side to side and flips over as it falls
					x = x + math.sin(lt * 9 + s.rot) * 12 * scale
					height = math.max(1, s.size * 0.6 * math.abs(math.sin(lt * 10 + s.rot)))
				elseif s.shape == "star" then
					local twinkle = 0.75 + 0.25 * math.sin(lt * 25 + s.rot)
					width, height = width * twinkle, height * twinkle
				end
				texture:ClearAllPoints()
				texture:SetPoint("CENTER", sparkLayer, "CENTER", x, y)
				texture:SetSize(width, height)
				texture:SetAlpha(1 - (lt / s.life) ^ 2)
				if texture.SetRotation then texture:SetRotation(s.rot + s.spin * lt) end
				texture:Show()
			elseif texture:IsShown() then
				texture:Hide()
			end
		end
		if flare then
			local life = 0.45
			if t < life then
				alive = true
				local x = t / life
				local size = (40 + 260 * x) * scale
				flare:SetSize(size, size)
				flare:SetAlpha(1 - x)
				flare:Show()
			else
				flare:Hide()
			end
		end
		return alive
	end
	function effect:finish()
		for _, s in ipairs(sparks) do releaseSpark(s.texture) end
		if flare then releaseSpark(flare) end
	end
	startEffect(effect)
end

-- Screen flash ------------------------------------------------------------------------------
local flashFrame = CreateFrame("Frame", nil, UIParent)
flashFrame:SetAllPoints(UIParent)
flashFrame:SetFrameStrata("BACKGROUND")
flashFrame:Hide()
local flashTexture = flashFrame:CreateTexture(nil, "BACKGROUND")
flashTexture:SetAllPoints()
flashTexture:SetTexture(VIGNETTE)
flashTexture:SetBlendMode("ADD")
flashTexture:SetDesaturated(true)
local flashEffect

local function screenFlash(color)
	flashTexture:SetVertexColor(color[1], color[2], color[3])
	if flashEffect then
		flashEffect.t = 0 -- already flashing: start over
		return
	end
	flashEffect = {}
	function flashEffect:update(t)
		local life = 0.9
		if t >= life then return false end
		local rise = 0.08
		local alpha = t < rise and (t / rise) or (1 - (t - rise) / (life - rise))
		flashFrame:SetAlpha(alpha * 0.8)
		return true
	end
	function flashEffect:finish()
		flashFrame:Hide()
		flashEffect = nil
	end
	flashFrame:SetAlpha(0)
	flashFrame:Show()
	startEffect(flashEffect)
end

-- Sparkles and flash for a kill. kind: "kill" | "rank" | "multi" | "other"; level: rank or multikill number
local function celebrate(kind, level)
	local cfg = fxConfig()
	level = level or 1
	local color = (kind == "multi" and MULTI_COLOR) or (kind == "other" and OTHER_COLOR) or RANK_COLORS[level] or RANK_COLORS[1]
	if cfg.sparkles then
		local factor
		if kind == "multi" then factor = 1 + 0.2 * level
		elseif kind == "rank" then factor = 0.8 + 0.1 * level
		elseif kind == "other" then factor = 0.25
		else factor = 0.45 end
		sparkleBurst(color, cfg.sparklecount * factor, kind == "multi" or kind == "rank")
	end
	if cfg.flash and (kind == "multi" or (kind == "rank" and level >= 3)) then
		screenFlash(color)
	end
end

-- Plain text --------------------------------------------------------------------------------
local banner = CreateFrame("Frame", "SpicyKillStreaksBanner", anchor)
banner:SetSize(900, 120)
banner:SetPoint("TOP", anchor, "CENTER", 0, 20)
banner:SetFrameStrata("HIGH")
banner:Hide()
local bannerText = banner:CreateFontString(nil, "OVERLAY")
bannerText:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 26, "OUTLINE")
bannerText:SetPoint("TOP", banner, "TOP", 0, 0)
bannerText:SetTextColor(1, 0.2, 0.1)
bannerText:SetJustifyH("CENTER")

local BANNER_SECONDS = 3.5
local bannerLines = {}

local function refreshBanner()
	local now = GetTime()
	for i = #bannerLines, 1, -1 do
		if bannerLines[i].expires <= now then table.remove(bannerLines, i) end
	end
	if #bannerLines == 0 then
		banner:Hide()
		return
	end
	local texts = {}
	for i, line in ipairs(bannerLines) do texts[i] = line.text end
	bannerText:SetText(table.concat(texts, "\n"))
	banner:Show()
end

local function showBanner(text)
	bannerLines[#bannerLines + 1] = { text = text, expires = GetTime() + BANNER_SECONDS }
	while #bannerLines > 3 do table.remove(bannerLines, 1) end
	refreshBanner()
	C_Timer.After(BANNER_SECONDS + 0.1, refreshBanner)
end

-- Text on screen in the chosen style. kind: "kill" | "rank" | "multi" | "death" | "other"
local function showText(text, kind, level)
	if fxConfig().fancytext then
		fancyText(text, kind, level)
	else
		showBanner(text)
	end
end

-- One line of news: the log, the chat window and the screen
local function announce(text, kind, level)
	if not testing then
		table.insert(db.profile.log, 1, "[" .. date("%m/%d %H:%M:%S") .. "] " .. text)
		while #db.profile.log > LOG_LIMIT do table.remove(db.profile.log) end
	end
	if db.profile.dochat then chat(text) end
	if db.profile.doscreen then showText(text, kind, level) end
end

-- Effect previews: the effects and sounds only, no log, chat or stats
local function preview(what)
	if what == "kill" then
		showText((playerName or "You") .. " killed Test-Victim!", "kill", 1)
		playSound(RANK_SOUNDS[1])
		celebrate("kill", 1)
	elseif what == "rank" then
		showText(strupper(RANK_NAMES[3]) .. "!", "rank", 3)
		playSound(RANK_SOUNDS[3])
		celebrate("rank", 3)
	elseif what == "multi" then
		showText(MULTI_TEXTS[3], "multi", 3)
		playSound(MULTI_SOUNDS[3])
		celebrate("multi", 3)
	elseif what == "big" then
		showText((playerName or "You") .. " killed Test-Victim!", "kill", 7)
		showText(strupper(RANK_NAMES[7]) .. "!", "rank", 7)
		showText(MULTI_TEXTS[7], "multi", 7)
		playSound(MULTI_SOUNDS[7])
		celebrate("multi", 7)
	elseif what == "death" then
		showText("You were killed by Test-Killer.", "death")
		playHumiliation()
	elseif what == "other" then
		showText("Friend-Name killed Test-Victim! (streak 3)", "other")
		celebrate("other")
	end
end

-- ---------------------------------------------------------------------------------------------
-- Kills and deaths
-- ---------------------------------------------------------------------------------------------
local function count(list, name)
	local entry = list[name]
	if not entry then
		entry = { count = 0 }
		list[name] = entry
	end
	entry.count = entry.count + 1
	entry.last = date("%m/%d/%y %H:%M:%S")
	return entry.count
end

local syncSendKill, syncSendDeath -- defined in the sync section below

-- We landed a kill (or won a duel). victim: a name, or UNKNOWN_VICTIM.
local function registerKill(victim, isDuel)
	local profile = db.profile
	local now = GetTime()
	victim = usableString(victim) and victim or UNKNOWN_VICTIM

	streak = streak + 1
	deathstreak = 0
	local newRecord = false
	if streak > profile.maxstreak and not testing then
		profile.maxstreak = streak
		newRecord = true
	end

	-- A duel win is never part of a multikill
	local multi = 0
	if not isDuel then
		if lastKillTime and now - lastKillTime < MULTIKILL_WINDOW then
			multikill = math.min(multikill + 1, #MULTI_TEXTS)
		else
			multikill = 0
		end
		lastKillTime = now
		multi = multikill
	end

	local values = { k = playerName or "You", v = victim, s = streak }
	local colorRank = rankForStreak(streak)
	announce(fill(isDuel and profile.dueltext or profile.kstext, values), "kill", colorRank)
	local rank = nil
	if multi > 0 then
		announce(MULTI_TEXTS[multi], "multi", multi)
		playSound(MULTI_SOUNDS[multi])
		celebrate("multi", multi)
	else
		rank = soundRank(streak)
		if rank then playSound(RANK_SOUNDS[rank]) end
		-- Reaching a new rank gets its name on screen: "KILLING SPREE!"
		if rank and rank >= 2 and rank ~= lastRank then
			announce(strupper(RANK_NAMES[rank]) .. "!", "rank", rank)
			celebrate("rank", rank)
		else
			celebrate("kill", colorRank)
		end
		if rank then lastRank = rank end
	end

	if testing then return end

	-- Tell other Spicy Kill Streaks users in the group and guild
	syncSendKill(isDuel and "U" or "K", victim, streak, multi, rank)

	if victim ~= UNKNOWN_VICTIM then
		local times = count(profile.kills, victim)
		if profile.dochat then chat("You have " .. (isDuel and "defeated " or "killed ") .. victim .. " " .. times .. " times.") end
	end

	-- Emotes
	local emoteTarget = victim ~= UNKNOWN_VICTIM and victim or nil
	if isDuel then
		if profile.duelemotewin ~= "none" then
			social("emote", profile.duelemotewin, emoteTarget)
		end
	else
		if profile.dotxtemote then
			social("text", fill(profile.ksemote, values))
		end
		if profile.doemote ~= "none" then
			social("emote", profile.doemote, emoteTarget)
		end
	end

	-- Screenshots
	local shot = (isDuel and profile.shotduelwin)
		or (not isDuel and profile.shotkill)
		or (profile.shotstreak and newRecord)
		or (profile.shotmultikill and multi > 0)
	if shot then later(Screenshot) end
end

local function resetStreakOnDeath()
	streak = 0
	multikill = 0
	lastKillTime = nil
	lastRank = nil
end

-- We died (or lost a duel). killer: a name or nil.
local function registerDeath(killer, isDuel)
	local profile = db.profile
	resetStreakOnDeath()
	deathstreak = deathstreak + 1
	killer = usableString(killer) and killer or "an unknown enemy"
	announce("You were " .. (isDuel and "defeated" or "killed") .. " by " .. killer .. ".", "death")
	-- (A fled duel already plays it, from the duel setting)
	if not isDuel and profile.dodeathsound then playHumiliation() end

	if testing then return end

	syncSendDeath(killer, isDuel)
	if deathstreak > profile.maxdeathstreak then profile.maxdeathstreak = deathstreak end
	local times = count(profile.deaths, killer)
	if profile.dochat then chat(killer .. " has " .. (isDuel and "defeated" or "killed") .. " you " .. times .. " times.") end
	if isDuel then
		if profile.duelemoteloss ~= "none" then
			social("emote", profile.duelemoteloss, killer)
		end
		if profile.shotduelloss then later(Screenshot) end
	elseif profile.shotdeath then
		later(Screenshot)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Party and guild sync
--
-- Kills are shared with other Spicy Kill Streaks users through addon messages (invisible to
-- players without the addon). One line per message, fields separated by tabs:
--   K  <version> <victim> <streak> <multikill> <rank>   a kill
--   U  ...same...                                       a duel win
--   T  ...same...                                       a test from the Tests tab
--   D  <version> <killer> <duel 0/1>                    a death (or duel loss)
--   V? <version>                                        who is running the addon?
--   V! <version>                                        the answer (whispered back)
-- Sending is opt-in, separately for party and guild. What arrives is shown by the receiver's
-- own settings for party members and guild members. Received kills never touch our own stats.
-- ---------------------------------------------------------------------------------------------
local PREFIX = "SpicyKS"
local prefixRegistered = false
local recentReceived = {}   -- "sender|victim|streak" -> GetTime(): the same kill via party and guild
local senderBudget = {}     -- sender -> { start, count }: at most 12 messages per 10 seconds each

local function syncConfig() return db.profile.sync end

local function registerPrefix()
	if prefixRegistered then return true end
	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		prefixRegistered = pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) and true or false
	end
	return prefixRegistered
end

local function sendAddonMessage(message, channel, target)
	if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) or not registerPrefix() then return false end
	local ok, result = pcall(C_ChatInfo.SendAddonMessage, PREFIX, message, channel, target)
	debugPrint("sync: sent to", channel, target or "", ok and "ok" or "failed", result)
	-- Older clients return true/false, newer ones a result code (0 = success)
	return ok and (result == nil or result == true or result == 0)
end

-- The group channel we are in: battleground/arena/LFG, raid or party
local function groupChannel()
	if IsInGroup and LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
	if IsInRaid and IsInRaid() then return "RAID" end
	if IsInGroup and IsInGroup() then return "PARTY" end
	return nil
end

local function cleanField(text)
	return (tostring(text or ""):gsub("[\t\n|]", " "))
end

local function inGuild()
	return IsInGuild and IsInGuild() and true or false
end

-- Send one line to the group and the guild, as far as the player opted in
local function broadcast(message)
	local cfg = syncConfig()
	if not (cfg.shareparty or cfg.shareguild) then return end
	later(function()
		if cfg.shareparty then
			local channel = groupChannel()
			if channel then sendAddonMessage(message, channel) end
		end
		if cfg.shareguild and inGuild() then
			sendAddonMessage(message, "GUILD")
		end
	end)
end

-- Every kill and death message ends with the sender's GUID, so our own broadcast coming back is
-- recognised exactly. (Names are not enough on WoW Forever: characters have a family name, and
-- UnitName may return only the given name while the sender arrives with both.)
syncSendKill = function(kind, victim, streakCount, multi, rank)
	broadcast(table.concat({ kind, VERSION, cleanField(victim), tostring(streakCount or 0),
		tostring(multi or 0), tostring(rank or 0), playerGUID or "" }, "\t"))
end

syncSendDeath = function(killer, isDuel)
	broadcast(table.concat({ "D", VERSION, cleanField(killer), isDuel and "1" or "0", playerGUID or "" }, "\t"))
end

-- "Given Family-Realm" -> "givenfamily-realm" and "givenfamily" (no spaces, lower case)
local function nameKeys(name)
	if not usableString(name) then return nil, nil end
	local full = strlower((name:gsub("%s", "")))
	local short = strlower(((strsplit("-", name)):gsub("%s", "")))
	return full, short
end

-- Is this addon message from our own character?
local function isOwnSender(sender, fields)
	-- Exact: the GUID at the end of kill and death messages
	local last = fields and fields[#fields]
	if usableString(last) and playerGUID and last == playerGUID then return true end
	-- Otherwise by name, in every form the client might use
	local senderFull, senderShort = nameKeys(sender)
	if not senderFull then return false end
	local candidates = { playerName, (UnitName("player")), GetUnitName("player", true) }
	if type(UnitFullName) == "function" then
		local ok, name, realm = pcall(UnitFullName, "player")
		if ok and usableString(name) then
			candidates[#candidates + 1] = name
			if usableString(realm) then candidates[#candidates + 1] = name .. "-" .. realm end
		end
	end
	for _, candidate in ipairs(candidates) do
		local full, short = nameKeys(candidate)
		if full and (full == senderFull or short == senderShort or full == senderShort) then return true end
	end
	return false
end

-- Answers to our own "who runs it?" question: { names = { [name] = version }, quiet = bool }.
-- quiet: collect them for one summary line (the login count) instead of a line per answer.
local census

local function versionCheck()
	if not registerPrefix() then
		chat("Addon messages are not available on this client.")
		return
	end
	census = { names = {}, quiet = false }
	chat("Asking your group and guild who runs " .. TITLE .. "...")
	-- Asking is an explicit request, so it goes out whatever the sharing settings say
	local message = "V?\t" .. VERSION
	if groupChannel() then sendAddonMessage(message, groupChannel()) end
	if inGuild() then sendAddonMessage(message, "GUILD") end
	if not (groupChannel() or inGuild()) then
		chat("You are not in a group or guild, so nobody can answer.")
	end
end

local function sendTestSync()
	local cfg = syncConfig()
	local toGroup = cfg.shareparty and groupChannel() ~= nil
	local toGuild = cfg.shareguild and inGuild()
	if not (cfg.shareparty or cfg.shareguild) then
		chat("Sharing is off. Switch on \"Share with my party\" or \"Share with my guild\" under Sync first.")
		return
	end
	if not (toGroup or toGuild) then
		chat("You are not in a group or guild you share with: there is nobody to send the test to.")
		return
	end
	broadcast(table.concat({ "T", VERSION, "Test-Victim", "3", "0", "2", playerGUID or "" }, "\t"))
	chat("Sent a test kill to your " .. ((toGroup and toGuild) and "group and guild" or (toGroup and "group" or "guild"))
		.. ". Other users of " .. TITLE .. " should see it.")
end

local function shortName(name)
	if type(Ambiguate) == "function" then
		local ok, short = pcall(Ambiguate, name, "none")
		if ok and usableString(short) then return short end
	end
	return name
end

-- Is this sender over its message allowance? (A broken or hostile client must not flood us.)
local function overBudget(sender)
	local now = GetTime()
	local budget = senderBudget[sender]
	if not budget or now - budget.start > 10 then
		senderBudget[sender] = { start = now, count = 1 }
		return false
	end
	budget.count = budget.count + 1
	return budget.count > 12
end

-- Is the sender in our party or raid? Then their messages use the party settings, whichever
-- channel delivered them first; everyone else uses the guild settings.
local function isGroupMember(sender, channel)
	if channel == "PARTY" or channel == "RAID" or channel == "INSTANCE_CHAT" then return true end
	local short = shortName(sender)
	for _, check in ipairs({ UnitInParty, UnitInRaid }) do
		if type(check) == "function" then
			local ok, result = pcall(check, short)
			if ok and result and not isSecret(result) then return true end
		end
	end
	return false
end

-- The same event arriving through party and guild is handled once
local recentCount = 0
local function seenRecently(key)
	local now = GetTime()
	if recentReceived[key] and now - recentReceived[key] < 5 then return true end
	-- Keep the table small: entries older than a few seconds are no longer needed
	recentCount = recentCount + 1
	if recentCount > 200 then
		for oldKey, stamp in pairs(recentReceived) do
			if now - stamp >= 5 then recentReceived[oldKey] = nil end
		end
		recentCount = 0
	end
	recentReceived[key] = now
	return false
end

-- Text from another player's message, made safe to show: no "|" escape codes (colours,
-- links, textures) and no line breaks, at most 60 characters
local function safeText(text)
	if not usableString(text) then return nil end
	text = text:gsub("[|\r\n\t]", "")
	text = strtrim(text)
	if text == "" then return nil end
	return strsub(text, 1, 60)
end

-- A kill, duel win, test or death from another user, shown by the settings for its source
local function onFeedMessage(kind, sender, channel, fields)
	local source = isGroupMember(sender, channel) and syncConfig().party or syncConfig().guild
	local who = safeText(shortName(sender))
	local name = safeText(fields[3])
	if not who or not name then return end

	if kind == "D" then
		if seenRecently(sender .. "|D|" .. name) then return end
		if not source.deaths then return end
		local text = who .. " was " .. (fields[4] == "1" and "defeated" or "killed") .. " by " .. name .. "."
		if source.feed then chat(text) end
		if source.text then showText(text, "death") end
		if source.sound and fields[4] ~= "1" then playHumiliation() end
		return
	end

	local streakCount = tonumber(fields[4])
	local multi = tonumber(fields[5])
	local rank = tonumber(fields[6])
	-- Anything not shaped like a kill is dropped
	if not streakCount or not multi or not rank then return end
	streakCount = math.max(0, math.floor(streakCount))
	multi = math.min(math.max(0, math.floor(multi)), #MULTI_TEXTS)
	rank = math.min(math.max(0, math.floor(rank)), #RANK_SOUNDS)
	if seenRecently(sender .. "|" .. kind .. "|" .. name .. "|" .. streakCount) then return end

	local text
	if kind == "U" then
		text = who .. " defeated " .. name .. " in a duel!"
	else
		text = who .. " killed " .. name .. "!"
	end
	if streakCount > 1 then text = text .. " (streak " .. streakCount .. ")" end
	if kind == "T" then text = text .. " [test]" end

	if source.feed then
		chat(text)
		if multi > 0 then chat(who .. ": " .. MULTI_TEXTS[multi]) end
	end
	if source.text then
		showText(text, "other")
		if multi > 0 then showText(who .. ": " .. MULTI_TEXTS[multi], "other") end
		celebrate("other")
	end
	if source.sound then
		if multi > 0 then
			playSound(MULTI_SOUNDS[multi])
		elseif rank > 0 then
			playSound(RANK_SOUNDS[rank])
		end
	end
end

function events.CHAT_MSG_ADDON(prefix, message, channel, sender)
	if prefix ~= PREFIX then return end
	-- Addon message payloads can be secret values in restricted content
	if not usableString(message) or not usableString(sender) then return end
	if #message > 255 then return end
	local fields = { strsplit("\t", message) }
	local isOwn = isOwnSender(sender, fields)
	debugPrint("sync: received from", sender, "via", channel, isOwn and "(our own echo, ignored)" or "", ":", (message:gsub("\t", " ")))
	if isOwn then return end -- our own broadcast coming back
	if overBudget(sender) then return end

	local kind = fields[1]
	if kind == "K" or kind == "U" or kind == "T" or kind == "D" then
		-- Kills and deaths travel by party/raid/instance or guild only
		if channel ~= "WHISPER" then onFeedMessage(kind, sender, channel, fields) end
	elseif kind == "V?" then
		-- Only answer when the player shares with someone: otherwise stay invisible
		local cfg = syncConfig()
		if cfg.shareparty or cfg.shareguild then
			later(function() sendAddonMessage("V!\t" .. VERSION, "WHISPER", sender) end)
		end
	elseif kind == "V!" then
		local who, version = safeText(shortName(sender)), safeText(fields[2])
		if not who then return end
		if census then
			if census.names[who] then return end -- answered through party and guild
			census.names[who] = version or "?"
			if census.quiet then return end
		end
		chat(who .. " runs " .. TITLE .. " " .. (version or "?") .. ".")
	end
end

-- At login: ask the guild who runs the addon and print one line with the count. Only when the
-- player shares with the guild (asking makes the addon visible to them) and wants the line.
local CENSUS_DELAY = 10   -- seconds after login: guild info is not ready at once
local CENSUS_WAIT = 6     -- seconds to collect the answers
local MAX_NAMES_SHOWN = 6

local function loginCensus()
	local cfg = syncConfig()
	if not cfg.logincount or not cfg.shareguild then return end
	C_Timer.After(CENSUS_DELAY, function()
		if not inGuild() or not registerPrefix() then return end
		census = { names = {}, quiet = true }
		sendAddonMessage("V?\t" .. VERSION, "GUILD")
		C_Timer.After(CENSUS_WAIT, function()
			if not census or not census.quiet then return end -- a manual check took over
			local names = {}
			for name in pairs(census.names) do names[#names + 1] = name end
			census = nil
			table.sort(names)
			if #names == 0 then
				chat("No guildmates online are sharing " .. TITLE .. " kills right now.")
				return
			end
			local line = #names .. (#names == 1 and " guildmate is" or " guildmates are") .. " using " .. TITLE
			if #names <= MAX_NAMES_SHOWN then line = line .. ": " .. table.concat(names, ", ") end
			chat(line .. ".")
		end)
	end)
end

-- Who killed us according to the Death Recap, or nil. The entry with overkill >= 0 is the
-- killing blow; failing that the newest entry.
local function recapKiller()
	if not (C_DeathRecap and C_DeathRecap.GetRecapEvents) then return nil end
	local ok, recap = pcall(C_DeathRecap.GetRecapEvents)
	if not ok or type(recap) ~= "table" or #recap == 0 then return nil end
	local best, bestTime
	for i, entry in ipairs(recap) do
		if type(entry) == "table" then
			if usableNumber(entry.overkill) and entry.overkill >= 0 then
				best = entry
				break
			end
			local stamp = usableNumber(entry.timestamp) and entry.timestamp or i
			if not bestTime or stamp >= bestTime then best, bestTime = entry, stamp end
		end
	end
	if best and usableString(best.sourceName) then return best.sourceName end
	return nil
end

-- ---------------------------------------------------------------------------------------------
-- Detection: battleground and arena scoreboard
-- ---------------------------------------------------------------------------------------------
local kbBaseline            -- our killing blows at the last scoreboard read, nil = not read yet
local enemyDeaths = {}      -- enemy name -> deaths at the last scoreboard read
local scoreRecheckPending = false
local testScore             -- a made-up scoreboard reading while the kill test runs

local function requestScoreData()
	if type(RequestBattlefieldScoreData) == "function" then pcall(RequestBattlefieldScoreData) end
end

-- One scoreboard row: name, guid (nil with the old API), killing blows, deaths, faction/team
local function readScoreRow(i)
	if C_PvP and C_PvP.GetScoreInfo then
		local ok, info = pcall(C_PvP.GetScoreInfo, i)
		if ok and type(info) == "table" and info.killingBlows ~= nil then
			return info.name, info.guid, info.killingBlows, info.deaths, info.faction
		end
	end
	if type(GetBattlefieldScore) == "function" then
		local name, killingBlows, _, deaths, _, faction = GetBattlefieldScore(i)
		return name, nil, killingBlows, deaths, faction
	end
end

-- The ways our own name can be written on the scoreboard
local function ownNames()
	local names = {}
	local function add(name)
		if usableString(name) then
			names[name] = true
			names[(strsplit("-", name))] = true
		end
	end
	add(playerName)
	add((UnitName("player")))
	add(GetUnitName("player", true))
	return names
end

-- Returns our killing blows and a table of enemy name -> deaths, or nil when our row is not there
local function readScoreboard()
	local rowCount = type(GetNumBattlefieldScores) == "function" and GetNumBattlefieldScores() or 0
	if not usableNumber(rowCount) or rowCount < 1 then return nil end

	local mineNames = ownNames()
	local rows = {}
	local mine, mineByName
	for i = 1, rowCount do
		local name, guid, kb, deaths, faction = readScoreRow(i)
		if usableString(name) then
			local row = { name = name, kb = kb, deaths = deaths, faction = faction }
			rows[#rows + 1] = row
			if usableString(guid) then
				if guid == playerGUID then mine = row end
			elseif mineNames[name] or mineNames[(strsplit("-", name))] then
				mineByName = mineByName or row
			end
		end
	end
	mine = mine or mineByName
	if not mine then
		debugPrint("scoreboard:", rowCount, "rows, none is ours. We are", playerName, "/", playerGUID, "- first row:", rows[1] and rows[1].name)
		return nil
	end
	if not usableNumber(mine.kb) then
		debugPrint("scoreboard: our killing blows are not readable:", mine.kb)
		return nil
	end

	local deathsByEnemy = {}
	if not isSecret(mine.faction) then
		for _, row in ipairs(rows) do
			if row ~= mine and not isSecret(row.faction) and row.faction ~= mine.faction and usableNumber(row.deaths) then
				deathsByEnemy[row.name] = row.deaths
			end
		end
	end
	return mine.kb, deathsByEnemy
end

-- Name of our current target if it is a dead enemy: the best guess for who we just killed
local function deadEnemyTargetName()
	local ok, name = pcall(function()
		if UnitExists("target") and UnitIsDeadOrGhost("target") and UnitCanAttack("player", "target") then
			return GetUnitName("target", true)
		end
	end)
	if ok and usableString(name) then return name end
	return nil
end

function events.PLAYER_PVP_KILLS_CHANGED(unit)
	debugPrint("PLAYER_PVP_KILLS_CHANGED", unit)
	-- Also fires for our raid unit ("raid9") and for other players; only "player" is counted
	if isSecret(unit) or (unit ~= nil and unit ~= "player") then return end
	requestScoreData()
	-- The first answer can arrive before the server has added the killing blow: ask once more
	if not scoreRecheckPending then
		scoreRecheckPending = true
		C_Timer.After(1.5, function()
			scoreRecheckPending = false
			requestScoreData()
		end)
	end
end

function events.UPDATE_BATTLEFIELD_SCORE()
	local kb, deathsByEnemy
	if testScore then
		kb, deathsByEnemy = testScore.kb, testScore.deaths
	else
		kb, deathsByEnemy = readScoreboard()
	end
	if not kb then return end

	-- Enemies whose death count rose since the last read
	local fallen = {}
	for name, deaths in pairs(deathsByEnemy) do
		local before = enemyDeaths[name]
		if before and deaths > before then fallen[#fallen + 1] = name end
	end

	local previous = kbBaseline
	kbBaseline, enemyDeaths = kb, deathsByEnemy
	if previous ~= kb then debugPrint("scoreboard: our killing blows", previous, "->", kb) end

	-- First read (the baseline) or a lower count (new match): nothing to announce
	if previous == nil or kb <= previous then return end
	local gained = kb - previous

	-- If exactly as many enemies died as we got killing blows, it was them. Otherwise fall back
	-- on our dead target, and failing that on a placeholder.
	local victims
	if #fallen == gained then
		victims = fallen
	else
		victims = { deadEnemyTargetName() }
	end
	for i = 1, gained do
		registerKill(victims[i] or UNKNOWN_VICTIM, false)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Detection: outside battlegrounds and arenas
-- ---------------------------------------------------------------------------------------------
local credited = {} -- GUID -> true: this death was already announced
local watched = {}  -- GUID -> "alive" | "engaged": NPC targets seen alive
-- GUID -> GUID of whoever landed the killing blow, from PARTY_KILL. PARTY_KILL is exact, so it
-- overrules the target-death guess: a target it credits to a group member is not our kill.
local killedBy = {}
local killedByCount = 0
-- How long a target-death guess waits for PARTY_KILL before it counts (PARTY_KILL can come
-- just after the target turns dead)
local GUESS_DELAY = 0.6

local function creditKill(guid, name)
	if credited[guid] then return end
	credited[guid] = true
	registerKill(name, false)
end

local function isPlayerGUID(guid)
	return strsub(guid, 1, 7) == "Player-"
end

local function nameFromGUID(guid)
	if isPlayerGUID(guid) and type(GetPlayerInfoByGUID) == "function" then
		local ok, _, _, _, _, _, name = pcall(GetPlayerInfoByGUID, guid)
		if ok and usableString(name) then return name end
	end
	if type(UnitNameFromGUID) == "function" then
		local ok, name = pcall(UnitNameFromGUID, guid)
		if ok and usableString(name) then return name end
	end
	local ok, name = pcall(function()
		if UnitGUID("target") == guid then return (UnitName("target")) end
	end)
	if ok and usableString(name) then return name end
	return nil
end

-- Is this GUID us, or our pet or guardian? (A pet's killing blow is ours.)
local function isOurs(guid)
	if guid == playerGUID then return true end
	local ok, petGUID = pcall(UnitGUID, "pet")
	return ok and usableString(petGUID) and guid == petGUID
end

function events.PARTY_KILL(attackerGUID, targetGUID)
	-- Hidden (secret) GUIDs cannot even be compared: check before anything else
	if not usableString(attackerGUID) or not usableString(targetGUID) then
		debugPrint("PARTY_KILL with hidden or missing GUIDs:", attackerGUID, targetGUID)
		return
	end
	debugPrint("PARTY_KILL attacker", attackerGUID, isOurs(attackerGUID) and "(us)" or "(someone else)", "target", targetGUID)
	-- Remember who got it, so the target-death guess leaves it alone
	if not killedBy[targetGUID] then
		killedByCount = killedByCount + 1
		if killedByCount > 500 then
			wipe(killedBy)
			killedByCount = 1
		end
	end
	killedBy[targetGUID] = attackerGUID
	if not isOurs(attackerGUID) then return end
	if isPlayerGUID(targetGUID) then
		-- In a battleground or arena the scoreboard counts player kills
		if inBG or inArena then return end
	elseif not db.profile.dopve then
		return
	end
	creditKill(targetGUID, nameFromGUID(targetGUID))
end

-- NPC kills (the NPC option), as a fallback for when PARTY_KILL does not arrive: a target we saw
-- alive dies while we fight it and is not tapped by someone else.
local function checkTargetDeath()
	if not db.profile.dopve then return end
	local ok, guid, state, name, fighting = pcall(function()
		if not UnitExists("target") or UnitIsPlayer("target") then return end
		local id = UnitGUID("target")
		if not usableString(id) then return end
		local inCombat = UnitAffectingCombat("player") and true or false
		if UnitIsDead("target") then
			if type(UnitIsTapDenied) == "function" and UnitIsTapDenied("target") then return id, "denied" end
			return id, "dead", (UnitName("target")), inCombat
		end
		if not UnitCanAttack("player", "target") then return end
		if inCombat and UnitAffectingCombat("target") then return id, "engaged" end
		return id, "alive"
	end)
	if not ok or not guid then return end

	if state == "dead" then
		local was = watched[guid]
		watched[guid] = nil
		debugPrint("target died:", name, "seen before as", was, "we are in combat:", fighting)
		if was == "engaged" or (was == "alive" and fighting) then
			-- Only a guess: give PARTY_KILL a moment to say who really got it. Where PARTY_KILL
			-- does not come (hidden in some content), the guess counts.
			C_Timer.After(GUESS_DELAY, function()
				local attacker = killedBy[guid]
				if attacker then
					debugPrint("target death decided by PARTY_KILL:", isOurs(attacker) and "ours" or "someone else's")
					return -- PARTY_KILL already credited it if it was ours
				end
				debugPrint("no PARTY_KILL for", name, "- counting it as ours (guess)")
				creditKill(guid, name)
			end)
		end
	elseif state == "denied" then
		watched[guid] = nil
	elseif watched[guid] ~= "engaged" then
		watched[guid] = state
	end
end

-- ---------------------------------------------------------------------------------------------
-- Execute sound ("finish him"): our target drops to or below the threshold
-- ---------------------------------------------------------------------------------------------
local targetHealth = {}  -- GUID or name -> last health percent seen
local lastExecuteReason  -- debug output only: why the last check was skipped
local executeHiddenNoticed = false -- told the player that enemy health is hidden (once per session)

local function checkExecute()
	local profile = db.profile
	if not (profile.doexecute or profile.doexecutepve) then return end
	-- Unit information can be hidden (secret values) in some content; then there is nothing to compare
	local ok, key, percent = pcall(function()
		if not UnitExists("target") then return end
		if not UnitCanAttack("player", "target") then return nil, "target cannot be attacked" end
		local isPlayer = UnitIsPlayer("target")
		if isPlayer and not profile.doexecute then return nil, "target is a player and the player option is off" end
		if not isPlayer and not profile.doexecutepve then return nil, "target is an NPC and the NPC option is off" end
		local health, healthMax = UnitHealth("target"), UnitHealthMax("target")
		if isSecret(health) or isSecret(healthMax) then return nil, "target health is hidden from addons (secret value)" end
		if not usableNumber(health) or not usableNumber(healthMax) or healthMax <= 0 then return nil, "target health is not a number" end
		local id = UnitGUID("target")
		if not usableString(id) then id = GetUnitName("target", true) end
		if not usableString(id) then return nil, "target has no usable GUID or name" end
		return id, floor(health / healthMax * 100)
	end)
	if not ok or not key then
		local reason = not ok and ("error: " .. tostring(key)) or percent
		-- Hidden health is the client's rule, not a setting: say so once per session
		if not executeHiddenNoticed and type(reason) == "string" and reason:find("hidden", 1, true) then
			executeHiddenNoticed = true
			chat("\"Finish him\" cannot work here: the game hides enemy health from addons during combat.")
		end
		if reason and reason ~= lastExecuteReason then debugPrint("execute:", reason) end
		lastExecuteReason = reason
		return
	end
	lastExecuteReason = nil

	local before = targetHealth[key]
	targetHealth[key] = percent
	local threshold = profile.executepercent
	if before ~= percent then debugPrint("execute: target health", before, "->", percent, "percent, threshold", threshold) end
	if percent <= threshold and percent > 1 and (before == nil or before > threshold) then
		playSound(SOUND_EXECUTE)
	end
end

function events.UNIT_HEALTH(unit)
	if isSecret(unit) or unit ~= "target" then return end
	checkExecute()
	checkTargetDeath()
end

function events.PLAYER_TARGET_CHANGED()
	checkExecute()
	checkTargetDeath()
end

-- We can enter combat with a target we already had: note it as engaged then
function events.PLAYER_REGEN_DISABLED()
	checkTargetDeath()
end

-- Built-in emotes from kills during the fight
function events.PLAYER_REGEN_ENABLED()
	C_Timer.After(1, flushEmotes)
end

-- ---------------------------------------------------------------------------------------------
-- Our own death
-- ---------------------------------------------------------------------------------------------
local deathPending = false

function events.PLAYER_DEAD()
	-- The recap may not be filled in the instant we die: retry briefly, then give up on the name
	if deathPending then return end
	deathPending = true
	resetStreakOnDeath()
	local attempts = 0
	local function resolve()
		attempts = attempts + 1
		local ok, killer = pcall(recapKiller)
		if not ok then killer = nil end
		if killer or attempts >= 4 then
			deathPending = false
			registerDeath(killer, false)
		else
			C_Timer.After(0.5, resolve)
		end
	end
	C_Timer.After(0.5, resolve)
end

-- ---------------------------------------------------------------------------------------------
-- Duels and the "prepare" sound, from chat lines
-- ---------------------------------------------------------------------------------------------
-- "%1$s has defeated %2$s in a duel" -> "^(.+) has defeated (.+) in a duel$" and which argument
-- each capture is
local function linePattern(formatString)
	if type(formatString) ~= "string" then return nil end
	local order = {}
	local pattern = formatString:gsub("[%(%)%.%+%-%*%?%[%]%^]", "%%%0")
	pattern = pattern:gsub("%%(%d?)%$?s", function(index)
		order[#order + 1] = tonumber(index) or (#order + 1)
		return "(.+)"
	end)
	return "^" .. pattern .. "$", order
end

-- Returns winner, loser when the line matches the format (argument 1 = winner, 2 = loser)
local function duelResult(message, formatString)
	local pattern, order = linePattern(formatString)
	if not pattern or #order ~= 2 then return nil end
	local first, second = message:match(pattern)
	if not first then return nil end
	local args = {}
	args[order[1]], args[order[2]] = first, second
	return args[1], args[2]
end

local function isMe(name)
	if not usableString(name) then return false end
	local names = ownNames()
	return (names[name] or names[(strsplit("-", name))]) and true or false
end

function events.CHAT_MSG_SYSTEM(message)
	if not usableString(message) then return end
	if db.profile.doprepare and type(DUEL_COUNTDOWN) == "string" and message == format(DUEL_COUNTDOWN, 3) then
		playSound(SOUND_PREPARE)
		return
	end
	local winner, loser = duelResult(message, DUEL_WINNER_KNOCKOUT)
	local fled = false
	if not winner then
		winner, loser = duelResult(message, DUEL_WINNER_RETREAT)
		fled = winner ~= nil
	end
	if not winner then return end
	if isMe(winner) then
		registerKill(loser, true)
	elseif isMe(loser) then
		if fled and db.profile.duelhumiliation then playHumiliation() end
		registerDeath(winner, true)
	end
end

function events.CHAT_MSG_BG_SYSTEM_NEUTRAL(message)
	if not usableString(message) or not db.profile.doprepare then return end
	if message:find("30 seconds", 1, true) then playSound(SOUND_PREPARE) end
end

-- ---------------------------------------------------------------------------------------------
-- Zones
-- ---------------------------------------------------------------------------------------------
local function updatePvPInstanceState()
	local _, instanceType = IsInInstance()
	if isSecret(instanceType) then instanceType = nil end
	inArena = (instanceType == "arena")
	inBG = (instanceType == "pvp")
end

function events.ZONE_CHANGED_NEW_AREA()
	if db.profile.dozonechange then
		streak = 0
		deathstreak = 0
		multikill = 0
		lastKillTime = nil
		lastRank = nil
	end
	updatePvPInstanceState()
end

function events.PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	-- Login or /reload, not a zone change: count the guildmates using the addon
	if isInitialLogin or isReloadingUi then loginCensus() end
	playerGUID = UnitGUID("player")
	playerName = UnitName("player")
	updatePvPInstanceState()
	-- New zone, new scoreboard: the killing blows already on it are the baseline
	kbBaseline = nil
	wipe(enemyDeaths)
	requestScoreData()
	C_Timer.After(2, requestScoreData)
	wipe(targetHealth)
	wipe(credited)
	wipe(watched)
	wipe(killedBy)
	killedByCount = 0
	-- First install: offer the setup once the loading screen is gone
	if not db.global.setupDone and not setupShownThisSession then
		setupShownThisSession = true
		C_Timer.After(3, function()
			if not db.global.setupDone then openSetup() end
		end)
	end
end

-- ---------------------------------------------------------------------------------------------
-- Tests: work anywhere, change no statistics, send nothing to other players
-- ---------------------------------------------------------------------------------------------
local function runTest(what)
	if what == "kill" then
		-- Feed the real scoreboard code a made-up scoreboard: a first reading (the baseline), then
		-- one more killing blow for us and one more death for "Test-Victim", delivered twice the
		-- way the game repeats its events. That must come out as exactly one kill.
		local savedBaseline, savedDeaths = kbBaseline, enemyDeaths
		kbBaseline, enemyDeaths = nil, {}
		testing = true
		local ok, err = pcall(function()
			testScore = { kb = 0, deaths = { ["Test-Victim"] = 0 } }
			events.UPDATE_BATTLEFIELD_SCORE()
			testScore = { kb = 1, deaths = { ["Test-Victim"] = 1 } }
			events.UPDATE_BATTLEFIELD_SCORE()
			events.UPDATE_BATTLEFIELD_SCORE()
		end)
		testScore = nil
		testing = false
		kbBaseline, enemyDeaths = savedBaseline, savedDeaths
		if not ok then chat("Test kill failed: " .. tostring(err)) end
	elseif what == "death" then
		testing = true
		local ok, err = pcall(registerDeath, "Test-Killer", false)
		testing = false
		if not ok then chat("Test death failed: " .. tostring(err)) end
	elseif what == "execute" then
		playSound(SOUND_EXECUTE)
	elseif what == "prepare" then
		playSound(SOUND_PREPARE)
	elseif what == "humiliation" then
		playHumiliation()
	elseif what == "emote" then
		-- Really sends: the kill emote and message, as set, with "Test-Victim"
		local profile = db.profile
		if not profile.dotxtemote and profile.doemote == "none" then
			chat("No kill emote is set: turn on \"Send a custom emote message\" or pick an emote on the General tab.")
			return
		end
		-- The built-in emote goes the automatic way a kill's does; the message is sent from this command
		if profile.doemote ~= "none" then social("emote", profile.doemote, nil) end
		if profile.dotxtemote then
			readyText = fill(profile.ksemote, { k = UnitName("player"), v = "Test-Victim", s = 1 })
			sendReadyEmote()
		end
	elseif what == "reset" then
		streak, deathstreak, multikill, lastKillTime, lastRank = 0, 0, 0, nil, nil
		chat("Current streaks reset.")
	else
		chat("Tests: /sks test kill, /sks test death, /sks test execute, /sks test prepare, /sks test emote (really sends it). "
			.. "Effects: /sks preview kill|rank|multi|big|death|other. Sync: /sks synctest, /sks who. Move: /sks unlock")
	end
end

-- ---------------------------------------------------------------------------------------------
-- First-run setup: a small window that walks through the main choices. Opens once on the first
-- login (account-wide), and again with /sks setup or the button on the General tab.
-- ---------------------------------------------------------------------------------------------
local setupFrame

local FLARE_PRESETS = {
	{ key = "full", name = "Full flare", desc = "Animated text, sparkles and screen flash",
		fx = { fancytext = true, sparkles = true, flash = true }, screen = true },
	{ key = "text", name = "Text only", desc = "Animated text, no sparkles or flash",
		fx = { fancytext = true, sparkles = false, flash = false }, screen = true },
	{ key = "plain", name = "Plain", desc = "Simple red lines, like the original addon",
		fx = { fancytext = false, sparkles = false, flash = false }, screen = true },
	{ key = "off", name = "Sounds only", desc = "Nothing on screen",
		fx = { fancytext = false, sparkles = false, flash = false }, screen = false },
}

local function currentPreset()
	local fx, profile = fxConfig(), db.profile
	for _, preset in ipairs(FLARE_PRESETS) do
		local match = (profile.doscreen and true or false) == preset.screen
		for key, value in pairs(preset.fx) do
			if (fx[key] and true or false) ~= value then match = false end
		end
		if match then return preset.key end
	end
	return nil
end

local function makeButton(parent, text, width, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 24)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

local function makeCheck(parent, label, get, set)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetSize(26, 26)
	local text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	text:SetPoint("LEFT", cb, "RIGHT", 2, 1)
	text:SetText(label)
	cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
	cb.refresh = function() cb:SetChecked(get() and true or false) end
	return cb
end

local function finishSetup(skipped)
	db.global.setupDone = true
	if setupFrame then setupFrame:Hide() end
	setAnchorUnlocked(false)
	if skipped then
		chat("Setup skipped. Type /sks setup to run it again, or /sks for all options.")
	else
		chat("All set! Type /sks for all options.")
	end
end

local function buildSetup()
	local f = CreateFrame("Frame", "SpicyKillStreaksSetup", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	f:SetSize(480, 340)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = WHITE, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		})
		f:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
		f:SetBackdropBorderColor(1, 0.45, 0.22, 1)
	else
		local bg = f:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
	end
	tinsert(UISpecialFrames, "SpicyKillStreaksSetup") -- Escape closes it

	local icon = f:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(CHILLI)
	icon:SetSize(36, 36)
	icon:SetPoint("TOPLEFT", 14, -12)
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
	local stepLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	stepLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -2, -2)
	close:SetScript("OnClick", function() finishSetup(true) end)

	local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	body:SetPoint("TOPLEFT", 18, -62)
	body:SetWidth(444)
	body:SetJustifyH("LEFT")
	body:SetJustifyV("TOP")
	body:SetSpacing(2)

	local back = makeButton(f, "Back", 90)
	back:SetPoint("BOTTOMLEFT", 12, 12)
	local nextButton = makeButton(f, "Next", 90)
	nextButton:SetPoint("BOTTOMRIGHT", -12, 12)
	local skip = makeButton(f, "Skip setup", 100, function() finishSetup(true) end)
	skip:SetPoint("BOTTOM", 0, 12)

	-- Each step: title, text, and its own widgets in a page frame
	local steps = {}
	local function addStep(stepTitle, text, build)
		local page = CreateFrame("Frame", nil, f)
		page:SetPoint("TOPLEFT", 18, -170)
		page:SetPoint("BOTTOMRIGHT", -18, 44)
		page:Hide()
		local refreshers = {}
		if build then build(page, refreshers) end
		steps[#steps + 1] = { title = stepTitle, text = text, page = page, refreshers = refreshers }
	end

	addStep("Welcome to " .. TITLE .. "!",
		"Announcer voices, combat text and sparkles when you land killing blows: killing sprees, "
		.. "multikills and duel wins.\n\nThis quick setup takes about 30 seconds. You can change "
		.. "everything later with |cffffd100/sks|r.",
		function(page)
			makeButton(page, "Play a sample", 140, function() preview("rank") end):SetPoint("TOPLEFT", 0, 0)
		end)

	addStep("Pick a voice",
		"Choose the announcer. Click a voice to hear it.",
		function(page, refreshers)
			local packs = { { "male", "Male" }, { "female", "Female" }, { "sexy", "Sexy" }, { "baby", "Baby" } }
			local buttons = {}
			for i, pack in ipairs(packs) do
				local b = makeButton(page, pack[2], 100, function()
					db.profile.soundpack = pack[1]
					local was = db.profile.dosound
					db.profile.dosound = true -- the sample plays even with sounds off
					playSound(RANK_SOUNDS[2])
					db.profile.dosound = was
					for _, r in ipairs(refreshers) do r() end
				end)
				b:SetPoint("TOPLEFT", (i - 1) * 108, 0)
				buttons[i] = { button = b, key = pack[1], label = pack[2] }
			end
			refreshers[#refreshers + 1] = function()
				for _, entry in ipairs(buttons) do
					entry.button:SetText(db.profile.soundpack == entry.key and ("> " .. entry.label .. " <") or entry.label)
				end
			end
			local sound = makeCheck(page, "Play sounds", function() return db.profile.dosound end,
				function(value) db.profile.dosound = value end)
			sound:SetPoint("TOPLEFT", 0, -36)
			refreshers[#refreshers + 1] = sound.refresh
		end)

	addStep("How much flare?",
		"What should appear on screen when you get a kill? Each choice plays a preview.",
		function(page, refreshers)
			local rows = {}
			for i, preset in ipairs(FLARE_PRESETS) do
				local b = makeButton(page, preset.name, 120, function()
					for key, value in pairs(preset.fx) do fxConfig()[key] = value end
					db.profile.doscreen = preset.screen
					if preset.screen then preview("rank") else playSound(RANK_SOUNDS[3]) end
					for _, r in ipairs(refreshers) do r() end
				end)
				b:SetPoint("TOPLEFT", 0, -(i - 1) * 26)
				local desc = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				desc:SetPoint("LEFT", b, "RIGHT", 10, 0)
				desc:SetText(preset.desc)
				rows[i] = { button = b, key = preset.key, name = preset.name }
			end
			local move = makeButton(page, "Move it", 90, function()
				setAnchorUnlocked(not anchorUnlocked)
				chat(anchorUnlocked and "Drag the orange box to where you want the text. It locks when setup closes."
					or "Position locked.")
			end)
			move:SetPoint("TOPRIGHT", 0, 0)
			refreshers[#refreshers + 1] = function()
				local active = currentPreset()
				for _, row in ipairs(rows) do
					row.button:SetText(row.key == active and ("> " .. row.name .. " <") or row.name)
				end
			end
		end)

	addStep("What counts as a kill",
		"Only your own killing blows count, not kills your group finishes. Players count everywhere; "
		.. "creatures only if you want them to.",
		function(page, refreshers)
			local options = {
				{ "Count NPC kills too (spammy, but great for trying it out)", function() return db.profile.dopve end,
					function(v) db.profile.dopve = v end },
				{ "\"Finish him!\" when an enemy player gets low", function() return db.profile.doexecute end,
					function(v) db.profile.doexecute = v end },
				{ "\"Finish him!\" when an NPC gets low (where the game shows addons its health)", function() return db.profile.doexecutepve end,
					function(v) db.profile.doexecutepve = v end },
			}
			for i, option in ipairs(options) do
				local cb = makeCheck(page, option[1], option[2], option[3])
				cb:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
				refreshers[#refreshers + 1] = cb.refresh
			end
		end)

	addStep("Share with friends?",
		"Share your kills and deaths with party and guild members who also run " .. TITLE
		.. ". Nothing is shared unless you tick a box. What you see from others is set under "
		.. "|cffffd100/sks|r > Sync.",
		function(page, refreshers)
			local party = makeCheck(page, "Share with my party (also raid, battleground and arena)",
				function() return syncConfig().shareparty end, function(v) syncConfig().shareparty = v end)
			party:SetPoint("TOPLEFT", 0, 0)
			local guild = makeCheck(page, "Share with my guild",
				function() return syncConfig().shareguild end, function(v) syncConfig().shareguild = v end)
			guild:SetPoint("TOPLEFT", 0, -28)
			refreshers[#refreshers + 1] = party.refresh
			refreshers[#refreshers + 1] = guild.refresh
		end)

	addStep("You're ready!",
		"|cffffd100/sks|r  all options\n|cffffd100/sks preview|r  show off the effects\n"
		.. "|cffffd100/sks test kill|r  simulate a kill\n|cffffd100/sks unlock|r  move the text\n"
		.. "|cffffd100/sks setup|r  this setup again",
		function(page)
			makeButton(page, "Simulate a kill", 140, function() runTest("kill") end):SetPoint("TOPLEFT", 0, 0)
		end)

	local current = 1
	local function show(index)
		current = math.max(1, math.min(index, #steps))
		for i, step in ipairs(steps) do step.page:SetShown(i == current) end
		local step = steps[current]
		title:SetText(step.title)
		stepLabel:SetText("Step " .. current .. " of " .. #steps)
		body:SetText(step.text)
		for _, refresh in ipairs(step.refreshers) do refresh() end
		back:SetEnabled(current > 1)
		skip:SetShown(current < #steps)
		nextButton:SetText(current == #steps and "Finish" or "Next")
	end
	back:SetScript("OnClick", function() show(current - 1) end)
	nextButton:SetScript("OnClick", function()
		if current == #steps then finishSetup(false) else show(current + 1) end
	end)
	f.showStep = show
	return f
end

openSetup = function()
	if not setupFrame then
		local ok, result = pcall(buildSetup)
		if not ok then
			chat("Could not open the setup window: " .. tostring(result))
			return
		end
		setupFrame = result
	end
	setupFrame.showStep(1)
	setupFrame:Show()
end

-- ---------------------------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------------------------
local function toggle(key, name, order, desc)
	return {
		type = "toggle", name = name, desc = desc, order = order, width = "full",
		get = function() return db.profile[key] end,
		set = function(_, value) db.profile[key] = value end,
	}
end

local function input(key, name, order, desc)
	return {
		type = "input", name = name, desc = desc, order = order, width = "full",
		get = function() return db.profile[key] end,
		set = function(_, value) db.profile[key] = value end,
	}
end

local function fxToggle(key, name, order, desc)
	return {
		type = "toggle", name = name, desc = desc, order = order, width = "full",
		get = function() return db.profile.fx[key] end,
		set = function(_, value) db.profile.fx[key] = value end,
	}
end

-- path: keys under db.profile.sync, e.g. { "party", "feed" }
local function syncToggle(path, name, order, desc)
	local function parent()
		local t = db.profile.sync
		for i = 1, #path - 1 do t = t[path[i]] end
		return t
	end
	local key = path[#path]
	return {
		type = "toggle", name = name, desc = desc, order = order, width = "full",
		get = function() return parent()[key] end,
		set = function(_, value) parent()[key] = value end,
	}
end

local function emoteSelect(key, name, order)
	return {
		type = "select", name = name, order = order, values = EMOTES,
		get = function() return db.profile[key] end,
		set = function(_, value) db.profile[key] = value end,
	}
end

local function button(name, order, func, desc)
	return { type = "execute", name = name, desc = desc, order = order, func = func }
end

local function header(name, order)
	return { type = "header", name = name, order = order }
end

local function note(text, order)
	return { type = "description", name = text, order = order, fontSize = "medium" }
end

local function topList(list, limit)
	local rows = {}
	for name, entry in pairs(list) do
		rows[#rows + 1] = { name = name, count = entry.count or 0, last = entry.last or "" }
	end
	if #rows == 0 then return "  nobody yet\n" end
	table.sort(rows, function(a, b)
		if a.count ~= b.count then return a.count > b.count end
		return a.name < b.name
	end)
	local lines = {}
	for i = 1, math.min(limit, #rows) do
		lines[i] = "  " .. rows[i].count .. " x " .. rows[i].name .. "  (last " .. rows[i].last .. ")"
	end
	return table.concat(lines, "\n") .. "\n"
end

local previewRank, previewMulti = 1, 1

local function buildOptions()
	local options = {
		type = "group",
		name = TITLE .. " " .. VERSION,
		childGroups = "tab",
		args = {
			general = {
				type = "group", name = "General", order = 1,
				args = {
					style = {
						type = "select", name = "When to play a kill sound", order = 1, width = "double",
						values = {
							dota = "On every kill (DotA / LoL style)",
							ut = "On the first kill and every few kills (Unreal Tournament style)",
						},
						get = function() return db.profile.style end,
						set = function(_, value) db.profile.style = value end,
					},
					dopve = toggle("dopve", "Count NPC kills too (spammy, good for testing)", 2,
						"Your killing blows on creatures count as kills, not only those on players."),
					dozonechange = toggle("dozonechange", "Reset streaks when changing zone", 3),
					setup = button("Run setup again", 4, function() openSetup() end),
					textHeader = header("Text", 10),
					dochat = toggle("dochat", "Print kills and deaths in the chat window", 11),
					doscreen = toggle("doscreen", "Show kills and deaths on screen", 12),
					kstext = input("kstext", "Kill text", 13, "$k = you, $v = victim, $s = streak"),
					emoteHeader = header("Emotes on a kill", 20),
					emoteNote = note("The emote plays by itself (after combat, if you are fighting). WoW Forever only lets "
						.. "a custom message go out from a key press, so a kill gets it ready and /sks emote sends it: "
						.. "put /sks emote in a macro on a key.", 20.5),
					doemote = emoteSelect("doemote", "Emote", 21),
					dotxtemote = toggle("dotxtemote", "Send a custom emote message", 22),
					ksemote = input("ksemote", "Custom emote message", 23, "$v = victim, $s = streak"),
				},
			},
			sounds = {
				type = "group", name = "Sounds", order = 2,
				args = {
					dosound = toggle("dosound", "Play sounds", 1),
					soundpack = {
						type = "select", name = "Voice pack", order = 2,
						values = { male = "Male", female = "Female", sexy = "Sexy", baby = "Baby" },
						get = function() return db.profile.soundpack end,
						set = function(_, value) db.profile.soundpack = value end,
					},
					soundchannel = {
						type = "select", name = "Sound channel", order = 3,
						values = { Master = "Master", SFX = "SFX", Ambience = "Ambience", Music = "Music", Dialog = "Dialog" },
						get = function() return db.profile.soundchannel end,
						set = function(_, value) db.profile.soundchannel = value end,
					},
					doprepare = toggle("doprepare", "Play \"prepare\" before a battleground or duel starts", 10),
					dodeathsound = toggle("dodeathsound", "Play \"humiliation\" when you die", 11),
					humiliationvoice = {
						type = "select", name = "Humiliation voice (plays when picked)", order = 12, width = "double",
						desc = "Each voice pack has its own recording. \"Custom\" plays sounds\\custom\\humiliation.ogg if you add one.",
						values = {
							humiliation = "Humiliation (default)", pack = "Same as the voice pack", male = "Male",
							female = "Female", sexy = "Sexy", baby = "Baby", custom = "Custom file",
						},
						get = function() return db.profile.humiliationvoice end,
						set = function(_, value)
							db.profile.humiliationvoice = value
							playHumiliation()
						end,
					},
					executeHeader = header("Finish him", 20),
					executeNote = note("WoW Forever hides enemy health from addons during combat, so this only "
						.. "works where the game still shows it. If it can't, you get one message in chat.", 20.5),
					doexecute = toggle("doexecute", "Play \"finish him\" when an enemy player target drops below the threshold", 21),
					doexecutepve = toggle("doexecutepve", "Play \"finish him\" when an NPC target drops below the threshold", 22),
					executepercent = {
						type = "range", name = "Threshold (percent health)", order = 23, width = "full",
						min = 5, max = 50, step = 1,
						get = function() return db.profile.executepercent end,
						set = function(_, value) db.profile.executepercent = value end,
					},
				},
			},
			effects = {
				type = "group", name = "Effects", order = 2.5,
				args = {
					about = note("Animated text, sparkles and a screen flash when you get kills. All optional.", 0),
					fancytext = fxToggle("fancytext", "Animated text (punches in and floats up; the colour follows your streak)", 1),
					font = {
						type = "select", name = "Font", order = 2, values = FONT_NAMES,
						get = function() return fxConfig().font end,
						set = function(_, value) fxConfig().font = value end,
						disabled = function() return not fxConfig().fancytext end,
					},
					scale = {
						type = "range", name = "Size", order = 3, min = 0.5, max = 2, step = 0.05, isPercent = true,
						get = function() return fxConfig().scale end,
						set = function(_, value) fxConfig().scale = value end,
					},
					sparkles = fxToggle("sparkles", "Sparkle burst on kills (bigger for new ranks and multikills)", 10),
					sparklestyle = {
						type = "select", name = "Sparkles", order = 11,
						values = { mix = "Mix", star = "Stars", chilli = "Chillies", confetti = "Confetti" },
						get = function() return fxConfig().sparklestyle end,
						set = function(_, value) fxConfig().sparklestyle = value end,
						disabled = function() return not fxConfig().sparkles end,
					},
					sparklecount = {
						type = "range", name = "How many", order = 12, min = 5, max = 80, step = 1,
						get = function() return fxConfig().sparklecount end,
						set = function(_, value) fxConfig().sparklecount = value end,
						disabled = function() return not fxConfig().sparkles end,
					},
					flash = fxToggle("flash", "Flash the screen edges on multikills and big streaks (Rampage and up)", 13),
					positionHeader = header("Position", 20),
					unlock = {
						type = "toggle", name = "Unlock: drag the orange box to move the text and sparkles", order = 21, width = "full",
						get = function() return anchorUnlocked end,
						set = function(_, value) setAnchorUnlocked(value) end,
					},
					resetPosition = button("Reset position", 22, function()
						fxConfig().x, fxConfig().y = defaults.profile.fx.x, defaults.profile.fx.y
						placeAnchor()
					end),
					previewHeader = header("Preview", 30),
					previewKill = button("Kill", 31, function() preview("kill") end),
					previewRank = button("New rank", 32, function() preview("rank") end),
					previewMulti = button("Multikill", 33, function() preview("multi") end),
					previewBig = button("The big one", 34, function() preview("big") end),
					previewDeath = button("Death", 35, function() preview("death") end),
					previewOther = button("Party member's kill", 36, function() preview("other") end),
				},
			},
			sync = {
				type = "group", name = "Sync", order = 2.7,
				args = {
					about = note("Share your kills and deaths with party and guild members who also run " .. TITLE
						.. ". Players without the addon see nothing. Sharing is off until you switch it on.", 0),
					shareHeader = header("Share my kills and deaths", 1),
					shareparty = syncToggle({ "shareparty" }, "Share with my party (also raid, battleground and arena)", 2),
					shareguild = syncToggle({ "shareguild" }, "Share with my guild", 3),
					logincount = syncToggle({ "logincount" }, "At login, tell me how many guildmates use the addon", 4,
						"Needs \"Share with my guild\". Counts guildmates who also share."),
					partyHeader = header("Kills and deaths shared by party members", 10),
					partyFeed = syncToggle({ "party", "feed" }, "Show their kills in the chat feed", 11),
					partyText = syncToggle({ "party", "text" }, "Show their kills as combat text on screen", 12),
					partySound = syncToggle({ "party", "sound" }, "Play their sounds (streaks, multikills, humiliation)", 13),
					partyDeaths = syncToggle({ "party", "deaths" }, "Also show when they die", 14),
					guildHeader = header("Kills and deaths shared by guild members", 20),
					guildFeed = syncToggle({ "guild", "feed" }, "Show their kills in the chat feed", 21),
					guildText = syncToggle({ "guild", "text" }, "Show their kills as combat text on screen", 22),
					guildSound = syncToggle({ "guild", "sound" }, "Play their sounds (streaks, multikills, humiliation)", 23),
					guildDeaths = syncToggle({ "guild", "deaths" }, "Also show when they die", 24),
					testHeader = header("Check it works", 30),
					testSync = button("Send a test kill", 31, sendTestSync),
					who = button("Who runs this addon?", 32, versionCheck,
						"Asks your group and guild; users of the addon who share their kills answer with their version."),
				},
			},
			ranks = {
				type = "group", name = "Ranks", order = 3,
				args = {
					about = note("Kills in a row needed for each streak sound (every-kill style). 0 switches a rank off.", 0),
					utrank = {
						type = "range", name = "Unreal Tournament style: kills between sounds", order = 20, width = "full",
						min = 1, max = 10, step = 1,
						get = function() return db.profile.utrank end,
						set = function(_, value) db.profile.utrank = value end,
					},
				},
			},
			duels = {
				type = "group", name = "Duels", order = 4,
				args = {
					dueltext = input("dueltext", "Duel win text", 1, "$k = you, $v = opponent, $s = streak"),
					duelhumiliation = toggle("duelhumiliation", "Play \"humiliation\" when you flee a duel", 2),
					duelemotewin = emoteSelect("duelemotewin", "Emote after a win", 3),
					duelemoteloss = emoteSelect("duelemoteloss", "Emote after a loss", 4),
				},
			},
			screenshots = {
				type = "group", name = "Screenshots", order = 5,
				args = {
					shotkill = toggle("shotkill", "On every kill", 1),
					shotstreak = toggle("shotstreak", "On a new longest killing streak", 2),
					shotmultikill = toggle("shotmultikill", "On a multikill", 3),
					shotduelwin = toggle("shotduelwin", "On a duel win", 4),
					shotduelloss = toggle("shotduelloss", "On a duel loss", 5),
					shotdeath = toggle("shotdeath", "On death", 6),
				},
			},
			stats = {
				type = "group", name = "Stats", order = 6,
				args = {
					streaks = {
						type = "description", order = 1, fontSize = "medium",
						name = function()
							return "Killing streak: " .. streak .. "  (longest " .. db.profile.maxstreak .. ")\n"
								.. "Death streak: " .. deathstreak .. "  (longest " .. db.profile.maxdeathstreak .. ")\n"
						end,
					},
					prey = {
						type = "description", order = 2, fontSize = "medium",
						name = function() return "Top prey:\n" .. topList(db.profile.kills, 5) end,
					},
					predators = {
						type = "description", order = 3, fontSize = "medium",
						name = function() return "Top predators:\n" .. topList(db.profile.deaths, 5) end,
					},
					log = {
						type = "description", order = 4,
						name = function()
							if #db.profile.log == 0 then return "Recent:\n  nothing yet\n" end
							return "Recent:\n  " .. table.concat(db.profile.log, "\n  ") .. "\n"
						end,
					},
					refresh = button("Refresh", 10, function() end),
					reset = {
						type = "execute", name = "Reset stats", order = 11, confirm = true,
						confirmText = "Delete all " .. TITLE .. " statistics?",
						func = function()
							local profile = db.profile
							streak, deathstreak, multikill, lastKillTime, lastRank = 0, 0, 0, nil, nil
							profile.maxstreak, profile.maxdeathstreak = 0, 0
							profile.log, profile.kills, profile.deaths = {}, {}, {}
						end,
					},
				},
			},
			tests = {
				type = "group", name = "Tests", order = 7,
				args = {
					about = note("These work anywhere. They change no statistics, do no emotes and take no screenshots, "
						.. "but test kills do raise the current killing streak so the sounds climb.", 0),
					status = {
						type = "description", order = 1, fontSize = "medium",
						name = function() return "Current killing streak: " .. streak .. "\n" end,
					},
					kill = button("Simulate a kill", 2, function() runTest("kill") end,
						"Runs a made-up scoreboard update through the real detection. Press again within 10 seconds for a multikill."),
					death = button("Simulate a death", 3, function() runTest("death") end,
						"Resets the killing streak, as dying does."),
					reset = button("Reset current streaks", 4, function() runTest("reset") end),
					soundHeader = header("Sounds", 10),
					execute = button("Finish him", 11, function() runTest("execute") end),
					prepare = button("Prepare", 12, function() runTest("prepare") end),
					humiliation = button("Humiliation", 13, function() runTest("humiliation") end),
					previewRank = {
						type = "select", name = "Play a streak sound", order = 14, values = RANK_NAMES,
						get = function() return previewRank end,
						set = function(_, value)
							previewRank = value
							playSound(RANK_SOUNDS[value])
						end,
					},
					previewMulti = {
						type = "select", name = "Play a multikill sound", order = 15, values = MULTI_TEXTS,
						get = function() return previewMulti end,
						set = function(_, value)
							previewMulti = value
							playSound(MULTI_SOUNDS[value])
						end,
					},
					fxHeader = header("Effects", 16),
					previewKill = button("Preview a kill", 17, function() preview("kill") end),
					previewBig = button("Preview the big one", 18, function() preview("big") end,
						"Wicked Sick and a Holy Shit multikill at once."),
					syncHeader = header("Sync", 19),
					testSync = button("Send a test kill to party/guild", 19.1, sendTestSync,
						"Other users of the addon see \"... killed Test-Victim! [test]\". Needs sharing switched on under Sync."),
					who = button("Who runs this addon?", 19.2, versionCheck),
					debugHeader = header("Troubleshooting", 20),
					debug = {
						type = "toggle", name = "Print what the kill detection sees to chat", order = 21, width = "full",
						get = function() return debugOn end,
						set = function(_, value) debugOn = value end,
					},
				},
			},
		},
	}
	for rank = 1, #RANK_NAMES do
		options.args.ranks.args["rank" .. rank] = {
			type = "range", name = RANK_NAMES[rank], order = rank, width = "full",
			min = (rank == 1) and 1 or 0, max = 50, step = 1,
			get = function() return db.profile.ksrank[rank] end,
			set = function(_, value) db.profile.ksrank[rank] = value end,
		}
	end
	return options
end

local optionsCategory

local function openOptions()
	if Settings and Settings.OpenToCategory and optionsCategory then
		if pcall(Settings.OpenToCategory, optionsCategory) then return end
	end
	LibStub("AceConfigDialog-3.0"):Open(ADDON)
end

-- ---------------------------------------------------------------------------------------------
-- Start-up
-- ---------------------------------------------------------------------------------------------
local function initialize()
	db = LibStub("AceDB-3.0"):New("SpicyKillStreaksDB", defaults, true)

	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(ADDON, buildOptions)
	local ok, _, category = pcall(function()
		return LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON, TITLE)
	end)
	if ok then optionsCategory = category end

	placeAnchor()
	registerPrefix()

	-- (/spicy is taken by the Spicy Side Quests addon)
	SLASH_SPICYKILLSTREAKS1 = "/sks"
	SLASH_SPICYKILLSTREAKS2 = "/killstreaks"
	SlashCmdList.SPICYKILLSTREAKS = function(text)
		local command = type(text) == "string" and strlower(strtrim(text)) or ""
		if command == "" then
			openOptions()
		elseif command == "unlock" or command == "lock" then
			setAnchorUnlocked(command == "unlock")
			chat(command == "unlock" and "Drag the orange box, then /sks lock." or "Position locked.")
		elseif command == "setup" then
			openSetup()
		elseif command == "who" then
			versionCheck()
		elseif command == "emote" then
			sendReadyEmote()
		elseif command == "synctest" then
			sendTestSync()
		elseif strmatch(command, "^preview") then
			preview(strmatch(command, "^preview%s+(%a+)$") or "big")
		elseif command == "debug" then
			debugOn = not debugOn
			chat("Detection debug output is " .. (debugOn and "ON" or "OFF") .. ".")
		elseif command == "test" then
			runTest("kill")
		else
			runTest(strmatch(command, "^test%s+(%a+)$") or "help")
		end
	end
end

frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON and not db then
			initialize()
			-- An event this client does not know or allow must not stop the others
			for name in pairs(events) do
				if not pcall(frame.RegisterEvent, frame, name) then
					chat("Could not register event " .. name .. "; the feature that uses it is off.")
				end
			end
		end
		return
	end
	local handler = events[event]
	if handler and db then handler(...) end
end)
frame:RegisterEvent("ADDON_LOADED")
