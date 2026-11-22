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
    if k == "GetStringWidth" or k == "GetStringHeight" or k == "GetTextWidth" then return function() return 10 end end
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
string.split = function(sep, s) return strsplit(sep, s) end
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
-- Timers queue up; runTimers() runs the ones waiting (new ones wait for the next call)
local timerQueue = {}
C_Timer = { After = function(_, fn) timerQueue[#timerQueue + 1] = fn end, NewTicker = function() return stub("ticker") end }
local function runTimers()
  local due = timerQueue
  timerQueue = {}
  for _, fn in ipairs(due) do fn() end
end
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
-- a player who set up an older version (before 1.0.0)
SpicyKillStreaksDB = { global = { setupDone = true, sharingShown = true } }
step("ADDON_LOADED", function() fire("ADDON_LOADED", "SpicyKillStreaks") end)
step("older setup: the 1.0.0 setup opens once at login", function()
  fire("PLAYER_ENTERING_WORLD", true, false)
  runTimers()
  local setup = rawget(_G, "SpicyKillStreaksSetup")
  assert(setup and setup.__shown, "setup not shown")
  ns.core.finishSetup(true)
  setup:Hide()
  assert(ns.core.db().global.setup1Done, "setup1Done not saved")
end)
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
-- (The classic AceConfig window needs WoW's own templates, which the fake API lacks; it is
-- unchanged library code, so these buttons are left out here.)
ns.core.openClassic = function() end
ns.core.openStats = function() end
-- Click every control on every page: switches, dropdowns (and the rows of their lists), sliders,
-- text boxes and buttons
for _, id in ipairs({ "announcer", "sound", "screen", "friends", "board", "extras", "soundboard", "about" }) do
  step("every control on " .. id, function()
    ns.ui.open()
    local before = #ALLFRAMES
    ns.ui.show(id, true)
    local made = {}
    for i = before + 1, #ALLFRAMES do made[#made + 1] = ALLFRAMES[i] end
    for _, f in ipairs(made) do
      local sc = f.__scripts
      if sc.OnClick then
        sc.OnClick(f, "LeftButton")
        -- a dropdown's list: pick its first row
        local list = rawget(_G, "SpicyKillStreaksDropdown")
        if list and list.__shown then
          for _, row in ipairs(list.rows) do if row.__scripts.OnClick then row.__scripts.OnClick(row) break end end
        end
      end
      if sc.OnValueChanged then sc.OnValueChanged(f, 1) end
      if sc.OnEnterPressed then sc.OnEnterPressed(f) end
      if sc.OnMouseWheel then sc.OnMouseWheel(f, -1) end
    end
    ns.ui.open()
  end)
end
step("resize handle lays the page out again", function()
  local win = rawget(_G, "SpicyKillStreaksWindow")
  local grip
  for _, f in ipairs(ALLFRAMES) do if f.__parent == win and f.__scripts.OnMouseUp then grip = f end end
  assert(grip, "no resize handle")
  grip.__scripts.OnMouseDown(grip); grip.__scripts.OnMouseUp(grip)
end)
step("guild board post: one line, top killers then most deaths", function()
  local sp = ns.core.special
  sp.readStats("Panda", { "V!", "1.0.0", sp.monthKey(), "12", "40", "Spice Guild", "3" }, false)
  sp.readStats("Bob", { "V!", "1.0.0", sp.monthKey(), "9", "15", "Spice Guild", "14" }, false)
  sp.noteMyKill(1); sp.noteMyDeath()
  local sent = {}
  SendChatMessage = function(msg, channel) sent[#sent + 1] = channel .. ": " .. msg end
  sp.shareBoard("GUILD")
  runTimers()
  assert(#sent == 1, "expected one message, got " .. #sent)
  assert(sent[1]:find("^GUILD: {skull} Top kill streaks of %a+: 1%. Panda %(12%), 2%. Bob %(9%)"), sent[1])
  assert(sent[1]:find("{cross} Most deaths: Bob %(14%), Panda %(3%)"), sent[1])
  assert(#sent[1] <= 255 + #"GUILD: ")
end)
step("guild board page with deaths", function() ns.ui.open(); ns.ui.show("board") end)
step("kudos: offer, send, chat post, receive", function()
  local core, kudos, sp = ns.core, ns.kudos, ns.core.special
  local P = core.db().profile
  local PREFIX = "SpicyKS"
  local addon, said = {}, {}
  C_ChatInfo.SendAddonMessage = function(_, msg, channel) addon[#addon + 1] = channel .. ": " .. msg return true end
  SendChatMessage = function(msg, channel) said[#said + 1] = channel .. ": " .. msg end
  kudos.clear()
  -- off by default: nothing offered
  local bob = "Player-1-0002"
  local kill = table.concat({ "K", "1.0.1", "Alice", "3", "0", "2", "60", "60", "-", bob }, "\t")
  fire("CHAT_MSG_ADDON", PREFIX, kill, "GUILD", "Bob-Realm")
  assert(#kudos.rows == 0, "offered while off")
  P.kudos.give, P.kudos.chat, P.kudos.receive = true, true, true
  P.sync.shareguild, P.sync.shareparty = true, true -- (the click-everything test above flips them)
  fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "K", "1.0.1", "Carl", "4", "0", "3", "60", "60", "-", bob }, "\t"), "GUILD", "Bob-Realm")
  assert(#kudos.rows == 1, "no kudos row for a friend's kill")
  local row = kudos.rows[1]
  assert(row.label:GetText():find("Rampage"), row.label:GetText())
  assert(#row.buttons == 4, "expected 4 kill reactions, got " .. #row.buttons)
  row.buttons[1].__scripts.OnClick(row.buttons[1])
  assert(#addon == 1 and addon[1] == "GUILD: R\t" .. core.VERSION .. "\t" .. bob .. "\tzug\tK\tH\tPlayer-1-0001", addon[1])
  assert(#said == 1 and said[1] == "GUILD: Zug zug! (to Bob for Rampage)", said[1])
  row.buttons[2].__scripts.OnClick(row.buttons[2])
  assert(#addon == 1, "a second reaction for the same kill")
  -- a friend's death: RIP and F
  fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "D", "1.0.1", "Orcbro", "0", "60", "60", "-", bob }, "\t"), "GUILD", "Bob-Realm")
  local drow = kudos.rows[#kudos.rows]
  assert(#drow.buttons == 2 and drow.label:GetText():find("killed by Orcbro"), drow.label:GetText())
  drow.buttons[2].__scripts.OnClick(drow.buttons[2])
  assert(addon[2]:find("\tf\tD\t"), addon[2])
  assert(#said == 1, "chat cooldown ignored")
  -- getting kudos: only for something we just did, once per player, only when meant for us
  kudos.clear()
  local before = tonumber(P.kudos.got) or 0
  local function kudo(target, id, kind, from)
    fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "R", "1.0.1", target, id, kind, "A", from or bob }, "\t"), "GUILD", "Bob-Realm")
  end
  kudo("Player-1-0001", "hell", "K")
  assert(#kudos.rows == 0, "kudos accepted with no kill of ours")
  sp.ownEvent("K", "r2")
  kudo("Player-1-0009", "hell", "K")
  assert(#kudos.rows == 0, "kudos for someone else shown")
  kudo("Player-1-0001", "rip", "K")
  assert(#kudos.rows == 0, "a death reaction for a kill shown")
  kudo("Player-1-0001", "faction", "K")
  assert(#kudos.rows == 1 and kudos.rows[1].label:GetText():find("^|cffffd100Bob|r: For the Alliance!.*your Killing Spree"), kudos.rows[1] and kudos.rows[1].label:GetText())
  kudo("Player-1-0001", "hell", "K")
  assert(#kudos.rows == 1, "two kudos from one player for one kill")
  assert(P.kudos.got == before + 1, "got not counted")
  -- preview, move, lock
  kudos.preview(); kudos.unlock(true); assert(kudos.isUnlocked()); kudos.unlock(false); kudos.resetPosition()
  SlashCmdList.SPICYKILLSTREAKS("kudos"); SlashCmdList.SPICYKILLSTREAKS("kudos")
  kudos.clear()
  P.kudos.give, P.kudos.chat = false, false
end)
step("debug log window", function() ns.core.debugLog.setEnabled(true); ns.core.debugLog.add("hello"); ns.core.debugLog.setEnabled(false) end)
step("/sks minimap hides", function() ns.core.db().global.minimap.hide = false; SlashCmdList.SPICYKILLSTREAKS("minimap"); assert(ns.core.db().global.minimap.hide) end)
for _, e in ipairs(errors) do io.write("handler error: " .. e, "\n"); failed = true end
for _, l in ipairs(printed) do if l:find("failed") or l:find("Could not") then io.write("chat: ", l, "\n") end end
os.exit(failed and 1 or 0)
