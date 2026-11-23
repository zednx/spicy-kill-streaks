-- Spicy Kill Streaks: the KOS (kill on sight) list and nemeses.
--
--   * Rivals: every player who kills us, and whom we kill, is tallied by GUID (never by name:
--     family names repeat).
--   * Add to KOS: after a player kills us for the second time, a card offers to add them.
--   * Nemesis: a player who kills us NEMESIS_AT times in a row (without us killing them back) is
--     added by itself, as our nemesis.
--   * Payback: killing someone on the list is "GRUDGE SETTLED!" / "NEMESIS SLAIN!", a Retribution
--     with no time limit (SpicyKillStreaks.lua plays it, from kos.onKill).
--   * Sightings: a listed player as our target, mouseover or on a nameplate gets an alert.
--   * By hand: /sks kos <name> or the KOS page. A typed name has no GUID, so it's "unconfirmed"
--     until we see a player with that name and say yes; only then does payback play for it.
--
-- Everything matches by GUID, and only when the GUID is readable (it can be secret in some content).
-- Talks to SpicyKillStreaks.lua through ns.core; cards come from Kudos.lua's stack.
local ADDON, ns = ...

local kos = {}
ns.kos = kos

local function core() return ns.core end
local function cfg() return ns.core.db().profile.kos end
local function cards() return ns.kudos and ns.kudos.cards end
local function kit() return ns.ui and ns.ui.kit end

local NEMESIS_AT = 3      -- deaths in a row to one player without killing them back
local OFFER_AT = 2        -- deaths to one player before "Add to KOS?" is offered
local SIGHT_EVERY = 120   -- seconds between two sighting alerts for the same player
local RIVALS_MAX = 300    -- players tallied (the oldest go)
local NAME_MAX = 40
kos.NEMESIS_AT = NEMESIS_AT

local function usable(value)
	if issecretvalue and issecretvalue(value) then return false end
	return type(value) == "string" and value ~= ""
end

local function isPlayerGUID(guid)
	return usable(guid) and #guid <= 40 and guid:match("^Player%-[%w%-]+$") ~= nil
end

-- A typed or seen name, cleaned: no escape codes or line breaks, no realm, capped
local function cleanName(name)
	if not usable(name) then return nil end
	name = strtrim((name:gsub("[|\r\n\t]", "")))
	name = name:gsub("%-.*$", "")
	if name == "" then return nil end
	return strsub(name, 1, NAME_MAX)
end

local function nameKey(name)
	local clean = cleanName(name)
	return clean and ("name:" .. strlower((clean:gsub("%s", "")))) or nil
end

local function store()
	local g = core().db().global
	g.kos = g.kos or {}
	g.rivals = g.rivals or {}
	return g.kos, g.rivals
end
kos.store = store

-- The list entry for a GUID, or nil
function kos.entry(guid)
	if not isPlayerGUID(guid) then return nil end
	local list = store()
	return list[guid]
end

-- ---------------------------------------------------------------------------------------------
-- The list
-- ---------------------------------------------------------------------------------------------
-- Add a player we know by GUID (from a death, a kill or a sighting)
function kos.add(guid, name, nemesis)
	if not isPlayerGUID(guid) then return nil end
	local list, rivals = store()
	local entry = list[guid]
	if not entry then
		local rival = rivals[guid] or {}
		entry = { name = cleanName(name) or rival.name or "?", killedMe = rival.killedMe or 0, iKilled = rival.iKilled or 0,
			added = time() }
		list[guid] = entry
	end
	if nemesis then entry.nemesis = true end
	return entry
end

-- Add a player by name (typed): unconfirmed until we see them and say it's them
function kos.addByName(name)
	local clean, key = cleanName(name), nameKey(name)
	if not clean then return false, "no name" end
	local list = store()
	for guid, entry in pairs(list) do
		if entry.name and nameKey(entry.name) == key then return false, clean .. " is already on your list" end
	end
	list[key] = { name = clean, killedMe = 0, iKilled = 0, added = time(), unconfirmed = true }
	return true
end

function kos.remove(key)
	local list = store()
	list[key] = nil
end

-- Link a typed name to the player we just saw: from now on it matches by GUID
function kos.confirm(key, guid, name)
	local list, rivals = store()
	local entry = list[key]
	if not entry or not isPlayerGUID(guid) then return nil end
	list[key] = nil
	local rival = rivals[guid] or {}
	entry.unconfirmed = nil
	entry.name = cleanName(name) or entry.name
	entry.killedMe = math.max(entry.killedMe or 0, rival.killedMe or 0)
	entry.iKilled = math.max(entry.iKilled or 0, rival.iKilled or 0)
	list[guid] = entry
	return entry
end

-- The list, sorted: nemeses first, then by deaths to them
function kos.sorted()
	local list = store()
	local out = {}
	for key, entry in pairs(list) do out[#out + 1] = { key = key, entry = entry } end
	table.sort(out, function(a, b)
		local ea, eb = a.entry, b.entry
		if (ea.nemesis and 1 or 0) ~= (eb.nemesis and 1 or 0) then return ea.nemesis and true or false end
		if (ea.killedMe or 0) ~= (eb.killedMe or 0) then return (ea.killedMe or 0) > (eb.killedMe or 0) end
		return (ea.name or "") < (eb.name or "")
	end)
	return out
end

-- Rivals not on the list, most deaths to them first
function kos.rivals(count)
	local list, rivals = store()
	local out = {}
	for guid, rival in pairs(rivals) do
		if not list[guid] and (rival.killedMe or 0) > 0 then out[#out + 1] = { guid = guid, rival = rival } end
	end
	table.sort(out, function(a, b) return (a.rival.killedMe or 0) > (b.rival.killedMe or 0) end)
	while #out > (count or 10) do table.remove(out) end
	return out
end

local function rivalOf(guid, name)
	local _, rivals = store()
	local rival = rivals[guid]
	if not rival then
		local count, oldest, oldestAt = 0, nil, nil
		for g, r in pairs(rivals) do
			count = count + 1
			if not oldestAt or (r.last or 0) < oldestAt then oldest, oldestAt = g, r.last or 0 end
		end
		if count >= RIVALS_MAX and oldest then rivals[oldest] = nil end
		rival = { killedMe = 0, iKilled = 0, onMe = 0 }
		rivals[guid] = rival
	end
	rival.name = cleanName(name) or rival.name
	rival.last = time()
	return rival
end

-- ---------------------------------------------------------------------------------------------
-- Cards (in the Kudos/Request help stack)
-- ---------------------------------------------------------------------------------------------
local function card(tone, title, sub, buttons, seconds)
	local c = cards()
	local k = kit()
	if not c or not k then return nil end
	local row = c.newRow(buttons and 80 or 50, tone)
	row.label:SetText(title)
	row.sub = c.fontString(row, 11, 0.66, 0.61, 0.56)
	row.sub:SetPoint("TOPLEFT", c.TEXT_X, -27)
	row.sub:SetPoint("RIGHT", -12, 0)
	row.sub:SetText(sub or "")
	local x = c.PAD
	for _, b in ipairs(buttons or {}) do
		local button = k.makeButton(row, b[1], function()
			b[2]()
			c.removeRow(row)
		end, b[3] or "secondary", nil, 24)
		button.text:SetFont(button.text:GetFont(), 11, "")
		button:SetWidth(math.max(70, (button.text:GetStringWidth() or 50) + 22))
		button:SetPoint("BOTTOMLEFT", x, 10)
		x = x + button:GetWidth() + 6
	end
	c.expireAfter(row, seconds or 20, buttons ~= nil)
	return row
end
kos.card = card

-- ---------------------------------------------------------------------------------------------
-- Deaths and kills (from SpicyKillStreaks.lua)
-- ---------------------------------------------------------------------------------------------
-- A player killed us (guid from the Death Recap; level as seen, or nil)
function kos.onDeath(killer, guid, level)
	if not cfg().enabled or not isPlayerGUID(guid) then return end
	local rival = rivalOf(guid, killer)
	rival.killedMe = (rival.killedMe or 0) + 1
	rival.onMe = (rival.onMe or 0) + 1
	local entry = kos.entry(guid)
	local name = cleanName(killer) or rival.name or "?"
	if entry then
		entry.killedMe = (entry.killedMe or 0) + 1
		entry.name = name
		if entry.nemesis then
			core().showText("Your nemesis " .. name .. " strikes again!", "death")
		else
			core().chat(name .. " (on your KOS list) has killed you " .. entry.killedMe .. " times.")
		end
		return
	end
	-- A typed name on the list that matches: ask whether it's them
	local list = store()
	local key = nameKey(name)
	if key and list[key] and list[key].unconfirmed then
		kos.askConfirm(key, guid, name, level)
		return
	end
	if cfg().nemesis and rival.onMe >= NEMESIS_AT then
		entry = kos.add(guid, name, true)
		core().showText(name .. " IS NOW YOUR NEMESIS!", "death")
		core().chat(name .. " has killed you " .. rival.onMe .. " times in a row: your nemesis, on your KOS list.")
		return
	end
	if cfg().offer and rival.killedMe >= OFFER_AT then
		card("death", "|cffffffff" .. name .. "|r |cff9aa3b8has killed you " .. rival.killedMe .. " times|r",
			"Add them to your kill-on-sight list?", {
				{ "Add to KOS", function()
					kos.add(guid, name)
					core().chat(name .. " is on your KOS list.")
				end, "primary" },
			}, 20)
	end
end

-- We killed a player: tally it, and return their list entry for payback (or nil)
function kos.onKill(victim, guid)
	if not cfg().enabled or not isPlayerGUID(guid) then return nil end
	local rival = rivalOf(guid, victim)
	rival.iKilled = (rival.iKilled or 0) + 1
	rival.onMe = 0
	local entry = kos.entry(guid)
	if entry then
		entry.iKilled = (entry.iKilled or 0) + 1
		entry.name = cleanName(victim) or entry.name
	end
	return entry
end

-- ---------------------------------------------------------------------------------------------
-- Sightings
-- ---------------------------------------------------------------------------------------------
local lastSeen = {}      -- guid -> GetTime() of the last alert
local declined = {}      -- name key -> true: "not that one", this session
local asking = {}        -- name key -> true: a confirm card is up

function kos.askConfirm(key, guid, name, level)
	if asking[key] or declined[key] then return end
	asking[key] = true
	local row = card("aid", "|cffffffffIs this the " .. name .. " on your KOS list?|r",
		(level and level ~= 0 and ("Level " .. (level < 0 and "??" or level) .. ". ") or "") .. "From now on they'd match exactly.", {
			{ "Yes", function()
				asking[key] = nil
				if kos.confirm(key, guid, name) then core().chat(name .. " is confirmed on your KOS list.") end
			end, "primary" },
			{ "No", function()
				asking[key] = nil
				declined[key] = true
			end },
		}, 30)
	if not row then asking[key] = nil end
	C_Timer.After(31, function() asking[key] = nil end)
end

local function levelOf(unit)
	local ok, level = pcall(UnitLevel, unit)
	if ok and type(level) == "number" and not (issecretvalue and issecretvalue(level)) then return level end
	return nil
end

-- An enemy player we can see (target, mouseover, nameplate): on the list?
function kos.sight(unit)
	if not cfg().enabled or not cfg().sightings then return end
	local ok, guid, name = pcall(function()
		if not UnitExists(unit) or not UnitIsPlayer(unit) or not UnitCanAttack("player", unit) then return nil end
		return UnitGUID(unit), GetUnitName(unit, true)
	end)
	if not ok or not isPlayerGUID(guid) then return end
	local entry = kos.entry(guid)
	local level = levelOf(unit)
	if entry then
		local now = GetTime()
		if lastSeen[guid] and now - lastSeen[guid] < SIGHT_EVERY then return end
		lastSeen[guid] = now
		local label = (entry.nemesis and "NEMESIS: " or "KOS: ") .. (entry.name or "?")
			.. (level and (" (" .. (level < 0 and "??" or level) .. ")") or "") .. " nearby!"
		core().showText(label, "death")
		core().chat(label)
		if cfg().sightsound then kos.playSight(cfg().sightkit) end
		return
	end
	-- an unconfirmed typed name: "possibly", and ask
	local key = nameKey(name)
	local list = store()
	if key and list[key] and list[key].unconfirmed and not declined[key] then
		local now = GetTime()
		if not (lastSeen[key] and now - lastSeen[key] < SIGHT_EVERY) then
			lastSeen[key] = now
			core().chat("KOS? " .. (cleanName(name) or "?") .. " nearby (unconfirmed).")
		end
		kos.askConfirm(key, guid, cleanName(name), level)
	end
end

-- Sighting sounds: the game's own, by sound kit name (looked up when played: a client without
-- one plays the raid warning instead)
kos.SIGHT_SOUNDS = {
	{ key = "raidwarning", label = "Raid warning" },
	{ key = "bosswarning", label = "Boss warning", kit = "RAID_BOSS_EMOTE_WARNING" },
	{ key = "alarm", label = "Alarm clock", kit = "ALARM_CLOCK_WARNING_3" },
	{ key = "readycheck", label = "Ready check", kit = "READY_CHECK" },
	{ key = "queue", label = "PvP queue pop", kit = "PVP_THROUGH_QUEUE" },
	{ key = "whisper", label = "Whisper", kit = "TELL_MESSAGE" },
	{ key = "drum", label = "Alarm drum", file = 1487136 }, -- sound/doodad/fx_alarm_drum_hit_01.ogg
	{ key = "agony", label = "\"Eternal agony awaits you!\"", file = 543937 }, -- a creature's aggro line
	{ key = "chime", label = "Chime", file = 4191882 }, -- sound/ui/content_tracking_objective_tracking_start
}
function kos.playSight(key, forced)
	local special = core().special
	if not forced and (not core().db().profile.dosound or special.soundMuted()) then return end
	local kit, file
	for _, s in ipairs(kos.SIGHT_SOUNDS) do if s.key == key then kit, file = s.kit, s.file end end
	if file then
		local ok, played = pcall(PlaySoundFile, file, core().db().profile.soundchannel or "Master")
		if ok and played then return true end
	end
	local id = kit and type(SOUNDKIT) == "table" and SOUNDKIT[kit]
	if type(id) == "number" then
		local ok, played = pcall(PlaySound, id, core().db().profile.soundchannel or "Master")
		if ok and played ~= false then return end
	end
	-- the game's raid warning (also when the kit is missing)
	local ok, played = pcall(PlaySoundFile, 567397, core().db().profile.soundchannel or "Master")
	return ok and played
end

-- The enemy player we have targeted, for the KOS page's "Add": guid, name; or nil
function kos.targetEnemy()
	local ok, guid, name = pcall(function()
		if not UnitExists("target") or not UnitIsPlayer("target") or not UnitCanAttack("player", "target") then return nil end
		return UnitGUID("target"), GetUnitName("target", true)
	end)
	if ok and isPlayerGUID(guid) and cleanName(name) then return guid, cleanName(name) end
	return nil
end

local watch = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED" }) do
	pcall(watch.RegisterEvent, watch, event)
end
watch:SetScript("OnEvent", function(_, event, unit)
	if not (ns.core and ns.core.db()) then return end
	if event == "PLAYER_TARGET_CHANGED" then
		kos.sight("target")
		if kos.onTarget then pcall(kos.onTarget) end
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		kos.sight("mouseover")
	elseif type(unit) == "string" and not (issecretvalue and issecretvalue(unit)) then
		kos.sight(unit)
	end
end)
