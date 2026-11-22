-- Spicy Kill Streaks: Kudos. When a party or guild member running the addon gets a kill or dies,
-- a small popup offers a reaction ("Zug zug!", "For the Horde!", "Hell yeah!", thumbs up; "RIP",
-- "F" for a death). The reaction travels as a hidden addon message on the channel the kill came
-- from, addressed to that player's GUID, so only they show it (on their own kudos popup).
-- Optionally it is also posted as a normal chat line, which everyone sees.
--
-- Talks to SpicyKillStreaks.lua through ns.core, and borrows the drawing kit from UI.lua.
--
-- Message: "R", version, target GUID, reaction id, "K"/"D", faction ("H"/"A"/"-"), sender GUID
local ADDON, ns = ...

local kudos = {}
ns.kudos = kudos

local function core() return ns.core end
local function cfg() return ns.core.db().profile.kudos end
local function kit() return ns.ui and ns.ui.kit end

local SHOW_FOR = 30        -- seconds a friend's kill or death stays offered
local GOT_FOR = 8          -- seconds a kudos we got stays on screen
local ACCEPT_FOR = 45      -- kudos are accepted this long after our own kill or death
local CHAT_COOLDOWN = 15   -- seconds between reaction posts in chat
local MAX_ROWS = 4
local ROW_W = 300

-- Reactions: id -> { label, kind = "K" (for a kill) or "D" (for a death) }
local REACTIONS = {
	zug = { label = "Zug zug!", kind = "K" },
	faction = { kind = "K" }, -- "For the Horde!" / "For the Alliance!": the sender's own faction
	hell = { label = "Hell yeah!", kind = "K" },
	thumbs = { label = "Thumbs up!", kind = "K" },
	rip = { label = "RIP", kind = "D" },
	f = { label = "F", kind = "D" },
}
local KILL_ORDER = { "zug", "faction", "hell", "thumbs" }
local DEATH_ORDER = { "rip", "f" }
local FACTION_TEXT = { H = "For the Horde!", A = "For the Alliance!" }
kudos.REACTIONS, kudos.KILL_ORDER, kudos.DEATH_ORDER = REACTIONS, KILL_ORDER, DEATH_ORDER

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

-- The words of a reaction: faction is the sender's ("H"/"A"), for "For the ..."
local function reactionText(id, faction)
	if id == "faction" then return FACTION_TEXT[faction] end
	return REACTIONS[id] and REACTIONS[id].label
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
-- The popup: a movable stack of rows. A friend's row has reaction buttons and a timer bar; a
-- kudos we got is a single line.
-- ---------------------------------------------------------------------------------------------
local holder, rows, mover = nil, {}, nil
kudos.rows = rows -- (for the smoke test)

local function place()
	if not holder then return end
	holder:ClearAllPoints()
	holder:SetPoint("TOP", UIParent, "CENTER", cfg().x or 0, cfg().y or -160)
end

local function layout()
	local y = 0
	for _, row in ipairs(rows) do
		row:ClearAllPoints()
		row:SetPoint("TOP", holder, "TOP", 0, -y)
		y = y + row.height + 4
	end
	holder:SetHeight(math.max(y, 1))
end

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
	holder:SetSize(ROW_W, 1)
	holder:SetFrameStrata("MEDIUM")
	holder:SetClampedToScreen(true)
	holder:SetMovable(true)
	place()
	return holder
end

local function newRow(height)
	ensureHolder()
	local k = kit()
	local row = CreateFrame("Frame", nil, holder, "BackdropTemplate")
	row:SetSize(ROW_W, height)
	row.height = height
	if k then k.paint(row, k.COLORS.bg, 0.92) end
	row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.label:SetPoint("TOPLEFT", 10, -8)
	row.label:SetPoint("RIGHT", -26, 0)
	row.label:SetJustifyH("LEFT")
	if k then
		local close = k.makeClose(row, function() removeRow(row) end)
		close:SetSize(22, 22)
		close:SetPoint("TOPRIGHT", -2, -2)
	end
	-- Keep at most MAX_ROWS: the oldest goes
	if #rows >= MAX_ROWS then removeRow(rows[1]) end
	rows[#rows + 1] = row
	row:Show()
	layout()
	return row
end

-- Hide the row after `seconds`, with a timer bar along the bottom when bar is set
local function expireAfter(row, seconds, bar)
	row.left = seconds
	if bar and not row.bar then
		row.bar = row:CreateTexture(nil, "ARTWORK")
		row.bar:SetPoint("BOTTOMLEFT", 1, 1)
		row.bar:SetHeight(2)
		local c = kit() and kit().COLORS.accent or { 0.91, 0.33, 0.16 }
		row.bar:SetColorTexture(c[1], c[2], c[3], 0.9)
	end
	if row.bar then row.bar:SetShown(bar and true or false) end
	row.total = seconds
	row:SetScript("OnUpdate", function(self, elapsed)
		self.left = self.left - (elapsed or 0)
		if self.bar and self.bar:IsShown() then
			self.bar:SetWidth(math.max(1, (ROW_W - 2) * self.left / self.total))
		end
		if self.left <= 0 then removeRow(self) end
	end)
end

-- ---------------------------------------------------------------------------------------------
-- Giving kudos
-- ---------------------------------------------------------------------------------------------
local lastChatPost = -CHAT_COOLDOWN

-- The chat channel a friend's message came through, for a public post: party/raid/battleground
-- as it is now, or the guild
local function chatChannelFor(info)
	if info.channel == "GUILD" then return core().inGuild() and "GUILD" or nil end
	return core().groupChannel()
end

local function send(row, info, id)
	if row.sent then return end
	row.sent = true
	local faction = myFaction()
	local words = reactionText(id, faction) or "?"
	if not info.preview then
		local sync = core().db().profile.sync
		local channel
		if info.channel == "GUILD" then
			if sync.shareguild and core().inGuild() then channel = "GUILD" end
		elseif sync.shareparty then
			channel = core().groupChannel()
		end
		if channel then
			core().sendAddonMessage(table.concat({ "R", core().VERSION, info.guid, id, info.kind == "D" and "D" or "K",
				faction or "-", core().playerGUID() or "" }, "\t"), channel)
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
	if row.bar then row.bar:Hide() end
	row.label:SetText("|cff9a8f86Sent|r " .. words .. " |cff9a8f86to|r " .. info.who
		.. (info.preview and " |cff9a8f86(preview, nothing sent)|r" or ""))
	row.height = 30
	row:SetHeight(30)
	layout()
	expireAfter(row, 2.5, false)
end
kudos.send = send

local function offer(info)
	local row = newRow(62)
	row.info = info
	local deed = deedText(info)
	if info.kind == "D" then
		row.label:SetText("|cffff7733" .. info.who .. "|r " .. deed .. ".")
	else
		row.label:SetText("|cffff7733" .. info.who .. "|r: " .. deed .. "!")
	end
	row.buttons = {}
	local order = info.kind == "D" and DEATH_ORDER or KILL_ORDER
	local faction = myFaction()
	local k = kit()
	local x = 10
	for _, id in ipairs(order) do
		local words = reactionText(id, faction)
		if words and k then
			local b = k.makeButton(row, words, function() send(row, info, id) end, "secondary", nil, 24)
			b.text:SetFont(b.text:GetFont(), 11, "")
			b:SetWidth(math.max(44, (b.text:GetStringWidth() or 40) + 18))
			b:SetPoint("BOTTOMLEFT", x, 8)
			x = x + b:GetWidth() + 6
			row.buttons[#row.buttons + 1] = b
		end
	end
	expireAfter(row, SHOW_FOR, true)
	return row
end
kudos.offer = offer

-- A friend killed or died (from SpicyKillStreaks.lua's feed, already checked and de-duplicated)
function kudos.allyEvent(info)
	if not cfg().give then return end
	info.guid = cleanGUID(info.guid)
	if not info.guid or not info.who then return end -- older versions without a GUID: nowhere to send it
	-- Reactions go back the way the kill came, so only offer them where we share
	local sync = core().db().profile.sync
	if info.channel == "GUILD" then
		if not sync.shareguild then return end
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
	if #fields < 7 then return end
	local me = core().playerGUID()
	if not me or fields[3] ~= me then return end -- for someone else
	local id, kind, faction = fields[4], fields[5], fields[6]
	local reaction = REACTIONS[id]
	if not reaction or (kind ~= "K" and kind ~= "D") or reaction.kind ~= kind then return end
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
	local row = newRow(30)
	local tally = event.count > 1 and ("  |cffffd100+" .. event.count .. "|r") or ""
	row.label:SetText("|cffffd100" .. who .. "|r: " .. words .. " |cff9a8f86(your " .. ownDeedText(kind, event.what) .. ")|r" .. tally)
	expireAfter(row, GOT_FOR, false)
end

-- ---------------------------------------------------------------------------------------------
-- Moving it, and a preview
-- ---------------------------------------------------------------------------------------------
function kudos.unlock(on)
	ensureHolder()
	if not mover then
		mover = CreateFrame("Frame", nil, holder, "BackdropTemplate")
		mover:SetPoint("TOP", holder, "TOP", 0, 0)
		mover:SetSize(ROW_W, 62)
		mover:SetFrameLevel((holder:GetFrameLevel() or 1) + 20)
		local k = kit()
		if k then k.paint(mover, k.COLORS.accent, 0.35, k.COLORS.accent) end
		local label = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetPoint("CENTER")
		label:SetText("Kudos popup: drag me")
		mover:EnableMouse(true)
		mover:RegisterForDrag("LeftButton")
		mover:SetScript("OnDragStart", function() holder:StartMoving() end)
		mover:SetScript("OnDragStop", function()
			holder:StopMovingOrSizing()
			local x, top = holder:GetCenter(), holder:GetTop()
			local ux, uy = UIParent:GetCenter()
			if x and top and ux and uy then
				cfg().x, cfg().y = math.floor(x - ux + 0.5), math.floor(top - uy + 0.5)
			end
			place()
		end)
	end
	mover:SetShown(on and true or false)
end

function kudos.isUnlocked() return mover and mover:IsShown() or false end

function kudos.resetPosition()
	local d = core().defaults.profile.kudos
	cfg().x, cfg().y = d.x, d.y
	place()
end

-- Sample rows: a friend's kill, a friend's death and a kudos we got. Clicks send nothing.
function kudos.preview()
	offer({ kind = "K", who = "Bob", other = "Alice", rank = 2, multi = 0, streak = 3, preview = true })
	offer({ kind = "D", who = "Panda", other = "Orcbro", preview = true })
	local row = newRow(30)
	row.label:SetText("|cffffd100Bob|r: Hell yeah! |cff9a8f86(your Rampage)|r  |cffffd100+2|r")
	expireAfter(row, GOT_FOR, false)
end

function kudos.clear()
	while #rows > 0 do removeRow(rows[1]) end
end
