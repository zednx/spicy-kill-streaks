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
	-- (and off the Do not kill list)
	local _, dnkKey = kos.dnkFind(guid, entry.name)
	if dnkKey then kos.dnkRemove(dnkKey) end
	kos.guildChanged("+", guid, entry.nemesis and "N" or "K", entry.name)
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
	local _, dnkKey = kos.dnkFind(nil, clean)
	if dnkKey then kos.dnkRemove(dnkKey) end
	return true
end

function kos.remove(key)
	local list = store()
	list[key] = nil
	kos.guildChanged("-", key)
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
	kos.guildChanged("+", guid, entry.nemesis and "N" or "K", entry.name)
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
	-- On the Do not kill list: no nemesis, no offer (just the tally)
	if kos.dnkFind(guid, name) then return end
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

-- Any other player we have targeted (the Do not kill list): guid, name; or nil
function kos.targetPlayer()
	local ok, guid, name = pcall(function()
		if not UnitExists("target") or not UnitIsPlayer("target") or UnitIsUnit("target", "player") then return nil end
		return UnitGUID("target"), GetUnitName("target", true)
	end)
	if ok and isPlayerGUID(guid) and cleanName(name) then return guid, cleanName(name) end
	return nil
end

-- ---------------------------------------------------------------------------------------------
-- Do not kill: players we'd rather leave alone (friends on the other faction...). Added from the
-- target (kept by GUID) or by name. Targeting one reminds us, once per session.
-- ---------------------------------------------------------------------------------------------
local function dnkStore()
	local g = core().db().global
	g.dnk = g.dnk or {}
	return g.dnk
end
kos.dnkStore = dnkStore

-- Their entry and key: by GUID, else by name (a name entry found by GUID moves to the GUID)
function kos.dnkFind(guid, name)
	local list = dnkStore()
	if isPlayerGUID(guid) and list[guid] then return list[guid], guid end
	local key = nameKey(name)
	local entry = key and list[key]
	if entry and isPlayerGUID(guid) then
		list[key] = nil
		list[guid] = entry
		kos.guildChanged("+", guid, "D", entry.name)
		return entry, guid
	end
	return entry, key
end

function kos.dnkAdd(guid, name)
	local clean = cleanName(name)
	if not clean then return false, "no name" end
	if kos.dnkFind(guid, clean) then return false, clean .. " is already on it" end
	local key = isPlayerGUID(guid) and guid or nameKey(clean)
	dnkStore()[key] = { name = clean, added = time() }
	kos.guildChanged("+", key, "D", clean)
	-- (and off the KOS list)
	local list = store()
	if isPlayerGUID(guid) then list[guid] = nil end
	list[nameKey(clean)] = nil
	return true
end

function kos.dnkRemove(key)
	dnkStore()[key] = nil
	kos.guildChanged("-", key)
end

function kos.dnkSorted()
	local out = {}
	for key, entry in pairs(dnkStore()) do out[#out + 1] = { key = key, entry = entry } end
	table.sort(out, function(a, b) return (a.entry.name or "") < (b.entry.name or "") end)
	return out
end

local dnkReminded = {} -- key -> true: reminded this session
function kos.dnkCheck(unit)
	unit = unit or "target"
	local ok, guid, name = pcall(function()
		if not UnitExists(unit) or not UnitIsPlayer(unit) then return nil end
		return UnitGUID(unit), GetUnitName(unit, true)
	end)
	if not ok or not (isPlayerGUID(guid) or usable(name)) then return end
	local entry, key = kos.dnkFind(guid, name)
	if not entry or dnkReminded[key] then return end
	dnkReminded[key] = true
	local line = (entry.name or "?") .. " is on your Do not kill list."
	core().showText(line, "other")
	core().chat(line)
end

-- ---------------------------------------------------------------------------------------------
-- Guild sharing (optional): our KOS and Do not kill players (the ones known by GUID) go to
-- guildmates who share too, and theirs show on our tooltips (only there: no payback, sightings
-- or reminders for someone else's list).
--   "G", version, kind, guild, payload
--   kind "L": our whole list, at login (guildmates answer with theirs, "R"); "R": a reply;
--   "+": more entries (the rest of a long list, or one just added); "-": payload is a GUID taken off
--   payload: "K:<guid>:<name>;N:...;D:..." (K = KOS, N = nemesis, D = Do not kill)
-- ---------------------------------------------------------------------------------------------
local GUILD_MAX = 40      -- entries per player
local GUILD_SENDERS = 100 -- guildmates' lists kept
local function field(s) return (tostring(s or ""):gsub("[:;\t|\r\n]", "")) end

function kos.guildOn()
	local p = core().db().profile
	return cfg().enabled and cfg().guildshare and p.sync.shareguild and core().special.guildName() ~= nil
end

-- Guildmates' lists for our guild: sender -> { [guid] = { k = "K" | "N" | "D", n = name } }
local function guildLists()
	local guild = core().special.guildName()
	if not guild then return nil end
	local g = core().db().global
	g.guildLists = g.guildLists or {}
	g.guildLists[guild] = g.guildLists[guild] or {}
	return g.guildLists[guild]
end
kos.guildLists = guildLists

-- What we share: { k, guid, name }
function kos.myShared()
	local out = {}
	for key, e in pairs(store()) do
		if isPlayerGUID(key) and not e.unconfirmed then out[#out + 1] = { k = e.nemesis and "N" or "K", guid = key, name = e.name } end
	end
	for key, e in pairs(dnkStore()) do
		if isPlayerGUID(key) then out[#out + 1] = { k = "D", guid = key, name = e.name } end
	end
	while #out > GUILD_MAX do table.remove(out) end
	return out
end

-- Send entries: the first message has `kind`, the rest "+", half a second apart
function kos.guildSend(kind, items)
	if not kos.guildOn() or core().inPvP() then return end
	local function headFor(k) return table.concat({ "G", core().VERSION, k, field(core().special.guildName()) }, "\t") .. "\t" end
	local head = headFor(kind)
	local chunks, current = {}, ""
	for _, item in ipairs(items) do
		local piece = item.k .. ":" .. item.guid .. ":" .. field(item.name)
		if current ~= "" and #head + #current + #piece + 1 > 250 then
			chunks[#chunks + 1] = current
			current = ""
		end
		current = current == "" and piece or (current .. ";" .. piece)
	end
	chunks[#chunks + 1] = current
	for i, chunk in ipairs(chunks) do
		local message = (i == 1 and head or headFor("+")) .. chunk
		C_Timer.After((i - 1) * 0.5, function() core().sendAddonMessage(message, "GUILD") end)
	end
end

-- One of our entries changed: tell the guild ("+" with the entry, "-" with the GUID)
function kos.guildChanged(kind, guid, k, name)
	if not isPlayerGUID(guid) or not kos.guildOn() or core().inPvP() then return end
	if kind == "-" then
		core().sendAddonMessage(table.concat({ "G", core().VERSION, "-", field(core().special.guildName()), guid }, "\t"), "GUILD")
	else
		kos.guildSend("+", { { k = k, guid = guid, name = name } })
	end
end

local replyPending = false
function kos.guildReceive(sender, channel, fields)
	if channel ~= "GUILD" or not kos.guildOn() then return end
	if fields[4] ~= field(core().special.guildName()) then return end
	local kind, payload = fields[3], fields[5] or ""
	local who = core().safeText(core().shortName(sender))
	local lists = guildLists()
	if not who or not lists then return end
	if kind == "-" then
		if lists[who] and isPlayerGUID(payload) then lists[who][payload] = nil end
		return
	end
	if kind ~= "L" and kind ~= "R" and kind ~= "+" then return end
	if not lists[who] then
		local count = 0
		for _ in pairs(lists) do count = count + 1 end
		if count >= GUILD_SENDERS then return end
	end
	-- a whole list replaces what we had from them
	if kind == "L" or kind == "R" or not lists[who] then lists[who] = {} end
	local set, count = lists[who], 0
	for _ in pairs(set) do count = count + 1 end
	for item in payload:gmatch("[^;]+") do
		local k, guid, name = strmatch(item, "^([KND]):(Player%-[%w%-]+):([^:]*)$")
		if k and isPlayerGUID(guid) and (set[guid] or count < GUILD_MAX) then
			if not set[guid] then count = count + 1 end
			set[guid] = { k = k, n = cleanName(core().safeText(name)) }
		end
	end
	-- Their login list: answer with ours, once, after a random moment
	if kind == "L" and not replyPending then
		replyPending = true
		C_Timer.After(1 + math.random() * 4, function()
			replyPending = false
			kos.guildSend("R", kos.myShared())
		end)
	end
end

-- Guildmates who have this player on a list: kosBy, dnkBy (lists of names), or nil
function kos.guildMarks(guid)
	if not isPlayerGUID(guid) or not kos.guildOn() then return nil end
	local lists = guildLists()
	local kosBy, dnkBy = {}, {}
	for who, set in pairs(lists or {}) do
		local e = set[guid]
		if e then
			if e.k == "D" then dnkBy[#dnkBy + 1] = who else kosBy[#kosBy + 1] = who end
		end
	end
	table.sort(kosBy)
	table.sort(dnkBy)
	return kosBy, dnkBy
end

local function namesShort(list)
	local shown = {}
	for i = 1, math.min(2, #list) do shown[i] = list[i] end
	return table.concat(shown, ", ") .. (#list > 2 and (" +" .. (#list - 2)) or "")
end

-- The guild's line for a player's tooltip (when they're not on our own lists), or nil
function kos.guildLine(unit)
	local ok, guid = pcall(function() if UnitIsPlayer(unit) then return UnitGUID(unit) end end)
	if not ok or not isPlayerGUID(guid) then return nil end
	local kosBy, dnkBy = kos.guildMarks(guid)
	if kosBy and #kosBy > 0 then return "Guild KOS (" .. namesShort(kosBy) .. ")", 1, 0.54, 0.29 end
	if dnkBy and #dnkBy > 0 then return "Guild: Do not kill (" .. namesShort(dnkBy) .. ")", 0.4, 0.85, 0.45 end
	return nil
end

-- Tooltips: "KOS", "Nemesis" or "Do not kill" on a player's tooltip
function kos.tooltipLine(unit)
	local ok, guid, name = pcall(function()
		if not UnitIsPlayer(unit) then return nil end
		return UnitGUID(unit), GetUnitName(unit, true)
	end)
	if not ok or not (isPlayerGUID(guid) or usable(name)) then return nil end
	local entry = isPlayerGUID(guid) and kos.entry(guid)
	if entry then
		if entry.nemesis then return "Nemesis (KOS list)", 1, 0.27, 0.27 end
		return "KOS list", 1, 0.54, 0.29
	end
	if kos.dnkFind(guid, name) then return "Do not kill", 0.4, 0.85, 0.45 end
	return nil
end
local function onTooltip(tooltip)
	if not (ns.core and ns.core.db()) or not cfg().enabled then return end
	local ok, _, unit = pcall(tooltip.GetUnit, tooltip)
	if not ok or not usable(unit) then return end
	local line, r, g, b = kos.tooltipLine(unit)
	if not line then line, r, g, b = kos.guildLine(unit) end
	if line then
		tooltip:AddLine(line, r, g, b)
		pcall(tooltip.Show, tooltip)
	end
end
kos.onTooltip = onTooltip
-- (newer clients: TooltipDataProcessor; older: OnTooltipSetUnit. Either may be missing.)
pcall(function()
	local unitType = type(Enum) == "table" and type(Enum.TooltipDataType) == "table" and Enum.TooltipDataType.Unit
	if type(TooltipDataProcessor) == "table" and type(TooltipDataProcessor.AddTooltipPostCall) == "function" and unitType then
		TooltipDataProcessor.AddTooltipPostCall(unitType, function(tooltip)
			if tooltip == GameTooltip then pcall(onTooltip, tooltip) end
		end)
	elseif GameTooltip and GameTooltip.HookScript then
		GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip) pcall(onTooltip, tooltip) end)
	end
end)

-- At login (and /reload): our list to the guild, once the guild is known
local loginWatch = CreateFrame("Frame")
loginWatch:RegisterEvent("PLAYER_ENTERING_WORLD")
loginWatch:SetScript("OnEvent", function(_, _, isInitialLogin, isReloadingUi)
	if not (isInitialLogin or isReloadingUi) then return end
	C_Timer.After(15, function()
		if ns.core and ns.core.db() and kos.guildOn() then kos.guildSend("L", kos.myShared()) end
	end)
end)

local watch = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED" }) do
	pcall(watch.RegisterEvent, watch, event)
end
watch:SetScript("OnEvent", function(_, event, unit)
	if not (ns.core and ns.core.db()) then return end
	if event == "PLAYER_TARGET_CHANGED" then
		kos.sight("target")
		pcall(kos.dnkCheck, "target")
		if kos.onTarget then pcall(kos.onTarget) end
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		kos.sight("mouseover")
	elseif type(unit) == "string" and not (issecretvalue and issecretvalue(unit)) then
		kos.sight(unit)
	end
end)
