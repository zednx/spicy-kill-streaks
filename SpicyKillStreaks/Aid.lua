-- Spicy Kill Streaks: Request aid. When a player kills you (in the open world: nothing can be
-- sent from battlegrounds or arenas), a card offers "Need help!". One click asks your party and
-- guild (as far as you share with them) for help: friends running the addon get a card with who
-- killed you and, if you allow it, where, with "On my way" and "Waypoint" buttons. A friend who
-- then kills your killer gets "AVENGED!", and you see that they avenged you.
--
-- Messages (addon messages, like the rest):
--   "A", version, killer, killer level, zone, subzone, map ID, x, y, sender GUID   (a request)
--   "W", version, target GUID, sender GUID                                         (on my way)
-- Uses the card stack from Kudos.lua and talks to SpicyKillStreaks.lua through ns.core.
local ADDON, ns = ...

local aid = {}
ns.aid = aid

local function core() return ns.core end
local function cfg() return ns.core.db().profile.aid end
local function cards() return ns.kudos and ns.kudos.cards end
local function kit() return ns.ui and ns.ui.kit end

local OFFER_FOR = 30      -- seconds the "Need help!" card stays after our death
local REQUEST_FOR = 60    -- seconds a friend's request stays on screen
local COOLDOWN = 60       -- seconds between our requests
local CHAT_COOLDOWN = 60  -- seconds between public chat posts
local ANSWER_FOR = 180    -- seconds "on my way" answers are accepted after our request
local AVENGE_FOR = 600    -- seconds: killing the killer of a friend who asked counts as avenging

local lastRequest, lastChat = -COOLDOWN, -CHAT_COOLDOWN
local requestedAt         -- when we last asked for help
local requests = {}       -- killer key -> { who = friend, at = GetTime() }: requests we got
local seenFrom = {}       -- sender -> GetTime(): one request per friend per minute
aid.requests = requests

-- Text for a message field: no tabs, line breaks or escape codes, at most 40 characters
local function field(text)
	text = tostring(text or ""):gsub("[\t\r\n|]", " ")
	return strsub(strtrim(text), 1, 40)
end

local function firstName(name)
	local first = name and strmatch(name, "^[^%s%-]+")
	return first and strlower(first) or nil
end

-- Where we are: zone, subzone, and (only when the player allows it) map ID and position
local function whereAmI(withPosition)
	local zone = type(GetRealZoneText) == "function" and GetRealZoneText() or ""
	local sub = type(GetSubZoneText) == "function" and GetSubZoneText() or ""
	if type(zone) ~= "string" then zone = "" end
	if type(sub) ~= "string" then sub = "" end
	local mapID, x, y
	if withPosition and C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
		pcall(function()
			local id = C_Map.GetBestMapForUnit("player")
			local pos = id and C_Map.GetPlayerMapPosition(id, "player")
			if pos then
				local px, py = pos:GetXY()
				if type(id) == "number" and type(px) == "number" and type(py) == "number" then
					mapID, x, y = id, px, py
				end
			end
		end)
	end
	return zone, sub, mapID, x, y
end

-- "Ashenvale - Splintertree Post (52, 41)"
local function placeText(zone, sub, x, y)
	local text = zone ~= "" and zone or "somewhere"
	if sub ~= "" and sub ~= zone then text = text .. " - " .. sub end
	if x and y then text = text .. string.format(" (%d, %d)", math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5)) end
	return text
end
aid.placeText = placeText

local function killerText(killer, level)
	if level and level ~= 0 then return killer .. " (" .. (level < 0 and "??" or level) .. ")" end
	return killer
end

-- A text button on a card
local function cardButton(row, label, onClick, kind, width)
	local k = kit()
	if not k then return nil end
	local b = k.makeButton(row, label, onClick, kind or "secondary", width or 100, 24)
	b.text:SetFont(b.text:GetFont(), 11, "")
	return b
end

-- The channels we may send on: the group (if we share with it) and the guild (likewise)
local function shareChannels()
	local sync, list = core().db().profile.sync, {}
	if sync.shareparty and core().groupChannel() then list[#list + 1] = core().groupChannel() end
	if sync.shareguild and core().inGuild() then list[#list + 1] = "GUILD" end
	return list
end

-- Anyone to ask: the group, the guild, or online friends we share with (Friends.lua)
local function anyoneToAsk()
	if #shareChannels() > 0 then return true end
	local f = ns.friends
	return f and core().db().profile.sync.sharefriends and #f.online() > 0 or false
end

-- Send back to whoever a request came from: their channel, or a whisper for a friend
local function replyTo(req, message)
	if req.channel == "WHISPER" then
		if ns.friends then ns.friends.reply(req.sender, message) end
		return
	end
	local sync = core().db().profile.sync
	local channel
	if req.channel == "GUILD" then
		if sync.shareguild and core().inGuild() then channel = "GUILD" end
	elseif sync.shareparty then
		channel = core().groupChannel()
	end
	if channel then core().sendAddonMessage(message, channel) end
end

-- ---------------------------------------------------------------------------------------------
-- Asking for help
-- ---------------------------------------------------------------------------------------------
local function sendRequest(row, info)
	if row.sent then return end
	local now = GetTime()
	if not info.preview and now - lastRequest < COOLDOWN then
		row.sub:SetText("|cffff7733You asked a moment ago; wait a little.|r")
		return
	end
	row.sent = true
	local zone, sub, mapID, x, y = whereAmI(cfg().location)
	local place = placeText(zone, sub, x, y)
	if not info.preview then
		lastRequest, requestedAt = now, now
		local message = table.concat({ "A", core().VERSION, field(info.killer), tostring(info.level or 0), field(zone),
			field(sub), mapID and tostring(mapID) or "-", x and string.format("%.4f", x) or "-",
			y and string.format("%.4f", y) or "-", core().playerGUID() or "" }, "\t")
		for _, channel in ipairs(shareChannels()) do core().sendAddonMessage(message, channel) end
		if ns.friends then ns.friends.broadcast(message) end
		-- A public line too, when switched on (from the click itself, as WoW Forever requires)
		if cfg().chat and now - lastChat >= CHAT_COOLDOWN then
			local channel = core().groupChannel() or (core().inGuild() and "GUILD" or nil)
			if channel then
				lastChat = now
				pcall(SendChatMessage, "{cross} Need help in " .. place .. "! Killed by "
					.. killerText(info.killer, info.level) .. ".", channel)
			end
		end
	end
	local c = cards()
	if row.button then row.button:Hide() end
	c.setTone(row, "sent")
	row.label:SetText("|cff9a8f86Help requested|r" .. (info.preview and " |cff9a8f86(preview)|r" or ""))
	row.sub:SetText(place)
	c.expireAfter(row, 6, false)
end

local function withSubLine(row)
	local c = cards()
	row.sub = c.fontString(row, 11, 0.66, 0.61, 0.56)
	row.sub:SetPoint("TOPLEFT", c.TEXT_X, -27)
	row.sub:SetPoint("RIGHT", -12, 0)
	return row
end

-- A player killed us: offer "Need help!" (SpicyKillStreaks.lua calls this from our death)
function aid.offer(info)
	if not cfg().enabled or not cards() then return end
	if not info.preview then
		if core().inPvP() then return end -- nothing can be sent from battlegrounds or arenas
		if not anyoneToAsk() then return end
	end
	local c = cards()
	local row = withSubLine(c.newRow(80, "aid"))
	row.info = info
	row.label:SetText("|cffffffffKilled by|r |cffff7733" .. killerText(info.killer, info.level) .. "|r")
	row.sub:SetText("Ask your " .. (core().groupChannel() and "group and guild" or "guild") .. " for help?")
	row.button = cardButton(row, "Need help!", function() sendRequest(row, info) end, "primary", 110)
	if row.button then row.button:SetPoint("BOTTOMLEFT", c.PAD, 10) end
	c.expireAfter(row, OFFER_FOR, true)
	return row
end

-- ---------------------------------------------------------------------------------------------
-- A friend asking for help
-- ---------------------------------------------------------------------------------------------
local function setWaypoint(req)
	local ok = pcall(function()
		local point = UiMapPoint.CreateFromCoordinates(req.mapID, req.x, req.y)
		C_Map.SetUserWaypoint(point)
		if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
	end)
	if ok then
		core().chat("Waypoint set to " .. req.who .. ": " .. placeText(req.zone, req.sub, req.x, req.y) .. ".")
	else
		core().chat(req.who .. " is at " .. placeText(req.zone, req.sub, req.x, req.y) .. ".")
	end
end

local function sendOnMyWay(row, req)
	if row.answered then return end
	row.answered = true
	if not req.preview and req.guid then
		replyTo(req, table.concat({ "W", core().VERSION, req.guid, core().playerGUID() or "" }, "\t"))
	end
	if row.onMyWay then row.onMyWay:Hide() end
	row.label:SetText("|cff9a8f86On your way to|r " .. req.who .. (req.preview and " |cff9a8f86(preview)|r" or ""))
end

local function showRequest(req)
	local c = cards()
	local row = withSubLine(c.newRow(80, "aid"))
	row.label:SetText("|cffffffff" .. req.who .. "|r |cffff5544needs help!|r")
	row.sub:SetText(placeText(req.zone, req.sub, req.x, req.y) .. "  |cff9a8f86killed by|r " .. killerText(req.killer, req.level))
	row.onMyWay = cardButton(row, "On my way", function() sendOnMyWay(row, req) end, "primary", 100)
	if row.onMyWay then row.onMyWay:SetPoint("BOTTOMLEFT", c.PAD, 10) end
	if req.mapID then
		local way = cardButton(row, "Waypoint", function() setWaypoint(req) end, "secondary", 90)
		if way then way:SetPoint("BOTTOMLEFT", c.PAD + 106, 10) end
	end
	c.expireAfter(row, REQUEST_FOR, true)
	if cfg().sound and not req.silent then
		local special = core().special
		special.soundOnce = true
		pcall(core().playSound, 567397) -- the game's raid warning (sound/interface/raidwarning.ogg)
		special.soundOnce = false
	end
	return row
end

function aid.receive(sender, channel, fields)
	if not cfg().receive or not cards() or #fields < 10 then return end
	-- whispered: only from a friend, and not a muted one (Friends.lua)
	if channel == "WHISPER" and not (ns.friends and ns.friends.acceptsFeed(sender)) then return end
	local safe = core().safeText
	local who = safe(core().shortName(sender))
	local killer = safe(fields[3])
	if not who or not killer then return end
	who = who:gsub("%-.*$", "")
	-- One request per friend per minute
	local now = GetTime()
	if seenFrom[who] and now - seenFrom[who] < COOLDOWN then return end
	seenFrom[who] = now
	local level = tonumber(fields[4])
	if level then level = math.floor(level) if level < -1 or level > 255 then level = nil end end
	local mapID, x, y = tonumber(fields[7]), tonumber(fields[8]), tonumber(fields[9])
	if not (mapID and x and y and mapID > 0 and mapID < 100000 and x >= 0 and x <= 1 and y >= 0 and y <= 1) then
		mapID, x, y = nil, nil, nil
	end
	local guid = fields[10]
	if type(guid) ~= "string" or not guid:match("^Player%-[%w%-]+$") or #guid > 40 then guid = nil end
	local req = { who = who, killer = killer, level = level, zone = safe(fields[5]) or "", sub = safe(fields[6]) or "",
		mapID = mapID, x = x, y = y, guid = guid, channel = channel, sender = sender }
	local key = firstName(killer)
	if key then requests[key] = { who = who, at = now, guid = guid, channel = channel, sender = sender } end
	showRequest(req)
end

-- "On my way" from a friend, for our request
function aid.receiveOnMyWay(sender, channel, fields)
	if #fields < 4 or not cards() then return end
	local me = core().playerGUID()
	if not me or fields[3] ~= me then return end
	if not requestedAt or GetTime() - requestedAt > ANSWER_FOR then return end
	local who = core().safeText(core().shortName(sender))
	if not who then return end
	who = who:gsub("%-.*$", "")
	local c = cards()
	local row = c.newRow(32, "got")
	row.label:SetText("|cffffd04d" .. who .. "|r is on the way!")
	c.expireAfter(row, 8, false)
end

-- ---------------------------------------------------------------------------------------------
-- Avenged
-- ---------------------------------------------------------------------------------------------
-- We killed someone: the killer of a friend who asked us for help? Returns that request (once)
-- or nil. SpicyKillStreaks.lua makes the kill a Retribution and calls aid.notifyAvenged.
function aid.takeAvenge(victim)
	local key = firstName(victim)
	local req = key and requests[key]
	if not req or GetTime() - req.at > AVENGE_FOR then return nil end
	requests[key] = nil
	return req
end

-- Tell the friend we avenged them ("X", version, their GUID, the victim, our GUID), on the channel
-- their request came through, as far as we share there
function aid.notifyAvenged(req, victim)
	core().chat("You avenged " .. req.who .. ": " .. victim .. " is down.")
	if not req.guid or core().inPvP() then return end
	replyTo(req, table.concat({ "X", core().VERSION, req.guid, field(victim), core().playerGUID() or "" }, "\t"))
end

-- Shown once per killer: the friend's notice and their kill in the feed may both arrive
local avengedShown = {} -- killer key -> GetTime()
local function avengedOnce(key)
	if not key then return false end
	if avengedShown[key] and GetTime() - avengedShown[key] < 60 then return false end
	avengedShown[key] = GetTime()
	return true
end

local function showAvenged(who, victim)
	core().showText(who .. " AVENGED YOU!", "rank", 4)
	core().celebrate("rank", 4)
	core().chat(who .. " avenged you: " .. victim .. " is down.")
	local c = cards()
	if c then
		local row = c.newRow(32, "got")
		row.label:SetText("|cffffd04d" .. who .. "|r avenged you!  |cff8a8079" .. victim .. " is down|r")
		c.expireAfter(row, 8, false)
	end
end

-- "X": a friend avenged us
function aid.receiveAvenged(sender, channel, fields)
	if #fields < 5 then return end
	local me = core().playerGUID()
	if not me or fields[3] ~= me then return end
	local who = core().safeText(core().shortName(sender))
	local victim = core().safeText(fields[4])
	if not who or not victim then return end
	who = who:gsub("%-.*$", "")
	if not avengedOnce(firstName(victim)) then return end
	showAvenged(who, victim)
end

-- A friend killed someone: the player who killed us lately? (our recent killers, for Retribution)
function aid.allyKill(info)
	if info.kind ~= "K" or not info.other then return end
	local key = firstName(info.other)
	local list = core().db().char.recentKillers
	local when = key and list and list[key]
	if not when or time() - when > AVENGE_FOR then return end
	if not avengedOnce(key) then return end
	showAvenged(info.who or "A friend", info.other)
end

-- ---------------------------------------------------------------------------------------------
-- Previews
-- ---------------------------------------------------------------------------------------------
function aid.previewOffer()
	aid.offer({ killer = "Orcbro", level = 60, preview = true })
end

function aid.previewRequest()
	if not cards() then return end
	showRequest({ who = "Panda", killer = "Orcbro", level = 60, zone = "Ashenvale", sub = "Splintertree Post",
		mapID = 1440, x = 0.521, y = 0.413, preview = true })
end
