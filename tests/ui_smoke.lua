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
UnitSex = function() return 2 end
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
  -- on by default now; switched off: nothing offered
  assert(ns.core.defaults.profile.kudos.give == true, "kudos should be on by default")
  P.kudos.give = false
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
  assert(#row.buttons == 9, "expected 9 emoji, got " .. #row.buttons)
  row.buttons[1].__scripts.OnClick(row.buttons[1])
  assert(#addon == 1 and addon[1] == "GUILD: R\t" .. core.VERSION .. "\t" .. bob .. "\tlaugh\tK\tH\tOrc\t2\tPlayer-1-0001", addon[1])
  assert(#said == 1 and said[1] == "GUILD: LOL! (to Bob for Rampage)", said[1])
  row.buttons[2].__scripts.OnClick(row.buttons[2])
  assert(#addon == 1, "a second reaction for the same kill")
  -- a friend's death: RIP and F
  fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "D", "1.0.1", "Orcbro", "0", "60", "60", "-", bob }, "\t"), "GUILD", "Bob-Realm")
  local drow = kudos.rows[#kudos.rows]
  assert(#drow.buttons == 9 and drow.label:GetText():find("killed by Orcbro"), drow.label:GetText())
  drow.buttons[7].__scripts.OnClick(drow.buttons[7])
  assert(addon[2]:find("\tskull\tD\t"), addon[2])
  assert(#said == 1, "chat cooldown ignored")
  -- getting kudos: only for something we just did, once per player, only when meant for us
  kudos.clear()
  local before = tonumber(P.kudos.got) or 0
  local function kudo(target, id, kind, from)
    fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "R", "1.0.1", target, id, kind, "A", "Dwarf", "3", from or bob }, "\t"), "GUILD", "Bob-Realm")
  end
  kudo("Player-1-0001", "hell", "K")
  assert(#kudos.rows == 0, "kudos accepted with no kill of ours")
  sp.ownEvent("K", "r2")
  kudo("Player-1-0009", "hell", "K")
  assert(#kudos.rows == 0, "kudos for someone else shown")
  kudo("Player-1-0001", "bogus", "K")
  assert(#kudos.rows == 0, "an unknown reaction shown")
  local played = {}
  local oldPSF = PlaySoundFile
  PlaySoundFile = function(f) played[#played + 1] = f return true end
  P.dosound, P.kudos.sound = true, true
  kudo("Player-1-0001", "faction", "K")
  PlaySoundFile = oldPSF
  assert(played[1] == 540014 or played[1] == 539977, "expected a female dwarf cheer, got " .. tostring(played[1]))
  assert(#played == 1, "kudos sounds should play once, got " .. #played)
  assert(#kudos.rows == 1 and kudos.rows[1].label:GetText():find("Bob|r  For the Alliance!.*your Killing Spree"), kudos.rows[1] and kudos.rows[1].label:GetText())
  kudo("Player-1-0001", "heart", "K")
  assert(#kudos.rows == 1, "two kudos from one player for one kill")
  -- an emoji kudos from another friend shows the image
  fire("CHAT_MSG_ADDON", PREFIX, table.concat({ "R", "1.3.0", "Player-1-0001", "party", "K", "H", "Orc", "2", "Player-1-0004" }, "\t"), "GUILD", "Dan-Realm")
  assert(#kudos.rows == 2 and kudos.rows[2].label:GetText():find("|TInterface\\AddOns\\SpicyKillStreaks\\Media\\Emoji\\party:0|t", 1, true), kudos.rows[2] and kudos.rows[2].label:GetText())
  assert(P.kudos.got == before + 2, "got not counted")
  -- preview, move, lock
  kudos.previewGot(); for _ = 1, 5 do runTimers() end; kudos.previewDeath(); kudos.clear()
  SlashCmdList.SPICYKILLSTREAKS("kudos got"); runTimers()
  kudos.preview(); kudos.unlock(true); assert(kudos.isUnlocked()); kudos.unlock(false); kudos.resetPosition()
  -- any card drags the stack
  kudos.clear()
  local grip = kudos.grip; assert(grip, "no move handle without cards")
  grip.__scripts.OnEnter(grip); grip.__scripts.OnDragStart(grip); grip.__scripts.OnDragStop(grip); grip.__scripts.OnLeave(grip)
  assert(P.kudos.lx and P.kudos.ly, "position not saved"); kudos.resetPosition(); kudos.clear()
  -- growing upwards: lay out, drag, and back
  kudos.setGrowUp(true); assert(P.kudos.growup)
  kudos.preview(); kudos.unlock(true)
  for _, f in ipairs(ALLFRAMES) do if f.__scripts.OnDragStop and f.__parent == rawget(_G, "SpicyKillStreaksKudos") then f.__scripts.OnDragStart(f); f.__scripts.OnDragStop(f) end end
  kudos.unlock(false); kudos.clear(); kudos.setGrowUp(false); assert(not P.kudos.growup)
  SlashCmdList.SPICYKILLSTREAKS("kudos"); SlashCmdList.SPICYKILLSTREAKS("kudos")
  kudos.clear()
  P.kudos.give, P.kudos.chat = false, false
end)
step("gank line at most once a minute, Headshot and Ownage in between", function()
  local played = {}
  local old = PlaySoundFile
  PlaySoundFile = function(f) played[#played + 1] = tostring(f) return true end
  local P = ns.core.db().profile
  P.dosound, P.soundpack = true, "male"
  ns.core.db().global.snoozeUntil = 0
  P.mutebg, P.mutedungeon, P.muteraid = false, false, false
  local sp = ns.core.special
  sp.lastGankLine = nil
  sp.playGank(); sp.playGank(); sp.playGank()
  PlaySoundFile = old
  assert(played[1]:find("gank%.ogg$"), played[1])
  assert(played[2]:find("headshot%.ogg$") and played[3]:find("ownage%.ogg$"), table.concat(played, " "))
end)
step("battleground probes write to the debug log", function()
  local sp = ns.core.special
  ns.core.debugLog.setEnabled(true)
  GetNumBattlefieldScores = function() return 2 end
  C_PvP.GetScoreInfo = function(i) return { name = i == 1 and "Tester" or "Other", killingBlows = 3, deaths = 1, honorableKills = 5, stats = { { pvpStatID = 1, name = "Flags", pvpStatValue = 0 } } } end
  sp.probeScore(); sp.probeHonor(); sp.probePartyKill("Player-1-0001", "Player-1-0002")
  fire("PARTY_KILL", nil, nil)
  fire("CHAT_MSG_COMBAT_HONOR_GAIN", "Someone dies, honorable kill")
  GetStatisticsCategoryList = function() return 1, 2 end
  GetCategoryNumAchievements = function(c) return c == 1 and 2 or 1 end
  GetAchievementInfo = function(c, i) if c == 1 and i == 1 then return 382, "Battleground killing blows" end return 100 + i, "Other stat" end
  GetStatistic = function(id) return "7" end
  sp.probeStats("test:"); sp.probeLookup("Player-1-0001")
  SlashCmdList.SPICYKILLSTREAKS("stats")
  SlashCmdList.SPICYKILLSTREAKS("note mine")
  local text = ns.core.debugLog.text()
  assert(text:find("probe: our score row:.*honorableKills=5"), "no score row probe")
  assert(text:find("NOTE: mine"), "no note")
  assert(text:find("probe: stats test: Battleground killing blows %(382%)=7"), "no stats probe")
  assert(text:find("table lookup of the hidden attacker: us"), "no lookup probe")
  ns.core.debugLog.setEnabled(false)
end)
step("battleground best guess: our enemy target disappears with the hidden killing blow", function()
  local sp = ns.core.special
  local clock = 1000
  local saved = { GetTime, IsInInstance, UnitExists, UnitIsPlayer, UnitCanAttack, GetUnitName, UnitIsDeadOrGhost }
  local playerDead, hasTarget, targetName = false, true, "Victim"
  GetTime = function() return clock end
  IsInInstance = function() return true, "pvp" end
  UnitAffectingCombat = function() return true end
  UnitExists = function(u) return u == "target" and hasTarget end
  UnitIsPlayer = function(u) return u == "target" end
  UnitCanAttack = function() return true end
  GetUnitName = function(u) if u == "target" then return hasTarget and targetName or nil end return "Tester" end
  UnitIsDeadOrGhost = function(u) if u == "target" then return false end return playerDead end
  ns.core.db().profile.dobgguess = true
  fire("PLAYER_ENTERING_WORLD", false, false)
  runTimers()
  local function target(name) hasTarget, targetName = name ~= nil, name; fire("PLAYER_TARGET_CHANGED") end
  local function kb() fire("PARTY_KILL", nil, nil) end
  -- killing blow, then the client clears our dead target: ours, and named
  target("Victim"); clock = clock + 0.5; kb(); clock = clock + 0.1; target(nil)
  assert(sp.hiddenCount == 1, "expected 1, got " .. tostring(sp.hiddenCount))
  -- target cleared first, killing blow just after: ours
  clock = clock + 10; target("Second"); clock = clock + 0.5; target(nil); clock = clock + 0.2; kb()
  assert(sp.hiddenCount == 2, "expected 2, got " .. tostring(sp.hiddenCount))
  -- a party member's kill while our target lives on: not ours
  clock = clock + 10; target("Third"); clock = clock + 0.5; kb(); clock = clock + 1; runTimers()
  assert(sp.hiddenCount == 2, "counted with our target still alive")
  -- our target cleared well after the killing blow: not ours
  clock = clock + 10; target("Fourth"); clock = clock + 0.5; kb(); runTimers(); clock = clock + 2; target(nil)
  assert(sp.hiddenCount == 2, "counted a late target clear")
  -- switching to another enemy at the moment of a kill: not ours
  clock = clock + 10; target("Fifth"); clock = clock + 0.5; kb(); target("Sixth"); runTimers()
  assert(sp.hiddenCount == 2, "counted a target switch")
  -- dead or out of combat: nothing
  playerDead = true
  clock = clock + 10; target("Seventh"); clock = clock + 0.5; kb(); target(nil)
  playerDead = false
  UnitAffectingCombat = function() return false end
  clock = clock + 10; target("Eighth"); clock = clock + 0.5; kb(); target(nil)
  assert(sp.hiddenCount == 2, "counted while dead or out of combat")
  GetTime, IsInInstance, UnitExists, UnitIsPlayer, UnitCanAttack, GetUnitName, UnitIsDeadOrGhost = unpack(saved)
  UnitAffectingCombat = function() return false end
  fire("PLAYER_ENTERING_WORLD", false, false)
  runTimers()
end)
step("messages refused by the lockdown are held and sent after combat", function()
  local sp = ns.core.special
  local result, sent = 11, {}
  local old = C_ChatInfo.SendAddonMessage
  C_ChatInfo.SendAddonMessage = function(_, msg, channel) sent[#sent + 1] = channel return result end
  sp.held = {}
  sp.holdMessage("D\ttest", "GUILD")
  assert(#sp.held == 1, "not held")
  sp.sendHeld()
  assert(#sp.held == 1, "dropped while still locked down")
  result = 0
  fire("PLAYER_REGEN_ENABLED"); runTimers()
  assert(#sp.held == 0, "not sent after combat")
  C_ChatInfo.SendAddonMessage = old
  sp.retryScheduled = false
end)
step("an unnamed victim is never a Retribution", function()
  local sp = ns.core.special
  ns.core.db().char.recentKillers = ns.core.db().char.recentKillers or {}
  ns.core.db().char.recentKillers["an"] = time()
  assert(sp.takeRetribution("an enemy") == false, "\"an enemy\" matched a killer named An")
  ns.core.db().char.recentKillers["an"] = nil
end)
step("battlegrounds: nothing is sent", function()
  local core = ns.core
  local sent = {}
  local old, oldInst = C_ChatInfo.SendAddonMessage, IsInInstance
  C_ChatInfo.SendAddonMessage = function(_, msg, channel) sent[#sent + 1] = channel return 0 end
  IsInInstance = function() return true, "pvp" end
  fire("PLAYER_ENTERING_WORLD", false, false); runTimers()
  assert(core.sendAddonMessage("D\ttest", "GUILD") == false and #sent == 0, "sent from a battleground")
  IsInInstance = function() return false, "none" end
  fire("PLAYER_ENTERING_WORLD", false, false); runTimers()
  sent = {}
  assert(core.sendAddonMessage("D\ttest", "GUILD") and #sent == 1, "not sent outside")
  C_ChatInfo.SendAddonMessage, IsInInstance = old, oldInst
end)
step("friends' sounds play the quiet copies, ours the normal ones", function()
  local P = ns.core.db().profile
  local played = {}
  local old = PlaySoundFile
  PlaySoundFile = function(f) played[#played + 1] = tostring(f) return true end
  P.dosound, P.soundpack, P.sync.shareguild, P.sync.guild.sound = true, "female", true, true
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "K", "1.2.0", "Alice", "3", "0", "2", "60", "60", "-", "Player-1-0003" }, "\t"), "GUILD", "Carl-Realm")
  assert(played[1] and played[1]:find("sounds\\quiet\\female\\killingspree%.ogg$"), "friend: " .. tostring(played[1]))
  played = {}
  ns.core.playSound("killingspree.ogg")
  assert(played[1]:find("sounds\\female\\killingspree%.ogg$"), "own: " .. tostring(played[1]))
  assert(not ns.core.special.quiet, "quiet left on")
  PlaySoundFile = old
  P.soundpack, P.sync.guild.sound = "male", false
end)
step("match summary at the end of a battleground, shared only on a click", function()
  local sp = ns.core.special
  local said = {}
  local oldInst = IsInInstance
  SendChatMessage = function(msg, channel) said[#said + 1] = channel .. ": " .. msg end
  GetRealZoneText = function() return "Warsong Gulch" end
  ns.core.db().profile.dobgsummary = true -- (the click-everything test above flips it)
  local old = rawget(_G, "SpicyKillStreaksMatchSummary"); if old then old:Hide() end
  IsInInstance = function() return true, "pvp" end
  fire("PLAYER_ENTERING_WORLD", false, false); runTimers()
  assert(sp.match and sp.match.zone == "Warsong Gulch", "no match started")
  sp.matchNote(3); sp.matchNote(5); sp.matchNote(1)
  ns.core.db().profile.doflagcap = true
  fire("CHAT_MSG_BG_SYSTEM_HORDE", "Bob captured the Alliance flag!")
  assert((sp.match.caps or 0) == 0, "someone else's capture counted")
  fire("CHAT_MSG_BG_SYSTEM_HORDE", "Tester captured the Alliance flag!")
  assert(sp.match.caps == 1, "our capture not counted")
  -- the scoreboard's killing blows win over the addon's count
  GetNumBattlefieldScores = function() return 1 end
  C_PvP.GetScoreInfo = function() return { name = "Tester", killingBlows = 4 } end
  fire("PVP_MATCH_COMPLETE"); runTimers()
  local card = rawget(_G, "SpicyKillStreaksMatchSummary")
  assert(card and card.__shown, "no summary card")
  assert(#said == 0, "posted without a click")
  card.shareGuild.__scripts.OnClick(card.shareGuild)
  assert(said[1] == "GUILD: {skull} Warsong Gulch: 4 killing blows, best kill streak 5, 1 flag capture", tostring(said[1]))
  card:Hide()
  IsInInstance = function() return false, "none" end
  fire("PLAYER_ENTERING_WORLD", false, false); runTimers()
  assert(not card.__shown and not sp.match, "shown twice or not ended")
  SlashCmdList.SPICYKILLSTREAKS("summary")
  assert(card.__shown, "no sample card"); card:Hide()
  IsInInstance = oldInst
end)
step("request aid: offer on a player kill, send, a friend's request, on my way, avenged", function()
  local core, aid, kudos = ns.core, ns.aid, ns.kudos
  local P = core.db().profile
  local addon, said = {}, {}
  local oldSend = C_ChatInfo.SendAddonMessage
  C_ChatInfo.SendAddonMessage = function(_, msg, channel) addon[#addon + 1] = channel .. ": " .. msg return true end
  SendChatMessage = function(msg, channel) said[#said + 1] = channel .. ": " .. msg end
  GetRealZoneText = function() return "Ashenvale" end
  GetSubZoneText = function() return "Splintertree Post" end
  P.aid.enabled, P.aid.receive, P.aid.location, P.aid.chat, P.aid.sound = true, true, false, true, true
  P.sync.shareguild, P.sync.shareparty = true, true
  kudos.clear()
  -- our "Need help!" card, and the request it sends (zone only: location is off)
  local row = aid.offer({ killer = "Orcbro", level = 62 })
  assert(row and row.button, "no Need help card")
  row.button.__scripts.OnClick(row.button)
  assert(#addon == 1 and addon[1]:find("^GUILD: A\t" .. core.VERSION .. "\tOrcbro\t62\tAshenvale\tSplintertree Post\t%-\t%-\t%-\tPlayer%-1%-0001$"), addon[1])
  assert(#said == 1 and said[1]:find("Need help in Ashenvale %- Splintertree Post! Killed by Orcbro %(62%)"), said[1])
  -- a second request within the minute is refused
  local row2 = aid.offer({ killer = "Orcbro", level = 62 }); row2.button.__scripts.OnClick(row2.button)
  assert(#addon == 1, "asked twice within the cooldown")
  -- a friend's request, with a position: card, waypoint, on my way
  kudos.clear()
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "A", "1.5.0", "Gankster", "60", "Barrens", "Crossroads", "1413", "0.5", "0.3", "Player-1-0005" }, "\t"), "GUILD", "Panda-Realm")
  assert(#kudos.rows == 1 and kudos.rows[1].label:GetText():find("Panda.*needs help"), kudos.rows[1] and kudos.rows[1].label:GetText())
  local req = kudos.rows[1]
  assert(req.sub:GetText():find("Barrens %- Crossroads %(50, 30%)"), req.sub:GetText())
  req.onMyWay.__scripts.OnClick(req.onMyWay)
  assert(addon[#addon] == "GUILD: W\t" .. core.VERSION .. "\tPlayer-1-0005\tPlayer-1-0001", addon[#addon])
  -- the same friend again within a minute: ignored
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "A", "1.5.0", "Gankster", "60", "Barrens", "", "-", "-", "-", "Player-1-0005" }, "\t"), "GUILD", "Panda-Realm")
  assert(#kudos.rows == 1, "a repeated request shown")
  -- bad coordinates are dropped
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "A", "1.5.0", "Other", "60", "Barrens", "", "99", "5", "-1", "Player-1-0006" }, "\t"), "GUILD", "Carl-Realm")
  assert(#kudos.rows == 2 and not kudos.rows[2].sub:GetText():find("%(%d+, %d+%)"), kudos.rows[2].sub:GetText())
  -- an answer to our request
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "W", "1.5.0", "Player-1-0001", "Player-1-0007" }, "\t"), "GUILD", "Dan-Realm")
  assert(kudos.rows[#kudos.rows].label:GetText():find("Dan.*on the way"), kudos.rows[#kudos.rows].label:GetText())
  -- we kill Gankster: avenged Panda
  assert(aid.requests["gankster"], "request not remembered")
  local oldInfo = GetPlayerInfoByGUID
  GetPlayerInfoByGUID = function() return nil, nil, nil, nil, nil, "Gankster" end
  P.doretribution = true
  fire("PARTY_KILL", "Player-1-0001", "Player-1-0099")
  GetPlayerInfoByGUID = oldInfo
  assert(not aid.requests["gankster"], "avenge not taken")
  assert(addon[#addon] == "GUILD: X\t" .. core.VERSION .. "\tPlayer-1-0005\tGankster\tPlayer-1-0001", addon[#addon])
  -- a friend tells us they avenged us, and their kill also arrives in the feed: shown once
  kudos.clear()
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "X", "1.6.0", "Player-1-0001", "Brute", "Player-1-0008" }, "\t"), "GUILD", "Eve-Realm")
  assert(#kudos.rows == 1 and kudos.rows[1].label:GetText():find("Eve.*avenged you"), kudos.rows[1] and kudos.rows[1].label:GetText())
  core.db().char.recentKillers = core.db().char.recentKillers or {}
  core.db().char.recentKillers["brute"] = time()
  aid.allyKill({ kind = "K", who = "Eve", other = "Brute" })
  assert(#kudos.rows == 1, "avenged shown twice")
  -- a friend kills who killed us: they avenged us
  core.db().char.recentKillers = core.db().char.recentKillers or {}
  core.db().char.recentKillers["orcbro"] = time()
  aid.allyKill({ kind = "K", who = "Bob", other = "Orcbro" })
  aid.previewOffer(); aid.previewRequest(); SlashCmdList.SPICYKILLSTREAKS("aid")
  kudos.clear()
  runTimers(); runTimers() -- (the kill's own broadcast, still queued)
  C_ChatInfo.SendAddonMessage = oldSend
  P.aid.chat = false
end)
step("guild board sync: merge the highest, reply with only what's higher", function()
  local core, sp = ns.core, ns.core.special
  local P = core.db().profile
  P.sync.shareguild = true
  core.db().global.boards = nil
  sp.boardSeen = {}
  sp.boardReplyPending = false
  local sent = {}
  local old = C_ChatInfo.SendAddonMessage
  C_ChatInfo.SendAddonMessage = function(_, msg, channel) sent[#sent + 1] = channel .. ": " .. msg return true end
  sp.boardNote("Panda", 12, 40, 3); sp.boardNote("Bob", 9, 15, 14)
  local head = table.concat({ "B", "1.5.0", sp.monthKey(), "Spice Guild" }, "\t")
  fire("CHAT_MSG_ADDON", "SpicyKS", head .. "\tL\tZed:7:20:2;Panda:15:41:3;Tester:99:99:99", "GUILD", "Carl-Realm")
  local players = sp.board().players
  assert(players.Zed and players.Zed.best == 7, "new player not merged")
  assert(players.Panda.best == 15 and players.Panda.kills == 41, "higher values not taken")
  assert(not players.Tester or players.Tester.best ~= 99, "an entry naming us was taken")
  -- a lower value never lowers ours
  fire("CHAT_MSG_ADDON", "SpicyKS", head .. "\tR\tPanda:3:1:0", "GUILD", "Dan-Realm")
  assert(players.Panda.best == 15, "a lower value lowered the board")
  -- our reply: only Bob (nobody sent him); Panda and Zed were already seen at least as high
  runTimers(); runTimers()
  assert(#sent == 1 and sent[1]:find("\tR\tBob:9:15:14$"), tostring(sent[1]))
  -- wrong guild or month: ignored
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "B", "1.5.0", sp.monthKey(), "Other Guild", "R", "Evil:500:1:1" }, "\t"), "GUILD", "Eve-Realm")
  fire("CHAT_MSG_ADDON", "SpicyKS", table.concat({ "B", "1.5.0", "1999-01", "Spice Guild", "R", "Evil:500:1:1" }, "\t"), "GUILD", "Eve-Realm")
  assert(not players.Evil, "a board from another guild or month merged")
  -- at login: our whole board goes out as an "L"
  sent = {}
  sp.boardLoginSync(); runTimers(); runTimers()
  local all = table.concat(sent, "\n")
  assert(all:find("\tL\t") and all:find("Panda:15:41:3") and all:find("Bob:9:15:14") and all:find("Zed:7:20:2"), all)
  assert(not all:find("Tester:"), "our own entry sent in a board")
  C_ChatInfo.SendAddonMessage = old
end)
step("secrets: 15 is the male voice only; five ganks in five minutes play the secret line", function()
  local sp, P = ns.core.special, ns.core.db().profile
  P.soundpack = "male"; assert(sp.secretFor(15) == "secret15.ogg" and sp.secretFor(25) and sp.secretFor(30) and sp.secretFor(40))
  P.soundpack = "female"; assert(sp.secretFor(15) == nil and sp.secretFor(30) == "secret30.ogg", "15 for another pack")
  P.soundpack = "male"
  local played = {}
  local old = PlaySoundFile
  PlaySoundFile = function(f) played[#played + 1] = tostring(f) return true end
  P.dosound = true; ns.core.db().global.snoozeUntil = 0
  sp.gankRun, sp.lastGankLine = {}, nil
  for _ = 1, 5 do sp.registerGank("Lowbie") end
  PlaySoundFile = old
  assert(played[#played]:find("secret30%.ogg$"), "the fifth gank: " .. tostring(played[#played]))
  assert(not played[1]:find("secret30"), "the first gank played the secret")
end)
step("debug log window", function() ns.core.debugLog.setEnabled(true); ns.core.debugLog.add("hello"); ns.core.debugLog.setEnabled(false) end)
step("/sks minimap hides", function() ns.core.db().global.minimap.hide = false; SlashCmdList.SPICYKILLSTREAKS("minimap"); assert(ns.core.db().global.minimap.hide) end)
for _, e in ipairs(errors) do io.write("handler error: " .. e, "\n"); failed = true end
for _, l in ipairs(printed) do if l:find("failed") or l:find("Could not") then io.write("chat: ", l, "\n") end end
os.exit(failed and 1 or 0)
