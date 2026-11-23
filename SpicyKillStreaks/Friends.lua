-- Spicy Kill Streaks: sharing with friends. Characters on your friends list, and Battle.net friends
-- playing WoW Forever on your realm (or a connected one) and faction, get your kills and deaths
-- (and Kudos and help requests) as addon whispers, one each, at most MAX_SEND per message. Off by
-- default ("Share with my friends"). Nothing is sent from battlegrounds or arenas.
--
-- Per friend: "Share with them" and "Show their kills" (mute). Muted names (friends or anyone in
-- the party or guild) are in db.global.muted.
--
-- Messages: "F?" / "F!", version, sharing with friends (1/0), sender GUID: "do you run it?" and the
-- answer, for the Friends list's status column.
-- Talks to SpicyKillStreaks.lua through ns.core.
local ADDON, ns = ...

local friends = {}
ns.friends = friends

local function core() return ns.core end
local function sync() return ns.core.db().profile.sync end
local function gdb() return ns.core.db().global end

local MAX_SEND = 10     -- friends whispered per message
local LIST_FOR = 5      -- seconds the online-friends list is kept before reading it again

local function usable(value)
	if issecretvalue and issecretvalue(value) then return false end
	return type(value) == "string" and value ~= ""
end

-- The key a name is saved under: lower case, no spaces, realm kept when there is one
local function keyOf(name)
	if not usable(name) then return nil end
	return strlower((name:gsub("%s", "")))
end
-- The same without the realm, for matching a sender who may arrive with or without it
local function shortKey(name)
	local key = keyOf(name)
	return key and (strsplit("-", key)) or nil
end
friends.keyOf = keyOf

local function myRealm()
	local realm = type(GetNormalizedRealmName) == "function" and GetNormalizedRealmName() or nil
	if not usable(realm) then realm = (type(GetRealmName) == "function" and GetRealmName() or ""):gsub("%s", "") end
	return realm
end

-- Realms we can whisper: ours and the ones connected to it
local function realmOk(realm)
	if not usable(realm) then return false end
	local wanted = strlower((realm:gsub("%s", "")))
	if wanted == strlower(myRealm()) then return true end
	if type(GetAutoCompleteRealms) == "function" then
		local ok, list = pcall(GetAutoCompleteRealms)
		if ok and type(list) == "table" then
			for _, r in ipairs(list) do
				if usable(r) and strlower((r:gsub("%s", ""))) == wanted then return true end
			end
		end
	end
	return false
end

local function myFaction()
	local ok, faction = pcall(UnitFactionGroup, "player")
	return ok and faction or nil
end

-- ---------------------------------------------------------------------------------------------
-- Who's online
-- ---------------------------------------------------------------------------------------------
local cache, cachedAt

-- Online friends we could whisper: { { name = whisper target, label, bnet = bool, key } }
function friends.online()
	local now = GetTime()
	if cache and cachedAt and now - cachedAt < LIST_FOR then return cache end
	local list, seen = {}, {}
	local function add(name, label, bnet)
		local key = keyOf(name)
		if not key or seen[key] then return end
		seen[key] = true
		list[#list + 1] = { name = name, label = label or name, bnet = bnet, key = key }
	end
	-- the friends list
	if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
		pcall(function()
			for i = 1, C_FriendList.GetNumFriends() or 0 do
				local info = C_FriendList.GetFriendInfoByIndex(i)
				if type(info) == "table" and info.connected == true and usable(info.name) then add(info.name) end
			end
		end)
	end
	-- Battle.net friends in this game, on our realm (or a connected one) and faction
	for _, game in ipairs(friends.bnetGames()) do
		if not friends.whyNot(game) then add(friends.bnetTarget(game), game.characterName, true) end
	end
	table.sort(list, function(a, b) return a.key < b.key end)
	cache, cachedAt = list, now
	return list
end

function friends.forget() cache = nil end

-- Every Battle.net friend's game account (online or not), as the client gives them
function friends.bnetGames()
	local games = {}
	if not (C_BattleNet and C_BattleNet.GetFriendAccountInfo and type(BNGetNumFriends) == "function") then return games end
	pcall(function()
		for i = 1, BNGetNumFriends() or 0 do
			local account = C_BattleNet.GetFriendAccountInfo(i)
			local game = type(account) == "table" and account.gameAccountInfo
			if type(game) == "table" then games[#games + 1] = game end
		end
	end)
	return games
end

local function myRealmID()
	if type(GetRealmID) ~= "function" then return nil end
	local ok, id = pcall(GetRealmID)
	return ok and type(id) == "number" and id or nil
end

-- Is a Battle.net friend's character on our realm (or a connected one)? By ID, name or display name
local function sameRealm(game)
	local id = myRealmID()
	if id and type(game.realmID) == "number" and game.realmID == id then return true end
	return realmOk(game.realmName) or realmOk(game.realmDisplayName)
end

-- Why a Battle.net friend isn't someone we can whisper, or nil when they are
function friends.whyNot(game)
	if game.isOnline ~= true then return "offline" end
	local wow = type(BNET_CLIENT_WOW) == "string" and BNET_CLIENT_WOW or "WoW"
	if game.clientProgram ~= wow then return "not in WoW (" .. tostring(game.clientProgram) .. ")" end
	if type(WOW_PROJECT_ID) == "number" and type(game.wowProjectID) == "number" and game.wowProjectID ~= WOW_PROJECT_ID then
		return "another WoW version (project " .. tostring(game.wowProjectID) .. ", ours " .. WOW_PROJECT_ID .. ")"
	end
	if not usable(game.characterName) then return "no character name" end
	local faction = myFaction()
	if faction and usable(game.factionName) and game.factionName ~= faction then return "other faction (" .. game.factionName .. ")" end
	if not sameRealm(game) then
		return "other realm (" .. tostring(game.realmName or game.realmDisplayName) .. " / id " .. tostring(game.realmID) .. ")"
	end
	return nil
end

-- The name to whisper a Battle.net friend's character by (with the realm when it's not ours)
function friends.bnetTarget(game)
	local target = game.characterName
	local theirRealm = usable(game.realmName) and game.realmName:gsub("%s", "") or nil
	if theirRealm and strlower(theirRealm) ~= strlower(myRealm()) then target = target .. "-" .. theirRealm end
	return target
end

-- /sks friends: every friend the addon can see, and why any is left out
function friends.explain()
	local lines = {}
	local function say(text) lines[#lines + 1] = text end
	say("We are " .. tostring(myFaction()) .. " on " .. tostring(myRealm()) .. " (realm id " .. tostring(myRealmID())
		.. "), WoW project " .. tostring(WOW_PROJECT_ID) .. ".")
	local n = 0
	if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
		pcall(function()
			for i = 1, C_FriendList.GetNumFriends() or 0 do
				local info = C_FriendList.GetFriendInfoByIndex(i)
				if type(info) == "table" then
					n = n + 1
					say("Friends list: " .. tostring(info.name) .. " - " .. (info.connected and "online, included" or "offline"))
				end
			end
		end)
	end
	if n == 0 then say("Friends list: empty (or not readable).") end
	local games = friends.bnetGames()
	if #games == 0 then say("Battle.net: no friends (or not readable).") end
	for _, game in ipairs(games) do
		local why = friends.whyNot(game)
		say("Battle.net: " .. tostring(game.characterName or "?") .. " - " .. (why or ("included, whispered as " .. friends.bnetTarget(game)))
			.. " [program " .. tostring(game.clientProgram) .. ", project " .. tostring(game.wowProjectID) .. ", realm "
			.. tostring(game.realmName) .. "/" .. tostring(game.realmDisplayName) .. "/" .. tostring(game.realmID)
			.. ", faction " .. tostring(game.factionName) .. "]")
	end
	return lines
end

-- Is this sender one of our online friends? (with or without a realm on either side)
function friends.isFriend(sender)
	local key, short = keyOf(sender), shortKey(sender)
	if not key then return false end
	for _, f in ipairs(friends.online()) do
		if f.key == key or (strsplit("-", f.key)) == short then return true, f end
	end
	return false
end

-- ---------------------------------------------------------------------------------------------
-- Choices per friend, and the mute list
-- ---------------------------------------------------------------------------------------------
local function prefs()
	local g = gdb()
	g.friends = g.friends or {}
	return g.friends
end

function friends.pref(name)
	local key = shortKey(name)
	local p = key and prefs()[key]
	return { share = not (p and p.share == false), show = not (p and p.show == false) }
end

function friends.setPref(name, field, value)
	local key = shortKey(name)
	if not key then return end
	local p = prefs()[key] or {}
	if value then p[field] = nil else p[field] = false end -- only "off" is saved
	prefs()[key] = next(p) and p or nil
end

local function muted()
	local g = gdb()
	g.muted = g.muted or {}
	return g.muted
end
friends.mutedList = muted

-- Muted: on the mute list, or a friend whose kills we chose not to show
function friends.isMuted(sender)
	local key = shortKey(sender)
	if not key then return false end
	if muted()[key] then return true end
	local p = prefs()[key]
	return p ~= nil and p.show == false
end

function friends.mute(name, on)
	local key = shortKey(name)
	if not key then return false end
	muted()[key] = on and (name:gsub("%-.*$", "")) or nil
	return true
end

-- ---------------------------------------------------------------------------------------------
-- Sending
-- ---------------------------------------------------------------------------------------------
-- In our party or raid already (they get it through the group)
local function inOurGroup(name)
	for _, check in ipairs({ UnitInParty, UnitInRaid }) do
		if type(check) == "function" then
			local ok, result = pcall(check, (name:gsub("%-.*$", "")))
			if ok and result and not (issecretvalue and issecretvalue(result)) then return true end
		end
	end
	return false
end

-- A message to every online friend we share with (kills, deaths, help requests)
function friends.broadcast(message)
	if not sync().sharefriends or core().inPvP() then return end
	local sent = 0
	for _, f in ipairs(friends.online()) do
		if sent >= MAX_SEND then break end
		if friends.pref(f.name).share and not inOurGroup(f.name) then
			core().sendAddonMessage(message, "WHISPER", f.name)
			sent = sent + 1
		end
	end
end

-- One whisper back to a friend (a Kudos reaction, "on my way", "avenged")
function friends.reply(name, message)
	if not sync().sharefriends or core().inPvP() or not usable(name) then return end
	core().sendAddonMessage(message, "WHISPER", name)
end

-- ---------------------------------------------------------------------------------------------
-- "Do you run it?" for the Friends list
-- ---------------------------------------------------------------------------------------------
friends.status = {} -- short key -> { version, sharing = bool, at = GetTime() }

local function hello(kind)
	return table.concat({ kind, core().VERSION, sync().sharefriends and "1" or "0", core().playerGUID() or "" }, "\t")
end

-- Ask every online friend (it's an explicit question, so it goes out whatever the share setting).
-- announce: print each answer in chat (/sks who), for the next few seconds
function friends.check(announce)
	if core().inPvP() then return 0 end
	friends.announceUntil = announce and GetTime() + 8 or nil
	local asked = 0
	for _, f in ipairs(friends.online()) do
		if asked >= 50 then break end
		core().sendAddonMessage(hello("F?"), "WHISPER", f.name)
		asked = asked + 1
	end
	return asked
end

function friends.receive(sender, channel, fields)
	if channel ~= "WHISPER" or not friends.isFriend(sender) then return end
	local key = shortKey(sender)
	local version = core().safeText(fields[2])
	if key then friends.status[key] = { version = version or "?", sharing = fields[3] == "1", at = GetTime() } end
	if fields[1] == "F!" and friends.announceUntil and GetTime() <= friends.announceUntil then
		local who = core().safeText(core().shortName(sender)) or "A friend"
		core().chat(who:gsub("%-.*$", "") .. " (friend) runs " .. core().TITLE .. " " .. (version or "?")
			.. (fields[3] == "1" and ", sharing with friends." or ", not sharing with friends."))
	end
	if fields[1] == "F?" then
		-- answer, so they see we run it (and whether we share)
		core().sendAddonMessage(hello("F!"), "WHISPER", sender)
	end
	if friends.onStatus then pcall(friends.onStatus) end
end

-- Should a whispered kill or death be shown? Only from a friend, and not when muted
function friends.acceptsFeed(sender)
	return friends.isFriend(sender) and not friends.isMuted(sender)
end
