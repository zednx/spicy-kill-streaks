-- Spicy Kill Streaks: the settings window, the first-run setup and the minimap button.
--
-- Everything here talks to SpicyKillStreaks.lua through ns.core (see the bottom of that file).
-- All controls are drawn here (switches, dropdowns, sliders, text boxes, buttons) in the same
-- dark style as the setup; the old AceConfig options stay available as a fallback (/sks classic).
local ADDON, ns = ...

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
	field = { 0.07, 0.06, 0.05 },
	border = { 0.29, 0.24, 0.20 },
	accent = { 0.91, 0.33, 0.16 },
	gold = { 0.95, 0.76, 0.31 },
	text = { 0.93, 0.90, 0.87 },
	muted = { 0.66, 0.61, 0.56 },
	on = { 0.35, 1, 0.48 },
}

-- ---------------------------------------------------------------------------------------------
-- Drawing helpers
-- ---------------------------------------------------------------------------------------------
local function paint(frame, color, alpha, border)
	frame:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
	frame:SetBackdropColor(color[1], color[2], color[3], alpha or 0.97)
	local b = border or COLORS.border
	frame:SetBackdropBorderColor(b[1], b[2], b[3], 1)
end

local function font(fs, size, flags, path)
	fs:SetFont(path or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, flags or "")
end

local function text(parent, size, color, layer)
	local fs = parent:CreateFontString(nil, layer or "OVERLAY")
	font(fs, size)
	local c = color or COLORS.text
	fs:SetTextColor(c[1], c[2], c[3])
	fs:SetJustifyH("LEFT")
	return fs
end

local function gradient(tex, r1, g1, b1, r2, g2, b2)
	tex:SetColorTexture(1, 1, 1, 1)
	local ok = CreateColor and pcall(tex.SetGradient, tex, "HORIZONTAL", CreateColor(r1, g1, b1, 1), CreateColor(r2, g2, b2, 1))
	if not ok then ok = pcall(tex.SetGradient, tex, "HORIZONTAL", r1, g1, b1, r2, g2, b2) end
	if not ok then tex:SetColorTexture(r1, g1, b1, 1) end
end

-- A flat button. kind: "primary" (orange), "secondary" (dark, bordered) or "ghost" (text only)
local function makeButton(parent, label, onClick, kind, width, height)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	kind = kind or "secondary"
	b.text = text(b, 13, kind == "ghost" and COLORS.gold or COLORS.text)
	b.text:SetPoint("CENTER")
	b.text:SetJustifyH("CENTER")
	b.text:SetText(label)
	if kind == "primary" then
		paint(b, { 0.76, 0.27, 0.12 }, 1, COLORS.accent)
	elseif kind == "secondary" then
		paint(b, { 0.17, 0.135, 0.115 }, 1, { 0.38, 0.31, 0.26 })
	end
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetPoint("TOPLEFT", 1, -1)
	hl:SetPoint("BOTTOMRIGHT", -1, 1)
	hl:SetColorTexture(1, 1, 1, kind == "ghost" and 0.04 or 0.08)
	b:SetSize(width or math.max(90, (b.text:GetStringWidth() or 60) + 32), height or 30)
	b:SetScript("OnClick", onClick)
	function b:SetLabel(t) self.text:SetText(t) end
	return b
end

-- A small "x" close button
local function makeClose(parent, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(28, 28)
	b.text = text(b, 18, COLORS.muted)
	b.text:SetPoint("CENTER", 0, 1)
	b.text:SetText("x")
	b:SetScript("OnEnter", function() b.text:SetTextColor(1, 1, 1) end)
	b:SetScript("OnLeave", function() b.text:SetTextColor(COLORS.muted[1], COLORS.muted[2], COLORS.muted[3]) end)
	b:SetScript("OnClick", onClick)
	return b
end

-- For the debug log window in SpicyKillStreaks.lua
ui.kit = { paint = paint, makeButton = makeButton, makeClose = makeClose, COLORS = COLORS }

-- ---------------------------------------------------------------------------------------------
-- Controls. Each returns an item for a card: { frame, height = n or fit = function(width) }.
-- `changed` runs after any change (the live preview listens).
-- ---------------------------------------------------------------------------------------------
local changed = function() end

-- A round texture (a circle mask over a flat colour); square where the client has no masks
local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local function circle(parent, size, layer)
	local t = parent:CreateTexture(nil, layer or "ARTWORK")
	t:SetSize(size, size)
	t:SetColorTexture(1, 1, 1, 1)
	if parent.CreateMaskTexture then
		pcall(function()
			local mask = parent:CreateMaskTexture()
			mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
			mask:SetAllPoints(t)
			t:AddMaskTexture(mask)
		end)
	end
	return t
end

-- A pill-shaped track: two round ends and a bar between them, all one colour
local function pill(parent, width, height)
	local p = { parts = {} }
	local left = circle(parent, height)
	left:SetPoint("TOPLEFT", 0, -2)
	local right = circle(parent, height)
	right:SetPoint("TOPLEFT", width - height, -2)
	local mid = parent:CreateTexture(nil, "ARTWORK")
	mid:SetPoint("TOPLEFT", height / 2, -2)
	mid:SetSize(width - height, height)
	p.parts = { left, right, mid }
	function p:SetColor(r, g, b) for _, t in ipairs(self.parts) do t:SetColorTexture(r, g, b, 1) end end
	p.anchor = left
	return p
end

-- A switch with a label and an optional line of description
local function toggle(label, desc, get, set)
	local f = CreateFrame("Button", nil, UIParent)
	local track = pill(f, 34, 18)
	local knob = circle(f, 14, "OVERLAY")
	local title = text(f, 13)
	title:SetPoint("TOPLEFT", 46, -3)
	title:SetText(label)
	local sub
	if desc then
		sub = text(f, 11, COLORS.muted)
		sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
		sub:SetText(desc)
	end
	local function refresh()
		local on = get() and true or false
		if on then
			track:SetColor(0.76, 0.27, 0.12)
			knob:SetColorTexture(1, 1, 1, 1)
		else
			track:SetColor(0.23, 0.19, 0.16)
			knob:SetColorTexture(0.75, 0.70, 0.65, 1)
		end
		knob:ClearAllPoints()
		knob:SetPoint("TOPLEFT", track.anchor, "TOPLEFT", on and 18 or 2, -2)
	end
	f:SetScript("OnClick", function()
		set(not get())
		refresh()
		changed()
	end)
	refresh()
	return {
		frame = f, refresh = refresh,
		fit = function(width)
			title:SetWidth(width - 50)
			if sub then sub:SetWidth(width - 50) end
			return sub and (24 + (sub:GetStringHeight() or 12)) or 24
		end,
	}
end

-- The shared popup list for dropdowns, and an invisible layer that closes it on outside clicks
local popup, catcher
local POPUP_ROWS = 12
local function closePopup()
	if popup then popup:Hide() end
	if catcher then catcher:Hide() end
end

local function openPopup(anchor, list, order, current, onPick)
	if not popup then
		catcher = CreateFrame("Button", nil, UIParent)
		catcher:SetAllPoints(UIParent)
		catcher:SetFrameStrata("FULLSCREEN")
		catcher:SetScript("OnClick", closePopup)
		catcher:Hide()
		popup = CreateFrame("Frame", "SpicyKillStreaksDropdown", UIParent, "BackdropTemplate")
		popup:SetFrameStrata("FULLSCREEN_DIALOG")
		paint(popup, { 0.06, 0.05, 0.04 }, 1)
		popup:EnableMouse(true)
		popup:EnableMouseWheel(true)
		popup.rows = {}
		for i = 1, POPUP_ROWS do
			local row = CreateFrame("Button", nil, popup)
			row:SetHeight(24)
			row:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 24)
			row:SetPoint("TOPRIGHT", -4, -4 - (i - 1) * 24)
			row.text = text(row, 13)
			row.text:SetPoint("LEFT", 10, 0)
			row.mark = row:CreateTexture(nil, "BACKGROUND")
			row.mark:SetAllPoints()
			row.mark:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.25)
			local hl = row:CreateTexture(nil, "HIGHLIGHT")
			hl:SetAllPoints()
			hl:SetColorTexture(1, 1, 1, 0.08)
			popup.rows[i] = row
		end
		tinsert(UISpecialFrames, "SpicyKillStreaksDropdown")
		popup:SetScript("OnHide", function() if catcher then catcher:Hide() end end)
	end
	popup.offset = 0
	local function render()
		for i, row in ipairs(popup.rows) do
			local key = order[popup.offset + i]
			if key then
				row.text:SetText(list[key])
				row.mark:SetShown(key == current)
				row:SetScript("OnClick", function()
					closePopup()
					onPick(key)
				end)
				row:Show()
			else
				row:Hide()
			end
		end
	end
	popup:SetScript("OnMouseWheel", function(_, delta)
		popup.offset = math.max(0, math.min(#order - POPUP_ROWS, popup.offset - delta))
		render()
	end)
	-- Start scrolled to the current choice
	for i, key in ipairs(order) do
		if key == current then popup.offset = math.max(0, math.min(#order - POPUP_ROWS, i - 3)) end
	end
	render()
	popup:SetSize(math.max(anchor:GetWidth(), 180), math.min(#order, POPUP_ROWS) * 24 + 8)
	popup:ClearAllPoints()
	popup:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
	catcher:Show()
	popup:Show()
end

local function fieldLabel(f, label)
	local l = text(f, 11, COLORS.muted)
	l:SetPoint("TOPLEFT", 0, 0)
	l:SetText(label)
	return l
end

-- A dropdown: a label, then a field showing the choice; click for the list
local function dropdown(label, list, order, get, set)
	local f = CreateFrame("Frame", nil, UIParent)
	fieldLabel(f, label)
	local b = CreateFrame("Button", nil, f, "BackdropTemplate")
	paint(b, COLORS.field, 1)
	b:SetPoint("TOPLEFT", 0, -16)
	b:SetPoint("TOPRIGHT", 0, -16)
	b:SetHeight(30)
	local value = text(b, 13)
	value:SetPoint("LEFT", 10, 0)
	value:SetPoint("RIGHT", -28, 0)
	value:SetWordWrap(false)
	local arrow = b:CreateTexture(nil, "OVERLAY")
	arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
	arrow:SetSize(14, 14)
	arrow:SetPoint("RIGHT", -8, 0)
	pcall(arrow.SetRotation, arrow, -math.pi / 2)
	local hl = b:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.05)
	local function refresh() value:SetText(list[get()] or tostring(get() or "")) end
	b:SetScript("OnClick", function()
		if popup and popup:IsShown() then closePopup() return end
		openPopup(b, list, order, get(), function(key)
			set(key)
			refresh()
			changed()
		end)
	end)
	refresh()
	return { frame = f, height = 48, refresh = refresh }
end

-- A slider with its value on the right
local function slider(label, min, max, step, get, set, isPercent)
	local f = CreateFrame("Frame", nil, UIParent)
	fieldLabel(f, label)
	local shown = text(f, 11, COLORS.gold)
	shown:SetPoint("TOPRIGHT", 0, 0)
	shown:SetJustifyH("RIGHT")
	local s = CreateFrame("Slider", nil, f, "BackdropTemplate")
	s:SetOrientation("HORIZONTAL")
	s:SetPoint("TOPLEFT", 0, -22)
	s:SetPoint("TOPRIGHT", 0, -22)
	s:SetHeight(8)
	paint(s, COLORS.field, 1)
	s:SetThumbTexture(WHITE)
	local thumb = s:GetThumbTexture()
	if thumb then
		thumb:SetSize(10, 18)
		thumb:SetVertexColor(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
	end
	s:SetMinMaxValues(min, max)
	s:SetValueStep(step)
	if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
	local function show(v)
		shown:SetText(isPercent and (math.floor(v * 100 + 0.5) .. "%") or tostring(v))
	end
	local quiet = false
	s:SetScript("OnValueChanged", function(_, v)
		v = math.floor(v / step + 0.5) * step
		show(v)
		if quiet then return end
		set(v)
		changed()
	end)
	s:EnableMouseWheel(true)
	s:SetScript("OnMouseWheel", function(self, delta) self:SetValue(self:GetValue() + delta * step) end)
	local function refresh()
		quiet = true
		s:SetValue(get())
		show(get())
		quiet = false
	end
	refresh()
	return { frame = f, height = 40, refresh = refresh }
end

-- A one-line text box; saves on Enter or when it loses focus
local function edit(label, get, set)
	local f = CreateFrame("Frame", nil, UIParent)
	fieldLabel(f, label)
	local e = CreateFrame("EditBox", nil, f, "BackdropTemplate")
	paint(e, COLORS.field, 1)
	e:SetPoint("TOPLEFT", 0, -16)
	e:SetPoint("TOPRIGHT", 0, -16)
	e:SetHeight(30)
	e:SetAutoFocus(false)
	font(e, 13)
	e:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3])
	e:SetTextInsets(10, 10, 0, 0)
	local function save()
		set(e:GetText())
		changed()
	end
	e:SetScript("OnEnterPressed", function(self) save() self:ClearFocus() end)
	e:SetScript("OnEditFocusLost", save)
	e:SetScript("OnEscapePressed", function(self) self:SetText(get() or "") self:ClearFocus() end)
	local function refresh() e:SetText(get() or "") end
	refresh()
	return { frame = f, height = 48, refresh = refresh }
end

local function button(label, onClick, kind)
	local b = makeButton(UIParent, label, onClick, kind)
	return { frame = b, height = 30, stretch = true }
end

-- Text that wraps to the card's width
local function para(str, size, color)
	local f = CreateFrame("Frame", nil, UIParent)
	local fs = text(f, size or 13, color)
	fs:SetPoint("TOPLEFT")
	fs:SetText(str)
	return {
		frame = f, fs = fs,
		fit = function(width)
			fs:SetWidth(width)
			return math.max(size or 13, fs:GetStringHeight() or 13) + 2
		end,
	}
end

local function gap(height) return { frame = CreateFrame("Frame", nil, UIParent), height = height or 6 } end

-- ---------------------------------------------------------------------------------------------
-- Cards and pages
-- ---------------------------------------------------------------------------------------------
local CARD_PAD, ITEM_GAP_X, ITEM_GAP_Y = 18, 18, 12

-- A card holds items laid out left to right in rows; `width` is a share of the row (default 1)
local function newCard(title)
	local card = { title = title, items = {} }
	function card:add(item, width)
		item.width = width or 1
		self.items[#self.items + 1] = item
		return item
	end
	return card
end

-- Place a card's items inside `frame` at `width`; returns the card's height
local function layoutCard(frame, card, width)
	local inner = width - CARD_PAD * 2
	local y = CARD_PAD
	if card.title then
		local t = text(frame, 15, COLORS.gold)
		t:SetPoint("TOPLEFT", CARD_PAD, -CARD_PAD + 2)
		t:SetText(card.title)
		y = y + 28
	end
	local x, rowHeight, used = 0, 0, 0
	for _, item in ipairs(card.items) do
		local w = math.floor(inner * item.width - (item.width < 1 and ITEM_GAP_X * (1 - item.width) or 0))
		if used + item.width > 1.001 then
			y = y + rowHeight + ITEM_GAP_Y
			x, rowHeight, used = 0, 0, 0
		end
		local f = item.frame
		f:SetParent(frame)
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", frame, "TOPLEFT", CARD_PAD + x, -y)
		local h = item.fit and item.fit(w) or item.height or 24
		f:SetSize(w, h)
		f:Show()
		x = x + w + ITEM_GAP_X
		used = used + item.width
		rowHeight = math.max(rowHeight, h)
	end
	return y + rowHeight + CARD_PAD
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

-- Shortcuts for settings in the saved profile
local function ptoggle(key, label, desc)
	return toggle(label, desc, function() return P()[key] end, function(v) P()[key] = v end)
end
local function fxtoggle(key, label, desc)
	return toggle(label, desc, function() return P().fx[key] end, function(v) P().fx[key] = v end)
end
-- path: { "shareparty" } or { "party", "feed" } inside profile.sync
local function synctoggle(path, label, desc)
	local function tbl()
		local t = P().sync
		for i = 1, #path - 1 do t = t[path[i]] end
		return t
	end
	return toggle(label, desc, function() return tbl()[path[#path]] end, function(v) tbl()[path[#path]] = v end)
end

-- ---------------------------------------------------------------------------------------------
-- Settings window
-- ---------------------------------------------------------------------------------------------
local WIN_W, WIN_H = 940, 700   -- default size (it can be resized; the scale makes it a bit smaller)
local WIN_SCALE = 0.85
local NAV_W = 200
local HEADER_H = 58
local CONTENT_X = NAV_W + 24
local CONTENT_RIGHT = 28        -- space right of the content
local PREVIEW_H = 132

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

local function refreshPreview()
	if not preview.big or not win or not win:IsShown() then return end
	local p = P()
	local s = SAMPLES[preview.index or 2]
	local path = S().fontPath(p.fx.font) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
	local scale = p.fx.scale or 1
	local ok = pcall(preview.big.SetFont, preview.big, path, math.floor(32 * scale + 0.5), "THICKOUTLINE")
	if not ok then font(preview.big, 32, "THICKOUTLINE") end
	pcall(preview.small.SetFont, preview.small, path, 15, "OUTLINE")
	-- A font string only redraws in a new font when its text changes: clear it first
	preview.big:SetText("")
	preview.small:SetText("")
	for i, b in ipairs(preview.buttons) do
		b:SetBackdropBorderColor(unpack(i == (preview.index or 2) and COLORS.accent or { 0.38, 0.31, 0.26 }))
	end

	local packText = S().PACK_TEXT[p.soundpack]
	if not p.doscreen then
		font(preview.big, 14)
		preview.big:SetText("Nothing shows on screen: \"Big callouts on screen\" is off (Screen)")
		preview.big:SetTextColor(0.5, 0.5, 0.5)
		return
	end
	if not p.fx.fancytext then
		-- Plain mode: simple red lines, like the original addon
		font(preview.big, 20, "OUTLINE")
		preview.big:SetText(s.text)
		preview.big:SetTextColor(1, 0.2, 0.2)
	elseif packText and not s.grey then
		preview.big:SetText(S().rainbow(packText[s.text] or s.text))
		preview.big:SetTextColor(1, 1, 1)
	else
		preview.big:SetText(s.text)
		local c = s.grey and { 0.7, 0.7, 0.7 } or (s.multi and { 1, 0.85, 0.2 })
			or core().rankColors[S().LEVEL[s.level] or s.level] or { 1, 1, 1 }
		preview.big:SetTextColor(c[1], c[2], c[3])
	end
	preview.small:SetText(s.small)
end

-- Any change redraws the preview, and once more shortly after (a font used for the first time
-- can take a moment to load)
changed = function()
	refreshPreview()
	C_Timer.After(0.15, refreshPreview)
	C_Timer.After(0.6, refreshPreview)
end

local function buildPreview(parent)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	box:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_X, -(HEADER_H + 14))
	box:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -(CONTENT_RIGHT + 186), -(HEADER_H + 14))
	box:SetHeight(PREVIEW_H)
	paint(box, { 0.05, 0.065, 0.06 }, 1)
	local tag = text(box, 11, COLORS.muted)
	tag:SetPoint("TOPLEFT", 10, -8)
	tag:SetText("LIVE PREVIEW")
	preview.big = box:CreateFontString(nil, "OVERLAY")
	preview.big:SetPoint("CENTER", 0, 10)
	font(preview.big, 32, "THICKOUTLINE")
	preview.small = box:CreateFontString(nil, "OVERLAY")
	preview.small:SetPoint("TOP", preview.big, "BOTTOM", 0, -6)
	font(preview.small, 15, "OUTLINE")
	preview.small:SetTextColor(1, 0.91, 0.84)

	-- Sample buttons: show that moment, and play its sound
	preview.buttons = {}
	for i, s in ipairs(SAMPLES) do
		local b = makeButton(parent, s.label, function()
			preview.index = i
			refreshPreview()
			S().playForced(s.sound)
		end, "secondary", 84, 28)
		b:SetPoint("TOPLEFT", box, "TOPRIGHT", 14 + ((i - 1) % 2) * 90, -((math.floor((i - 1) / 2)) * 34))
		preview.buttons[i] = b
	end
	local real = makeButton(parent, "Show in game", function()
		core().preview(preview.index == 5 and "big" or (preview.index == 3 and "multi" or "rank"))
	end, "primary", 174, 28)
	real:SetPoint("TOPLEFT", box, "TOPRIGHT", 14, -104)
	preview.index = 2
end

-- ---------------------------------------------------------------------------------------------
-- Sections: each returns a list of cards
-- ---------------------------------------------------------------------------------------------
sections[#sections + 1] = { id = "announcer", label = "Announcer", hint = "Callouts and streaks", build = function()
	local cards = {}
	local c = newCard("When to call it")
	c:add(dropdown("Kill sounds", STYLES, { "dota", "ut" }, function() return P().style end, function(v)
		P().style = v
		C_Timer.After(0, function() ui.show("announcer", true) end)
	end), P().style == "ut" and 0.6 or 1)
	if P().style == "ut" then
		c:add(slider("Kills between sounds", 1, 10, 1, function() return P().utrank end, function(v) P().utrank = v end), 0.4)
	end
	cards[#cards + 1] = c

	c = newCard("Callouts")
	c:add(ptoggle("doheadshot", "Headshot", "Your first kill of a streak"), 0.5)
	c:add(ptoggle("dofirstblood", "First Blood", "Your first kill of the day"), 0.5)
	c:add(ptoggle("doretribution", "Retribution", "Kill someone who killed you in the last hour"), 0.5)
	c:add(ptoggle("docomeback", "Comeback", nil), 0.5)
	c:add(ptoggle("dopancake", "Pancake", "You or a friend die from falling or drowning"), 0.5)
	c:add(ptoggle("dogank", "Shame ganks", "You kill a player 10+ levels below you"), 0.5)
	c:add(ptoggle("doganked", "Got ganked", "A player 10+ levels above you (or ??) kills you"), 0.5)
	c:add(ptoggle("doflagcap", "Flag captures", "\"FLAG CAPTURED!\" when you capture a flag"), 0.5)
	c:add(ptoggle("doflagsounds", "Flag sounds", "Flags taken, dropped, returned and captured"), 0.5)
	c:add(ptoggle("dobgsummary", "Battleground summary", "At the end of a match: your killing blows and best streak, to share or not"), 0.5)
	c:add(button("Preview the summary", function() SlashCmdList.SPICYKILLSTREAKS("summary") end), 0.5)
	c:add(ptoggle("dobgguess", "Battleground kills (best guess)",
		"WoW Forever hides killing blows there; may now and then count a party member's"), 0.5)
	c:add(ptoggle("dopve", "Count NPC kills", "Spammy, handy for trying it out"), 0.5)
	c:add(ptoggle("dozonechange", "Reset streaks when changing zone", nil), 1)
	cards[#cards + 1] = c

	c = newCard("Streak ladder")
	local ladder = {
		{ "Headshot", "1", "ffd95a" }, { "Ownage", "2", "ffd95a" }, { "Killing Spree", "3", "ff9a26" },
		{ "Rampage", "4", "ff5a1a" }, { "Dominating", "5", "ff3d3d" }, { "Unstoppable", "6", "ff5fa8" },
		{ "Wicked Sick", "7", "c07bff" }, { "Godlike", "8+", "57e3ff" },
	}
	for _, step in ipairs(ladder) do
		local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
		paint(f, COLORS.field, 1)
		local count = text(f, 24, { 1, 1, 1 })
		count:SetPoint("TOP", 0, -10)
		count:SetJustifyH("CENTER")
		count:SetText(step[2])
		local name = text(f, 11)
		name:SetPoint("BOTTOM", 0, 8)
		name:SetJustifyH("CENTER")
		name:SetText("|cff" .. step[3] .. step[1] .. "|r")
		c:add({ frame = f, height = 66, fit = function(w) name:SetWidth(w - 4) return 66 end }, 1 / #ladder)
	end
	c:add(para("Kills in a row without dying. Godlike plays on every kill from 8 on. There are a couple of secrets too.",
		12, COLORS.muted), 1)
	cards[#cards + 1] = c
	return cards
end }

sections[#sections + 1] = { id = "sound", label = "Sound", hint = "Voice, muting, snooze", build = function()
	local cards = {}
	local c = newCard("Voice")
	c:add(ptoggle("dosound", "Play sounds", nil), 1)
	c:add(dropdown("Voice pack", PACKS, PACK_ORDER, function() return P().soundpack end, function(v)
		P().soundpack = v
		S().playForced("killingspree.ogg")
	end), 0.7)
	c:add(button("Play a sample", sample("killingspree.ogg")), 0.3)
	c:add(dropdown("When you die, play", HUMILIATION, HUMILIATION_ORDER, function() return P().humiliationvoice end,
		function(v)
			P().humiliationvoice = v
			S().playForced("humiliation")
		end), 0.7)
	c:add(button("Play it", sample("humiliation")), 0.3)
	c:add(dropdown("Sound channel", CHANNELS, CHANNEL_ORDER, function() return P().soundchannel end,
		function(v) P().soundchannel = v end), 0.7)
	c:add(gap(1), 0.3)
	c:add(ptoggle("dodeathsound", "Humiliation when you die", nil), 0.5)
	c:add(ptoggle("doprepare", "\"Prepare\" before a battleground or duel", nil), 0.5)
	cards[#cards + 1] = c

	c = newCard("Quiet time")
	c:add(para("Mute sounds in", 12, COLORS.muted), 1)
	c:add(ptoggle("mutebg", "Battlegrounds & arenas", nil), 0.34)
	c:add(ptoggle("mutedungeon", "Dungeons", nil), 0.33)
	c:add(ptoggle("muteraid", "Raids", nil), 0.33)
	local t = S().snoozedUntil()
	c:add(para(t and ("|cffffd100Snoozed|r until " .. date("%H:%M", t) .. ". Text and effects still show.")
		or "Snooze all sounds for a while:", 13), 1)
	local function snooze(arg) return function() S().snooze(arg) ui.show("sound", true) end end
	c:add(button("30 minutes", snooze(30)), 0.25)
	c:add(button("1 hour", snooze(60)), 0.25)
	c:add(button("Wake up", snooze("off"), "primary"), 0.25)
	cards[#cards + 1] = c
	return cards
end }

sections[#sections + 1] = { id = "screen", label = "Screen", hint = "Text, effects, position", build = function()
	local cards = {}
	local c = newCard("Where kills show")
	c:add(ptoggle("doscreen", "Big callouts on screen", nil), 0.5)
	c:add(ptoggle("dochat", "A line in chat", nil), 0.5)
	c:add(edit("Kill text  ($k you, $v victim, $s streak)", function() return P().kstext end,
		function(v) P().kstext = v end), 1)
	cards[#cards + 1] = c

	c = newCard("Effects")
	c:add(fxtoggle("fancytext", "Animated text", "Off: simple red lines, like the original addon"), 1)
	local choices = S().fontChoices()
	c:add(dropdown("Font", choices, sortedKeys(choices, "impact"), function() return P().fx.font end,
		function(v) P().fx.font = v end), 0.5)
	c:add(slider("Text size", 0.5, 2, 0.05, function() return P().fx.scale end, function(v) P().fx.scale = v end, true), 0.5)
	c:add(fxtoggle("sparkles", "Sparkle burst", "Bigger for new ranks and multikills"), 1)
	c:add(dropdown("Sparkles", SPARKLES, SPARKLE_ORDER, function() return P().fx.sparklestyle end,
		function(v) P().fx.sparklestyle = v end), 0.5)
	c:add(slider("How many", 5, 80, 1, function() return P().fx.sparklecount end,
		function(v) P().fx.sparklecount = v end), 0.5)
	c:add(fxtoggle("flash", "Screen-edge flash", "On multikills and big streaks"), 1)
	cards[#cards + 1] = c

	c = newCard("Position")
	c:add(button("Unlock to move", function() core().unlock(true) core().chat("Drag the orange box, then press Lock.") end), 0.25)
	c:add(button("Lock", function() core().unlock(false) end), 0.25)
	c:add(button("Reset position", function()
		P().fx.x, P().fx.y = core().defaults.profile.fx.x, core().defaults.profile.fx.y
		core().placeAnchor()
	end), 0.25)
	c:add(button("Show in game", function() core().preview("big") end, "primary"), 0.25)
	cards[#cards + 1] = c
	return cards
end }

sections[#sections + 1] = { id = "friends", label = "Friends", hint = "Party, guild and friends", build = function()
	local cards = {}
	local c = newCard("Share my kills and deaths with")
	c:add(synctoggle({ "shareparty" }, "My party", "Also raids, battlegrounds and arenas"), 0.5)
	c:add(synctoggle({ "shareguild" }, "My guild", "And join this month's guild board"), 0.5)
	c:add(synctoggle({ "sharefriends" }, "My friends",
		"Friends list, and Battle.net friends on your realm and faction"), 1)
	c:add(para("Only players running Spicy Kill Streaks see anything. Switch them all off to share nothing. "
		.. "Battlegrounds and arenas are just for you: nothing is shared from them (Kudos included), "
		.. "and they don't count on the guild board.", 12, COLORS.muted), 1)
	cards[#cards + 1] = c

	for _, who in ipairs({ { "party", "Party members' kills" }, { "guild", "Guild members' kills" },
		{ "friends", "Friends' kills" } }) do
		c = newCard(who[2])
		c:add(synctoggle({ who[1], "feed" }, "Chat feed", nil), 0.25)
		c:add(synctoggle({ who[1], "text" }, "Combat text", nil), 0.25)
		c:add(synctoggle({ who[1], "sound" }, "Sounds", nil), 0.25)
		c:add(synctoggle({ who[1], "deaths" }, "Their deaths", nil), 0.25)
		cards[#cards + 1] = c
	end

	c = newCard("Request help")
	local function atoggle(key, label, desc)
		return toggle(label, desc, function() return P().aid[key] end, function(v) P().aid[key] = v end)
	end
	c:add(atoggle("enabled", "\"Need help!\" when a player kills you", "Asks your party and guild; not from battlegrounds"), 0.5)
	c:add(atoggle("receive", "Show friends' help requests", "With On my way and a waypoint"), 0.5)
	c:add(atoggle("location", "Include where I died", "Your map position (the zone is always included)"), 0.5)
	c:add(atoggle("sound", "Raid warning sound for requests", nil), 0.5)
	c:add(atoggle("chat", "Also post my request in chat", "Everyone sees it; once a minute at most"), 1)
	c:add(para("Kill the player who killed a friend who asked, and you've AVENGED them.", 12, COLORS.muted), 1)
	c:add(button("Preview my request", function() if ns.aid then ns.aid.previewOffer() end end), 0.5)
	c:add(button("Preview a friend's request", function() if ns.aid then ns.aid.previewRequest() end end), 0.5)
	cards[#cards + 1] = c

	c = newCard("Guild extras")
	c:add(synctoggle({ "logincount" }, "At login, count guildmates using it", nil), 0.5)
	c:add(synctoggle({ "loginboard" }, "At login, show the top 3 killers", nil), 0.5)
	c:add(synctoggle({ "updatenotice" }, "Tell me when a newer version is out", nil), 1)
	c:add(button("Send a test kill", function() core().sendTestSync() end), 0.3)
	c:add(button("Who runs it?", function() core().versionCheck() end), 0.3)
	cards[#cards + 1] = c

	-- Online friends: who runs it, and per friend "Share with them" / "Show their kills"
	local F = ns.friends
	if F then
		c = newCard("Friends with Spicy Kill Streaks")
		local list = F.withSKS()
		c:add(para(#list == 0 and "No online friends with Spicy Kill Streaks found yet. They're found by themselves when "
			.. "My friends is on (at login and when a friend comes online), or press Who runs it?."
			or "Switch a friend off to stop sharing with them, or to stop showing their kills.", 12, COLORS.muted), 0.7)
		c:add(button("Who runs it?", function()
			local asked = F.check()
			core().chat("Asked " .. asked .. " online friend" .. (asked == 1 and "" or "s") .. " whether they run it.")
			C_Timer.After(3, function() ui.show("friends", true) end)
		end), 0.3)
		do
			for _, f in ipairs(list) do
				local st = F.status[(strsplit("-", f.key))]
				local status = "|cff5aff7aSKS " .. (st.version or "?") .. "|r" .. (st.sharing and " · sharing" or " · not sharing")
				c:add(para(f.label .. (f.bnet and " |cff9a8f86(Battle.net)|r" or "") .. "\n" .. status, 12), 0.4)
				c:add(toggle("Share with them", nil, function() return F.pref(f.name).share end,
					function(v) F.setPref(f.name, "share", v) end), 0.3)
				c:add(toggle("Show their kills", nil, function() return F.pref(f.name).show end,
					function(v) F.setPref(f.name, "show", v) end), 0.3)
			end
		end
		cards[#cards + 1] = c

		c = newCard("Muted players")
		local names = {}
		for key, name in pairs(F.mutedList()) do names[#names + 1] = { key = key, name = type(name) == "string" and name or key } end
		table.sort(names, function(a, b) return a.key < b.key end)
		c:add(para("Their kills and deaths aren't shown, whoever they share with (party, guild or friends). "
			.. "Mute someone with /sks mute <name>.", 12, COLORS.muted), 1)
		if #names == 0 then
			c:add(para("Nobody muted.", 12, COLORS.muted), 1)
		end
		for _, m in ipairs(names) do
			c:add(para(m.name, 13), 0.7)
			c:add(button("Unmute", function() F.mute(m.key, false) ui.show("friends", true) end), 0.3)
		end
		cards[#cards + 1] = c
		F.onStatus = function()
			local win = _G.SpicyKillStreaksWindow
			if ui.current == "friends" and win and win:IsShown() then ui.show("friends", true) end
		end
	end
	return cards
end, dynamic = true }

sections[#sections + 1] = { id = "kudos", label = "Kudos", hint = "React to friends' kills", build = function()
	local cards = {}
	local function ktoggle(key, label, desc)
		return toggle(label, desc, function() return P().kudos[key] end, function(v) P().kudos[key] = v end)
	end
	local sync = P().sync
	local c = newCard(nil)
	c:add(para("Kudos need sharing with your party or guild switched on (Friends page)."
		.. ((sync.shareparty or sync.shareguild) and "" or "  |cffff7733Both are off right now.|r"), 13), 1)
	c:add(para("Reactions only reach the friend you send them to (and anyone in chat, if you post there). "
		.. "Kudos received so far: |cffffd100" .. (tonumber(P().kudos.got) or 0) .. "|r", 12, COLORS.muted), 1)
	cards[#cards + 1] = c

	c = newCard("Kudos")
	c:add(ktoggle("give", "Kudos popup for friends' kills and deaths",
		"Nine emoji to pick from, for kills and deaths alike"), 1)
	c:add(ktoggle("receive", "Show kudos friends send me", nil), 0.5)
	c:add(ktoggle("sound", "Kudos sounds", "Their /cheer; loot toasts at 3 and 5; a death has its own"), 0.5)
	c:add(ktoggle("chat", "Also post my reactions in chat", "Everyone sees it; one every 15 seconds at most"), 1)
	cards[#cards + 1] = c

	c = newCard("Popup")
	c:add(slider("Popup size", 0.6, 1.2, 0.05, function() return P().kudos.scale or 0.85 end,
		function(v) if ns.kudos then ns.kudos.setScale(v) else P().kudos.scale = v end end, true), 0.5)
	c:add(slider("Card width", 180, 380, 10, function() return P().kudos.width or 220 end,
		function(v) if ns.kudos then ns.kudos.setWidth(v) else P().kudos.width = v end end), 0.5)
	c:add(toggle("Grow upwards", "New cards stack up from the popup's spot instead of down",
		function() return P().kudos.growup end, function(v) if ns.kudos then ns.kudos.setGrowUp(v) else P().kudos.growup = v end end), 0.5)
	c:add(toggle("Hide in combat", "Fades out when a fight starts, back after (kudos you get still flash)",
		function() return P().kudos.combathide end, function(v)
			P().kudos.combathide = v
			if not v and ns.kudos then ns.kudos.fadeHolder(1) end
		end), 0.5)
	c:add(para("Move it any time: mouse over the spot where cards appear and drag the handle.", 12, COLORS.muted), 1)
	c:add(button("Unlock to move", function()
		if not ns.kudos then return end
		ns.kudos.unlock(true)
		ns.kudos.preview()
		core().chat("Drag the Kudos popup by its bar where you want it, then press Lock.")
	end), 0.34)
	c:add(button("Lock", function() if ns.kudos then ns.kudos.unlock(false) end end), 0.33)
	c:add(button("Reset position", function() if ns.kudos then ns.kudos.resetPosition() end end), 0.33)
	cards[#cards + 1] = c

	c = newCard("Preview")
	c:add(button("Friends' kills", function() if ns.kudos then ns.kudos.preview() end end), 0.34)
	c:add(button("Kudos I get", function() if ns.kudos then ns.kudos.previewGot() end end), 0.33)
	c:add(button("A death", function() if ns.kudos then ns.kudos.previewDeath() end end), 0.33)
	cards[#cards + 1] = c
	return cards
end, dynamic = true }

sections[#sections + 1] = { id = "kos", label = "KOS list", hint = "Grudges and nemeses", build = function()
	local cards = {}
	local K = ns.kos
	local function kt(key, label, desc)
		return toggle(label, desc, function() return P().kos[key] end, function(v) P().kos[key] = v end)
	end
	local c = newCard(nil)
	c:add(para("Your kill-on-sight list: players who keep killing you. Kill one for |cffffd100GRUDGE SETTLED!|r "
		.. "(|cffffd100NEMESIS SLAIN!|r for a nemesis). Players are matched exactly, never by name alone.", 13), 1)
	cards[#cards + 1] = c

	c = newCard("Settings")
	c:add(kt("enabled", "KOS list and payback", nil), 0.5)
	c:add(kt("offer", "Offer \"Add to KOS\"", "After a player kills you twice"), 0.5)
	c:add(kt("nemesis", "Nemeses", "3 deaths in a row to one player adds them by itself"), 0.5)
	c:add(kt("sightings", "Sighting alerts", "When a listed player is your target, mouseover or nameplate"), 0.5)
	c:add(kt("sightsound", "Raid warning sound for a sighting", nil), 1)
	cards[#cards + 1] = c
	if not K then return cards end

	c = newCard("Add a player")
	local typed = ""
	c:add(edit("Name (then Add, or Enter)", function() return typed end, function(v) typed = v or "" end), 0.7)
	c:add(button("Add", function()
		local ok, why = K.addByName(typed)
		core().chat(ok and (typed .. " is on your KOS list (unconfirmed until you see them).") or ("Not added: " .. tostring(why) .. "."))
		if ok then typed = "" C_Timer.After(0, function() ui.show("kos", true) end) end
	end, "primary"), 0.3)
	c:add(para("A typed name is |cff9a8f86unconfirmed|r until you see a player with that name and say it's them; "
		.. "only then does payback play for them.", 12, COLORS.muted), 1)
	cards[#cards + 1] = c

	c = newCard("On your list")
	local list = K.sorted()
	if #list == 0 then c:add(para("Nobody yet.", 12, COLORS.muted), 1) end
	for _, item in ipairs(list) do
		local e = item.entry
		local tag = e.nemesis and "|cffff5544Nemesis|r" or (e.unconfirmed and "|cff9a8f86unconfirmed|r" or "|cffff8a4aKOS|r")
		c:add(para((e.name or "?") .. "  " .. tag .. "\n|cff9a8f86killed you " .. (e.killedMe or 0) .. ", you killed them "
			.. (e.iKilled or 0) .. "|r", 12), 0.7)
		c:add(button("Remove", function() K.remove(item.key) ui.show("kos", true) end), 0.3)
	end
	cards[#cards + 1] = c

	local rivals = K.rivals(8)
	if #rivals > 0 then
		c = newCard("Rivals (not on the list)")
		for _, r in ipairs(rivals) do
			c:add(para((r.rival.name or "?") .. "\n|cff9a8f86killed you " .. (r.rival.killedMe or 0) .. ", you killed them "
				.. (r.rival.iKilled or 0) .. "|r", 12), 0.7)
			c:add(button("Add to KOS", function() K.add(r.guid, r.rival.name) ui.show("kos", true) end), 0.3)
		end
		cards[#cards + 1] = c
	end
	return cards
end, dynamic = true }

sections[#sections + 1] = { id = "board", label = "Guild board", hint = "This month's top killers", build = function()
	local cards = {}
	local c = newCard("Guild board, " .. date("%B"))
	if not S().guildName() then
		c:add(para("You are not in a guild.", 14), 1)
		return { c }
	end
	local list = S().top(10)
	if #list == 0 then
		c:add(para("Nobody has a kill streak this month yet. Get out there!", 14), 1)
	else
		local head = function(str) return para("|cffa89c90" .. str .. "|r", 11) end
		c:add(head("PLAYER"), 0.46)
		c:add(head("BEST STREAK"), 0.18)
		c:add(head("KILLS"), 0.18)
		c:add(head("DEATHS"), 0.18)
		for i, entry in ipairs(list) do
			local medal = (i == 1 and "ffd100") or (i == 2 and "c0c0c0") or (i == 3 and "cd7f32") or "ffffff"
			c:add(para("|cff" .. medal .. i .. ".|r   " .. entry.name, 14), 0.46)
			c:add(para("|cff57e3ff" .. entry.best .. "|r", 14), 0.18)
			c:add(para(tostring(entry.kills), 14), 0.18)
			c:add(para(tostring(entry.deaths or 0), 14), 0.18)
		end
	end
	local deaths = S().topDeaths(3)
	if #deaths > 0 then
		local parts = {}
		for i, entry in ipairs(deaths) do parts[i] = entry.name .. " (" .. entry.deaths .. ")" end
		c:add(gap(4), 1)
		c:add(para("|cffff5555Most deaths:|r " .. table.concat(parts, ", "), 13), 1)
	end
	c:add(gap(4), 1)
	c:add(para("Best kill streak this month, from guildmates who run the addon and share with the guild. "
		.. "It starts again on the 1st.", 12, COLORS.muted), 1)
	c:add(button("Post to guild chat", function() S().shareBoard("GUILD") end, "primary"), 0.33)
	c:add(button("Post to party chat", function() S().shareBoard("PARTY") end), 0.33)
	c:add(button("Ask guildmates now", function()
		core().versionCheck()
		C_Timer.After(6, function() if current == "board" then ui.show("board", true) end end)
	end), 0.33)
	cards[#cards + 1] = c
	return cards
end, dynamic = true }

sections[#sections + 1] = { id = "extras", label = "Extras", hint = "Emotes, duels, screenshots", build = function()
	local cards = {}
	local emotes = core().emotes
	local emoteOrder = sortedKeys(emotes, "none")
	local c = newCard("Emotes after a kill")
	c:add(dropdown("Emote", emotes, emoteOrder, function() return P().doemote end, function(v) P().doemote = v end), 0.5)
	c:add(ptoggle("dotxtemote", "Send a custom emote message", nil), 0.5)
	c:add(edit("Custom message  ($v victim, $s streak)", function() return P().ksemote end,
		function(v) P().ksemote = v end), 1)
	c:add(para("WoW Forever only lets a custom message go out from a key press: put /sks emote in a macro.", 12,
		COLORS.muted), 1)
	cards[#cards + 1] = c

	c = newCard("Duels")
	c:add(edit("Duel win text  ($k you, $v opponent)", function() return P().dueltext end,
		function(v) P().dueltext = v end), 1)
	c:add(dropdown("Emote after a win", emotes, emoteOrder, function() return P().duelemotewin end,
		function(v) P().duelemotewin = v end), 0.5)
	c:add(dropdown("Emote after a loss", emotes, emoteOrder, function() return P().duelemoteloss end,
		function(v) P().duelemoteloss = v end), 0.5)
	c:add(ptoggle("duelhumiliation", "Humiliation when you flee a duel", nil), 1)
	cards[#cards + 1] = c

	c = newCard("Screenshots")
	c:add(ptoggle("shotkill", "Every kill", nil), 0.34)
	c:add(ptoggle("shotstreak", "New best streak", nil), 0.33)
	c:add(ptoggle("shotmultikill", "Multikill", nil), 0.33)
	c:add(ptoggle("shotduelwin", "Duel win", nil), 0.34)
	c:add(ptoggle("shotduelloss", "Duel loss", nil), 0.33)
	c:add(ptoggle("shotdeath", "Death", nil), 0.33)
	cards[#cards + 1] = c
	return cards
end }

sections[#sections + 1] = { id = "soundboard", label = "Sound board", hint = "Hear every sound", build = function()
	local cards = {}
	local c = newCard(nil)
	c:add(para("Click a sound to hear it in your voice pack (" .. (PACKS[P().soundpack] or P().soundpack)
		.. "). It plays even with sounds off, muted or snoozed.", 13), 1)
	cards[#cards + 1] = c
	for _, entry in ipairs(S().soundBoard()) do
		if entry.section then
			c = newCard(entry.section)
			cards[#cards + 1] = c
		else
			if entry[3] then
				c:add(button(entry[1], sample(entry[3])), 0.3)
			else
				-- a secret: named, never playable
				c:add(para("|cffffd100" .. entry[1] .. "|r  ???", 13), 0.3)
			end
			local p = para(entry[2], 12, COLORS.muted)
			local fit = p.fit
			-- (centred on the button's height)
			p.fit = function(w) fit(w) p.fs:ClearAllPoints() p.fs:SetPoint("LEFT", p.frame, "LEFT") return 30 end
			c:add(p, 0.7)
		end
	end
	return cards
end, dynamic = true }

sections[#sections + 1] = { id = "about", label = "About", hint = "Who made it, feedback", build = function()
	local cards = {}
	local c = newCard(nil)
	local head = CreateFrame("Frame", nil, UIParent)
	local icon = head:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(core().MEDIA .. "Chilli")
	icon:SetSize(64, 64)
	icon:SetPoint("LEFT")
	local name = text(head, 26, COLORS.gold)
	name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 16, -6)
	name:SetText(core().TITLE)
	local tagline = text(head, 13, COLORS.muted)
	tagline:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -6)
	tagline:SetText("Version " .. core().VERSION .. "  ·  Announcer voices for your killing blows in WoW Forever")
	c:add({ frame = head, height = 70 }, 1)
	cards[#cards + 1] = c

	c = newCard("Made by")
	c:add(para("|cffff7733Spicy Bubbletea|r", 20), 1)
	c:add(para("Horde  ·  WoW Forever  ·  PvP realm", 12, COLORS.muted), 1)
	c:add(gap(2), 1)
	c:add(para("Ideas, bugs, or a kill you're proud of? I'd love to hear it.", 13), 1)
	cards[#cards + 1] = c

	c = newCard("Feedback and bugs")
	for _, line in ipairs({
		{ "In game", "Send Spicy Bubbletea a message (Horde)." },
		{ "GitHub", "github.com/zednx/spicy-kill-streaks (Issues)" },
		{ "Bugs", "Open the Debug log at the top, then Select all, Ctrl+C, and send it along." },
	}) do
		c:add(para("|cffffd100" .. line[1] .. "|r", 13), 0.18)
		c:add(para(line[2], 13), 0.82)
	end
	cards[#cards + 1] = c

	c = newCard("Credits")
	for _, line in ipairs({
		{ "Inspired by", "dG KillShot by Lance Inman" },
		{ "Voices", "Unreal Tournament (Epic Games), Heroes of Newerth Flamboyant (S2 Games / Frostburn) and a few of WoW's own lines (Blizzard). Details in sounds\\CREDITS.txt" },
		{ "Fonts", "Google Fonts, under the SIL Open Font License and Apache 2.0 (Media\\Fonts)" },
		{ "Licence", "GNU GPL v2" },
	}) do
		c:add(para(line[1], 12, COLORS.muted), 0.18)
		c:add(para(line[2], 12), 0.82)
	end
	cards[#cards + 1] = c

	c = newCard("More")
	c:add(toggle("Show the minimap button", nil, function() return not db().global.minimap.hide end, function(v)
		db().global.minimap.hide = not v
		ui.updateMinimap()
	end), 1)
	c:add(button("Run the setup again", function() win:Hide() ui.openSetup() end, "primary"), 0.33)
	c:add(button("Classic options window", function() win:Hide() core().openClassic() end), 0.33)
	c:add(button("Stats", function() win:Hide() core().openStats() end), 0.33)
	cards[#cards + 1] = c
	return cards
end }

-- ---------------------------------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------------------------------
local pages = {} -- section id -> content frame (built once; "dynamic" sections are rebuilt)

local function styleNav(b, selected)
	if selected then
		b.bg:SetColorTexture(0.20, 0.12, 0.09, 1)
		b.name:SetTextColor(1, 1, 1)
	else
		b.bg:SetColorTexture(0, 0, 0, 0)
		b.name:SetTextColor(COLORS.text[1], COLORS.text[2], COLORS.text[3])
	end
	b.bar:SetShown(selected)
end

local function buildPage(section)
	local width = math.floor(scroll:GetWidth() - 14)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetWidth(width)
	local y = 0
	local ok, cards = pcall(section.build)
	if not ok then
		local c = newCard("Could not build this page")
		c:add(para(tostring(cards), 12, { 1, 0.4, 0.4 }), 1)
		cards = { c }
	end
	for _, card in ipairs(cards) do
		local f = CreateFrame("Frame", nil, content, "BackdropTemplate")
		paint(f, COLORS.panel, 1)
		f:SetPoint("TOPLEFT", 0, -y)
		local h = layoutCard(f, card, width)
		f:SetSize(width, h)
		y = y + h + 14
	end
	content:SetHeight(math.max(y, 10))
	return content
end

local function updateScrollbar()
	local range = scroll:GetVerticalScrollRange() or 0
	local track = scroll:GetHeight()
	if range <= 0 then scroll.thumb:Hide() return end
	local size = math.max(30, track * track / (track + range))
	scroll.thumb:SetHeight(size)
	scroll.thumb:ClearAllPoints()
	scroll.thumb:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 10, -(track - size) * (scroll:GetVerticalScroll() / range))
	scroll.thumb:Show()
end

-- rebuild: build the page again (its numbers changed)
function ui.show(id, rebuild)
	current = id
	ui.current = id
	closePopup()
	for _, b in ipairs(navButtons) do styleNav(b, b.id == id) end
	for _, page in pairs(pages) do page:Hide() end
	for _, s in ipairs(sections) do
		if s.id == id then
			if rebuild or s.dynamic or not pages[id] then
				if pages[id] then pages[id]:Hide() end
				pages[id] = buildPage(s)
			end
			scroll:SetScrollChild(pages[id])
			pages[id]:Show()
		end
	end
	scroll:SetVerticalScroll(0)
	C_Timer.After(0, updateScrollbar)
	refreshPreview()
end

local function buildWindow()
	local saved = db().global.window
	win = CreateFrame("Frame", "SpicyKillStreaksWindow", UIParent, "BackdropTemplate")
	win:SetSize(saved.width or WIN_W, saved.height or WIN_H)
	win:SetScale(WIN_SCALE)
	win:SetResizable(true)
	if win.SetResizeBounds then win:SetResizeBounds(780, 560, 1600, 1200)
	elseif win.SetMinResize then win:SetMinResize(780, 560) end
	if saved.point then win:SetPoint(saved.point, UIParent, saved.point, saved.x or 0, saved.y or 0) else win:SetPoint("CENTER") end
	win:SetFrameStrata("HIGH")
	win:SetToplevel(true)
	win:SetClampedToScreen(true)
	win:SetMovable(true)
	win:EnableMouse(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", function()
		win:StopMovingOrSizing()
		local point, _, _, x, y = win:GetPoint()
		saved.point, saved.x, saved.y = point, x, y
	end)
	win:SetScript("OnHide", closePopup)
	paint(win, COLORS.bg, 0.98)
	tinsert(UISpecialFrames, "SpicyKillStreaksWindow")

	-- Header: gradient like the setup's banner, the chilli, the name, the version and actions
	local band = win:CreateTexture(nil, "BORDER")
	band:SetPoint("TOPLEFT", 1, -1)
	band:SetPoint("TOPRIGHT", -1, -1)
	band:SetHeight(HEADER_H)
	gradient(band, 0.20, 0.07, 0.05, 0.13, 0.06, 0.16)
	local line = win:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOPLEFT", band, "BOTTOMLEFT")
	line:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")
	line:SetHeight(2)
	gradient(line, COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.69, 0.32, 0.87)
	local icon = win:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(core().MEDIA .. "Chilli")
	icon:SetSize(38, 38)
	icon:SetPoint("TOPLEFT", 14, -10)
	local name = win:CreateFontString(nil, "OVERLAY")
	font(name, 30, "OUTLINE", core().fonts.bangers and core().fonts.bangers.path)
	name:SetPoint("LEFT", icon, "RIGHT", 10, 0)
	name:SetText("SPICY |cffe8552aKILL STREAKS|r")
	local version = text(win, 12, COLORS.muted)
	version:SetPoint("BOTTOMLEFT", name, "BOTTOMRIGHT", 10, 4)
	version:SetText("v" .. core().VERSION)

	local close = makeClose(win, function() win:Hide() end)
	close:SetPoint("TOPRIGHT", -8, -14)
	local debug = makeButton(win, "Debug log", function() core().debugLog.setEnabled(not core().isDebugOn()) end)
	debug:SetPoint("RIGHT", close, "LEFT", -8, 0)
	local stats = makeButton(win, "Stats", function() win:Hide() core().openStats() end)
	stats:SetPoint("RIGHT", debug, "LEFT", -8, 0)
	local test = makeButton(win, "Test a kill", function() core().runTest("kill") end, "primary")
	test:SetPoint("RIGHT", stats, "LEFT", -8, 0)

	-- Navigation
	local nav = CreateFrame("Frame", nil, win, "BackdropTemplate")
	nav:SetPoint("TOPLEFT", 1, -(HEADER_H + 3))
	nav:SetPoint("BOTTOMLEFT", 1, 1)
	nav:SetWidth(NAV_W)
	nav:SetBackdrop({ bgFile = WHITE })
	nav:SetBackdropColor(0.07, 0.058, 0.048, 1)
	navButtons = {}
	for i, s in ipairs(sections) do
		local b = CreateFrame("Button", nil, nav)
		b:SetSize(NAV_W - 16, 46)
		b:SetPoint("TOPLEFT", 8, -12 - (i - 1) * 50)
		b.bg = b:CreateTexture(nil, "BACKGROUND")
		b.bg:SetAllPoints()
		b.bar = b:CreateTexture(nil, "ARTWORK")
		b.bar:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 1)
		b.bar:SetPoint("TOPLEFT")
		b.bar:SetPoint("BOTTOMLEFT")
		b.bar:SetWidth(3)
		local hl = b:CreateTexture(nil, "HIGHLIGHT")
		hl:SetAllPoints()
		hl:SetColorTexture(1, 1, 1, 0.04)
		b.name = text(b, 14)
		b.name:SetPoint("TOPLEFT", 14, -8)
		b.name:SetText(s.label)
		local hint = text(b, 11, COLORS.muted)
		hint:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -4)
		hint:SetText(s.hint)
		b.id = s.id
		b:SetScript("OnClick", function() ui.show(s.id) end)
		navButtons[#navButtons + 1] = b
	end
	win.snoozeText = text(nav, 12, COLORS.gold)
	win.snoozeText:SetPoint("BOTTOMLEFT", 16, 16)
	win.snoozeText:SetWidth(NAV_W - 32)

	buildPreview(win)

	-- The scrolling page, with a thin scrollbar of our own
	local top = HEADER_H + 14 + PREVIEW_H + 16
	scroll = CreateFrame("ScrollFrame", nil, win)
	scroll:SetPoint("TOPLEFT", win, "TOPLEFT", CONTENT_X, -top)
	scroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -(CONTENT_RIGHT + 6), 16)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local range = self:GetVerticalScrollRange() or 0
		self:SetVerticalScroll(math.max(0, math.min(range, self:GetVerticalScroll() - delta * 60)))
		updateScrollbar()
	end)
	scroll:SetScript("OnScrollRangeChanged", updateScrollbar)
	scroll.thumb = win:CreateTexture(nil, "OVERLAY")
	scroll.thumb:SetWidth(4)
	scroll.thumb:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.7)

	-- Resize handle: drag the bottom-right corner; the page is laid out again for the new width
	local grip = CreateFrame("Button", nil, win)
	grip:SetSize(18, 18)
	grip:SetPoint("BOTTOMRIGHT", -3, 3)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	grip:SetScript("OnMouseDown", function() closePopup() win:StartSizing("BOTTOMRIGHT") end)
	grip:SetScript("OnMouseUp", function()
		win:StopMovingOrSizing()
		saved.width, saved.height = win:GetSize()
		local point, _, _, x, y = win:GetPoint()
		saved.point, saved.x, saved.y = point, x, y
		for id, page in pairs(pages) do page:Hide() pages[id] = nil end
		ui.show(current or "announcer", true)
	end)

	win:SetScript("OnShow", function()
		local t = S().snoozedUntil()
		win.snoozeText:SetText(t and ("Sounds snoozed\nuntil " .. date("%H:%M", t)) or "")
		refreshPreview()
	end)
end

function ui.open(page)
	if not win then buildWindow() end
	win:Show()
	ui.show(type(page) == "string" and page or current or "announcer")
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
	b.title:SetWidth(b:GetWidth() - 12)
	b.title:SetWordWrap(false)
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

local FONT_ROWS = {
	{ "impact", "bangers", "luckiest", "anton", "russo", "bebas" },
	{ "blackops", "expressway", "grandstander", "orbitron", "pressstart", "marker" },
}
-- Some fonts are wider or taller than others: their sample size on the cards
local FONT_SAMPLE_SIZE = { pressstart = 11, orbitron = 16, blackops = 18, russo = 18, luckiest = 18, grandstander = 18 }
STEPS[3] = {
	title = "How much flair?",
	subtitle = "What shows on screen when you get a kill, and in which font. Each click shows it in game.",
	primary = "Next",
	hint = "Drag the text somewhere else later with /sks unlock.",
	build = function(page)
		local presets = core().presets
		local presetCards = cardRow(page, #presets, 0, 90, 200)
		-- Two rows of fonts (Expressway only when Daylight UI is installed)
		local fontKeys, fontCards = {}, {}
		for r, row in ipairs(FONT_ROWS) do
			local keys = {}
			for _, key in ipairs(row) do
				if core().fonts[key] and S().fontAvailable(key) then keys[#keys + 1] = key end
			end
			local cards = cardRow(page, #keys, 102 + (r - 1) * 100, 90, 140)
			for i, b in ipairs(cards) do
				fontKeys[#fontKeys + 1] = keys[i]
				fontCards[#fontCards + 1] = b
			end
		end
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
				local key = fontKeys[i]
				local f = core().fonts[key]
				local name = f and f.name:gsub(" %(.*%)", "") or key
				setCard(b, { title = name, sample = "GODLIKE!", sampleFont = f and f.path,
					sampleSize = FONT_SAMPLE_SIZE[key] or 22, sampleColor = { 0.34, 0.89, 1 } }, p.fx.font == key)
				b.sample:SetPoint("TOP", 0, -18)
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
	{ key = "docomeback", title = "Comeback", desc = "It's a surprise." },
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
	subtitle = "When a party member, guildmate or friend with the addon goes on a spree, your screen lights up too.",
	primary = "Next",
	hint = "Only players running Spicy Kill Streaks see anything. Switch them all off to share nothing.",
	build = function(page)
		local cards = cardRow(page, 3, 10, 170, 260)
		local info = {
			{ key = "shareparty", title = "Share with my party", desc = "Also raids, battlegrounds and arenas" },
			{ key = "shareguild", title = "Share with my guild", desc = "And join this month's guild board of top killers" },
			{ key = "sharefriends", title = "Share with my friends", desc = "Friends list, and Battle.net friends on your realm" },
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
	local close = makeClose(setup, function() finish(true) end)
	close:SetPoint("TOPRIGHT", -8, -8)

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

-- ---------------------------------------------------------------------------------------------
-- Match summary: at the end of a battleground or arena, our killing blows and best kill streak,
-- with buttons to share it (nothing is posted unless one is clicked)
-- ---------------------------------------------------------------------------------------------
local summary

local SUMMARY_W = 360
local SUMMARY_PAD = 18

-- A stat tile: a coloured strip on top, a big number, a small label
local function statBox(parent, label, accent)
	local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	paint(box, COLORS.field, 1)
	box:SetSize((SUMMARY_W - SUMMARY_PAD * 2 - 12) / 2, 84)
	local strip = box:CreateTexture(nil, "ARTWORK")
	strip:SetPoint("TOPLEFT", 1, -1)
	strip:SetPoint("TOPRIGHT", -1, -1)
	strip:SetHeight(3)
	strip:SetColorTexture(accent[1], accent[2], accent[3], 1)
	box.value = text(box, 36, { 1, 1, 1 })
	font(box.value, 36, "OUTLINE", fontInfo("bangers"))
	box.value:SetPoint("TOP", 0, -14)
	box.value:SetJustifyH("CENTER")
	box.label = text(box, 11, COLORS.muted)
	box.label:SetPoint("BOTTOM", 0, 10)
	box.label:SetJustifyH("CENTER")
	box.label:SetText(label)
	return box
end

local function buildSummary()
	local f = CreateFrame("Frame", "SpicyKillStreaksMatchSummary", UIParent, "BackdropTemplate")
	f:SetSize(SUMMARY_W, 260)
	f:SetPoint("TOP", UIParent, "TOP", 0, -140)
	f:SetFrameStrata("DIALOG")
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	paint(f, COLORS.bg, 0.97)
	-- Header: the setup's gradient, the chilli, the map in Bangers, a subtitle
	local band = f:CreateTexture(nil, "BORDER")
	band:SetPoint("TOPLEFT", 1, -1)
	band:SetPoint("TOPRIGHT", -1, -1)
	band:SetHeight(58)
	gradient(band, 0.20, 0.07, 0.05, 0.13, 0.06, 0.16)
	local line = f:CreateTexture(nil, "ARTWORK")
	line:SetPoint("TOPLEFT", band, "BOTTOMLEFT")
	line:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT")
	line:SetHeight(1)
	line:SetColorTexture(COLORS.accent[1], COLORS.accent[2], COLORS.accent[3], 0.6)
	local chilli = f:CreateTexture(nil, "ARTWORK")
	chilli:SetTexture(core().MEDIA .. "Chilli")
	chilli:SetSize(30, 30)
	chilli:SetPoint("TOPLEFT", SUMMARY_PAD - 4, -14)
	f.title = text(f, 22, COLORS.gold)
	font(f.title, 22, "OUTLINE", fontInfo("bangers"))
	f.title:SetPoint("TOPLEFT", SUMMARY_PAD + 32, -10)
	f.title:SetPoint("RIGHT", -40, 0)
	f.title:SetWordWrap(false)
	f.sub = text(f, 11, COLORS.muted)
	f.sub:SetPoint("TOPLEFT", SUMMARY_PAD + 32, -36)
	local close = makeClose(f, function() f:Hide() end)
	close:SetPoint("TOPRIGHT", -8, -14)
	-- Stats
	f.kills = statBox(f, "Killing blows", COLORS.accent)
	f.kills:SetPoint("TOPLEFT", SUMMARY_PAD, -74)
	f.best = statBox(f, "Best kill streak", COLORS.gold)
	f.best:SetPoint("TOPRIGHT", -SUMMARY_PAD, -74)
	f.note = text(f, 10, COLORS.muted)
	f.note:SetPoint("TOP", 0, -168)
	f.note:SetWidth(SUMMARY_W - SUMMARY_PAD * 2)
	f.note:SetJustifyH("CENTER")
	f.note:SetWordWrap(true)
	-- Footer: a divider, the status on the left, the share buttons on the right
	f.divider = f:CreateTexture(nil, "ARTWORK")
	f.divider:SetHeight(1)
	f.divider:SetColorTexture(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
	f.status = text(f, 11, COLORS.on)
	local function share(channel)
		if not f.match or not channel then return end
		local shared, hidden = S().matchLine(f.match)
		-- Posted in the click itself: WoW Forever only lets an addon post to chat from a click.
		-- A hidden scoreboard number may not be allowed in chat: then without it.
		if pcall(SendChatMessage, shared, channel) then
			f.status:SetText("Shared!")
		elseif hidden and pcall(SendChatMessage, S().matchLine(f.match, true), channel) then
			f.status:SetText("Shared (without the killing blows).")
		else
			f.status:SetText("Could not post to chat.")
		end
	end
	f.shareGroup = makeButton(f, "Share to battleground", function() share(f.groupChannel) end, "primary", nil, 28)
	f.shareGuild = makeButton(f, "Share to guild", function() share("GUILD") end, "secondary", nil, 28)
	tinsert(UISpecialFrames, "SpicyKillStreaksMatchSummary") -- Escape closes it
	return f
end

-- Place the note, divider and buttons under the stats, and fit the card's height to them
local function layoutSummary(f)
	local noteH = math.max(12, f.note:GetStringHeight() or 12)
	local footerY = 168 + noteH + 14
	f.divider:ClearAllPoints()
	f.divider:SetPoint("TOPLEFT", SUMMARY_PAD, -footerY)
	f.divider:SetPoint("TOPRIGHT", -SUMMARY_PAD, -footerY)
	-- buttons packed from the right
	local x = -SUMMARY_PAD
	for _, b in ipairs({ f.shareGuild, f.shareGroup }) do
		b:ClearAllPoints()
		if b:IsShown() then
			b:SetPoint("TOPRIGHT", x, -(footerY + 12))
			x = x - b:GetWidth() - 8
		end
	end
	f.status:ClearAllPoints()
	f.status:SetPoint("TOPLEFT", SUMMARY_PAD, -(footerY + 20))
	f:SetHeight(footerY + 12 + 28 + 16)
end

function ui.matchSummary(match)
	summary = summary or buildSummary()
	summary.match = match
	summary.title:SetText(match.zone)
	local caps = match.caps or 0
	summary.sub:SetText("Match summary" .. (caps > 0 and ("  ·  " .. caps .. " flag capture" .. (caps == 1 and "" or "s")) or ""))
	-- The scoreboard's killing blows when there are some: a hidden value can't be read, but the
	-- game may still let it be shown. Otherwise the addon's own count.
	local fromScoreboard = match.scoreKB ~= nil and pcall(summary.kills.value.SetText, summary.kills.value, match.scoreKB)
	if not fromScoreboard then summary.kills.value:SetText(tostring(match.kills)) end
	summary.note:SetText(fromScoreboard and "Killing blows from the scoreboard."
		or "Killing blows counted by Spicy Kill Streaks: a best guess, as battlegrounds hide them.")
	summary.best.value:SetText(tostring(match.best))
	summary.status:SetText("")
	-- Battleground chat only while we are still in the match's group
	summary.groupChannel = core().groupChannel()
	summary.shareGroup:SetShown(summary.groupChannel ~= nil)
	summary.shareGroup:SetLabel(summary.groupChannel == "INSTANCE_CHAT" and "Share to battleground"
		or (summary.groupChannel == "RAID" and "Share to raid" or "Share to party"))
	summary.shareGroup:SetWidth(math.max(90, (summary.shareGroup.text:GetStringWidth() or 60) + 32))
	summary.shareGuild:SetShown(core().inGuild())
	layoutSummary(summary)
	summary:Show()
end

function ui.updateMinimap()
	if not mini then buildMinimap() end
	mini:SetShown(not db().global.minimap.hide)
	updateBadge()
end

-- Called by SpicyKillStreaks.lua once the saved settings are loaded
function ui.init()
	ui.updateMinimap()
	if ns.kudos and ns.kudos.init then pcall(ns.kudos.init) end
end
