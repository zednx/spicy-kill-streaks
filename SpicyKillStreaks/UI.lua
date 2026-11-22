-- Spicy Kill Streaks: the settings window, the first-run setup and the minimap button.
--
-- Everything here talks to SpicyKillStreaks.lua through ns.core (see the bottom of that file).
-- The controls are AceGUI widgets (bundled in libs\) inside our own window frames; the old
-- AceConfig options stay available as a fallback (/sks classic).
local ADDON, ns = ...
local AceGUI = LibStub("AceGUI-3.0")

local ui = {}
ns.ui = ui

local function core() return ns.core end
local function db() return ns.core.db() end
local function P() return ns.core.db().profile end
local function S() return ns.core.special end

local WHITE = "Interface\\Buttons\\WHITE8X8"
local COLORS = {
	bg = { 0.086, 0.071, 0.059 },
	panel = { 0.125, 0.10, 0.085 },
	border = { 0.29, 0.24, 0.20 },
	accent = { 0.91, 0.33, 0.16 },
	gold = { 0.95, 0.76, 0.31 },
	muted = { 0.66, 0.61, 0.56 },
}

-- ---------------------------------------------------------------------------------------------
-- Frames
-- ---------------------------------------------------------------------------------------------
local function paint(frame, color, alpha)
	frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	frame:SetBackdropColor(color[1], color[2], color[3], alpha or 0.97)
	frame:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
end

-- A movable dark window with a title bar, a chilli and a close button
local function makeWindow(name, width, height, title, saved)
	local w = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
	w:SetSize(width, height)
	if saved and saved.point then
		w:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0)
	else
		w:SetPoint("CENTER")
	end
	w:SetFrameStrata("HIGH")
	w:SetToplevel(true)
	w:SetClampedToScreen(true)
	w:SetMovable(true)
	w:EnableMouse(true)
	w:RegisterForDrag("LeftButton")
	w:SetScript("OnDragStart", w.StartMoving)
	w:SetScript("OnDragStop", function()
		w:StopMovingOrSizing()
		if saved then
			local point, _, _, x, y = w:GetPoint()
			saved.point, saved.x, saved.y = point, x, y
		end
	end)
	paint(w, COLORS.bg)
	tinsert(UISpecialFrames, name) -- Esc closes it

	local bar = w:CreateTexture(nil, "BORDER")
	bar:SetColorTexture(0.12, 0.10, 0.08, 1)
	bar:SetPoint("TOPLEFT", 1, -1)
	bar:SetPoint("TOPRIGHT", -1, -1)
	bar:SetHeight(44)

	local icon = w:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(core().MEDIA .. "Chilli")
	icon:SetSize(28, 28)
	icon:SetPoint("TOPLEFT", 12, -8)

	w.title = w:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	w.title:SetPoint("LEFT", icon, "RIGHT", 8, 0)
	w.title:SetTextColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3])
	w.title:SetText(title)

	local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -6)
	w.close = close
	w:Hide()
	return w
end

local function headerButton(parent, text, width, onClick)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 24)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	return b
end

-- An AceGUI container living in one of our frames, at a fixed size
local function hostContainer(kind, parent, x, y, width, height)
	local c = AceGUI:Create(kind)
	c:SetLayout("List")
	c.frame:SetParent(parent)
	c.frame:ClearAllPoints()
	c.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	c:SetWidth(width)
	c:SetHeight(height)
	c.frame:Show()
	return c
end

-- ---------------------------------------------------------------------------------------------
-- Widgets (AceGUI)
-- ---------------------------------------------------------------------------------------------
local refreshPreview -- defined with the preview below

local function add(parent, widget, width)
	if width then
		if width <= 1 then widget:SetRelativeWidth(width) else widget:SetWidth(width) end
	end
	parent:AddChild(widget)
	return widget
end

local function card(parent, title)
	local g = AceGUI:Create("InlineGroup")
	g:SetTitle(title)
	g:SetLayout("Flow")
	g:SetFullWidth(true)
	parent:AddChild(g)
	return g
end

local function label(parent, text, width, font)
	local l = AceGUI:Create("Label")
	l:SetText(text)
	if font then l:SetFontObject(font) end
	if width then add(parent, l, width) else l:SetFullWidth(true); parent:AddChild(l) end
	return l
end

local function check(parent, text, desc, get, set, width)
	local c = AceGUI:Create("CheckBox")
	c:SetLabel(text)
	if desc then c:SetDescription(desc) end
	c:SetValue(get() and true or false)
	c:SetCallback("OnValueChanged", function(_, _, value)
		set(value and true or false)
		if refreshPreview then refreshPreview() end
	end)
	return add(parent, c, width or 0.5)
end

local function ptoggle(parent, key, text, desc, width)
	return check(parent, text, desc, function() return P()[key] end, function(v) P()[key] = v end, width)
end

local function fxtoggle(parent, key, text, desc, width)
	return check(parent, text, desc, function() return P().fx[key] end, function(v) P().fx[key] = v end, width)
end

-- path: { "shareparty" } or { "party", "feed" } inside profile.sync
local function synctoggle(parent, path, text, desc, width)
	local function tbl()
		local t = P().sync
		for i = 1, #path - 1 do t = t[path[i]] end
		return t
	end
	return check(parent, text, desc, function() return tbl()[path[#path]] end,
		function(v) tbl()[path[#path]] = v end, width)
end

local function dropdown(parent, text, list, order, get, set, width)
	local d = AceGUI:Create("Dropdown")
	d:SetLabel(text)
	d:SetList(list, order)
	d:SetValue(get())
	d:SetCallback("OnValueChanged", function(_, _, key)
		set(key)
		if refreshPreview then
			refreshPreview()
			-- A font file used for the first time can take a moment to load: draw again shortly
			C_Timer.After(0.1, refreshPreview)
			C_Timer.After(0.5, refreshPreview)
		end
	end)
	return add(parent, d, width or 0.5)
end

local function slider(parent, text, min, max, step, get, set, isPercent, width)
	local s = AceGUI:Create("Slider")
	s:SetLabel(text)
	s:SetSliderValues(min, max, step)
	if isPercent then s:SetIsPercent(true) end
	s:SetValue(get())
	s:SetCallback("OnValueChanged", function(_, _, value)
		set(value)
		if refreshPreview then refreshPreview() end
	end)
	return add(parent, s, width or 0.5)
end

local function edit(parent, text, get, set, width)
	local e = AceGUI:Create("EditBox")
	e:SetLabel(text)
	e:SetText(get() or "")
	e:SetCallback("OnEnterPressed", function(_, _, value) set(value) end)
	return add(parent, e, width or 1)
end

local function button(parent, text, onClick, width)
	local b = AceGUI:Create("Button")
	b:SetText(text)
	b:SetCallback("OnClick", onClick)
	return add(parent, b, width or 0.33)
end

local function space(parent, width)
	local l = AceGUI:Create("Label")
	l:SetText(" ")
	return add(parent, l, width or 1)
end

-- ---------------------------------------------------------------------------------------------
-- Lists the settings use
-- ---------------------------------------------------------------------------------------------
local PACKS = { male = "Male", female = "Female", sexy = "Sexy", baby = "Baby", flamboyant = "Flamboyant (HoN)" }
local PACK_ORDER = { "male", "female", "sexy", "baby", "flamboyant" }
local HUMILIATION = {
	humiliation = "Humiliation (classic)", pack = "Same as the voice pack", male = "Male", female = "Female",
	sexy = "Sexy", baby = "Baby", flamboyant = "Flamboyant", custom = "Custom file",
}
local HUMILIATION_ORDER = { "humiliation", "pack", "male", "female", "sexy", "baby", "flamboyant", "custom" }
local CHANNELS = { Master = "Master", SFX = "Effects", Dialog = "Dialog", Music = "Music", Ambience = "Ambience" }
local CHANNEL_ORDER = { "Master", "SFX", "Dialog", "Music", "Ambience" }
local SPARKLES = { mix = "Mix", star = "Stars", chilli = "Chillies", confetti = "Confetti" }
local SPARKLE_ORDER = { "mix", "star", "chilli", "confetti" }
local STYLES = { dota = "On every kill (DotA style)", ut = "First kill, then every few kills (Unreal style)" }

local function sortedKeys(list, first)
	local keys = {}
	for key in pairs(list) do if key ~= first then keys[#keys + 1] = key end end
	table.sort(keys, function(a, b) return tostring(list[a]) < tostring(list[b]) end)
	if first and list[first] then table.insert(keys, 1, first) end
	return keys
end

local function sample(file) return function() S().playForced(file) end end

-- ---------------------------------------------------------------------------------------------
-- Settings window
-- ---------------------------------------------------------------------------------------------
local WIN_W, WIN_H = 900, 660
local NAV_W = 190
local CONTENT_X = NAV_W + 16
local CONTENT_W = WIN_W - CONTENT_X - 16
local PREVIEW_H = 128

local win, scroll, navButtons, current
local preview = {}
local sections = {}

-- The live preview: the chosen font, size, colours and the voice pack's words
local SAMPLES = {
	-- level: the rank index (its colour); multi: the multikill colour; grey: the gank colour
	{ key = "kill", label = "Kill", text = "HEADSHOT!", small = "You killed Rogue!", level = 1, sound = "headshot.ogg" },
	{ key = "rank", label = "Rank", text = "KILLING SPREE!", small = "You killed Mage! (3 in a row)", level = 2, sound = "killingspree.ogg" },
	{ key = "multi", label = "Multi", text = "TRIPLE KILL!", small = "You killed Priest!", multi = true, sound = "triplekill.ogg" },
	{ key = "payback", label = "Payback", text = "RETRIBUTION!", small = "You killed the Warrior who killed you", level = 4, sound = "retribution.ogg" },
	{ key = "big", label = "Godlike", text = "GODLIKE!", small = "You killed Paladin! (9 in a row)", level = 6, sound = "godlike.ogg" },
	{ key = "gank", label = "Gank", text = "Bully!", small = "You ganked a level 12 Gnome.", grey = true, sound = "gank.ogg" },
}

refreshPreview = function()
	if not preview.big or not win or not win:IsShown() then return end
	local p = P()
	local s = SAMPLES[preview.index or 2]
	local path = S().fontPath(p.fx.font) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local scale = p.fx.scale or 1
	local ok = pcall(preview.big.SetFont, preview.big, path, math.floor(30 * scale + 0.5), "THICKOUTLINE")
	if not ok then preview.big:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 30, "THICKOUTLINE") end
	pcall(preview.small.SetFont, preview.small, path, 14, "OUTLINE")
	-- A font string only redraws in a new font when its text changes: clear it first
	preview.big:SetText("")
	preview.small:SetText("")

	local text = s.text
	local packText = S().PACK_TEXT[p.soundpack]
	if not p.doscreen then
		preview.big:SetText("(nothing on screen: \"Show kills on screen\" is off)")
		preview.big:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 13, "")
		preview.big:SetTextColor(0.5, 0.5, 0.5)
		preview.small:SetText("")
		return
	end
	if packText and not s.grey then
		preview.big:SetText(S().rainbow(packText[text] or text))
		preview.big:SetTextColor(1, 1, 1)
	else
		preview.big:SetText(text)
		local c = s.grey and { 0.7, 0.7, 0.7 } or (s.multi and { 1, 0.85, 0.2 })
			or core().rankColors[S().LEVEL[s.level] or s.level] or { 1, 1, 1 }
		preview.big:SetTextColor(c[1], c[2], c[3])
	end
	if not p.fx.fancytext then
		-- Plain mode: simple red lines, like the original addon
		preview.big:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
		preview.big:SetText(s.text)
		preview.big:SetTextColor(1, 0.2, 0.2)
	end
	preview.small:SetText(s.small)
end

local function buildPreview(parent)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	box:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_X, -56)
	box:SetSize(CONTENT_W - 170, PREVIEW_H)
	paint(box, { 0.06, 0.075, 0.068 }, 1)
	local tag = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tag:SetPoint("TOPLEFT", 8, -6)
	tag:SetText("Live preview")
	preview.big = box:CreateFontString(nil, "OVERLAY")
	preview.big:SetPoint("CENTER", 0, 10)
	preview.big:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 30, "THICKOUTLINE")
	preview.small = box:CreateFontString(nil, "OVERLAY")
	preview.small:SetPoint("TOP", preview.big, "BOTTOM", 0, -6)
	preview.small:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
	preview.small:SetTextColor(1, 0.91, 0.84)

	-- Sample buttons: show that moment, and play its sound
	for i, s in ipairs(SAMPLES) do
		local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		b:SetSize(76, 22)
		b:SetText(s.label)
		b:SetPoint("TOPLEFT", box, "TOPRIGHT", 8 + ((i - 1) % 2) * 80, -((math.floor((i - 1) / 2)) * 26))
		b:SetScript("OnClick", function()
			preview.index = i
			refreshPreview()
			S().playForced(s.sound)
		end)
	end
	local real = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	real:SetSize(156, 22)
	real:SetText("Show in game")
	real:SetPoint("TOPLEFT", box, "TOPRIGHT", 8, -82)
	real:SetScript("OnClick", function() core().preview(preview.index == 5 and "big" or (preview.index == 3 and "multi" or "rank")) end)
	preview.index = 2
end

-- ---------------------------------------------------------------------------------------------
-- Sections
-- ---------------------------------------------------------------------------------------------
sections[#sections + 1] = { id = "announcer", label = "Announcer", hint = "Callouts and streaks", build = function(c)
	local g = card(c, "When to call it")
	dropdown(g, "Kill sounds", STYLES, { "dota", "ut" }, function() return P().style end, function(v)
		P().style = v
		ui.show("announcer")
	end, 0.6)
	if P().style == "ut" then
		slider(g, "Unreal style: kills between sounds", 1, 10, 1, function() return P().utrank end,
			function(v) P().utrank = v end, false, 0.4)
	end

	g = card(c, "Callouts")
	ptoggle(g, "doheadshot", "Headshot", "Your first kill of a streak")
	ptoggle(g, "dofirstblood", "First Blood", "Your first kill of the day")
	ptoggle(g, "doretribution", "Retribution", "Kill someone who killed you in the last hour")
	ptoggle(g, "docomeback", "Meat's back on the menu", "Your first kill after dying 3+ times in a row")
	ptoggle(g, "dopancake", "Pancake", "You or a friend die from falling or drowning")
	ptoggle(g, "dogank", "Shame ganks", "You kill a player 10+ levels below you: no streak, a bit of shame")
	ptoggle(g, "doganked", "Got ganked", "A player 10+ levels above you (or ??) kills you")
	ptoggle(g, "dopve", "Count NPC kills", "Spammy, handy for trying it out")
	ptoggle(g, "dozonechange", "Reset streaks when changing zone", nil)

	g = card(c, "Streak ladder")
	local ladder = {
		{ "Headshot", "1", "ffd95a" }, { "Ownage", "2", "ffd95a" }, { "Killing\nSpree", "3", "ff9a26" },
		{ "Rampage", "4", "ff5a1a" }, { "Dominating", "5", "ff3d3d" }, { "Unstoppable", "6", "ff5fa8" },
		{ "Wicked\nSick", "7", "c07bff" }, { "Godlike", "8+", "57e3ff" },
	}
	local cell = 1 / #ladder - 0.001
	for _, step in ipairs(ladder) do
		local name = label(g, "|cff" .. step[3] .. step[1] .. "|r", cell, GameFontNormal)
		name:SetJustifyH("CENTER")
		name:SetJustifyV("BOTTOM")
		name:SetHeight(30)
	end
	for _, step in ipairs(ladder) do
		local kills = label(g, step[2], cell, GameFontHighlightHuge or GameFontNormalHuge)
		kills:SetJustifyH("CENTER")
	end
	space(g, 1)
	label(g, "Kills in a row without dying. Godlike plays on every kill from 8 on. There are a couple of secrets too.", 1,
		GameFontDisableSmall)
end }

sections[#sections + 1] = { id = "sound", label = "Sound", hint = "Voice, muting, snooze", build = function(c)
	local g = card(c, "Voice")
	ptoggle(g, "dosound", "Play sounds", nil, 1)
	dropdown(g, "Voice pack", PACKS, PACK_ORDER, function() return P().soundpack end, function(v)
		P().soundpack = v
		S().playForced("killingspree.ogg")
	end, 0.5)
	button(g, "Play a sample", sample("killingspree.ogg"), 0.25)
	space(g, 0.2)
	dropdown(g, "When you die, play", HUMILIATION, HUMILIATION_ORDER, function() return P().humiliationvoice end,
		function(v)
			P().humiliationvoice = v
			S().playForced("humiliation")
		end, 0.5)
	button(g, "Play it", sample("humiliation"), 0.25)
	space(g, 0.2)
	dropdown(g, "Sound channel", CHANNELS, CHANNEL_ORDER, function() return P().soundchannel end,
		function(v) P().soundchannel = v end, 0.5)
	space(g, 0.45)
	ptoggle(g, "dodeathsound", "Humiliation when you die")
	ptoggle(g, "doprepare", "\"Prepare\" before a battleground or duel")

	g = card(c, "Quiet time")
	label(g, "Mute sounds in:", 1, GameFontNormal)
	ptoggle(g, "mutebg", "Battlegrounds & arenas", nil, 0.33)
	ptoggle(g, "mutedungeon", "Dungeons", nil, 0.33)
	ptoggle(g, "muteraid", "Raids", nil, 0.33)
	local status = label(g, "", 1, GameFontHighlight)
	local function update()
		local t = S().snoozedUntil()
		status:SetText(t and ("|cffffd100Snoozed|r until " .. date("%H:%M", t) .. ". Text and effects still show.")
			or "Snooze all sounds for a while:")
	end
	update()
	button(g, "30 minutes", function() S().snooze(30) update() end, 0.25)
	button(g, "1 hour", function() S().snooze(60) update() end, 0.25)
	button(g, "Wake up", function() S().snooze("off") update() end, 0.25)
end }

sections[#sections + 1] = { id = "screen", label = "Screen", hint = "Text, effects, position", build = function(c)
	local g = card(c, "Where kills show")
	ptoggle(g, "doscreen", "Big callouts on screen")
	ptoggle(g, "dochat", "A line in chat")
	edit(g, "Kill text ($k you, $v victim, $s streak; press Enter)", function() return P().kstext end,
		function(v) P().kstext = v end, 1)

	g = card(c, "Effects")
	fxtoggle(g, "fancytext", "Animated text", "Off: simple red lines, like the original addon")
	local choices = S().fontChoices()
	dropdown(g, "Font", choices, sortedKeys(choices, "impact"), function() return P().fx.font end,
		function(v) P().fx.font = v end, 0.5)
	slider(g, "Text size", 0.5, 2, 0.05, function() return P().fx.scale end, function(v) P().fx.scale = v end, true, 0.5)
	fxtoggle(g, "sparkles", "Sparkle burst", "Bigger for new ranks and multikills", 0.5)
	dropdown(g, "Sparkles", SPARKLES, SPARKLE_ORDER, function() return P().fx.sparklestyle end,
		function(v) P().fx.sparklestyle = v end, 0.25)
	slider(g, "How many", 5, 80, 1, function() return P().fx.sparklecount end,
		function(v) P().fx.sparklecount = v end, false, 0.25)
	fxtoggle(g, "flash", "Screen-edge flash", "On multikills and big streaks", 1)

	g = card(c, "Position")
	button(g, "Unlock to move", function() core().unlock(true) core().chat("Drag the orange box, then press Lock.") end, 0.25)
	button(g, "Lock", function() core().unlock(false) end, 0.25)
	button(g, "Reset position", function()
		P().fx.x, P().fx.y = core().defaults.profile.fx.x, core().defaults.profile.fx.y
		core().placeAnchor()
	end, 0.25)
	button(g, "Show in game", function() core().preview("big") end, 0.25)
end }

sections[#sections + 1] = { id = "friends", label = "Friends", hint = "Party and guild sharing", build = function(c)
	local g = card(c, "Share my kills and deaths with")
	synctoggle(g, { "shareparty" }, "My party", "Also raids, battlegrounds and arenas")
	synctoggle(g, { "shareguild" }, "My guild", nil)
	label(g, "Only players running Spicy Kill Streaks see anything. Untick both to share nothing.", 1, GameFontDisableSmall)

	for _, who in ipairs({ { "party", "Party members' kills" }, { "guild", "Guild members' kills" } }) do
		g = card(c, who[2])
		synctoggle(g, { who[1], "feed" }, "In the chat feed", nil, 0.25)
		synctoggle(g, { who[1], "text" }, "As combat text", nil, 0.25)
		synctoggle(g, { who[1], "sound" }, "With sounds", nil, 0.25)
		synctoggle(g, { who[1], "deaths" }, "Their deaths too", nil, 0.25)
	end

	g = card(c, "Guild extras")
	synctoggle(g, { "logincount" }, "At login, count guildmates using it", nil)
	synctoggle(g, { "loginboard" }, "At login, show the top 3 killers this month", nil)
	synctoggle(g, { "updatenotice" }, "Tell me when a newer version is out", nil)
	space(g, 0.5)
	button(g, "Send a test kill", function() core().sendTestSync() end, 0.33)
	button(g, "Who runs it?", function() core().versionCheck() end, 0.33)
end }

sections[#sections + 1] = { id = "board", label = "Guild board", hint = "This month's top killers", build = function(c)
	local g = card(c, "Guild board, " .. date("%B"))
	if not S().guildName() then
		label(g, "You are not in a guild.", 1, GameFontHighlight)
		return
	end
	local list = S().top(10)
	if #list == 0 then
		label(g, "Nobody has a kill streak this month yet. Get out there!", 1, GameFontHighlight)
	else
		label(g, "|cffa89c90Player|r", 0.4, GameFontNormalSmall)
		label(g, "|cffa89c90Best streak|r", 0.2, GameFontNormalSmall)
		label(g, "|cffa89c90Kills|r", 0.2, GameFontNormalSmall)
		label(g, "|cffa89c90Deaths|r", 0.2, GameFontNormalSmall)
		for i, entry in ipairs(list) do
			local medal = (i == 1 and "|cffffd100") or (i == 2 and "|cffc0c0c0") or (i == 3 and "|cffcd7f32") or "|cffffffff"
			label(g, medal .. i .. ".|r  " .. entry.name, 0.4, GameFontHighlight)
			label(g, "|cff57e3ff" .. entry.best .. "|r", 0.2, GameFontHighlight)
			label(g, tostring(entry.kills), 0.2, GameFontHighlight)
			label(g, tostring(entry.deaths or 0), 0.2, GameFontHighlight)
		end
	end
	local deaths = S().topDeaths(3)
	if #deaths > 0 then
		local parts = {}
		for i, entry in ipairs(deaths) do parts[i] = entry.name .. " (" .. entry.deaths .. ")" end
		space(g, 1)
		label(g, "|cffff5555Most deaths:|r " .. table.concat(parts, ", "), 1, GameFontHighlight)
	end
	label(g, "Best kill streak this month, from guildmates who run the addon and share with the guild. "
		.. "It starts again on the 1st.", 1, GameFontDisableSmall)
	button(g, "Post to guild chat", function() S().shareBoard("GUILD") end, 0.33)
	button(g, "Post to party chat", function() S().shareBoard("PARTY") end, 0.33)
	button(g, "Ask guildmates now", function()
		core().versionCheck()
		C_Timer.After(6, function() if current == "board" then ui.show("board") end end)
	end, 0.33)
end }

sections[#sections + 1] = { id = "extras", label = "Extras", hint = "Emotes, duels, screenshots", build = function(c)
	local emotes = core().emotes
	local emoteOrder = sortedKeys(emotes, "none")
	local g = card(c, "Emotes after a kill")
	dropdown(g, "Emote", emotes, emoteOrder, function() return P().doemote end, function(v) P().doemote = v end, 0.5)
	ptoggle(g, "dotxtemote", "Send a custom emote message", nil, 0.5)
	edit(g, "Custom message ($v victim, $s streak; press Enter)", function() return P().ksemote end,
		function(v) P().ksemote = v end, 1)
	label(g, "WoW Forever only lets a custom message go out from a key press: put /sks emote in a macro.", 1,
		GameFontDisableSmall)

	g = card(c, "Duels")
	edit(g, "Duel win text ($k you, $v opponent; press Enter)", function() return P().dueltext end,
		function(v) P().dueltext = v end, 1)
	dropdown(g, "Emote after a win", emotes, emoteOrder, function() return P().duelemotewin end,
		function(v) P().duelemotewin = v end, 0.5)
	dropdown(g, "Emote after a loss", emotes, emoteOrder, function() return P().duelemoteloss end,
		function(v) P().duelemoteloss = v end, 0.5)
	ptoggle(g, "duelhumiliation", "Humiliation when you flee a duel", nil, 1)

	g = card(c, "Screenshots")
	ptoggle(g, "shotkill", "Every kill", nil, 0.33)
	ptoggle(g, "shotstreak", "New best streak", nil, 0.33)
	ptoggle(g, "shotmultikill", "Multikill", nil, 0.33)
	ptoggle(g, "shotduelwin", "Duel win", nil, 0.33)
	ptoggle(g, "shotduelloss", "Duel loss", nil, 0.33)
	ptoggle(g, "shotdeath", "Death", nil, 0.33)
end }

sections[#sections + 1] = { id = "soundboard", label = "Sound board", hint = "Hear every sound", build = function(c)
	label(c, "Click a sound to hear it in your voice pack (" .. (PACKS[P().soundpack] or P().soundpack)
		.. "). It plays even with sounds off, muted or snoozed.", nil, GameFontHighlight)
	local g
	for _, entry in ipairs(S().soundBoard()) do
		if entry.section then
			g = card(c, entry.section)
		else
			button(g, entry[1], sample(entry[3]), 0.3)
			label(g, entry[2], 0.68, GameFontHighlightSmall)
		end
	end
end }

sections[#sections + 1] = { id = "about", label = "About", hint = "Who made it, feedback", build = function(c)
	-- Header: the chilli, the name and the version
	local head = AceGUI:Create("Label")
	head:SetImage(core().MEDIA .. "Chilli")
	head:SetImageSize(56, 56)
	head:SetText("|cffffd100" .. core().TITLE .. "|r\n|cffa89c90Version " .. core().VERSION
		.. " · Announcer voices for your killing blows in WoW Forever|r")
	head:SetFontObject(GameFontNormalLarge)
	head:SetFullWidth(true)
	c:AddChild(head)
	space(c, 1)

	local g = card(c, "Made by")
	label(g, "|cffff7733Spicy Bubbletea|r", 1, GameFontNormalLarge)
	label(g, "Horde  ·  WoW Forever  ·  PvP realm", 1, GameFontDisable)
	space(g, 1)
	label(g, "Ideas, bugs, or a kill you're proud of? I'd love to hear it.", 1, GameFontHighlight)

	g = card(c, "Feedback and bugs")
	label(g, "|cffffd100In game|r   Send Spicy Bubbletea a message (Horde).", 1, GameFontHighlight)
	label(g, "|cffffd100GitHub|r      github.com/zednx/spicy-kill-streaks (Issues)", 1, GameFontHighlight)
	label(g, "|cffffd100Bugs|r          Debug log at the top, then Select all and Ctrl+C, and send it along.", 1,
		GameFontHighlight)

	g = card(c, "Credits")
	local credits = {
		{ "Original addon", "dG KillShot by Lance Inman" },
		{ "Voices", "Unreal Tournament (Epic Games), Heroes of Newerth Flamboyant (S2 Games / Frostburn), and a few of WoW's own lines (Blizzard). Details in sounds\\CREDITS.txt" },
		{ "Fonts", "Google Fonts: SIL Open Font License and Apache 2.0 (Media\\Fonts)" },
		{ "Libraries", "Ace3" },
		{ "Licence", "GNU GPL v2" },
	}
	for _, line in ipairs(credits) do
		label(g, "|cffa89c90" .. line[1] .. "|r", 0.22, GameFontHighlightSmall)
		label(g, line[2], 0.77, GameFontHighlightSmall)
	end

	g = card(c, "More")
	check(g, "Show the minimap button", nil, function() return not db().global.minimap.hide end, function(v)
		db().global.minimap.hide = not v
		ui.updateMinimap()
	end, 1)
	button(g, "Run the setup again", function() win:Hide() ui.openSetup() end, 0.33)
	button(g, "Classic options window", function() win:Hide() core().openClassic() end, 0.33)
	button(g, "Stats", function() win:Hide() core().openStats() end, 0.33)
end }

local function styleNav(b, selected)
	b.bg:SetColorTexture(selected and 0.17 or 0, selected and 0.11 or 0, selected and 0.09 or 0, selected and 1 or 0)
	b.bar:SetShown(selected)
end

function ui.show(id)
	current = id
	for _, b in ipairs(navButtons) do styleNav(b, b.id == id) end
	scroll:ReleaseChildren()
	scroll:PauseLayout()
	for _, s in ipairs(sections) do
		if s.id == id then
			local ok, err = pcall(s.build, scroll)
			if not ok then label(scroll, "|cffff5555Could not build this page:|r " .. tostring(err), nil, GameFontHighlight) end
		end
	end
	scroll:ResumeLayout()
	scroll:DoLayout()
	scroll:SetScroll(0)
	refreshPreview()
end

local function buildWindow()
	win = makeWindow("SpicyKillStreaksWindow", WIN_W, WIN_H, core().TITLE, db().global.window)
	local version = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	version:SetPoint("LEFT", win.title, "RIGHT", 8, -1)
	version:SetText("v" .. core().VERSION)

	local debug = headerButton(win, "Debug log", 90, function() core().debugLog.setEnabled(not core().isDebugOn()) end)
	debug:SetPoint("RIGHT", win.close, "LEFT", -4, 0)
	local stats = headerButton(win, "Stats", 70, function() win:Hide() core().openStats() end)
	stats:SetPoint("RIGHT", debug, "LEFT", -4, 0)
	local test = headerButton(win, "Test a kill", 100, function() core().runTest("kill") end)
	test:SetPoint("RIGHT", stats, "LEFT", -4, 0)

	-- Navigation
	local nav = CreateFrame("Frame", nil, win, "BackdropTemplate")
	nav:SetPoint("TOPLEFT", 1, -45)
	nav:SetPoint("BOTTOMLEFT", 1, 1)
	nav:SetWidth(NAV_W)
	paint(nav, { 0.10, 0.08, 0.07 }, 1)
	navButtons = {}
	for i, s in ipairs(sections) do
		local b = CreateFrame("Button", nil, nav)
		b:SetSize(NAV_W - 12, 40)
		b:SetPoint("TOPLEFT", 6, -8 - (i - 1) * 44)
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		b.bar = b:CreateTexture(nil, "ARTWORK")
		b.bar:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
		b.bar:SetPoint("TOPLEFT")
		b.bar:SetPoint("BOTTOMLEFT")
		b.bar:SetWidth(3)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, 0.05)
		local name = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		name:SetPoint("TOPLEFT", 12, -6)
		name:SetText(s.label)
		local hint = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		hint:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
		hint:SetText(s.hint)
		b.id = s.id
		b:SetScript("OnClick", function() ui.show(s.id) end)
		navButtons[#navButtons + 1] = b
	end
	-- Snooze status at the bottom of the navigation
	local snooze = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	snooze:SetPoint("BOTTOMLEFT", 12, 12)
	snooze:SetWidth(NAV_W - 24)
	snooze:SetJustifyH("LEFT")
	win.snoozeText = snooze

	buildPreview(win)
	local top = 56 + PREVIEW_H + 10
	scroll = hostContainer("ScrollFrame", win, CONTENT_X, -top, CONTENT_W, WIN_H - top - 12)
	win:SetScript("OnShow", function()
		local t = S().snoozedUntil()
		win.snoozeText:SetText(t and ("|cffffd100Sounds snoozed|r\nuntil " .. date("%H:%M", t)) or "")
		refreshPreview()
	end)
end

function ui.open()
	if not win then buildWindow() end
	win:Show()
	ui.show(current or "announcer")
end

-- ---------------------------------------------------------------------------------------------
-- First-run setup: a banner, a centred step title, clickable cards and one big button
-- ---------------------------------------------------------------------------------------------
local SETUP_W, SETUP_H = 920, 660
local BANNER_H = 150
local PAGE_TOP = BANNER_H + 96 -- below the banner, step line, title and subtitle
local PAGE_W = SETUP_W - 60
local SHARING_STEP = 5
local setup, setupStep
local STEPS = {}

local function font(fs, size, flags, path)
	fs:SetFont(path or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, flags or "")
end

local function gradient(tex, r1, g1, b1, r2, g2, b2)
	tex:SetColorTexture(1, 1, 1, 1)
	local ok = CreateColor and pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(r1, g1, b1, 1), CreateColor(r2, g2, b2, 1))
	if not ok then ok = pcall(tex.SetGradient, tex, "HORIZONTAL", r1, g1, b1, r2, g2, b2) end
	if not ok then tex:SetColorTexture(r1, g1, b1, 1) end
end

-- A card: title, a line of description, an optional sample line on top, a tick when selected
local function makeCard(parent)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	paint(b, COLORS.panel, 1)
	b.sample = b:CreateFontString(nil, "OVERLAY")
	font(b.sample, 22, "OUTLINE")
	b.sample:SetPoint("TOP", 0, -26)
	b.title = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	b.title:SetPoint("TOP", b.sample, "BOTTOM", 0, -12)
	b.desc = b:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	b.desc:SetPoint("TOP", b.title, "BOTTOM", 0, -8)
	b.desc:SetJustifyH("CENTER")
	b.desc:SetJustifyV("TOP")
	b.check = b:CreateTexture(nil, "OVERLAY")
	b.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	b.check:SetSize(24, 24)
	b.check:SetPoint("TOPLEFT", 6, -6)
	b.badge = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	b.badge:SetPoint("TOPRIGHT", -10, -10)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 1, -1)
	hl:SetPoint("BOTTOMRIGHT", -1, 1)
	hl:SetColorTexture(1, 1, 1, 0.04)
	return b
end

-- info = { title, desc, sample = text, sampleFont = path, sampleColor = { r, g, b }, badge = text }
local function setCard(b, info, selected)
	b.title:SetText(info.title or "")
	b.desc:SetWidth(b:GetWidth() - 24)
	b.desc:SetText(info.desc or "")
	if info.sample then
		font(b.sample, info.sampleSize or 22, "OUTLINE", info.sampleFont)
		b.sample:SetText("")
		b.sample:SetText(info.sample)
		local c = info.sampleColor or { 1, 1, 1 }
		b.sample:SetTextColor(c[1], c[2], c[3])
		b.sample:Show()
		b.title:SetPoint("TOP", b.sample, "BOTTOM", 0, -12)
	else
		b.sample:Hide()
		b.title:SetPoint("TOP", b, "TOP", 0, -28)
	end
	b.badge:SetText(info.badge or "")
	b.check:SetShown(selected and true or false)
	if selected then
		b:SetBackdropColor(0.17, 0.11, 0.09, 1)
		b:SetBackdropBorderColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
	else
		b:SetBackdropColor(COLORS.panel[1], COLORS.panel[2], COLORS.panel[3], 1)
		b:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
	end
end

-- Lay `count` cards out in a centred row at `top` (pixels below the page top)
local function cardRow(page, count, top, height, maxWidth)
	local gap = 14
	local width = math.min(maxWidth or 220, (PAGE_W - gap * (count - 1)) / count)
	local total = width * count + gap * (count - 1)
	local cards = {}
	for i = 1, count do
		local b = makeCard(page)
		b:SetSize(width, height)
		b:SetPoint("TOPLEFT", page, "TOPLEFT", (PAGE_W - total) / 2 + (i - 1) * (width + gap), -top)
		cards[i] = b
	end
	return cards
end

local function pageText(page, text, top, fontObject)
	local fs = page:CreateFontString(nil, "OVERLAY", fontObject or "GameFontHighlight")
	fs:SetPoint("TOP", page, "TOP", 0, -top)
	fs:SetWidth(PAGE_W - 80)
	fs:SetJustifyH("CENTER")
	fs:SetText(text)
	return fs
end

local function fontInfo(key)
	local f = core().fonts[key]
	return f and f.path
end

STEPS[1] = {
	title = "Welcome, killer.",
	subtitle = "Announcer voices, big callouts and sparkles for your killing blows.",
	primary = "Let's go",
	hint = "Five quick steps, about 30 seconds. You can change everything later with /sks.",
	build = function(page)
		local cards = cardRow(page, 3, 10, 200, 260)
		local info = {
			{ title = "Voices", desc = "Five announcer packs, from Unreal Tournament to the Flamboyant Heroes of Newerth announcer.",
				sample = "GODLIKE!", sampleColor = { 0.34, 0.89, 1 }, sampleFont = fontInfo("bangers"), sampleSize = 30 },
			{ title = "Flair", desc = "Big callouts in a font you pick, sparkle bursts and screen flashes. Or keep it quiet.",
				sample = "RAMPAGE!", sampleColor = { 1, 0.35, 0.1 }, sampleFont = fontInfo("luckiest"), sampleSize = 30 },
			{ title = "Friends", desc = "Your party and guild see your sprees, and a monthly guild board crowns the top killer.",
				sample = "TRIPLE KILL!", sampleColor = { 1, 0.85, 0.2 }, sampleFont = fontInfo("anton"), sampleSize = 30 },
		}
		for i, b in ipairs(cards) do
			setCard(b, info[i], false)
			b:EnableMouse(false)
		end
	end,
}

local VOICE_INFO = {
	{ key = "male", title = "Male", desc = "The classic Unreal Tournament announcer", sample = "KILLING SPREE!" },
	{ key = "female", title = "Female", desc = "Cool and sharp", sample = "KILLING SPREE!" },
	{ key = "sexy", title = "Sexy", desc = "Breathy and sultry", sample = "KILLING SPREE!" },
	{ key = "baby", title = "Baby", desc = "Silly", sample = "KILLING SPREE!" },
	{ key = "flamboyant", title = "Flamboyant", desc = "Heroes of Newerth, with rainbow callouts", sample = "HOMICIDAL!", rainbow = true },
}
STEPS[2] = {
	title = "Pick a voice",
	subtitle = "Click one to hear it.",
	primary = "Next",
	hint = "More voice settings (Humiliation, mute, snooze) are under Sound in /sks.",
	build = function(page)
		local cards = cardRow(page, #VOICE_INFO, 10, 200, 190)
		return function()
			for i, b in ipairs(cards) do
				local v = VOICE_INFO[i]
				setCard(b, {
					title = v.title, desc = v.desc,
					sample = v.rainbow and S().rainbow(v.sample) or v.sample, sampleSize = 18,
					sampleColor = { 1, 0.6, 0.15 }, sampleFont = S().fontPath(P().fx.font),
					badge = P().soundpack == v.key and "|cffffd100Selected|r" or nil,
				}, P().soundpack == v.key)
				b:SetScript("OnClick", function()
					P().soundpack = v.key
					S().playForced("killingspree.ogg")
					setup.refresh()
				end)
			end
		end
	end,
}

local FONT_CARDS = { "impact", "bangers", "luckiest", "anton", "russo", "bebas" }
STEPS[3] = {
	title = "How much flair?",
	subtitle = "What shows on screen when you get a kill, and in which font. Each click shows it in game.",
	primary = "Next",
	hint = "Drag the text somewhere else later with /sks unlock.",
	build = function(page)
		local presets = core().presets
		local presetCards = cardRow(page, #presets, 0, 120, 200)
		local fontCards = cardRow(page, #FONT_CARDS, 136, 110, 140)
		return function()
			local p = P()
			for i, b in ipairs(presetCards) do
				local preset = presets[i]
				local match = (p.doscreen and true or false) == preset.screen
				for key, value in pairs(preset.fx) do
					if (p.fx[key] and true or false) ~= value then match = false end
				end
				setCard(b, { title = preset.name, desc = preset.desc }, match)
				b:SetScript("OnClick", function()
					for key, value in pairs(preset.fx) do p.fx[key] = value end
					p.doscreen = preset.screen
					core().preview("rank")
					setup.refresh()
				end)
			end
			for i, b in ipairs(fontCards) do
				local key = FONT_CARDS[i]
				local f = core().fonts[key]
				setCard(b, { title = f and f.name or key, sample = "GODLIKE!", sampleFont = f and f.path,
					sampleSize = 24, sampleColor = { 0.34, 0.89, 1 } }, p.fx.font == key)
				b:SetScript("OnClick", function()
					p.fx.font = key
					core().preview("big")
					setup.refresh()
				end)
			end
		end
	end,
}

local CALLOUTS = {
	{ key = "doheadshot", title = "Headshot", desc = "Your first kill of a streak (First Blood once a day)" },
	{ key = "doretribution", title = "Retribution", desc = "Kill someone who killed you in the last hour" },
	{ key = "docomeback", title = "Comeback", desc = "\"Meat's back on the menu\" after dying 3+ times" },
	{ key = "dogank", title = "Shame ganks", desc = "You kill a player 10+ levels below you" },
	{ key = "doganked", title = "Got ganked", desc = "A player 10+ levels above you kills you" },
	{ key = "dopancake", title = "Pancake", desc = "Falling or drowning, yours or a friend's" },
}
local QUIET = {
	{ key = "mutebg", title = "Battlegrounds" }, { key = "mutedungeon", title = "Dungeons" }, { key = "muteraid", title = "Raids" },
}
STEPS[4] = {
	title = "Callouts",
	subtitle = "All on by default. Click any you'd rather switch off.",
	primary = "Next",
	hint = "Quiet in: no sounds there (text and effects still show).",
	build = function(page)
		local top = cardRow(page, 3, 0, 96, 270)
		local bottom = cardRow(page, 3, 108, 96, 270)
		local quiet = cardRow(page, 3, 232, 56, 200)
		local label = pageText(page, "|cffa89c90Keep quiet in|r", 212, "GameFontNormalSmall")
		label:SetPoint("TOP", page, "TOP", 0, -214)
		return function()
			local p = P()
			for i, b in ipairs({ top[1], top[2], top[3], bottom[1], bottom[2], bottom[3] }) do
				local c = CALLOUTS[i]
				setCard(b, { title = c.title, desc = c.desc, badge = p[c.key] and "|cff5aff7aON|r" or "|cffa89c90OFF|r" }, p[c.key])
				b:SetScript("OnClick", function() p[c.key] = not p[c.key] setup.refresh() end)
			end
			for i, b in ipairs(quiet) do
				local q = QUIET[i]
				setCard(b, { title = q.title }, p[q.key])
				b.title:SetPoint("TOP", b, "TOP", 0, -18)
				b:SetScript("OnClick", function() p[q.key] = not p[q.key] setup.refresh() end)
			end
		end
	end,
}

STEPS[5] = {
	title = "Better with friends",
	subtitle = "When a party member or guildmate with the addon goes on a spree, your screen lights up too.",
	primary = "Next",
	hint = "Only players running Spicy Kill Streaks see anything. Switch both off to share nothing.",
	build = function(page)
		local cards = cardRow(page, 2, 10, 170, 320)
		local info = {
			{ key = "shareparty", title = "Share with my party", desc = "Also raids, battlegrounds and arenas" },
			{ key = "shareguild", title = "Share with my guild", desc = "And join this month's guild board of top killers" },
		}
		return function()
			local sync = P().sync
			for i, b in ipairs(cards) do
				local c = info[i]
				setCard(b, { title = c.title, desc = c.desc, sample = sync[c.key] and "ON" or "OFF", sampleSize = 26,
					sampleColor = sync[c.key] and { 0.35, 1, 0.48 } or { 0.66, 0.61, 0.56 } }, sync[c.key])
				b:SetScript("OnClick", function() sync[c.key] = not sync[c.key] setup.refresh() end)
			end
		end
	end,
}

STEPS[6] = {
	title = "You're ready!",
	subtitle = "Go get some kills.",
	primary = "Done",
	hint = "Made by Spicy Bubbletea (Horde, WoW Forever PvP). Ideas or bugs? Send me a message in game.",
	build = function(page)
		local cards = cardRow(page, 3, 10, 170, 260)
		local info = {
			{ title = "Settings", desc = "Everything, with a live preview", sample = "/sks", sampleColor = COLORS.gold },
			{ title = "Need quiet?", desc = "Sounds off for 30 minutes", sample = "/sks snooze", sampleColor = COLORS.gold },
			{ title = "Minimap chilli", desc = "Right-click it for snooze, test and more", sample = "Chilli", sampleColor = COLORS.accent },
		}
		for i, b in ipairs(cards) do
			setCard(b, info[i], false)
			b:EnableMouse(false)
		end
	end,
}

local function finish(skipped)
	setup:Hide()
	core().finishSetup(skipped)
end

local function buildSetup()
	setup = CreateFrame("Frame", "SpicyKillStreaksSetup", UIParent, "BackdropTemplate")
	setup:SetSize(SETUP_W, SETUP_H)
	setup:SetPoint("CENTER")
	setup:SetFrameStrata("HIGH")
	setup:SetToplevel(true)
	setup:SetClampedToScreen(true)
	setup:SetMovable(true)
	setup:EnableMouse(true)
	setup:RegisterForDrag("LeftButton")
	setup:SetScript("OnDragStart", setup.StartMoving)
	setup:SetScript("OnDragStop", setup.StopMovingOrSizing)
	paint(setup, COLORS.bg, 0.98)
	tinsert(UISpecialFrames, "SpicyKillStreaksSetup")

	-- Banner
	local banner = setup:CreateTexture(nil, "BORDER")
	banner:SetPoint("TOPLEFT", 1, -1)
	banner:SetPoint("TOPRIGHT", -1, -1)
	banner:SetHeight(BANNER_H)
	gradient(banner, 0.20, 0.07, 0.05, 0.13, 0.06, 0.16)
	local line = setup:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOPLEFT", banner, "BOTTOMLEFT")
	line:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT")
	line:SetHeight(2)
	gradient(line, COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.69, 0.32, 0.87)
	local chilli = setup:CreateTexture(nil, "ARTWORK")
	chilli:SetTexture(core().MEDIA .. "Chilli")
	chilli:SetSize(104, 104)
	chilli:SetPoint("TOPLEFT", 150, -24)
	local name = setup:CreateFontString(nil, "OVERLAY")
	font(name, 58, "OUTLINE", fontInfo("bangers"))
	name:SetPoint("LEFT", chilli, "RIGHT", 24, 10)
	name:SetText("SPICY |cffe8552aKILL STREAKS|r")
	local tagline = setup:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	tagline:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 4, -4)
	tagline:SetTextColor(0.85, 0.80, 0.75)
	tagline:SetText("Announcer voices for your killing blows in WoW Forever")
	local close = CreateFrame("Button", nil, setup, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() finish(true) end)

	-- Step line, title and subtitle
	setup.stepLine = setup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	setup.stepLine:SetPoint("TOP", setup, "TOP", 0, -(BANNER_H + 16))
	setup.stepLine:SetTextColor(0.66, 0.61, 0.56)
	setup.title = setup:CreateFontString(nil, "OVERLAY")
	font(setup.title, 30)
	setup.title:SetPoint("TOP", setup.stepLine, "BOTTOM", 0, -8)
	setup.subtitle = setup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	setup.subtitle:SetPoint("TOP", setup.title, "BOTTOM", 0, -8)
	setup.subtitle:SetWidth(SETUP_W - 120)
	setup.subtitle:SetTextColor(0.80, 0.76, 0.72)

	-- Footer: the big button, its hint, Back and Skip
	local primary = CreateFrame("Button", nil, setup, "BackdropTemplate")
	primary:SetSize(340, 46)
	primary:SetPoint("BOTTOM", 0, 44)
	primary:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	primary:SetBackdropColor(0.76, 0.27, 0.12, 1)
	primary:SetBackdropBorderColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
	local phl = primary:CreateTexture(nil, "HIGHLIGHT")
	phl:SetAllPoints()
	phl:SetColorTexture(1, 1, 1, 0.08)
	primary.text = primary:CreateFontString(nil, "OVERLAY")
	font(primary.text, 18)
	primary.text:SetPoint("CENTER")
	primary:SetScript("OnClick", function()
		if setupStep == #STEPS then finish(false) else ui.setupStep(setupStep + 1) end
	end)
	setup.primary = primary
	setup.hint = setup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	setup.hint:SetPoint("TOP", primary, "BOTTOM", 0, -10)
	setup.hint:SetWidth(SETUP_W - 120)
	setup.hint:SetTextColor(0.66, 0.61, 0.56)

	local function textButton(text, onClick)
		local b = CreateFrame("Button", nil, setup)
		b:SetSize(120, 30)
		b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.text:SetPoint("CENTER")
		b.text:SetText(text)
		b:SetScript("OnClick", onClick)
		b:SetScript("OnEnter", function() b.text:SetTextColor(1, 1, 1) end)
		b:SetScript("OnLeave", function() b.text:SetTextColor(COLORS.gold[1], COLORS.gold[2], COLORS.gold[3]) end)
		return b
	end
	setup.back = textButton("<  Back", function() ui.setupStep(math.max(1, setupStep - 1)) end)
	setup.back:SetPoint("RIGHT", primary, "LEFT", -24, 0)
	setup.skip = textButton("Skip setup", function() finish(true) end)
	setup.skip:SetPoint("BOTTOMRIGHT", -16, 14)

	setup.pages = {}
	setup.refresh = function()
		local page = setup.pages[setupStep]
		if page and page.refresh then page.refresh() end
	end
end

function ui.setupStep(n)
	setupStep = n
	for _, page in pairs(setup.pages) do page:Hide() end
	local page = setup.pages[n]
	if not page then
		page = CreateFrame("Frame", nil, setup)
		page:SetPoint("TOPLEFT", setup, "TOPLEFT", 30, -PAGE_TOP)
		page:SetSize(PAGE_W, SETUP_H - PAGE_TOP - 120)
		local ok, refresh = pcall(STEPS[n].build, page)
		if not ok then pageText(page, "|cffff5555Could not build this step:|r " .. tostring(refresh), 20) end
		page.refresh = ok and refresh or nil
		setup.pages[n] = page
	end
	page:Show()
	if page.refresh then page.refresh() end
	local step = STEPS[n]
	setup.stepLine:SetText(("S T E P   %d   O F   %d"):format(n, #STEPS))
	setup.title:SetText(step.title)
	setup.subtitle:SetText(step.subtitle or "")
	setup.primary.text:SetText(step.primary .. (n < #STEPS and "   >" or ""))
	setup.hint:SetText(step.hint or "")
	setup.back:SetShown(n > 1)
end

function ui.openSetup(atSharing)
	if not setup then buildSetup() end
	if win then win:Hide() end
	setup:Show()
	ui.setupStep(atSharing and SHARING_STEP or 1)
end

-- ---------------------------------------------------------------------------------------------
-- Minimap button
-- ---------------------------------------------------------------------------------------------
local mini, menu

local function placeMini()
	local angle = math.rad(db().global.minimap.angle or 200)
	local radius = (Minimap:GetWidth() / 2) + 10
	mini:ClearAllPoints()
	mini:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function updateBadge()
	if mini then mini.badge:SetShown(S().snoozedUntil() ~= nil) end
end

local function menuItems()
	local snoozed = S().snoozedUntil()
	local items = {}
	if snoozed then
		items[#items + 1] = { "Wake up now", function() S().snooze("off") end }
	end
	items[#items + 1] = { "Snooze 30 minutes", function() S().snooze(30) end }
	items[#items + 1] = { "Snooze 1 hour", function() S().snooze(60) end }
	items[#items + 1] = { "-" }
	items[#items + 1] = { "Open settings", function() ui.open() end }
	items[#items + 1] = { "Test a kill", function() core().runTest("kill") end }
	items[#items + 1] = { "Debug log", function() core().debugLog.setEnabled(not core().isDebugOn()) end }
	items[#items + 1] = { "-" }
	items[#items + 1] = { "Hide minimap button", function()
		db().global.minimap.hide = true
		ui.updateMinimap()
		core().chat("Minimap button hidden. /sks minimap brings it back.")
	end }
	return items, snoozed
end

local function showMenu()
	if not menu then
		menu = CreateFrame("Frame", "SpicyKillStreaksMinimapMenu", UIParent, "BackdropTemplate")
		menu:SetFrameStrata("DIALOG")
		paint(menu, { 0.06, 0.05, 0.04 })
		menu.title = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		menu.title:SetPoint("TOPLEFT", 10, -8)
		menu.title:SetText(core().TITLE)
		menu.status = menu:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
		menu.status:SetPoint("TOPLEFT", menu.title, "BOTTOMLEFT", 0, -2)
		menu.rows = {}
		tinsert(UISpecialFrames, "SpicyKillStreaksMinimapMenu")
		-- Close when the mouse has been away from it (and the button) for a moment
		menu:SetScript("OnUpdate", function(self, elapsed)
			if self:IsMouseOver() or mini:IsMouseOver() then self.away = 0 return end
			self.away = (self.away or 0) + elapsed
			if self.away > 1.5 then self:Hide() end
		end)
	end
	local items, snoozed = menuItems()
	menu.status:SetText(snoozed and ("Snoozed until " .. date("%H:%M", snoozed)) or "Sounds on")
	for _, row in ipairs(menu.rows) do row:Hide() end
	local y = -40
	for i, item in ipairs(items) do
		local row = menu.rows[i]
		if not row then
			row = CreateFrame("Button", nil, menu)
			row:SetSize(180, 22)
			row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			row.text:SetPoint("LEFT", 10, 0)
			local hl = row:CreateTexture(nil, "HIGHLIGHT")
			hl:SetAllPoints()
			hl:SetColorTexture(1, 1, 1, 0.08)
			row.line = row:CreateTexture(nil, "ARTWORK")
			row.line:SetColorTexture(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
			row.line:SetPoint("LEFT", 6, 0)
			row.line:SetPoint("RIGHT", -6, 0)
			row.line:SetHeight(1)
			menu.rows[i] = row
		end
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", 4, y)
		if item[1] == "-" then
			row:SetHeight(8)
			row.text:SetText("")
			row.line:Show()
			row:EnableMouse(false)
			y = y - 8
		else
			row:SetHeight(22)
			row.text:SetText(item[1])
			row.line:Hide()
			row:EnableMouse(true)
			row:SetScript("OnClick", function()
				menu:Hide()
				item[2]()
				updateBadge()
			end)
			y = y - 22
		end
		row:Show()
	end
	menu:SetSize(190, -y + 8)
	menu:ClearAllPoints()
	menu:SetPoint("TOPRIGHT", mini, "BOTTOMLEFT", 0, 0)
	menu.away = 0
	menu:Show()
end

local function buildMinimap()
	mini = CreateFrame("Button", "SpicyKillStreaksMinimapButton", Minimap)
	mini:SetSize(31, 31)
	mini:SetFrameStrata("MEDIUM")
	mini:SetFrameLevel(8)
	mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	mini:RegisterForDrag("LeftButton")
	mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local bg = mini:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	bg:SetSize(20, 20)
	bg:SetPoint("CENTER")
	local icon = mini:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(core().MEDIA .. "Chilli")
	icon:SetSize(20, 20)
	icon:SetPoint("CENTER")
	local border = mini:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	mini.badge = mini:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	mini.badge:SetPoint("TOPRIGHT", 4, 2)
	mini.badge:SetText("|cff8fb3ffzZ|r")

	mini:SetScript("OnClick", function(_, which)
		if which == "RightButton" then
			if menu and menu:IsShown() then menu:Hide() else showMenu() end
		elseif IsShiftKeyDown() then
			S().snooze(S().snoozedUntil() and "off" or 30)
			updateBadge()
		elseif win and win:IsShown() then
			win:Hide()
		else
			ui.open()
		end
	end)
	mini:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local px, py = GetCursorPosition()
			local scale = Minimap:GetEffectiveScale()
			db().global.minimap.angle = math.deg((math.atan2 or atan2)(py / scale - my, px / scale - mx))
			placeMini()
		end)
	end)
	mini:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
	mini:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:AddLine(core().TITLE)
		local t = S().snoozedUntil()
		if t then GameTooltip:AddLine("Sounds snoozed until " .. date("%H:%M", t), 0.56, 0.7, 1) end
		GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
		GameTooltip:AddLine("Right-click: menu", 1, 1, 1)
		GameTooltip:AddLine("Shift-click: snooze 30 min / wake up", 1, 1, 1)
		GameTooltip:AddLine("Drag: move", 0.6, 0.6, 0.6)
		GameTooltip:Show()
	end)
	mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
	placeMini()
	updateBadge()
	-- Keep the zZ badge right when a snooze runs out
	local function tick()
		updateBadge()
		C_Timer.After(10, tick)
	end
	C_Timer.After(10, tick)
end

function ui.updateMinimap()
	if not mini then buildMinimap() end
	mini:SetShown(not db().global.minimap.hide)
	updateBadge()
end

-- Called by SpicyKillStreaks.lua once the saved settings are loaded
function ui.init()
	ui.updateMinimap()
end
