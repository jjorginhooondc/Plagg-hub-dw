local ITEM_OPTIONS = {
    "Research Capsule", "Tapes", "Gumballs", "Chocolate", "Stopwatch",
    "Stamina Candy", "Stealth Candy", "Pop", "Speed Candy", "Protein Bar",
    "Instructions", "Extraction Speed Candy", "Skill Check Candy", "Jumper Cable",
    "Bandage", "Air Horn", "Jawbreaker", "Bonbon", "Christmas Cookie",
    "Dandy Easter Egg", "Dandy Corn", "Bottle o' Pop", "Health Kit",
    "Box o' Chocolates", "Eject Button", "Smoke Bomb", "Valve",
    "Ornament", "Basket", "Pumpkin", "Fake Capsule"
}

local ITEM_LOOKUP = {
    ["Research Capsule"] = "ResearchCapsule",
    ["Tapes"] = "Tapes",
    ["Gumballs"] = "Gumballs",
    ["Chocolate"] = "Chocolate",
    ["Stopwatch"] = "Stopwatch",
    ["Stamina Candy"] = "StaminaCandy",
    ["Stealth Candy"] = "StealthCandy",
    ["Pop"] = "Pop",
    ["Speed Candy"] = "SpeedCandy",
    ["Protein Bar"] = "ProteinBar",
    ["Instructions"] = "Instructions",
    ["Extraction Speed Candy"] = "ExtractionSpeedCandy",
    ["Skill Check Candy"] = "SkillCheckCandy",
    ["Jumper Cable"] = "JumperCable",
    ["Bandage"] = "Bandage",
    ["Air Horn"] = "AirHorn",
    ["Jawbreaker"] = "Jawbreaker",
    ["Bonbon"] = "BonBon",
    ["Christmas Cookie"] = "ChristmasCookie",
    ["Dandy Easter Egg"] = "DandyEasterEgg",
    ["Dandy Corn"] = "DandCorn",
    ["Bottle o' Pop"] = "BottleOPop",
    ["Health Kit"] = "HealthKit",
    ["Box o' Chocolates"] = "BoxOChocolates",
    ["Eject Button"] = "EjectButton",
    ["Smoke Bomb"] = "SmokeBomb",
    ["Valve"] = "Valve",
    ["Ornament"] = "Ornament",
    ["Basket"] = "Basket",
    ["Pumpkin"] = "Pumpkin",
    ["Fake Capsule"] = "FakeCapsule"
}

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RUN = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lt = game:GetService("Lighting")
local SG = game:GetService("StarterGui")
local SS = game:GetService("SoundService")

if not game:IsLoaded() then game.Loaded:Wait() end
local me = P.LocalPlayer
local pg = me:WaitForChild("PlayerGui")

-- ===== controle de execuções =====
local genv = (getgenv and getgenv()) or {}

-- fecha o Plagg Hub antigo, se estiver aberto
genv.PlaggGen = (genv.PlaggGen or 0) + 1
if genv.PlaggConns then
    for _, c in ipairs(genv.PlaggConns) do pcall(function() c:Disconnect() end) end
end
for _, k in ipairs({"PlaggDandyBtn", "PlaggTopGenBtn", "PlaggAboveBtn", "PlaggOpenBtn", "PlaggMainGui",
    "PlaggNotifyGui", "PlaggClickSound", "PlaggFluent", "PlaggWin", "PlaggTool"}) do
    pcall(function() if genv[k] then genv[k]:Destroy() end end)
end
pcall(function() RUN:UnbindFromRenderStep("PlaggDandyWorld") end)

-- fecha uma execução anterior deste script
genv.TishaGen = (genv.TishaGen or 0) + 1
local GEN = genv.TishaGen
if genv.TishaConns then
    for _, c in ipairs(genv.TishaConns) do pcall(function() c:Disconnect() end) end
end
local conns = {}
genv.TishaConns = conns
for _, k in ipairs({"TishaTpBtn", "TishaTopBtn", "TishaOpenBtn", "TishaMainGui", "TishaNotifyGui",
    "TishaClickSound", "TishaTool"}) do
    pcall(function() if genv[k] then genv[k]:Destroy() end end)
end
pcall(function() RUN:UnbindFromRenderStep("TishaWorld") end)

local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local notifyImpl
local function notify(txt)
    if notifyImpl then pcall(notifyImpl, txt) end
end

-- ===== memória e diagnóstico =====
local memStart = collectgarbage("count") / 1024

local function memText()
    local lua = collectgarbage("count") / 1024
    local ok, tot = pcall(function() return game:GetService("Stats"):GetTotalMemoryUsageMb() end)
    local s = string.format("memory: Lua %.0f MB (%+.0f since load)", lua, lua - memStart)
    if ok and type(tot) == "number" then
        s = s .. string.format(" | game %.0f MB", tot)
    end
    return s
end

local prof = {}
local worstFrame = 0
local hitches = 0
local recentSlow = nil
local lastFreezeNote = 0

local function track(name, dt)
    local p = prof[name]
    if not p then
        p = {t = 0, n = 0, max = 0}
        prof[name] = p
    end
    p.t = p.t + dt
    p.n = p.n + 1
    if dt > p.max then p.max = dt end
end

local function noteSlow(name, dur)
    local now = tick()
    if not recentSlow or now - recentSlow.t > 3 or dur > recentSlow.dur then
        recentSlow = {name = name, dur = dur, t = now}
    end
end

local function onHitch(dt)
    hitches = hitches + 1
    local now = tick()
    if dt > 1 and now - lastFreezeNote > 15 then
        lastFreezeNote = now
        local s = recentSlow
        local head
        if s and now - s.t < 5 then
            head = string.format("Freeze %.1fs. Slowest recent module: %s (%.0fms)", dt, s.name, s.dur * 1000)
        else
            head = string.format("Freeze %.1fs. No script module was slow - likely the game or the device.", dt)
        end
        notify(head .. "\n" .. memText())
    end
end

-- ===== loops supervisionados =====
local loops = {}

local function pause(L, s)
    local t = os.clock()
    task.wait(s)
    if L then
        L.idle = L.idle + (os.clock() - t)
        L.beat = tick()
    end
end

local function breath(L, i, every)
    if L and i % every == 0 then pause(L, 0) end
end

local function spawnLoop(L)
    L.token = L.token + 1
    local my = L.token
    L.beat = tick()
    task.spawn(function()
        local last
        while GEN == genv.TishaGen and L.token == my do
            local t0 = os.clock()
            L.beat = tick()
            L.idle = 0
            local ok, err = pcall(L.fn, L)
            local dur = math.max(0, os.clock() - t0 - L.idle)
            track(L.name, dur)
            if dur > 0.03 then noteSlow(L.name, dur) end
            if not ok and tostring(err) ~= last then
                last = tostring(err)
                warn("[Tisha]", L.name, err)
            end
            L.beat = tick()
            task.wait(math.max(L.delay, dur * 6))
        end
    end)
end

local function loop(delay, fn, name)
    local L = {
        delay = delay, fn = fn, name = name or ("loop" .. (#loops + 1)),
        idle = 0, beat = tick(), token = 0
    }
    loops[#loops + 1] = L
    spawnLoop(L)
    return L
end

local alive = {hb = tick(), rs = tick(), th = tick()}
local lastRevive = 0
local connectHB, connectRS, startWatch

local function revive(now)
    if GEN ~= genv.TishaGen then return end
    if now - alive.hb > 3 and connectHB then connectHB() end
    if now - alive.rs > 3 and connectRS then connectRS() end
    if now - alive.th > 5 and startWatch then startWatch() end
    for _, L in ipairs(loops) do
        if now - L.beat > math.max(10, L.delay * 3 + 5) then spawnLoop(L) end
    end
end

local BLACK, WHITE = Color3.new(0, 0, 0), Color3.new(1, 1, 1)
local PURPLE, MAGENTA, GRAY = Color3.fromRGB(170, 70, 255), Color3.fromRGB(230, 50, 220), Color3.fromRGB(150, 150, 165)
local ORANGE, RED, GREEN = Color3.fromRGB(255, 140, 0), Color3.fromRGB(255, 40, 40), Color3.fromRGB(60, 255, 120)
local YELLOW = Color3.fromRGB(255, 230, 0)
local ZERO = Vector3.new(0, 0, 0)
local TAG_UP = Vector3.new(0, 2.5, 0)

local S = {
    esItem = false, esTw = false, esGen = false, esPl = false, esTend = false, esHand = false, esPud = false,
    noTags = false, onlyItem = false, size = 14, hlMax = 250,
    elev = false, elevCond = {instant = false, everyone = false},
    tpNearOn = true, tpNear = 35,
    speed = false, ws = 50, tpw = false, tpv = 2, fly = false, fs = 30,
    spin = false, spinv = 20, rng = false,
    autoAbility = false, tpTool = false,
    noPop = false, noSplot = false, autoCal = false,
    fb = false, nofog = false,
    autoCapsule = false,
    itemBlacklist = {}
}

local grav0 = workspace.Gravity
if grav0 < 1 then grav0 = 196.2 end
local ws0 = 16
local camPos = ZERO

local function clean(n) return (tostring(n):gsub("Monster", "")) end
local function pretty(n) return (tostring(n):gsub("(%l)(%u)", "%1 %2")) end

local function itemColor(name)
    local n = tostring(name):lower()
    if n:find("extraction", 1, true) then return PURPLE end
    if n:find("candy", 1, true) or n:find("pop", 1, true) or n:find("gumball", 1, true) or n:find("chocolate", 1, true) then return GREEN end
    if n:find("bandage", 1, true) or n:find("horn", 1, true) then return PURPLE end
    if n:find("kit", 1, true) then return ORANGE end
    return WHITE
end

local function partOf(x)
    if x:IsA("BasePart") then return x end
    if x:IsA("Model") then
        local hrp = x:FindFirstChild("HumanoidRootPart")
        if hrp then return hrp end
        return x.PrimaryPart or x:FindFirstChildWhichIsA("BasePart", true)
    end
    return x:FindFirstChildWhichIsA("BasePart", true)
end

local function inWorld(i)
    return i.Parent ~= nil and i:IsDescendantOf(workspace)
end

local torsoCache, itemCache, hooked = {}, {}, {}

local function torsoOf(x)
    local t = torsoCache[x]
    if t and t.Parent then return t end
    t = x:FindFirstChild("UpperTorso") or x:FindFirstChild("Torso")
        or x:FindFirstChild("HumanoidRootPart") or partOf(x)
    torsoCache[x] = t
    return t
end

local function plateOf(g)
    local p = g:FindFirstChild("Top_Diamond_Plate", true)
    if p and not p:IsA("BasePart") then
        p = p:FindFirstChildWhichIsA("BasePart", true)
    end
    return p or partOf(g)
end

local cChar, cHrp, cHum

local function hrpOf()
    local c = me.Character
    if not c then return nil, nil end
    if c ~= cChar then cChar, cHrp, cHum = c, nil, nil end
    if not (cHrp and cHrp.Parent) then cHrp = c:FindFirstChild("HumanoidRootPart") end
    if not (cHum and cHum.Parent) then cHum = c:FindFirstChildOfClass("Humanoid") end
    return cHrp, cHum
end

local function sv(st, n)
    local x = st and st:FindFirstChild(n)
    if x and x:IsA("ValueBase") then return x.Value end
end

local function inGame()
    local g = workspace:FindFirstChild("InGamePlayers")
    return g and g:FindFirstChild(me.Name)
end

local snap = {mon = {}, gen = {}, item = {}}

loop(0.4, function()
    local mon, gen, item = {}, {}, {}
    local r = workspace:FindFirstChild("CurrentRoom")
    if r then
        for _, m in ipairs(r:GetChildren()) do
            local a = m:FindFirstChild("Monsters")
            if a then for _, x in ipairs(a:GetChildren()) do mon[#mon + 1] = x end end
            local b = m:FindFirstChild("Generators")
            if b then for _, x in ipairs(b:GetChildren()) do gen[#gen + 1] = x end end
            local c = m:FindFirstChild("Items")
            if c then for _, x in ipairs(c:GetChildren()) do item[#item + 1] = x end end
        end
    end
    snap.mon, snap.gen, snap.item = mon, gen, item
end, "snap")

local function genStats(g) return g:FindFirstChild("Stats") end
local function genDone(g) return sv(genStats(g), "Completed") == true end
local function genPivot(g) return g:GetPivot().Position end

local function genBusy(g)
    local st = genStats(g)
    local a, b = sv(st, "ActivePlayer"), sv(st, "ActivePlayer2")
    return (a ~= nil and a ~= "" and a ~= false) or (b ~= nil and b ~= "" and b ~= false)
end

local function genAmt(g)
    local st = genStats(g)
    local c, r = sv(st, "CurrentAmount"), sv(st, "RequiredAmount")
    if type(c) == "number" and type(r) == "number" and r > 0 then return c, r end
end

local function allDone()
    local info = workspace:FindFirstChild("Info")
    local c, r = sv(info, "GeneratorsCompleted"), sv(info, "RequiredGenerators")
    if type(c) == "number" and type(r) == "number" and r > 0 then return c >= r end
    if #snap.gen == 0 then return false end
    for _, g in ipairs(snap.gen) do
        if not genDone(g) then return false end
    end
    return true
end

local function elevPos()
    local e = workspace:FindFirstChild("Elevators")
    e = e and e:FindFirstChild("Elevator")
    if not e then return end
    local b = e:FindFirstChild("Base")
    if b and b:IsA("BasePart") then return b.Position + Vector3.new(0, 4, 0) end
    return e:GetPivot().Position + Vector3.new(0, 4, 0)
end

local haz = {tend = {}, hand = {}, pud = {}}

local function inPlayer(v)
    local a = v
    while a and a ~= workspace do
        if a:IsA("Model") and P:GetPlayerFromCharacter(a) then return true end
        a = a.Parent
    end
    return false
end

local function hazKind(v, n)
    n = n or v.Name:lower()
    if n:find("tendril", 1, true) or n:find("tentacle", 1, true) then return "tend" end
    if n:find("puddle", 1, true) then
        if n:find("ichor", 1, true) then return "pud" end
        local p = v.Parent
        for _ = 1, 4 do
            if not p or p == workspace then break end
            if p.Name:lower():find("ichor", 1, true) then return "pud" end
            p = p.Parent
        end
        return nil
    end
    if n:find("hand", 1, true) and not n:find("handle", 1, true) then
        local p = v
        for _ = 1, 6 do
            if not p or p == workspace then break end
            if p.Name:lower():find("blot", 1, true) then return "hand" end
            p = p.Parent
        end
    end
end

local function hazClass(v)
    return v:IsA("BasePart") or v:IsA("Model") or v:IsA("Decal") or v:IsA("Texture")
end

local function isHandOrInsideHand(t)
    local a = t
    for _ = 1, 7 do
        if not a or a == workspace then break end
        if hazKind(a) == "hand" then return true end
        a = a.Parent
    end
    return false
end

local function hazScan(v)
    if not hazClass(v) then return end
    local n = v.Name:lower()
    if not (n:find("tendril", 1, true) or n:find("tentacle", 1, true) or n:find("puddle", 1, true)
        or n:find("hand", 1, true) or n:find("ichor", 1, true) or n:find("blot", 1, true)) then return end
    local isDecal = v:IsA("Decal") or v:IsA("Texture")
    local t = isDecal and v.Parent or v
    if not (t and (t:IsA("BasePart") or t:IsA("Model"))) then return end
    local k = hazKind(v, n)
    if not k then return end
    if v == t then
        local p = t.Parent
        if p and (p:IsA("BasePart") or p:IsA("Model")) and hazKind(p) == k then return end
    end
    if k == "pud" and isHandOrInsideHand(t) then return end
    if inPlayer(t) then return end
    haz[k][t] = true
end

local hazOn = false
local hazQueue = {}
local hazBusy = false

local function hazQueueAdd(v)
    if not hazClass(v) then return end
    if #hazQueue > 8000 then return end
    hazQueue[#hazQueue + 1] = v
    if not hazBusy then
        hazBusy = true
        task.spawn(function()
            local n = 0
            while #hazQueue > 0 do
                local batch = hazQueue
                hazQueue = {}
                for _, item in ipairs(batch) do
                    if item.Parent then pcall(hazScan, item) end
                    n = n + 1
                    if n % 100 == 0 then task.wait() end
                end
            end
            hazBusy = false
        end)
    end
end

local function hazStart()
    if hazOn then return end
    hazOn = true
    task.spawn(function()
        local n = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            hazScan(v)
            n = n + 1
            if n % 500 == 0 then task.wait() end
        end
    end)
    bind(workspace.DescendantAdded, hazQueueAdd)
end

loop(5, function(L)
    local n = 0
    for _, set in pairs(haz) do
        for inst in pairs(set) do
            if not inWorld(inst) then set[inst] = nil end
            n = n + 1
            breath(L, n, 300)
        end
    end
    for k in pairs(torsoCache) do
        if not inWorld(k) then torsoCache[k] = nil end
        n = n + 1
        breath(L, n, 300)
    end
    for k in pairs(itemCache) do
        if not inWorld(k) then itemCache[k] = nil end
        n = n + 1
        breath(L, n, 300)
    end
    for k in pairs(hooked) do
        if k.Parent == nil then hooked[k] = nil end
        n = n + 1
        breath(L, n, 300)
    end
end, "purge")

local reg = {item = {}, twist = {}, gen = {}, plr = {}, tend = {}, hand = {}, pud = {}}
local seen = {}
local hlUsed = 0
local sizeCache = {}

local function getSize(sz, lines)
    local key = sz * 100 + lines
    local c = sizeCache[key]
    if not c then
        c = UDim2.new(0, 400, 0, math.ceil(sz * 1.25) * lines)
        sizeCache[key] = c
    end
    return c
end

local function newGui(part, off)
    local g = Instance.new("BillboardGui")
    g.Name = "TishaESP"
    g.AlwaysOnTop = true
    g.StudsOffset = off
    g.Adornee = part
    g.Parent = part
    local t = Instance.new("TextLabel")
    t.Name = "T"
    t.Size = UDim2.new(1, 0, 1, 0)
    t.BackgroundTransparency = 1
    t.TextScaled = false
    t.TextWrapped = false
    t.Font = Enum.Font.FredokaOne
    t.TextStrokeColor3 = BLACK
    t.TextStrokeTransparency = 0
    t.Parent = g
    return g, t
end

local function put(kind, target, part, txt, color, stroke, outline, fill, fillT, noHl)
    local bag = reg[kind]
    local r = bag[target]
    if not r then
        r = {}
        bag[target] = r
    end
    seen[r] = true

    local tagOn = (not S.noTags) or (S.onlyItem and kind == "item")
    if tagOn then
        local off = (kind == "plr" or kind == "twist") and ZERO or TAG_UP
        if not r.gui or not r.gui.Parent or r.part ~= part then
            if r.gui then r.gui:Destroy() end
            r.gui, r.lbl = newGui(part, off)
            r.part = part
        end
        if r.gui.StudsOffset ~= off then r.gui.StudsOffset = off end
        local lines = txt:find("\n", 1, true) and 2 or 1
        local sz = getSize(S.size, lines)
        if r.gui.Size ~= sz then r.gui.Size = sz end
        if r.lbl.Text ~= txt then r.lbl.Text = txt end
        if r.lbl.TextSize ~= S.size then r.lbl.TextSize = S.size end
        local sc = stroke or BLACK
        if r.lbl.TextStrokeColor3 ~= sc then r.lbl.TextStrokeColor3 = sc end
        if r.lbl.TextColor3 ~= color then r.lbl.TextColor3 = color end
    elseif r.gui then
        r.gui:Destroy()
        r.gui, r.lbl, r.part = nil, nil, nil
    end

    if noHl then
        if r.hl then
            r.hl:Destroy()
            r.hl = nil
        end
    elseif hlUsed < S.hlMax then
        hlUsed = hlUsed + 1
        if not r.hl or not r.hl.Parent then
            local h = Instance.new("Highlight")
            h.Name = "TishaHL"
            h.OutlineTransparency = 0
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = target
            r.hl = h
        end
        local oc = outline or color
        local fc = fill or color
        local ft = fillT or 1
        if r.hl.OutlineColor ~= oc then r.hl.OutlineColor = oc end
        if r.hl.FillColor ~= fc then r.hl.FillColor = fc end
        if r.hl.FillTransparency ~= ft then r.hl.FillTransparency = ft end
    elseif r.hl then
        r.hl:Destroy()
        r.hl = nil
    end
end

local function sweep()
    for _, bag in pairs(reg) do
        for target, r in pairs(bag) do
            if not seen[r] or not target.Parent then
                if r.gui then pcall(function() r.gui:Destroy() end) end
                if r.hl then pcall(function() r.hl:Destroy() end) end
                bag[target] = nil
            end
        end
    end
    seen = {}
end

local function footprint(inst, part)
    local ok, size = pcall(function()
        if inst:IsA("Model") then return inst:GetExtentsSize() end
        return part.Size
    end)
    if not ok or not size then size = part.Size end
    return math.max(math.max(size.X, size.Z) / 2, 2)
end

local function nearestN(set, n, overlap)
    local list = {}
    for inst in pairs(set) do
        if inWorld(inst) then
            local part = partOf(inst)
            if part then list[#list + 1] = {inst, part, (part.Position - camPos).Magnitude} end
        else
            set[inst] = nil
        end
    end

    local cap = overlap and 120 or 400
    if #list > cap then
        table.sort(list, function(a, b) return a[3] < b[3] end)
        for i = #list, cap + 1, -1 do list[i] = nil end
    end

    if overlap then
        local top = {}
        for _, e in ipairs(list) do
            local hidden = false
            local a = e[1].Parent
            local depth = 0
            while a and a ~= workspace and depth < 12 do
                if set[a] then
                    hidden = true
                    break
                end
                a = a.Parent
                depth = depth + 1
            end
            if not hidden then
                e[4] = footprint(e[1], e[2])
                top[#top + 1] = e
            end
        end
        table.sort(top, function(a, b) return a[3] < b[3] end)
        local out = {}
        for _, e in ipairs(top) do
            local dup = false
            local ep = e[2].Position
            for _, k in ipairs(out) do
                local kp = k[2].Position
                local dx, dz = ep.X - kp.X, ep.Z - kp.Z
                local reach = e[4] + k[4]
                if dx * dx + dz * dz <= reach * reach then
                    dup = true
                    break
                end
            end
            if not dup then
                out[#out + 1] = e
                if #out >= n then break end
            end
        end
        return out
    end

    if #list <= n then return list end
    table.sort(list, function(a, b) return a[3] < b[3] end)
    for i = n + 1, #list do list[i] = nil end
    return list
end

local function dropPudsOnHands(puds, hands)
    if #hands == 0 then return puds end
    local out = {}
    for _, pe in ipairs(puds) do
        local bad = false
        for _, h in ipairs(hands) do
            if pe[1] == h[1] or pe[1]:IsDescendantOf(h[1]) or h[1]:IsDescendantOf(pe[1]) then
                bad = true
                break
            end
            if not h[4] then h[4] = footprint(h[1], h[2]) end
            local hp, pp = h[2].Position, pe[2].Position
            local dx, dz = hp.X - pp.X, hp.Z - pp.Z
            if dx * dx + dz * dz <= h[4] * h[4] then
                bad = true
                break
            end
        end
        if not bad then out[#out + 1] = pe end
    end
    return out
end

local function itemLabel(it)
    local pp = it:FindFirstChildWhichIsA("ProximityPrompt", true)
    local t = pp and pp.ObjectText
    if type(t) == "string" and t ~= "" then return t end
    return pretty(it.Name)
end

local function itemData(it)
    local now = tick()
    local c = itemCache[it]
    if not c then
        local n = it.Name:lower()
        c = {t = -100}
        if n:find("capsule", 1, true) and not n:find("fake", 1, true) then
            c.cap = true
            c.label = "Research Capsule"
        elseif n:find("pumpkin", 1, true) then
            c.pump = true
            c.kind = "pumpkin"
            c.label = "Pumpkin"
        end
        itemCache[it] = c
    end
    if not c.part or not c.part.Parent then c.part = partOf(it) end
    if now - c.t >= 3 then
        c.t = now
        if not c.cap and not c.pump then
            c.label = itemLabel(it)
            c.color = itemColor(it.Name)
        end
    end
    return c, c.label
end

local function pumpColor()
    local t = (math.sin(tick() * 3) + 1) / 2
    return ORANGE:Lerp(YELLOW, t)
end

loop(0.08, function()
    if not S.esItem then return end
    local pc = pumpColor()
    for _, r in pairs(reg.item) do
        if r.anim == "pumpkin" then
            if r.lbl then r.lbl.TextColor3 = pc end
            if r.hl then
                r.hl.OutlineColor = pc
                r.hl.FillColor = pc
            end
        end
    end
end, "pumpkin")

local hadEsp = false
loop(0.4, function(L)
    local any = S.esTw or S.esGen or S.esPl or S.esTend or S.esHand or S.esPud or S.esItem
    if not any then
        if hadEsp then
            hadEsp = false
            sweep()
        end
        return
    end
    hadEsp = true
    hlUsed = 0

    if S.esTend or S.esHand or S.esPud then
        local cam = workspace.CurrentCamera
        if cam then camPos = cam.CFrame.Position end
    end

    if S.esTw then
        for i, m in ipairs(snap.mon) do
            local part = torsoOf(m)
            if part then put("twist", m, part, clean(m.Name), RED, WHITE, WHITE, RED, 0.5) end
            breath(L, i, 60)
        end
    end
    if S.esGen then
        for i, g in ipairs(snap.gen) do
            if not genDone(g) then
                local part = plateOf(g)
                if part then
                    local c, r = genAmt(g)
                    local head = genBusy(g) and "Machine | Being Extracted" or "Machine"
                    local txt = head
                    if c then
                        txt = head.."\n("..math.floor(c).."/"..math.floor(r)..")"
                    end
                    put("gen", g, part, txt, GRAY, WHITE, WHITE, GRAY, 0.5)
                end
            end
            breath(L, i, 60)
        end
    end
    if S.esPl then
        for _, p in ipairs(P:GetPlayers()) do
            local c = p ~= me and p.Character
            if c then
                local hum = c:FindFirstChildOfClass("Humanoid")
                local part = torsoOf(c)
                if hum and part and hum.Health > 0 then put("plr", c, part, p.Name, GREEN, BLACK, WHITE) end
            end
        end
    end
    if S.esTend then
        for _, e in ipairs(nearestN(haz.tend, 20)) do put("tend", e[1], e[2], "Sprout Tendril", PURPLE) end
    end

    local hands = {}
    if S.esHand or S.esPud then
        hands = nearestN(haz.hand, 20)
    end
    if S.esHand then
        for _, e in ipairs(hands) do put("hand", e[1], e[2], "Blot's Hand", WHITE) end
    end
    if S.esPud then
        local puds = dropPudsOnHands(nearestN(haz.pud, 12, true), hands)
        for _, e in ipairs(puds) do put("pud", e[1], e[2], "Ichor Puddle", MAGENTA) end
    end

    if S.esItem then
        local pc = pumpColor()
        for i, it in ipairs(snap.item) do
            local c, label = itemData(it)
            if c.part and not S.itemBlacklist[it.Name] and not S.itemBlacklist[label] then
                local color, stroke = c.color or WHITE, BLACK
                if c.cap then
                    color, stroke = GREEN, WHITE
                elseif c.kind == "pumpkin" then
                    color = pc
                end
                put("item", it, c.part, label, color, stroke, color, color, 1, false)
                local r = reg.item[it]
                if r then
                    r.anim = (c.kind == "pumpkin") and "pumpkin" or nil
                end
            end
            breath(L, i, 60)
        end
    end
    sweep()
end, "esp")

local function tp(pos)
    local hrp = hrpOf()
    if not (hrp and pos) then return false end
    if hrp.Anchored then hrp.Anchored = false end
    hrp.AssemblyLinearVelocity = ZERO
    hrp.CFrame = CFrame.new(pos)
    return true
end

local function twistedNear(pos, dist)
    for _, m in ipairs(snap.mon) do
        if m.Parent then
            local part = partOf(m)
            if part and (part.Position - pos).Magnitude <= dist then return true end
        end
    end
    return false
end

local function scanTendrils()
    local list = {}
    local room = workspace:FindFirstChild("CurrentRoom")
    if not room then return list end
    for _, v in ipairs(room:GetDescendants()) do
        local n = v.Name:lower()
        if n:find("tendril", 1, true) or n:find("tentacle", 1, true) then
            local part = partOf(v)
            if part and not inPlayer(v) then list[#list + 1] = part end
        end
    end
    return list
end

local function scanHands()
    local list = {}
    for t in pairs(haz.hand) do
        if inWorld(t) then
            local part = partOf(t)
            if part then list[#list + 1] = part end
        end
    end
    local room = workspace:FindFirstChild("CurrentRoom")
    if room then
        for _, v in ipairs(room:GetDescendants()) do
            local n = v.Name:lower()
            if n:find("hand", 1, true) and hazKind(v, n) == "hand" then
                local t = (v:IsA("Decal") or v:IsA("Texture")) and v.Parent or v
                if t and (t:IsA("BasePart") or t:IsA("Model")) and not inPlayer(t) then
                    local part = partOf(t)
                    if part then list[#list + 1] = part end
                end
            end
        end
    end
    return list
end

local function nearFromList(list, pos, dist)
    for _, part in ipairs(list) do
        if part.Parent and (part.Position - pos).Magnitude <= dist then return true end
    end
    return false
end

local function tpGen()
    local hrp = hrpOf()
    if not hrp then return end

    hazStart()
    local tendrils = scanTendrils()
    local hands = scanHands()

    local best, bd, any, tendrilBlocked, handBlocked
    for pass = 1, 2 do
        for _, g in ipairs(snap.gen) do
            if not genDone(g) and (pass == 2 or not genBusy(g)) then
                any = true
                local gp = genPivot(g)
                if nearFromList(tendrils, gp, 10) then
                    tendrilBlocked = true
                elseif nearFromList(hands, gp, 10) then
                    handBlocked = true
                elseif not (S.tpNearOn and twistedNear(gp, S.tpNear)) then
                    local d = (gp - hrp.Position).Magnitude
                    if not bd or d < bd then best, bd = g, d end
                end
            end
        end
        if best then break end
    end
    if best then
        tp(genPivot(best) + Vector3.new(0, 3, 0))
    elseif tendrilBlocked and handBlocked then
        notify("All machines have a Sprout Tendril or Blot's Hand within 10 studs or less")
    elseif handBlocked then
        notify("All machines have a Blot's Hand within 10 studs or less")
    elseif tendrilBlocked then
        notify("All machines have a Sprout Tendril within 10 studs or less")
    elseif any then
        notify("All machines have a twisted less than "..S.tpNear.." studs away")
    else
        notify("No machines found")
    end
end

local function tpAboveGenerator()
    local hrp = hrpOf()
    if not hrp then return end

    local bestPart, bd
    for _, g in ipairs(snap.gen) do
        if not genDone(g) then
            local plate = g:FindFirstChild("Top_Diamond_Plate", true)
            if plate and plate:IsA("BasePart") then
                local d = (plate.Position - hrp.Position).Magnitude
                if not bd or d < bd then
                    bestPart, bd = plate, d
                end
            end
        end
    end

    if bestPart then
        tp(bestPart.Position + Vector3.new(0, 3, 0))
    else
        notify("No available generator found")
    end
end

local tpTool, backpackWas

local function makeTpTool()
    local t = Instance.new("Tool")
    t.Name = "TP Tool"
    t.ToolTip = "Click to teleport"
    t.RequiresHandle = false
    t.CanBeDropped = false
    t.Activated:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local m = me:GetMouse()
        local ray = cam:ScreenPointToRay(m.X, m.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {me.Character}
        local res = workspace:Raycast(ray.Origin, ray.Direction * 3000, params)
        if res then tp(res.Position + Vector3.new(0, 3, 0)) end
    end)
    return t
end

local function giveTpTool()
    if not tpTool or tpTool.Parent == nil then
        if tpTool then pcall(function() tpTool:Destroy() end) end
        tpTool = makeTpTool()
        genv.TishaTool = tpTool
    end
    local bp = me:FindFirstChildOfClass("Backpack")
    if bp and tpTool.Parent ~= bp and tpTool.Parent ~= me.Character then
        tpTool.Parent = bp
    end
end

local function setTpTool(v)
    S.tpTool = v
    if v then
        if backpackWas == nil then
            local ok, was = pcall(function() return SG:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
            if ok then backpackWas = was end
        end
        pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
        giveTpTool()
    else
        if tpTool then
            pcall(function() tpTool:Destroy() end)
            tpTool = nil
            genv.TishaTool = nil
        end
        if backpackWas ~= nil then
            local was = backpackWas
            backpackWas = nil
            pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, was) end)
        end
    end
end

loop(1, function()
    if not S.tpTool then return end
    local ok, on = pcall(function() return SG:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack) end)
    if ok and not on then
        pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true) end)
    end
    giveTpTool()
end, "tptool")

local function setFly(v)
    S.fly = v
    if v then
        if workspace.Gravity > 0 then grav0 = workspace.Gravity end
        workspace.Gravity = 0
    else
        workspace.Gravity = grav0
    end
end

local function moveStep(dt)
    local hrp, hum = hrpOf()
    if not (hrp and hum) then return end

    if S.speed and hum.WalkSpeed ~= S.ws then hum.WalkSpeed = S.ws end

    local dir = hum.MoveDirection
    if S.fly then
        if workspace.Gravity ~= 0 then workspace.Gravity = 0 end
        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z)
        flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
        local right = Vector3.new(-flat.Z, 0, flat.X)
        local mv = ZERO
        if dir.Magnitude > 0.01 then
            mv = look * dir:Dot(flat) + cam.CFrame.RightVector * dir:Dot(right)
        else
            local f = (UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local r = (UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local u = (UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0)
            mv = look * f + cam.CFrame.RightVector * r + Vector3.new(0, u, 0)
        end
        hrp.AssemblyLinearVelocity = ZERO
        hrp.AssemblyAngularVelocity = ZERO
        if mv.Magnitude > 0.01 and S.fs > 0 then
            hrp.CFrame = hrp.CFrame + mv.Unit * (S.fs * dt)
        end
    elseif S.tpw and S.tpv > 0 and dir.Magnitude > 0.01 then
        hrp.CFrame = hrp.CFrame + dir * (S.tpv * 10 * dt)
    end

    if S.spin and S.spinv > 0 then
        if hum.AutoRotate then hum.AutoRotate = false end
        local v = hrp.AssemblyLinearVelocity
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(S.spinv * 20) * dt, 0)
        hrp.AssemblyLinearVelocity = v
    elseif not hum.AutoRotate then
        hum.AutoRotate = true
    end
end

connectHB = function()
    if conns.hb then pcall(function() conns.hb:Disconnect() end) end
    local c = RUN.Heartbeat:Connect(function(dt)
        local now = tick()
        alive.hb = now
        if dt > worstFrame then worstFrame = dt end
        if dt > 0.4 then onHitch(dt) end
        if now - lastRevive > 1 then
            lastRevive = now
            revive(now)
        end
        if S.speed or S.tpw or S.fly or S.spin then
            local t0 = os.clock()
            pcall(moveStep, dt)
            track("move", os.clock() - t0)
        end
    end)
    conns.hb = c
    conns[#conns + 1] = c
end

connectRS = function()
    if conns.rs then pcall(function() conns.rs:Disconnect() end) end
    local c = RUN.RenderStepped:Connect(function()
        local now = tick()
        alive.rs = now
        if now - lastRevive > 1 then
            lastRevive = now
            revive(now)
        end
    end)
    conns.rs = c
    conns[#conns + 1] = c
end

local watchToken = 0
startWatch = function()
    watchToken = watchToken + 1
    local my = watchToken
    alive.th = tick()
    task.spawn(function()
        while GEN == genv.TishaGen and watchToken == my do
            alive.th = tick()
            revive(tick())
            task.wait(1)
        end
    end)
end

connectHB()
connectRS()
startWatch()

local NoclipConnection = nil

local function applyNoclip()
    local character = me.Character or me.CharacterAdded:Wait()
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanQuery"))) do conn:Disconnect() end
                for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanCollide"))) do conn:Disconnect() end
                for _, conn in ipairs(getconnections(part:GetPropertyChangedSignal("CanTouch"))) do conn:Disconnect() end
                for _, conn in ipairs(getconnections(part.Changed)) do conn:Disconnect() end
            end)
            part.CanCollide = false
        end
    end
end

local function setNoclip(state)
    if state then
        applyNoclip()
        if not NoclipConnection then
            NoclipConnection = RUN.Stepped:Connect(function()
                local character = me.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            conns[#conns + 1] = NoclipConnection
        end
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        local character = me.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function pressButton(btn)
    if getconnections then
        for _, key in ipairs({"Activated", "MouseButton1Click", "TouchTap", "MouseButton1Down"}) do
            local ok, cs = pcall(getconnections, btn[key])
            if ok and cs and #cs > 0 then
                for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
                return true
            end
        end
    end
    if firesignal then
        local ok = pcall(firesignal, btn.Activated)
        if ok then return true end
    end
    return false
end

local function topGui(inst)
    local a = inst
    while a and a.Parent and a.Parent ~= pg do a = a.Parent end
    return a
end

local function own(inst)
    local t = topGui(inst)
    if not t then return false end
    local n = t.Name:lower()
    return n:find("tisha", 1, true) ~= nil or n:find("plagg", 1, true) ~= nil
end

local function elevRadius()
    local e = workspace:FindFirstChild("Elevators")
    e = e and e:FindFirstChild("Elevator")
    local b = e and e:FindFirstChild("Base")
    if b and b:IsA("BasePart") then
        return math.max(b.Size.X, b.Size.Z) / 2 + 6
    end
    return 18
end

local function everyoneAtElevator()
    local pos = elevPos()
    if not pos then return false end
    local r = elevRadius()
    local list = {}
    local g = workspace:FindFirstChild("InGamePlayers")
    if g then
        for _, x in ipairs(g:GetChildren()) do
            local p = P:FindFirstChild(x.Name)
            if p then list[#list + 1] = p end
        end
    else
        list = P:GetPlayers()
    end
    local counted = 0
    for _, p in ipairs(list) do
        local c = p.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local root = c and c:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            counted = counted + 1
            if (root.Position - pos).Magnitude > r then return false end
        end
    end
    return counted > 0
end

local TIMER_KEYS = {"panic", "countdown", "timer", "timeleft", "remaining"}
local panicSrc, panicAt = nil, 0

local function nameHas(n, key)
    return n:lower():find(key, 1, true) ~= nil
end

local function parseClock(s)
    if type(s) ~= "string" then return nil end
    local m, sec = s:match("(%d+):(%d%d)")
    if m then return tonumber(m) * 60 + tonumber(sec) end
    local n = s:match("^%s*(%d+%.?%d*)%s*s?%s*$")
    return n and tonumber(n) or nil
end

local function findPanicSource()
    local roots = {}
    local info = workspace:FindFirstChild("Info")
    if info then roots[#roots + 1] = info end
    local el = workspace:FindFirstChild("Elevators")
    if el then roots[#roots + 1] = el end

    for _, key in ipairs(TIMER_KEYS) do
        for _, root in ipairs(roots) do
            for k, v in pairs(root:GetAttributes()) do
                if type(v) == "number" and nameHas(tostring(k), key) then
                    return {kind = "attr", inst = root, key = k}
                end
            end
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("ValueBase") and nameHas(d.Name, key) and type(d.Value) == "number" then
                    return {kind = "val", inst = d}
                end
            end
        end
    end

    for _, d in ipairs(pg:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible and not own(d) and parseClock(d.Text) then
            local a, hit = d, false
            for _ = 1, 4 do
                if not a or a == pg then break end
                for _, key in ipairs(TIMER_KEYS) do
                    if nameHas(a.Name, key) then hit = true end
                end
                a = a.Parent
            end
            if hit then return {kind = "gui", inst = d} end
        end
    end
end

local function readPanic(s)
    if not s.inst.Parent then return nil end
    if s.kind == "val" then
        local v = s.inst.Value
        return type(v) == "number" and v or nil
    elseif s.kind == "attr" then
        local v = s.inst:GetAttribute(s.key)
        return type(v) == "number" and v or nil
    end
    return parseClock(s.inst.Text)
end

local function panicTime()
    if panicSrc then
        local ok, v = pcall(readPanic, panicSrc)
        if ok and v then return v end
        panicSrc = nil
    end
    if tick() - panicAt < 5 then return nil end
    panicAt = tick()
    panicSrc = findPanicSource()
    if panicSrc then
        local ok, v = pcall(readPanic, panicSrc)
        if ok then return v end
    end
    return nil
end

local timerWarned = false

local function elevConditionMet()
    local c = S.elevCond
    if not (c.instant or c.everyone) then return true end
    if c.instant then return true end
    if everyoneAtElevator() then return true end

    local t = panicTime()
    if t then
        if t <= 5 then return true end
    elseif not timerWarned then
        timerWarned = true
        notify("Panic timer not found. Waiting only for everyone at the elevator.")
    end
    return false
end

do
    local fired = false
    loop(0.3, function()
        if not S.elev or not allDone() then
            fired = false
            timerWarned = false
            return
        end
        if fired then return end
        local hrp, hum = hrpOf()
        if not (hum and hum.Health > 0 and hrp and inGame()) then return end
        local pos = elevPos()
        if not pos then return end
        if elevConditionMet() and tp(pos) then fired = true end
    end, "elev")
end

local capsuleAttempted = setmetatable({}, {__mode = "k"})

loop(0.25, function(L)
    if not S.autoCapsule then return end
    local hrp = hrpOf()
    if not hrp then return end
    local room = workspace:FindFirstChild("CurrentRoom")
    if not room then return end
    for _, m in ipairs(room:GetChildren()) do
        local items = m:FindFirstChild("Items")
        if items then
            for _, it in ipairs(items:GetChildren()) do
                if it.Parent and not capsuleAttempted[it] then
                    local n = it.Name:lower()
                    if n:find("capsule", 1, true) and not n:find("fake", 1, true) then
                        local p = it:FindFirstChildWhichIsA("ProximityPrompt", true)
                        if p and p.Enabled then
                            local part = partOf(it)
                            if part then
                                capsuleAttempted[it] = true
                                tp(part.Position + Vector3.new(0, 2, 0))
                                pause(L, 0.1)
                                if fireproximityprompt then
                                    pcall(fireproximityprompt, p)
                                end
                                pause(L, 0.1)
                            end
                        end
                    end
                end
            end
        end
    end
end, "autoCapsule")

local function uiKind(inst)
    if not (inst:IsA("GuiObject") or inst:IsA("ScreenGui")) then return end
    local n = inst.Name:lower()
    if n:find("splotch", 1, true) or n:find("stain", 1, true) or n:find("splat", 1, true)
        or (n:find("ichor", 1, true) and (n:find("screen", 1, true) or n:find("overlay", 1, true) or n:find("vignette", 1, true))) then
        return "splot"
    end
    if n:find("popup", 1, true) or n:find("pop_up", 1, true) or n:find("pop-up", 1, true) or n:find("pop up", 1, true)
        or n:find("advert", 1, true) or n == "ad" or n == "ads" or n:find("^ad[%d_]") or n:find("^vee") then
        return "pop"
    end
end

local function kindOn(kind)
    return (kind == "pop" and S.noPop) or (kind == "splot" and S.noSplot)
end

local function closeAd(inst)
    for _, d in ipairs(inst:GetDescendants()) do
        if d:IsA("GuiButton") then
            local n = d.Name:lower()
            local t = d:IsA("TextButton") and d.Text:lower() or ""
            if n:find("close", 1, true) or n == "x" or t == "x" then pressButton(d) end
        end
    end
end

local function hideUi(inst, kind)
    if hooked[inst] then
        hooked[inst].apply()
        return
    end
    local prop = inst:IsA("ScreenGui") and "Enabled" or "Visible"
    local function apply()
        if kindOn(kind) and inst[prop] then inst[prop] = false end
    end
    hooked[inst] = {apply = apply}
    if kind == "pop" then pcall(closeAd, inst) end
    apply()
    inst:GetPropertyChangedSignal(prop):Connect(apply)
end

bind(pg.DescendantAdded, function(d)
    if not (S.noPop or S.noSplot) then return end
    local k = uiKind(d)
    if k and kindOn(k) and not own(d) then pcall(hideUi, d, k) end
end)

local function scanUi()
    local n = 0
    for _, d in ipairs(pg:GetDescendants()) do
        local k = uiKind(d)
        if k and kindOn(k) and not own(d) then pcall(hideUi, d, k) end
        n = n + 1
        if n % 400 == 0 then task.wait() end
    end
end

genv.scinstant = false
if not (genv.PlaggSCHook or genv.TishaSCHook) then
    task.spawn(function()
        pcall(function()
            local events = RS:FindFirstChild("Events")
            if events then
                local event = events:FindFirstChild("SkillcheckUpdate")
                if event and getcallbackvalue then
                    local ogcb = getcallbackvalue(event, "OnClientInvoke")
                    if ogcb then
                        local hook
                        hook = hookfunction(ogcb, function(...)
                            if genv.scinstant then return "supercomplete" end
                            return hook(...)
                        end)
                        genv.TishaSCHook = true
                    end
                end
            end
        end)
    end)
end

local RANGE_TOONS = {Shelly = true, Sprout = true, Cosmo = true, Scraps = true, Glisten = true}
local RANGE_BIG = 500
local rngOrig = setmetatable({}, {__mode = "k"})
local rngFound = setmetatable({}, {__mode = "k"})
local rngAt = 0

local function rangeScan(restore, L)
    if not (getconnections and getupvalues) then return end
    local idx = 0
    for _, conn in pairs(getconnections(RUN.RenderStepped)) do
        idx = idx + 1
        breath(L, idx, 25)
        local func = conn.Function
        if func then
            local ok, upvals = pcall(getupvalues, func)
            if ok and upvals then
                for _, val in pairs(upvals) do
                    if typeof(val) == "table" and val.Name and RANGE_TOONS[val.Name] and val.PlayerRadius then
                        if restore then
                            local o = rngOrig[val]
                            if o then
                                val.PlayerRadius = o
                                rngOrig[val] = nil
                            end
                            rngFound[val] = nil
                        else
                            if rngOrig[val] == nil then rngOrig[val] = val.PlayerRadius end
                            val.PlayerRadius = RANGE_BIG
                            rngFound[val] = true
                        end
                    end
                end
            end
        end
    end
end

loop(1, function(L)
    if not S.rng then return end
    if tick() - rngAt > 10 then
        rngAt = tick()
        rangeScan(false, L)
    end
    for val in pairs(rngFound) do
        if val.PlayerRadius ~= RANGE_BIG then val.PlayerRadius = RANGE_BIG end
    end
end, "range")

local abBusy = false
loop(1, function()
    if not S.autoAbility or abBusy then return end
    local char = me.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local ev = RS:FindFirstChild("Events")
    local ab = ev and ev:FindFirstChild("AbilityEvent")
    if char and hrp and ab then
        abBusy = true
        task.delay(3, function() abBusy = false end)
        task.spawn(function()
            pcall(function() ab:InvokeServer(char, hrp.CFrame, false) end)
            abBusy = false
        end)
    end
end, "ability")

local function keeper()
    local store = setmetatable({}, {__mode = "k"})
    local function set(i, p, v)
        local t = store[i]
        if not t then
            t = {}
            store[i] = t
        end
        if t[p] == nil then t[p] = i[p] end
        if i[p] ~= v then i[p] = v end
    end
    local function undo()
        for i, t in pairs(store) do
            for p, v in pairs(t) do
                pcall(function() i[p] = v end)
            end
        end
        store = setmetatable({}, {__mode = "k"})
    end
    return set, undo
end

local fogSet, fogUndo = keeper()
local brSet, brUndo = keeper()
local atmos, atmosAt = {}, 0

local function world()
    if S.nofog then
        local now = tick()
        if now - atmosAt > 2 then
            atmosAt = now
            atmos = {}
            for _, a in ipairs(Lt:GetChildren()) do
                if a:IsA("Atmosphere") then atmos[#atmos + 1] = a end
            end
        end
        fogSet(Lt, "FogEnd", 1e9)
        fogSet(Lt, "FogStart", 1e9)
        for _, a in ipairs(atmos) do
            fogSet(a, "Density", 0)
            fogSet(a, "Offset", 0)
            fogSet(a, "Haze", 0)
            fogSet(a, "Glare", 0)
        end
    end
    if S.fb then
        brSet(Lt, "Brightness", 2)
        brSet(Lt, "ClockTime", 14)
        brSet(Lt, "GlobalShadows", false)
        brSet(Lt, "Ambient", WHITE)
        brSet(Lt, "OutdoorAmbient", WHITE)
    end
end

local function refreshWorld()
    pcall(function() RUN:UnbindFromRenderStep("TishaWorld") end)
    atmosAt = 0
    if S.nofog or S.fb then
        RUN:BindToRenderStep("TishaWorld", Enum.RenderPriority.Last.Value, world)
    end
end

local C = {
    bg = Color3.fromRGB(244, 250, 255),
    bar = Color3.fromRGB(255, 255, 255),
    side = Color3.fromRGB(222, 240, 255),
    row = Color3.fromRGB(255, 255, 255),
    rowHi = Color3.fromRGB(205, 230, 255),
    accent = Color3.fromRGB(56, 160, 255),
    cyan = Color3.fromRGB(0, 215, 245),
    edge = Color3.fromRGB(150, 205, 255),
    text = Color3.fromRGB(24, 52, 92),
    sub = Color3.fromRGB(96, 134, 184),
    off = Color3.fromRGB(190, 208, 230)
}

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = (typeof(r) == "UDim") and r or UDim.new(0, r)
    c.Parent = o
    return c
end

local function pad(o, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l)
    p.PaddingTop = UDim.new(0, t)
    p.PaddingRight = UDim.new(0, r)
    p.PaddingBottom = UDim.new(0, b)
    p.Parent = o
    return p
end

local function vlist(o, gap)
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, gap or 0)
    l.Parent = o
    return l
end

local function gradient(o, a, b, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(a, b)
    g.Rotation = rot or 0
    g.Parent = o
    return g
end

local function label(props, parent)
    local p = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextColor3 = C.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left
    }
    for k, v in pairs(props) do p[k] = v end
    return mk("TextLabel", p, parent)
end

local function newScreen(name, order)
    local g = Instance.new("ScreenGui")
    g.Name = name
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = order
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ok = pcall(function() g.Parent = (gethui and gethui()) or pg end)
    if not ok or not g.Parent then g.Parent = pg end
    return g
end

local clickSound = Instance.new("Sound")
clickSound.Name = "TishaClick"
clickSound.SoundId = "rbxassetid://8919449656"
clickSound.Volume = 0.6
clickSound.Parent = SS
genv.TishaClickSound = clickSound

task.spawn(function()
    pcall(function() game:GetService("ContentProvider"):PreloadAsync({clickSound}) end)
end)

local function playClick()
    pcall(function()
        if clickSound and clickSound.Parent then
            clickSound.TimePosition = 0
            clickSound:Play()
        end
    end)
end

local function makeDraggable(btn, onTap)
    local activeInput = nil
    local dragging, moved = false, false
    local dragStart, startPos

    btn.InputBegan:Connect(function(input)
        if not activeInput and (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) then
            activeInput = input
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
        end
    end)

    bind(UIS.InputChanged, function(input)
        if dragging and (input == activeInput or (activeInput
            and activeInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            local d = input.Position - dragStart
            if d.Magnitude > 8 then moved = true end
            if moved then
                btn.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end
    end)

    bind(UIS.InputEnded, function(input)
        if activeInput and (input == activeInput
            or (activeInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1)) then
            dragging = false
            activeInput = nil
            if not moved and onTap then pcall(onTap) end
        end
    end)
end

local notifyGui = newScreen("TishaNotify", 30)
genv.TishaNotifyGui = notifyGui
local nHolder = mk("Frame", {
    Size = UDim2.fromOffset(260, 0), AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.fromOffset(12, 70), BackgroundTransparency = 1
}, notifyGui)
vlist(nHolder, 6)
local nCount = 0

notifyImpl = function(txt)
    nCount = nCount + 1
    local kids = {}
    for _, k in ipairs(nHolder:GetChildren()) do
        if k:IsA("Frame") then kids[#kids + 1] = k end
    end
    table.sort(kids, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    while #kids >= 4 do
        kids[1]:Destroy()
        table.remove(kids, 1)
    end
    local f = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = C.bar, BorderSizePixel = 0, LayoutOrder = nCount
    }, nHolder)
    corner(f, 10)
    local ns = mk("UIStroke", {Thickness = 1.5, Color = WHITE}, f)
    gradient(ns, C.cyan, C.accent, 45)
    pad(f, 12, 8, 12, 10)
    vlist(f, 2)
    label({
        Size = UDim2.new(1, 0, 0, 15), Text = "Tisha's Cleaner GUI", TextColor3 = C.accent,
        Font = Enum.Font.FredokaOne, TextSize = 14, LayoutOrder = 1
    }, f)
    label({
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Text = tostring(txt), TextWrapped = true, LayoutOrder = 2
    }, f)
    task.delay(5, function()
        if f.Parent then f:Destroy() end
    end)
end

local function floatBtn(name, order, posY, text, onTap)
    local gui = newScreen(name, order)
    gui.Enabled = false
    local b = mk("TextButton", {
        Size = UDim2.fromOffset(170, 40), Position = UDim2.new(0.72, 0, posY, 0),
        BackgroundColor3 = C.bar, BorderSizePixel = 0, AutoButtonColor = false,
        Text = text, Font = Enum.Font.FredokaOne, TextColor3 = C.accent,
        TextScaled = true, Active = true
    }, gui)
    pad(b, 10, 7, 10, 7)
    corner(b, 12)
    local st = mk("UIStroke", {Thickness = 2.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = WHITE}, b)
    gradient(st, C.cyan, C.accent, 45)
    makeDraggable(b, function()
        playClick()
        onTap()
    end)
    return gui
end

local tpGui = floatBtn("TishaTpGen", 22, 0.6, "TP Generator", tpGen)
genv.TishaTpBtn = tpGui
local topGenGui = floatBtn("TishaTopGen", 22, 0.72, "TP Above Generator", tpAboveGenerator)
genv.TishaTopBtn = topGenGui

local NORMAL = UDim2.fromOffset(500, 310)
local BIG = UDim2.new(0.94, 0, 0.92, 0)

local mainGui = newScreen("TishaHub", 20)
genv.TishaMainGui = mainGui

local main = mk("Frame", {
    Name = "Main", Size = NORMAL, AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = WHITE,
    BorderSizePixel = 0, Active = true, ClipsDescendants = true
}, mainGui)
corner(main, 14)
gradient(main, Color3.fromRGB(250, 253, 255), Color3.fromRGB(214, 236, 255), 90)
local mStroke = mk("UIStroke", {Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = WHITE}, main)
local mGrad = gradient(mStroke, C.cyan, C.accent, 45)

local top = mk("Frame", {
    Name = "Top", Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = WHITE, BorderSizePixel = 0
}, main)
gradient(top, Color3.fromRGB(255, 255, 255), Color3.fromRGB(226, 242, 255), 0)

local title = label({
    Size = UDim2.new(0, 330, 1, 0), Position = UDim2.fromOffset(16, 0),
    Text = "TISHA'S CLEANER GUI", TextColor3 = WHITE, Font = Enum.Font.FredokaOne, TextSize = 19
}, top)
gradient(title, C.cyan, Color3.fromRGB(40, 120, 235), 0)

local topLine = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 3), Position = UDim2.fromOffset(0, 40),
    BackgroundColor3 = WHITE, BorderSizePixel = 0
}, main)
gradient(topLine, C.cyan, C.accent, 0)

local dots = mk("Frame", {
    Size = UDim2.fromOffset(90, 40), AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 0), BackgroundTransparency = 1
}, top)
do
    local dl = Instance.new("UIListLayout")
    dl.FillDirection = Enum.FillDirection.Horizontal
    dl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    dl.VerticalAlignment = Enum.VerticalAlignment.Center
    dl.SortOrder = Enum.SortOrder.LayoutOrder
    dl.Padding = UDim.new(0, 8)
    dl.Parent = dots
end

local function dot(color, symbol, order)
    local b = mk("TextButton", {
        Size = UDim2.fromOffset(22, 22), BackgroundColor3 = color, BorderSizePixel = 0,
        AutoButtonColor = true, Text = symbol, TextColor3 = WHITE,
        Font = Enum.Font.GothamBold, TextSize = 14, LayoutOrder = order
    }, dots)
    corner(b, 11)
    return b
end
local dGreen = dot(Color3.fromRGB(60, 205, 100), "+", 1)
local dYellow = dot(Color3.fromRGB(255, 190, 50), "-", 2)
local dRed = dot(Color3.fromRGB(255, 85, 85), "x", 3)

do
    local dragging, dragStart, startPos = false, nil, nil
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local side = mk("Frame", {
    Name = "Side", Position = UDim2.fromOffset(0, 43), Size = UDim2.new(0, 124, 1, -43),
    BackgroundColor3 = WHITE, BorderSizePixel = 0
}, main)
gradient(side, Color3.fromRGB(236, 247, 255), Color3.fromRGB(200, 227, 255), 90)
local tabList = mk("Frame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1}, side)
pad(tabList, 8, 8, 8, 8)
vlist(tabList, 6)

local sideLine = mk("Frame", {
    Size = UDim2.new(0, 2, 1, -43), Position = UDim2.fromOffset(124, 43),
    BackgroundColor3 = WHITE, BorderSizePixel = 0
}, main)
gradient(sideLine, C.cyan, C.accent, 90)

local content = mk("Frame", {
    Name = "Content", Position = UDim2.fromOffset(128, 43), Size = UDim2.new(1, -128, 1, -43),
    BackgroundTransparency = 1
}, main)

local function newPage()
    local sf = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false
    }, content)
    vlist(sf, 7)
    pad(sf, 10, 10, 14, 10)

    local order = 0
    local function nxt()
        order = order + 1
        return order
    end
    local page = {sf = sf}

    local function card(h)
        local f = mk("Frame", {
            Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.row,
            BorderSizePixel = 0, LayoutOrder = nxt()
        }, sf)
        corner(f, 10)
        mk("UIStroke", {Thickness = 1, Color = C.edge, Transparency = 0.25}, f)
        return f
    end

    function page.section(titleText)
        local f = mk("Frame", {Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = nxt()}, sf)
        label({
            Size = UDim2.new(1, 0, 1, -4), Text = string.upper(titleText), TextColor3 = C.accent,
            Font = Enum.Font.FredokaOne, TextSize = 14
        }, f)
        local ln = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 2), Position = UDim2.new(0, 0, 1, -2),
            BackgroundColor3 = WHITE, BorderSizePixel = 0
        }, f)
        gradient(ln, C.cyan, C.edge, 0)
    end

    function page.toggle(titleText, default, cb)
        local row = card(38)
        local hit = mk("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false
        }, row)
        label({
            Size = UDim2.new(1, -66, 1, 0), Position = UDim2.fromOffset(12, 0),
            Text = titleText, TextWrapped = true
        }, row)
        local sw = mk("Frame", {
            Size = UDim2.fromOffset(40, 22), AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = C.off, BorderSizePixel = 0
        }, row)
        corner(sw, 11)
        local knob = mk("Frame", {
            Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(2, 2),
            BackgroundColor3 = WHITE, BorderSizePixel = 0
        }, sw)
        corner(knob, 9)
        local state = default and true or false
        local function paint()
            sw.BackgroundColor3 = state and C.accent or C.off
            knob.Position = state and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2)
        end
        paint()
        local function set(v, silent)
            state = v and true or false
            paint()
            if not silent then pcall(cb, state) end
        end
        hit.Activated:Connect(function()
            playClick()
            set(not state)
        end)
        return {Set = set}
    end

    function page.slider(titleText, min, max, default, step, cb)
        local row = card(50)
        label({Size = UDim2.new(1, -90, 0, 22), Position = UDim2.fromOffset(12, 4), Text = titleText}, row)
        local val = label({
            Size = UDim2.fromOffset(70, 22), AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 4), Text = "", TextColor3 = C.sub,
            TextXAlignment = Enum.TextXAlignment.Right
        }, row)
        local track = mk("Frame", {
            Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 35),
            BackgroundColor3 = C.off, BorderSizePixel = 0
        }, row)
        corner(track, 3)
        local fill = mk("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0}, track)
        corner(fill, 3)
        gradient(fill, C.cyan, C.accent, 0)
        local knob = mk("Frame", {
            Size = UDim2.fromOffset(16, 16), AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0
        }, track)
        corner(knob, 8)
        mk("UIStroke", {Thickness = 2, Color = C.accent}, knob)
        local hit = mk("TextButton", {
            Size = UDim2.new(1, -10, 0, 28), Position = UDim2.new(0, 5, 0, 22),
            BackgroundTransparency = 1, Text = "", AutoButtonColor = false
        }, row)

        local function fmtv(v)
            if step < 1 then return string.format("%.1f", v) end
            return tostring(math.floor(v + 0.5))
        end
        local cur = default
        local function paint(v)
            local a = math.clamp((v - min) / (max - min), 0, 1)
            fill.Size = UDim2.new(a, 0, 1, 0)
            knob.Position = UDim2.new(a, 0, 0.5, 0)
            val.Text = fmtv(v)
        end
        paint(cur)

        local function setFromX(x)
            local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = min + a * (max - min)
            v = min + math.floor((v - min) / step + 0.5) * step
            v = math.clamp(v, min, max)
            v = tonumber(string.format("%.3f", v))
            if v ~= cur then
                cur = v
                paint(v)
                pcall(cb, v)
            end
        end

        local sliding = false
        hit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                sf.ScrollingEnabled = false
                setFromX(input.Position.X)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        sliding = false
                        sf.ScrollingEnabled = true
                    end
                end)
            end
        end)
        bind(UIS.InputChanged, function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
    end

    function page.button(titleText, cb)
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.accent, AutoButtonColor = true,
            Text = titleText, TextColor3 = WHITE, Font = Enum.Font.GothamBold, TextSize = 14,
            BorderSizePixel = 0, LayoutOrder = nxt()
        }, sf)
        corner(b, 10)
        gradient(b, C.cyan, C.accent, 0)
        b.Activated:Connect(function()
            playClick()
            pcall(cb)
        end)
    end

    function page.choice(titleText, options, default, cb)
        local row = card(72)
        label({Size = UDim2.new(1, -24, 0, 22), Position = UDim2.fromOffset(12, 6), Text = titleText}, row)
        local holder = mk("Frame", {
            Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 32), BackgroundTransparency = 1
        }, row)
        local hl = Instance.new("UIListLayout")
        hl.FillDirection = Enum.FillDirection.Horizontal
        hl.SortOrder = Enum.SortOrder.LayoutOrder
        hl.Padding = UDim.new(0, 6)
        hl.Parent = holder
        local n = #options
        local btns = {}
        local function paint(sel)
            for name, b in pairs(btns) do
                local on = (name == sel)
                b.BackgroundColor3 = on and C.accent or C.rowHi
                b.TextColor3 = on and WHITE or C.text
            end
        end
        for i, name in ipairs(options) do
            local b = mk("TextButton", {
                Size = UDim2.new(1 / n, -(6 * (n - 1)) / n, 1, 0), Text = name,
                Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
                BorderSizePixel = 0, LayoutOrder = i, BackgroundColor3 = C.rowHi, TextColor3 = C.text
            }, holder)
            corner(b, 8)
            btns[name] = b
            b.Activated:Connect(function()
                playClick()
                paint(name)
                pcall(cb, name)
            end)
        end
        paint(default)
    end

    function page.multi(titleText, values, cb)
        local wrap = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = nxt()
        }, sf)
        corner(wrap, 10)
        mk("UIStroke", {Thickness = 1, Color = C.edge, Transparency = 0.25}, wrap)
        vlist(wrap, 0)
        local head = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1,
            AutoButtonColor = false, Text = "", LayoutOrder = 1
        }, wrap)
        label({
            Size = UDim2.new(1, -100, 1, 0), Position = UDim2.fromOffset(12, 0),
            Text = titleText, TextWrapped = true
        }, head)
        local cnt = label({
            Size = UDim2.fromOffset(90, 38), AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 0), Text = "0  +", TextColor3 = C.sub,
            TextXAlignment = Enum.TextXAlignment.Right
        }, head)
        local list = mk("Frame", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Visible = false, LayoutOrder = 2
        }, wrap)
        vlist(list, 0)
        pad(list, 0, 0, 0, 8)

        local open = false
        local n = 0
        local picked = {}
        local function refresh()
            cnt.Text = tostring(n) .. (open and "  -" or "  +")
        end
        head.Activated:Connect(function()
            playClick()
            open = not open
            list.Visible = open
            refresh()
        end)

        for i, v in ipairs(values) do
            local it = mk("TextButton", {
                Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
                AutoButtonColor = false, Text = "", LayoutOrder = i
            }, list)
            local box = mk("Frame", {
                Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 14, 0.5, -8),
                BackgroundColor3 = C.off, BorderSizePixel = 0
            }, it)
            corner(box, 4)
            label({Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(38, 0), Text = v}, it)
            it.Activated:Connect(function()
                playClick()
                if picked[v] then
                    picked[v] = nil
                    n = n - 1
                else
                    picked[v] = true
                    n = n + 1
                end
                box.BackgroundColor3 = picked[v] and C.accent or C.off
                refresh()
                local out = {}
                for _, name in ipairs(values) do
                    if picked[name] then out[#out + 1] = name end
                end
                pcall(cb, out)
            end)
        end
    end

    return page
end

local tabs = {}

local function selectTab(i)
    for j, t in ipairs(tabs) do
        local on = (j == i)
        t.page.sf.Visible = on
        t.btn.BackgroundColor3 = on and WHITE or C.rowHi
        t.btn.BackgroundTransparency = on and 0 or 1
        t.btn.TextColor3 = on and C.accent or C.sub
        t.bar.Visible = on
    end
end

local function addTab(name)
    local idx = #tabs + 1
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
        AutoButtonColor = false, Text = name, TextColor3 = C.sub, Font = Enum.Font.FredokaOne,
        TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0,
        LayoutOrder = idx
    }, tabList)
    corner(btn, 10)
    pad(btn, 16, 0, 4, 0)
    local bar = mk("Frame", {
        Size = UDim2.new(0, 4, 1, -16), Position = UDim2.fromOffset(-12, 8),
        BackgroundColor3 = C.accent, BorderSizePixel = 0, Visible = false
    }, btn)
    corner(bar, 2)
    local page = newPage()
    tabs[idx] = {btn = btn, bar = bar, page = page}
    btn.Activated:Connect(function()
        playClick()
        selectTab(idx)
    end)
    return page
end

local pPlayer = addTab("Player")
local pVis = addTab("Visuals")
local pAut = addTab("Automations")
local pTp = addTab("Teleport")
local pCfg = addTab("Configs")

pPlayer.section("Speed")
pPlayer.toggle("Speed", false, function(v)
    S.speed = v
    local _, hum = hrpOf()
    if v then
        if hum and hum.WalkSpeed ~= S.ws then ws0 = hum.WalkSpeed end
    elseif hum then
        hum.WalkSpeed = ws0 > 0 and ws0 or 16
    end
end)
pPlayer.slider("Walk Speed", 0, 100, 50, 1, function(v) S.ws = v end)
pPlayer.toggle("TP Walk", false, function(v) S.tpw = v end)
pPlayer.slider("TP Walk Speed", 0, 10, 2, 0.1, function(v) S.tpv = v end)

pPlayer.section("Movement")
pPlayer.toggle("Fly", false, setFly)
pPlayer.slider("Fly Speed", 0, 50, 30, 1, function(v) S.fs = v end)
pPlayer.toggle("Noclip", false, setNoclip)
pPlayer.toggle("Spin", false, function(v)
    S.spin = v
    local _, hum = hrpOf()
    if hum then hum.AutoRotate = not v end
end)
pPlayer.slider("Spin Speed", 0, 67, 20, 1, function(v) S.spinv = v end)

pPlayer.section("Abilities")
pPlayer.toggle("Infinite Ability Range", false, function(v)
    S.rng = v
    if v then
        rngAt = 0
    else
        pcall(rangeScan, true)
    end
end)

pVis.section("ESP")
pVis.toggle("ESP Items", false, function(v) S.esItem = v end)
pVis.toggle("ESP Twisteds", false, function(v) S.esTw = v end)
pVis.toggle("ESP Generators", false, function(v) S.esGen = v end)
pVis.toggle("ESP Players", false, function(v) S.esPl = v end)

pVis.section("Twisted Attacks")
pVis.toggle("Sprout Tendril ESP", false, function(v)
    S.esTend = v
    if v then hazStart() end
end)
pVis.toggle("Blot Hands ESP", false, function(v)
    S.esHand = v
    if v then hazStart() end
end)
pVis.toggle("Ichor Puddles ESP", false, function(v)
    S.esPud = v
    if v then hazStart() end
end)

pVis.section("ESP Settings")
pVis.toggle("Remove ESP Nametags", false, function(v) S.noTags = v end)
pVis.toggle("Only Item Nametag On Disable ESP Nametag", false, function(v) S.onlyItem = v end)
pVis.slider("ESP Text Size", 8, 60, 14, 1, function(v) S.size = v end)
pVis.slider("Highlight Limit", 0, 250, 250, 5, function(v) S.hlMax = v end)

pVis.section("ESP Items Blacklist")
pVis.multi("Blacklisted Items", ITEM_OPTIONS, function(selected)
    S.itemBlacklist = {}
    for _, friendly in ipairs(selected) do
        local internal = ITEM_LOOKUP[friendly]
        if internal then
            S.itemBlacklist[internal] = true
        end
    end
end)

pVis.section("Lighting")
pVis.toggle("Full Bright", false, function(v)
    S.fb = v
    if not v then brUndo() end
    refreshWorld()
end)
pVis.toggle("No Fog", false, function(v)
    S.nofog = v
    if not v then fogUndo() end
    refreshWorld()
end)

pVis.section("Screen")
pVis.toggle("No Pop-ups (Vee)", false, function(v)
    S.noPop = v
    if v then
        for _, h in pairs(hooked) do h.apply() end
        task.spawn(scanUi)
    end
end)
pVis.toggle("Anti Splotches", false, function(v)
    S.noSplot = v
    if v then
        for _, h in pairs(hooked) do h.apply() end
        task.spawn(scanUi)
    end
end)

pAut.section("Abilities")
pAut.toggle("Auto Use Ability", false, function(v) S.autoAbility = v end)

pAut.section("Machines")
pAut.toggle("Auto Calibration", false, function(v)
    S.autoCal = v
    genv.scinstant = v
end)

pAut.section("Elevator")
pAut.toggle("Auto TP Elevator", false, function(v) S.elev = v end)
pAut.multi("Auto TP Elevator Conditions", {"Instant", "Everyone At Elevator"}, function(selected)
    S.elevCond = {instant = false, everyone = false}
    for _, name in ipairs(selected) do
        if name == "Instant" then
            S.elevCond.instant = true
        elseif name == "Everyone At Elevator" then
            S.elevCond.everyone = true
        end
    end
end)

pAut.section("Items")
pAut.toggle("Auto Pick Up Research Capsules", false, function(v) S.autoCapsule = v end)

pTp.section("Generators")
pTp.button("TP To Generator", tpGen)
pTp.button("TP Above Generator", tpAboveGenerator)
pTp.toggle("Skip Machines With Twisted Near", true, function(v) S.tpNearOn = v end)
pTp.slider("Twisted Distance", 5, 150, 35, 1, function(v) S.tpNear = v end)
pTp.toggle("TP Generator Button", false, function(v) tpGui.Enabled = v end)
pTp.toggle("TP Above Generator Button", false, function(v) topGenGui.Enabled = v end)

pTp.section("Tools")
pTp.toggle("Teleport Tool", false, setTpTool)

local openGui = newScreen("TishaOpen", 25)
genv.TishaOpenBtn = openGui

local openBtn = mk("ImageButton", {
    Size = UDim2.fromOffset(52, 52), Position = UDim2.new(0, 12, 0.4, 0),
    BackgroundColor3 = WHITE, BorderSizePixel = 0, AutoButtonColor = false,
    Image = "rbxassetid://125702985812849", ScaleType = Enum.ScaleType.Crop, Active = true
}, openGui)
local openCorner = corner(openBtn, 0)
local openStroke = mk("UIStroke", {Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = WHITE}, openBtn)
local oGrad = gradient(openStroke, Color3.fromRGB(150, 215, 255), C.cyan, 45)
makeDraggable(openBtn, function()
    playClick()
    main.Visible = not main.Visible
end)

local function applyOpenShape(name)
    if name == "Circle" then
        openCorner.CornerRadius = UDim.new(0.5, 0)
    elseif name == "Rounded Square" then
        openCorner.CornerRadius = UDim.new(0, 14)
    else
        openCorner.CornerRadius = UDim.new(0, 0)
    end
end

pCfg.section("Open Button")
pCfg.choice("Button Shape", {"Square", "Circle", "Rounded Square"}, "Square", applyOpenShape)
pCfg.slider("Button Size", 36, 90, 52, 1, function(v)
    openBtn.Size = UDim2.fromOffset(v, v)
end)

selectTab(1)

loop(0.05, function()
    local r = (tick() * 45) % 360
    if main.Visible then mGrad.Rotation = r end
    oGrad.Rotation = r
end, "shine")

local isBig = false
dGreen.Activated:Connect(function()
    playClick()
    isBig = not isBig
    main.Size = isBig and BIG or NORMAL
    main.Position = UDim2.fromScale(0.5, 0.5)
end)
dYellow.Activated:Connect(function()
    playClick()
    main.Visible = false
end)

local function unload()
    playClick()

    S.esItem, S.esTw, S.esGen, S.esPl = false, false, false, false
    S.esTend, S.esHand, S.esPud = false, false, false
    S.elev, S.autoAbility, S.autoCapsule, S.autoCal = false, false, false, false
    S.noPop, S.noSplot = false, false
    genv.scinstant = false

    if S.fly then pcall(setFly, false) end
    if NoclipConnection then pcall(setNoclip, false) end
    if S.tpTool then pcall(setTpTool, false) end

    local _, hum = hrpOf()
    if hum then
        if S.speed then hum.WalkSpeed = ws0 > 0 and ws0 or 16 end
        hum.AutoRotate = true
    end
    S.speed, S.tpw, S.spin = false, false, false

    pcall(brUndo)
    pcall(fogUndo)
    pcall(function() RUN:UnbindFromRenderStep("TishaWorld") end)
    if S.rng then pcall(rangeScan, true) end
    S.rng = false

    seen = {}
    pcall(sweep)

    genv.TishaGen = (genv.TishaGen or 0) + 1
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end

    for _, g in ipairs({mainGui, openGui, notifyGui, tpGui, topGenGui}) do
        pcall(function() g:Destroy() end)
    end

    task.delay(2, function()
        pcall(function() clickSound:Destroy() end)
    end)
end

dRed.Activated:Connect(unload)

notify("Tisha's Cleaner GUI loaded")
