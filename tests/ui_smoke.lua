-- Headless smoke test: a permissive fake WoW API, the real addon and Ace3 libraries, then the
-- settings window, every page, the setup, the minimap button and its menu.
-- Run from the repo root: lua5.1 tests/ui_smoke.lua SpicyKillStreaks
-- It catches mistakes in our own code (nil fields, typos, bad calls); it can't show how
-- anything looks, so test in game too.
local root = arg[1] or "SpicyKillStreaks"
local errors = {}
-- Any unknown method/field on a fake object is a function returning another fake object.
local function stub(name)
  local o = { __name = name, __scripts = {}, __shown = false, __w = 100, __h = 100 }
  return setmetatable(o, { __call = function() return nil end, __index = function(t, k)
    if k == "GetWidth" then return function(self) return self.__w end end
    if k == "GetHeight" then return function(self) return self.__h end end
    if k == "SetWidth" then return function(self, v) self.__w = v end end
    if k == "SetHeight" then return function(self, v) self.__h = v end end
    if k == "SetSize" then return function(self, w, h) self.__w, self.__h = w, h end end
    if k == "RegisterEvent" then return function(self, e) self.__events = self.__events or {}; self.__events[e] = true end end
    if k == "SetScript" then return function(self, n, f) self.__scripts[n] = f end end
    if k == "HookScript" then return function(self, n, f) self.__scripts[n] = f end end
    if k == "GetScript" then return function(self, n) return self.__scripts[n] end end
    if k == "Show" then return function(self) self.__shown = true; if self.__scripts.OnShow then self.__scripts.OnShow(self) end end end
    if k == "Hide" then return function(self) self.__shown = false end end
    if k == "IsShown" or k == "IsVisible" then return function(self) return self.__shown end end
    if k == "SetShown" then return function(self, v) self.__shown = v and true or false end end
    if k == "GetText" then return function(self) return self.__text or "" end end
    if k == "SetText" then return function(self, v) self.__text = v end end
    if k == "GetCenter" then return function() return 500, 400 end end
    if k == "GetEffectiveScale" or k == "GetScale" then return function() return 1 end end
    if k == "GetNumPoints" then return function() return 0 end end
    if k == "GetPoint" then return function() return "CENTER", nil, "CENTER", 0, 0 end end
    if k == "GetFrameLevel" then return function() return 1 end end
    if k == "GetStringWidth" or k == "GetStringHeight" then return function() return 10 end end
    if k == "IsMouseOver" then return function() return false end end
    if k == "GetFont" then return function() return "Fonts\\FRIZQT__.TTF", 12, "" end end
    if k == "GetObjectType" then return function() return "Frame" end end
    if k == "GetName" then return function(self) return self.__gname end end
    if k == "GetParent" then return function(self) return self.__parent or UIParent end end
    if k == "SetParent" then return function(self, p) self.__parent = p end end
    if k == "GetChildren" or k == "GetRegions" then return function() return end end
    if k == "GetVerticalScrollRange" or k == "GetVerticalScroll" then return function() return 0 end end
    if k == "GetValue" then return function(self) return self.__value or 0 end end
    if k == "SetValue" then return function(self, v) self.__value = v end end
    if k == "GetMinMaxValues" then return function() return 0, 1 end end
    if k == "GetChecked" then return function(self) return self.__checked end end
    if k == "SetChecked" then return function(self, v) self.__checked = v end end
    if k == "IsEnabled" then return function() return true end end
    if k == "GetFontString" or k == "GetNormalTexture" or k == "GetHighlightTexture" or k == "GetPushedTexture" or k == "GetDisabledTexture" or k == "GetCheckedTexture" or k == "GetThumbTexture" or k == "GetFontObject" or k == "GetScrollChild" then
      return function(self) self["__" .. k] = self["__" .. k] or stub(k); return self["__" .. k] end end
    if type(k) == "string" and k:match("^Create") then return function(self, ...) local c = stub(k); c.__parent = self; return c end end
    if type(k) == "string" and k:match("^%u") then return function() end end
    return nil
  end })
end
-- globals
setmetatable(_G, { __index = function(t, k)
  if type(k) == "string" and (k:match("^%u") or k:match("^C_")) and not k:match("^Lib") and not k:match("^Ace") and not k:match("^SpicyKillStreaks") then
    local v = stub(k); rawset(t, k, v); return v
  end
end })
UIParent = stub("UIParent"); Minimap = stub("Minimap"); WorldFrame = stub("WorldFrame")
GameTooltip = stub("GameTooltip")
ALLFRAMES = {}
function CreateFrame(kind, name, parent) local f = stub(kind); f.__gname = name; f.__parent = parent; if name then rawset(_G, name, f) end ALLFRAMES[#ALLFRAMES + 1] = f return f end
function CreateFont(n) local f = stub("Font"); rawset(_G, n, f); return f end
issecretvalue = nil
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
table.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
UISpecialFrames = {}; tinsert = table.insert; tremove = table.remove; wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
strsplit = function(sep, s, n) local out = {} for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end return unpack(out) end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
strlower, strupper, strsub, strmatch, strfind, strlen, strrep, format, gsub = string.lower, string.upper, string.sub, string.match, string.find, string.len, string.rep, string.format, string.gsub
floor, ceil, abs, min, max, sqrt = math.floor, math.ceil, math.abs, math.min, math.max, math.sqrt
atan2 = math.atan2
date = os.date; time = os.time
GetTime = function() return os.clock() end
GetLocale = function() return "enUS" end
GetBuildInfo = function() return "1.60.1", "12345", "", 16001 end
UnitName = function() return "Tester" end
RegionalUniqueNamesEnabled = function() return false end
UnitNameUnmodified = function() return "Tester" end
UnitFactionGroup = function() return "Horde", "Horde" end
GetRealmName = function() return "Realm" end
UnitRace = function() return "Orc", "Orc" end
UnitClass = function() return "Warrior", "WARRIOR" end
GetCurrentRegion = function() return 1 end
GetCurrentRegionName = function() return "US" end
UnitGUID = function() return "Player-1-0001" end
UnitLevel = function() return 60 end
UnitExists = function() return false end
IsInInstance = function() return false, "none" end
IsInGuild = function() return true end
GetGuildInfo = function() return "Spice Guild" end
IsShiftKeyDown = function() return false end
IsInGroup = function() return false end
IsInRaid = function() return false end
GetCursorPosition = function() return 600, 500 end
PlaySoundFile = function() return true end
PlaySound = function() return true end
SendChatMessage = function() end
Screenshot = function() end
hooksecurefunc = function() end
geterrorhandler = function() return function(e) errors[#errors + 1] = tostring(e) .. "\n" .. debug.traceback("", 2) end end
securecallfunction = function(f, ...) return f(...) end
-- WoW's xpcall passes extra arguments on (Lua 5.1's does not)
do
  local xp = xpcall
  xpcall = function(f, handler, ...)
    local args, n = { ... }, select("#", ...)
    return xp(function() return f(unpack(args, 1, n)) end, handler)
  end
end
C_Timer = { After = function() end, NewTicker = function() return stub("ticker") end }
C_ChatInfo = { RegisterAddonMessagePrefix = function() return true end, SendAddonMessage = function() return true end }
Settings = nil
SlashCmdList = {}
local printed = {}
print = function(...) local t = {} for i = 1, select("#", ...) do t[i] = tostring(select(i, ...)) end printed[#printed + 1] = table.concat(t, " ") end

-- load the .toc
local ns = {}
local function loadFile(path)
  path = path:gsub("\\", "/")
  local fh = io.open(root .. "/" .. path); if not fh then return end; fh:close()
  if path:match("%.xml$") then
    -- load the scripts an Ace xml includes
    local dir = path:match("^(.*)/")
    for line in io.lines(root .. "/" .. path) do
      local file = line:match('<Script file="([^"]+)"') or line:match('<Include file="([^"]+)"')
      if file then loadFile(dir .. "/" .. file) end
    end
    return
  end
  local chunk = assert(loadfile(root .. "/" .. path))
  chunk("SpicyKillStreaks", ns)
end
for line in io.lines(root .. "/SpicyKillStreaks.toc") do
  line = line:gsub("\r", "")
  if line ~= "" and not line:match("^#") then loadFile(line) end
end

local function fire(event, ...)
  for _, f in ipairs(ALLFRAMES) do
    if f.__events and f.__events[event] and f.__scripts.OnEvent then f.__scripts.OnEvent(f, event, ...) end
  end
end
local failed = false
local function step(name, fn)
  local ok, err = pcall(fn)
  io.write((ok and "ok   " or "FAIL ") .. name .. (ok and "" or (": " .. tostring(err))), "\n")
  if not ok then failed = true end
end
step("ADDON_LOADED", function() fire("ADDON_LOADED", "SpicyKillStreaks") end)
step("core exported", function() assert(ns.core and ns.core.db(), "no core/db") end)
step("minimap button made", function() assert(rawget(_G, "SpicyKillStreaksMinimapButton"), "no minimap button") end)
step("/sks opens the new window", function() SlashCmdList.SPICYKILLSTREAKS(""); assert(rawget(_G, "SpicyKillStreaksWindow").__shown, "window not shown") end)
for _, id in ipairs({ "announcer", "sound", "screen", "friends", "board", "extras", "soundboard", "about" }) do
  step("section " .. id, function() ns.ui.show(id) end)
end
step("unreal style section", function() ns.core.db().profile.style = "ut"; ns.ui.show("announcer") end)
step("flamboyant preview", function() ns.core.db().profile.soundpack = "flamboyant"; ns.ui.show("screen") end)
step("setup opens", function() SlashCmdList.SPICYKILLSTREAKS("setup"); assert(rawget(_G, "SpicyKillStreaksSetup").__shown) end)
for n = 1, 6 do step("setup step " .. n, function() ns.ui.setupStep(n) end) end
step("setup at sharing", function() ns.ui.openSetup(true) end)
local mini = rawget(_G, "SpicyKillStreaksMinimapButton")
step("minimap left click", function() mini.__scripts.OnClick(mini, "LeftButton") end)
step("minimap right click menu", function() mini.__scripts.OnClick(mini, "RightButton"); assert(rawget(_G, "SpicyKillStreaksMinimapMenu").__shown) end)
step("minimap tooltip", function() mini.__scripts.OnEnter(mini) end)
step("minimap drag", function() mini.__scripts.OnDragStart(mini); mini.__scripts.OnUpdate(mini) end)
step("snooze + badge", function() ns.core.special.snooze(30); ns.ui.updateMinimap(); assert(ns.core.special.snoozedUntil()) end)
step("menu with snooze", function() mini.__scripts.OnClick(mini, "RightButton"); mini.__scripts.OnClick(mini, "RightButton") end)
step("sound board plays", function() for _, e in ipairs(ns.core.special.soundBoard()) do if not e.section then ns.core.special.playForced(e[3]) end end end)
step("/sks minimap hides", function() SlashCmdList.SPICYKILLSTREAKS("minimap"); assert(ns.core.db().global.minimap.hide) end)
for _, e in ipairs(errors) do io.write("handler error: " .. e, "\n"); failed = true end
for _, l in ipairs(printed) do if l:find("failed") or l:find("Could not") then io.write("chat: ", l, "\n") end end
os.exit(failed and 1 or 0)
