local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local RunService = RS
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local me = Players.LocalPlayer
local LocalPlayer = me
local pg = me:WaitForChild("PlayerGui")

local IMG = "rbxassetid://125702985812849"

local genv = (getgenv and getgenv()) or {}
pcall(function() if genv.TishaUI then genv.TishaUI:Destroy() end end)
pcall(function() if genv.TishaConn then genv.TishaConn:Disconnect() end end)
pcall(function() if genv.TishaConn2 then genv.TishaConn2:Disconnect() end end)

local WHITE = Color3.fromRGB(255, 255, 255)
local BG = Color3.fromRGB(244, 250, 255)
local PANEL = Color3.fromRGB(226, 242, 255)
local BLUE = Color3.fromRGB(56, 160, 255)
local CYAN = Color3.fromRGB(0, 215, 245)
local TEXT = Color3.fromRGB(24, 52, 92)
local SUB = Color3.fromRGB(96, 134, 184)
local BLACK = Color3.new(0, 0, 0)
local PURPLE = Color3.fromRGB(170, 70, 255)
local MAGENTA = Color3.fromRGB(230, 50, 220)
local GRAY = Color3.fromRGB(150, 150, 165)
local ORANGE = Color3.fromRGB(255, 140, 0)
local RED = Color3.fromRGB(255, 40, 40)
local GREEN = Color3.fromRGB(60, 255, 120)
local YELLOW = Color3.fromRGB(255, 230, 0)
local ZERO = Vector3.new(0, 0, 0)
local TAG_UP = Vector3.new(0, 2.5, 0)

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

local function round(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
end

local function grad(o, a, b, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(a, b)
    g.Rotation = rot or 0
    g.Parent = o
    return g
end

local function stroke(o, th)
    local s = Instance.new("UIStroke")
    s.Thickness = th
    s.Color = WHITE
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = o
    return s
end

local function makeDraggable(btn)
    local dragging, dragInput, dragStart, startPos
    local state = {moved = false}
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            state.moved = false
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then state.moved = true end
            if state.moved then
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    return state
end

task.wait(5)

local gui = Instance.new("ScreenGui")
gui.Name = "TishaCleanerGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or pg end)
if not okParent or not gui.Parent then gui.Parent = pg end
genv.TishaUI = gui

local main = mk("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(470, 300),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    Active = true,
    Visible = true,
}, gui)
round(main, 16)
grad(main, Color3.fromRGB(252, 254, 255), Color3.fromRGB(210, 234, 255), 90)
local mStroke = stroke(main, 3)
local mGrad = grad(mStroke, CYAN, BLUE, 45)

local title = mk("TextLabel", {
    Size = UDim2.fromOffset(300, 34),
    Position = UDim2.fromOffset(18, 8),
    BackgroundTransparency = 1,
    Text = "TISHA'S CLEANER GUI",
    Font = Enum.Font.FredokaOne,
    TextSize = 19,
    TextColor3 = WHITE,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)
grad(title, CYAN, Color3.fromRGB(40, 120, 235), 0)

mk("TextLabel", {
    Size = UDim2.fromOffset(70, 34),
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -52, 0, 8),
    BackgroundTransparency = 1,
    Text = "V:1.0",
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = SUB,
    TextXAlignment = Enum.TextXAlignment.Right,
}, main)

local closeBtn = mk("TextButton", {
    Size = UDim2.fromOffset(34, 34),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(1, -6, 0, 6),
    BackgroundColor3 = WHITE,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextColor3 = BLUE,
    AutoButtonColor = true,
    BorderSizePixel = 0,
    ZIndex = 5,
}, main)
round(closeBtn, 17)
grad(stroke(closeBtn, 2.5), CYAN, BLUE, 45)

local dragZone = mk("Frame", {
    Size = UDim2.new(1, -60, 0, 44),
    BackgroundTransparency = 1,
}, main)

local activeDragInput, dragStart, startPos = nil, nil, nil
dragZone.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeDragInput then
        activeDragInput = input
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == activeDragInput then
        local d = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input == activeDragInput then
        activeDragInput = nil
    end
end)

local contentPages = {}
local function createPage()
    local page = mk("ScrollingFrame", {
        Position = UDim2.fromOffset(176, 96),
        Size = UDim2.new(1, -190, 1, -110),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        Visible = false,
    }, main)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page
    return page
end

for _, name in ipairs({"Player", "Visuals", "Automations", "Teleport"}) do
    contentPages[name] = createPage()
end

local tabsFrame = mk("Frame", {
    Position = UDim2.fromOffset(14, 52),
    Size = UDim2.fromOffset(136, 160),
    BackgroundTransparency = 1,
}, main)
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = tabsFrame
end

local currentSelectedTab = "Player"
local tabButtons = {}
local searchBox

local function filterElements()
    if not searchBox then return end
    local query = searchBox.Text:lower()
    local activePage = contentPages[currentSelectedTab]
    if not activePage then return end
    
    for _, child in ipairs(activePage:GetChildren()) do
        if child:IsA("GuiObject") and child.Name == "ItemContainer" then
            local textLabel = child:FindFirstChild("SearchText", true)
            if textLabel then
                local txt = textLabel.Text:lower()
                if query == "" or txt:find(query, 1, true) then
                    child.Visible = true
                else
                    child.Visible = false
                end
            end
        end
    end
end

local function selectTab(name)
    currentSelectedTab = name
    for n, b in pairs(tabButtons) do
        local on = (n == name)
        b.BackgroundColor3 = on and BLUE or WHITE
        b.TextColor3 = on and WHITE or TEXT
        if contentPages[n] then
            contentPages[n].Visible = on
        end
    end
    filterElements()
end

for i, name in ipairs({"Player", "Visuals", "Automations", "Teleport"}) do
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = WHITE,
        Text = name,
        Font = Enum.Font.FredokaOne,
        TextSize = 15,
        TextColor3 = TEXT,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        LayoutOrder = i,
    }, tabsFrame)
    round(b, 10)
    local s = Instance.new("UIStroke")
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(150, 205, 255)
    s.Parent = b
    tabButtons[name] = b
    b.Activated:Connect(function() selectTab(name) end)
end
selectTab("Player")

local sep = mk("Frame", {
    Position = UDim2.fromOffset(160, 52),
    Size = UDim2.new(0, 3, 1, -70),
    BackgroundColor3 = WHITE,
    BorderSizePixel = 0,
}, main)
round(sep, 2)
grad(sep, CYAN, BLUE, 90)

searchBox = mk("TextBox", {
    Position = UDim2.fromOffset(176, 52),
    Size = UDim2.new(1, -176 - 70, 0, 34),
    BackgroundColor3 = WHITE,
    Text = "",
    PlaceholderText = "Search",
    PlaceholderColor3 = SUB,
    Font = Enum.Font.GothamMedium,
    TextSize = 14,
    TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
}, main)
round(searchBox, 10)
mk("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, searchBox)
do
    local s = Instance.new("UIStroke")
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(150, 205, 255)
    s.Parent = searchBox
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterElements()
end)

local checkBtn = mk("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 52),
    Size = UDim2.fromOffset(40, 34),
    BackgroundColor3 = WHITE,
    Text = "✓",
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextColor3 = BLUE,
    AutoButtonColor = true,
    BorderSizePixel = 0,
}, main)
round(checkBtn, 10)
do
    local s = Instance.new("UIStroke")
    s.Thickness = 1.5
    s.Color = Color3.fromRGB(150, 205, 255)
    s.Parent = checkBtn
end

checkBtn.Activated:Connect(function()
    filterElements()
end)

local ComponentBuilder = {}

function ComponentBuilder:CreateToggle(tabName, config)
    local name = config.Name or "Toggle"
    local callback = config.Callback or function() end
    local currentValue = config.CurrentValue or false

    local wrapper = mk("Frame", {
        Name = "ItemContainer",
        Size = UDim2.new(1, -4, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, contentPages[tabName])

    local toggleBtn = mk("TextButton", {
        Name = "SearchText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = currentValue and BLUE or WHITE,
        Text = "  " .. name .. ": " .. (currentValue and "ON" or "OFF"),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = currentValue and WHITE or TEXT,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, wrapper)
    round(toggleBtn, 8)
    local strokeObj = Instance.new("UIStroke")
    strokeObj.Thickness = 1.5
    strokeObj.Color = Color3.fromRGB(150, 205, 255)
    strokeObj.Parent = toggleBtn

    -- se ja nasce ligado, avisa o callback agora
    if currentValue then pcall(callback, true) end

    toggleBtn.Activated:Connect(function()
        currentValue = not currentValue
        toggleBtn.Text = "  " .. name .. ": " .. (currentValue and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = currentValue and BLUE or WHITE
        toggleBtn.TextColor3 = currentValue and WHITE or TEXT
        pcall(function()
            callback(currentValue)
        end)
    end)
end

function ComponentBuilder:CreateButton(tabName, config)
    local name = config.Name or "Button"
    local callback = config.Callback or function() end

    local wrapper = mk("Frame", {
        Name = "ItemContainer",
        Size = UDim2.new(1, -4, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, contentPages[tabName])

    local btn = mk("TextButton", {
        Name = "SearchText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WHITE,
        Text = "  " .. name,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = TEXT,
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, wrapper)
    round(btn, 8)
    local strokeObj = Instance.new("UIStroke")
    strokeObj.Thickness = 1.5
    strokeObj.Color = Color3.fromRGB(150, 205, 255)
    strokeObj.Parent = btn

    btn.Activated:Connect(function()
        pcall(callback)
    end)
end

function ComponentBuilder:CreateSlider(tabName, config)
    local name = config.Name or "Slider"
    local min = config.Min or 1
    local max = config.Max or 50
    local default = config.Default or 25
    local step = config.Step or 1
    local callback = config.Callback or function() end

    local currentVal = default

    local wrapper = mk("Frame", {
        Name = "ItemContainer",
        Size = UDim2.new(1, -4, 0, 50),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, contentPages[tabName])

    local sliderFrame = mk("Frame", {
        Name = "SearchText",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
    }, wrapper)
    round(sliderFrame, 8)
    local strokeObj = Instance.new("UIStroke")
    strokeObj.Thickness = 1.5
    strokeObj.Color = Color3.fromRGB(150, 205, 255)
    strokeObj.Parent = sliderFrame

    local label = mk("TextLabel", {
        Size = UDim2.new(1, -12, 0, 20),
        Position = UDim2.fromOffset(6, 4),
        BackgroundTransparency = 1,
        Text = "  " .. name .. ": " .. currentVal,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = TEXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, sliderFrame)

    local bar = mk("TextButton", {
        Size = UDim2.new(1, -16, 0, 14),
        Position = UDim2.fromOffset(8, 28),
        BackgroundColor3 = PANEL,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
    }, sliderFrame)
    round(bar, 6)

    local fill = mk("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = BLUE,
        BorderSizePixel = 0,
    }, bar)
    round(fill, 6)

    local function formatVal(v)
        if step < 1 then
            return string.format("%.1f", v)
        else
            return tostring(math.floor(v + 0.5))
        end
    end

    local activeSliderInput = nil
    bar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeSliderInput then
            activeSliderInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == activeSliderInput then
            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local v = min + pos * (max - min)
            v = min + math.floor((v - min) / step + 0.5) * step
            currentVal = math.clamp(v, min, max)
            
            fill.Size = UDim2.new((currentVal - min) / (max - min), 0, 1, 0)
            label.Text = "  " .. name .. ": " .. formatVal(currentVal)
            pcall(function() callback(currentVal) end)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input == activeSliderInput then
            activeSliderInput = nil
        end
    end)
end

local S = {
    esItem = false, esTw = false, esGen = false, esPl = false, esTend = false, esHand = false, esPud = false,
    noTags = false, onlyItem = false, size = 14, itemBlacklist = {}
}

local camPos = ZERO
local torsoCache = {}
local itemCache = {}
local genCompleteTimes = {}

local function inWorld(i)
    return i.Parent ~= nil and i:IsDescendantOf(workspace)
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

local function torsoOf(x)
    local t = torsoCache[x]
    if t and t.Parent then return t end
    t = x:FindFirstChild("UpperTorso") or x:FindFirstChild("Torso")
        or x:FindFirstChild("HumanoidRootPart") or partOf(x)
    torsoCache[x] = t
    return t
end

local function plateOf(g)
    local valve = g:FindFirstChild("Valve", true)
    if valve then
        if valve:IsA("BasePart") then return valve end
        local bp = valve:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp end
    end
    local p = g:FindFirstChild("Top_Diamond_Plate", true)
    if p and not p:IsA("BasePart") then
        p = p:FindFirstChildWhichIsA("BasePart", true)
    end
    return p or partOf(g)
end

local function topPlateOf(g)
    local plate = g:FindFirstChild("Top_Diamond_Plate", true)
    if plate then
        if plate:IsA("BasePart") then return plate end
        local bp = plate:FindFirstChildWhichIsA("BasePart", true)
        if bp then return bp end
    end
    return plateOf(g)
end

local snap = {mon = {}, gen = {}, item = {}}
task.spawn(function()
    while true do
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
        task.wait(0.4)
    end
end)

local haz = {tend = {}, hand = {}, pud = {}}
local function inPlayer(v)
    local a = v
    while a and a ~= workspace do
        if a:IsA("Model") and Players:GetPlayerFromCharacter(a) then return true end
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

local function hazStart()
    task.spawn(function()
        for _, v in ipairs(workspace:GetDescendants()) do hazScan(v) end
    end)
    workspace.DescendantAdded:Connect(hazScan)
end

local reg = {item = {}, twist = {}, gen = {}, plr = {}, tend = {}, hand = {}, pud = {}}
local seen = {}
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
    g.Name = "PlaggESP"
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

    if not noHl then
        if not r.hl or not r.hl.Parent then
            local h = Instance.new("Highlight")
            h.Name = "PlaggHL"
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
                if set[a] then hidden = true break end
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
    return (tostring(it.Name):gsub("(%l)(%u)", "%1 %2"))
end

local function itemColor(name)
    local n = tostring(name):lower()
    if n:find("extraction", 1, true) then return PURPLE end
    if n:find("candy", 1, true) or n:find("pop", 1, true) or n:find("gumball", 1, true) or n:find("chocolate", 1, true) then return GREEN end
    if n:find("bandage", 1, true) or n:find("horn", 1, true) then return PURPLE end
    if n:find("kit", 1, true) then return ORANGE end
    return WHITE
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

local S_nofog = false
local S_fb = false

local function keeper()
    local store = setmetatable({}, {__mode = "k"})
    local function set(i, p, v)
        local t = store[i]
        if not t then t = {} store[i] = t end
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
local atmosAt = 0

local function worldLighting()
    if S_nofog then
        local now = tick()
        if now - atmosAt > 2 then
            atmosAt = now
            for _, a in ipairs(Lighting:GetChildren()) do
                if a:IsA("Atmosphere") then
                    fogSet(a, "Density", 0)
                    fogSet(a, "Offset", 0)
                    fogSet(a, "Haze", 0)
                    fogSet(a, "Glare", 0)
                end
            end
        end
        fogSet(Lighting, "FogEnd", 1e9)
        fogSet(Lighting, "FogStart", 1e9)
    end
    if S_fb then
        brSet(Lighting, "Brightness", 2)
        brSet(Lighting, "ClockTime", 14)
        brSet(Lighting, "GlobalShadows", false)
        brSet(Lighting, "Ambient", WHITE)
        brSet(Lighting, "OutdoorAmbient", WHITE)
    end
end

RS.RenderStepped:Connect(function(dt)
    local any = S.esTw or S.esGen or S.esPl or S.esTend or S.esHand or S.esPud or S.esItem
    if any then
        if S.esTend or S.esHand or S.esPud then
            local cam = workspace.CurrentCamera
            if cam then camPos = cam.CFrame.Position end
        end

        if S.esTw then
            for _, m in ipairs(snap.mon) do
                local part = torsoOf(m)
                if part then put("twist", m, part, (tostring(m.Name):gsub("Monster", "")), RED, WHITE, WHITE, RED, 0.5) end
            end
        end
        if S.esGen then
            local nowTick = tick()
            for _, g in ipairs(snap.gen) do
                local st = g:FindFirstChild("Stats")
                local completed = st and st:FindFirstChild("Completed") and st.Completed.Value == true
                
                if completed then
                    if not genCompleteTimes[g] then
                        genCompleteTimes[g] = nowTick + 1
                    end
                else
                    genCompleteTimes[g] = nil
                end

                if not completed or (genCompleteTimes[g] and nowTick < genCompleteTimes[g]) then
                    local part = topPlateOf(g)
                    if part then
                        local curAmt, reqAmt = 0, 0
                        if st then
                            local cVal = st:FindFirstChild("CurrentAmount")
                            local rVal = st:FindFirstChild("RequiredAmount")
                            if cVal and rVal then
                                curAmt, reqAmt = math.floor(cVal.Value or 0), math.floor(rVal.Value or 0)
                            end
                        end
                        local txt = "Generator\n(" .. curAmt .. "/" .. reqAmt .. ")"
                        put("gen", g, part, txt, GRAY, WHITE, WHITE, GRAY, 0.5, false)
                    end
                end
            end
        end
        if S.esPl then
            for _, p in ipairs(Players:GetPlayers()) do
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
            for _, e in ipairs(puds) do 
                put("pud", e[1], e[2], "Ichor Puddle", MAGENTA, BLACK, MAGENTA, MAGENTA, 0.5, false) 
            end
        end
        if S.esItem then
            local pc = pumpColor()
            for _, it in ipairs(snap.item) do
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
            end
        end
        sweep()
    end

    if S_nofog or S_fb then
        worldLighting()
    end
end)

local noclipEnabled = false
local noclipConns = {}
local noclipOrig = setmetatable({}, {__mode = "k"})

local noclipCleaned = setmetatable({}, {__mode = "k"})

-- desconecta os listeners do jogo nessa peca (so uma vez por peca)
local function cleanPart(part)
    if noclipCleaned[part] or not getconnections then return end
    noclipCleaned[part] = true
    local signals = {
        part:GetPropertyChangedSignal("CanQuery"),
        part:GetPropertyChangedSignal("CanCollide"),
        part:GetPropertyChangedSignal("CanTouch"),
        part.Changed,
    }
    for _, sig in ipairs(signals) do
        pcall(function()
            for _, conn in ipairs(getconnections(sig)) do conn:Disconnect() end
        end)
    end
end

local function noclipStep()
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipOrig[part] == nil then noclipOrig[part] = part.CanCollide end
            cleanPart(part)
            if part.CanCollide then part.CanCollide = false end
        end
    end
end

local function stopNoclip()
    for _, c in ipairs(noclipConns) do pcall(function() c:Disconnect() end) end
    noclipConns = {}
    for part, was in pairs(noclipOrig) do
        pcall(function()
            if part.Parent and part.Name ~= "HumanoidRootPart" then part.CanCollide = was end
        end)
    end
    noclipOrig = setmetatable({}, {__mode = "k"})
end

local function updateNoclip()
    stopNoclip()
    if noclipEnabled then
        -- roda em 3 momentos do frame, assim o jogo nao consegue reativar a colisao
        noclipConns[#noclipConns + 1] = RunService.Stepped:Connect(noclipStep)
        noclipConns[#noclipConns + 1] = RunService.Heartbeat:Connect(noclipStep)
        noclipConns[#noclipConns + 1] = RunService.RenderStepped:Connect(noclipStep)
    end
end

local function setNoclip(state)
    noclipEnabled = state
    updateNoclip()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    noclipOrig = setmetatable({}, {__mode = "k"})
    noclipCleaned = setmetatable({}, {__mode = "k"})
    if noclipEnabled then
        updateNoclip()
    end
end)

ComponentBuilder:CreateToggle("Player", {
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        setNoclip(Value)
    end,
})

local flyActive = false
local flySpeed = 25
local gravityOriginal = workspace.Gravity
if gravityOriginal < 1 then gravityOriginal = 196.2 end

local function setFly(state)
    flyActive = state
    if state then
        if workspace.Gravity > 0 then gravityOriginal = workspace.Gravity end
        workspace.Gravity = 0
    else
        workspace.Gravity = gravityOriginal
    end
end

local tpwActive = false
local tpwSpeed = 2

RunService.Heartbeat:Connect(function(dt)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    
    if not (hrp and humanoid) then return end
    
    if flyActive then
        if workspace.Gravity ~= 0 then workspace.Gravity = 0 end
        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local flat = Vector3.new(look.X, 0, look.Z).Unit
        local right = Vector3.new(-flat.Z, 0, flat.X)
        local dir = humanoid.MoveDirection
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
        if mv.Magnitude > 0.01 and flySpeed > 0 then
            hrp.CFrame = hrp.CFrame + mv.Unit * (flySpeed * dt)
        end
    end

    local dir = humanoid.MoveDirection
    if tpwActive and tpwSpeed > 0 and dir.Magnitude > 0.01 then
        hrp.CFrame = hrp.CFrame + dir * (tpwSpeed * 10 * dt)
    end
end)

ComponentBuilder:CreateToggle("Player", {
    Name = "Fly",
    CurrentValue = false,
    Callback = setFly,
})

ComponentBuilder:CreateSlider("Player", {
    Name = "Fly Speed",
    Min = 1,
    Max = 40,
    Default = 25,
    Callback = function(Value) flySpeed = Value end,
})

local speedActive = false
local walkSpeedValue = 25

RunService.Heartbeat:Connect(function()
    if not speedActive then return end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.WalkSpeed ~= walkSpeedValue then
        humanoid.WalkSpeed = walkSpeedValue
    end
end)

ComponentBuilder:CreateToggle("Player", {
    Name = "Speed",
    CurrentValue = false,
    Callback = function(Value)
        speedActive = Value
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and not Value then
            humanoid.WalkSpeed = 16
        end
    end,
})

ComponentBuilder:CreateSlider("Player", {
    Name = "Speed",
    Min = 1,
    Max = 50,
    Default = 25,
    Callback = function(Value)
        walkSpeedValue = Value
    end,
})

ComponentBuilder:CreateToggle("Player", {
    Name = "TP Walk",
    CurrentValue = false,
    Callback = function(v) tpwActive = v end,
})

ComponentBuilder:CreateSlider("Player", {
    Name = "TP Walk Speed",
    Min = 0,
    Max = 10,
    Default = 2,
    Step = 0.1,
    Callback = function(v) tpwSpeed = v end,
})

local rngOrig = {}
local function rangeScan(restore)
    if not (getconnections and getupvalues) then return end
    for _, conn in pairs(getconnections(RunService.RenderStepped)) do
        local func = conn.Function
        if func then
            local ok, upvals = pcall(getupvalues, func)
            if ok and upvals then
                for _, val in pairs(upvals) do
                    if typeof(val) == "table" and val.Name and (val.Name == "Shelly" or val.Name == "Sprout" or val.Name == "Cosmo" or val.Name == "Scraps" or val.Name == "Glisten") and val.PlayerRadius then
                        if restore then
                            local o = rngOrig[val]
                            if o then val.PlayerRadius = o rngOrig[val] = nil end
                        else
                            if rngOrig[val] == nil then rngOrig[val] = val.PlayerRadius end
                            val.PlayerRadius = 500
                        end
                    end
                end
            end
        end
    end
end

ComponentBuilder:CreateToggle("Player", {
    Name = "Infinite Ability Range",
    CurrentValue = false,
    Callback = function(v)
        if v then rangeScan(false) else pcall(rangeScan, true) end
    end,
})

ComponentBuilder:CreateToggle("Visuals", {Name = "ESP Items", CurrentValue = false, Callback = function(v) S.esItem = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "ESP Twisteds", CurrentValue = false, Callback = function(v) S.esTw = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "ESP Generators", CurrentValue = false, Callback = function(v) S.esGen = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "ESP Players", CurrentValue = false, Callback = function(v) S.esPl = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "Sprout Tendril ESP", CurrentValue = false, Callback = function(v) S.esTend = v if v then hazStart() end end})
ComponentBuilder:CreateToggle("Visuals", {Name = "Blot Hands ESP", CurrentValue = false, Callback = function(v) S.esHand = v if v then hazStart() end end})
ComponentBuilder:CreateToggle("Visuals", {Name = "Ichor Puddles ESP", CurrentValue = false, Callback = function(v) S.esPud = v if v then hazStart() end end})

ComponentBuilder:CreateToggle("Visuals", {Name = "Remove ESP Nametags", CurrentValue = false, Callback = function(v) S.noTags = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "Only Item Nametag On Disable", CurrentValue = false, Callback = function(v) S.onlyItem = v end})
ComponentBuilder:CreateSlider("Visuals", {Name = "ESP Text Size", Min = 8, Max = 60, Default = 14, Step = 1, Callback = function(v) S.size = v end})

ComponentBuilder:CreateToggle("Visuals", {Name = "Full Bright", CurrentValue = false, Callback = function(v) S_fb = v if not v then brUndo() end end})
ComponentBuilder:CreateToggle("Visuals", {Name = "No Fog", CurrentValue = false, Callback = function(v) S_nofog = v if not v then fogUndo() end end})
ComponentBuilder:CreateToggle("Visuals", {Name = "No Pop-ups (Vee)", CurrentValue = false, Callback = function(v) S.noPop = v end})
ComponentBuilder:CreateToggle("Visuals", {Name = "Anti Splotches", CurrentValue = false, Callback = function(v) S.noSplot = v end})

local autoAbilityEnabled = false
local autoCalibrationEnabled = false
local autoElevatorEnabled = false
local autoCapsulesEnabled = false

RunService.Heartbeat:Connect(function()
    if autoAbilityEnabled then
        pcall(function()
            local char = me.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local ev = ReplicatedStorage:FindFirstChild("Events")
            local ab = ev and ev:FindFirstChild("AbilityEvent")
            if char and hrp and ab then
                ab:InvokeServer(char, hrp.CFrame, false)
            end
        end)
    end
end)

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Use Ability",
    CurrentValue = false,
    Callback = function(v) autoAbilityEnabled = v end,
})

task.spawn(function()
    pcall(function()
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local event = events:FindFirstChild("SkillcheckUpdate")
            if event and getcallbackvalue then
                local ogcb = getcallbackvalue(event, "OnClientInvoke")
                if ogcb then
                    hookfunction(ogcb, function(...)
                        if autoCalibrationEnabled then return "supercomplete" end
                        return ogcb(...)
                    end)
                end
            end
        end
    end)
end)

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Calibration",
    CurrentValue = false,
    Callback = function(v) autoCalibrationEnabled = v end,
})

local function getElevatorPos()
    local e = workspace:FindFirstChild("Elevators")
    e = e and e:FindFirstChild("Elevator")
    if not e then return nil end
    local b = e:FindFirstChild("Base")
    if b and b:IsA("BasePart") then return b.Position + Vector3.new(0, 4, 0) end
    return e:GetPivot().Position + Vector3.new(0, 4, 0)
end

local function allGeneratorsDone()
    local info = workspace:FindFirstChild("Info")
    local c = info and info:FindFirstChild("GeneratorsCompleted") and info.GeneratorsCompleted.Value
    local r = info and info:FindFirstChild("RequiredGenerators") and info.RequiredGenerators.Value
    if type(c) == "number" and type(r) == "number" and r > 0 then return c >= r end
    return false
end

local function isInsideElevator(hrp)
    local e = workspace:FindFirstChild("Elevators")
    e = e and e:FindFirstChild("Elevator")
    if not e then return false end
    local ok, cf, size = pcall(function() return e:GetBoundingBox() end)
    if not ok or not cf then return false end
    local rel = cf:PointToObjectSpace(hrp.Position)
    return math.abs(rel.X) <= size.X / 2 + 2
        and math.abs(rel.Z) <= size.Z / 2 + 2
        and math.abs(rel.Y) <= size.Y / 2 + 8
end

-- teleporta pro elevador quando as maquinas acabam. Quando o player ja esta dentro,
-- desarma e NAO teleporta mais (mesmo se sair) ate o proximo andar.
local elevatorArmed = true
local elevatorNotDoneSince = nil
local elevatorFirstTp = nil

RunService.Stepped:Connect(function()
    if not autoElevatorEnabled then return end

    if not allGeneratorsDone() then
        -- andar novo: rearma depois de 3s sem as maquinas completas
        elevatorNotDoneSince = elevatorNotDoneSince or tick()
        if tick() - elevatorNotDoneSince >= 3 then
            elevatorArmed = true
            elevatorFirstTp = nil
        end
        return
    end
    elevatorNotDoneSince = nil
    if not elevatorArmed then return end

    local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if isInsideElevator(hrp) then
        elevatorArmed = false
        return
    end

    -- so tenta teleportar durante 1.5s apos o primeiro TP; depois disso desarma de vez
    if elevatorFirstTp and tick() - elevatorFirstTp > 1.5 then
        elevatorArmed = false
        return
    end

    local pos = getElevatorPos()
    if pos then
        elevatorFirstTp = elevatorFirstTp or tick()
        hrp.CFrame = CFrame.new(pos)
    end
end)

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto TP Elevator",
    CurrentValue = false,
    Callback = function(v)
        autoElevatorEnabled = v
        elevatorArmed = true
        elevatorNotDoneSince = nil
        elevatorFirstTp = nil
    end,
})

-- ===== Auto Pick Up (capsules, event currency, heals, extraction, tapes) =====
local savedPosition = nil
local originalGravity = 196.2
local collectingState = false

local PICK = {caps = false, event = false, heal = false, extr = false, tape = false}
local INVENTORY_MAX = 3 -- slots do inventario (ajuste se o jogo tiver outro limite)

local function inventoryFull()
    local n = 0
    local bp = me:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then n = n + 1 end
        end
    end
    local ch = me.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") then n = n + 1 end
        end
    end
    return n >= INVENTORY_MAX
end

local function hasAny(n, list)
    for _, w in ipairs(list) do
        if n:find(w, 1, true) then return true end
    end
    return false
end

-- devolve a categoria do item (ou nil). needsInv = vai pro inventario?
local function pickKind(it)
    local n = it.Name -- nomes exatos do jogo, com maiuscula
    if n:find("Fake", 1, true) or n:find("Stopwatch", 1, true) then return nil end

    if PICK.event and hasAny(n, {"Pumpkin", "Ornament", "Basket"}) then return "event", false end
    if PICK.heal and hasAny(n, {"Bandage", "HealthKit"}) then return "heal", true end
    if PICK.extr and hasAny(n, {"JumperCable", "SkillCheckCandy", "ExtractionSpeedCandy", "Instructions"}) then return "extr", true end
    if PICK.tape and n:find("Tape", 1, true) then return "tape", false end
    return nil
end

local function anyPickEnabled()
    return PICK.caps or PICK.event or PICK.heal or PICK.extr or PICK.tape
end

local function endCollecting(hrp)
    if collectingState then
        collectingState = false
        workspace.Gravity = originalGravity
        local h = hrp or (me.Character and me.Character:FindFirstChild("HumanoidRootPart"))
        if savedPosition and h then h.CFrame = savedPosition end
        savedPosition = nil
    end
end

task.spawn(function()
    while true do
        task.wait(0.05)
        if anyPickEnabled() then
            pcall(function()
                local char = me.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local room = workspace:FindFirstChild("CurrentRoom")
                if not (hrp and room) then return end

                local targets = {}

                -- capsulas (sempre pega, nao depende do inventario)
                if PICK.caps then
                    for _, m in ipairs(room:GetDescendants()) do
                        if m.Name:find("ResearchCapsule", 1, true) then
                            local part = partOf(m)
                            if part then
                                targets[#targets + 1] = {
                                    part = part,
                                    prompt = m:FindFirstChildWhichIsA("ProximityPrompt", true),
                                }
                            end
                        end
                    end
                end

                -- demais itens
                if PICK.event or PICK.heal or PICK.extr or PICK.tape then
                    local full = nil
                    for _, it in ipairs(snap.item) do
                        if it.Parent then
                            local kind, needsInv = pickKind(it)
                            if kind then
                                if needsInv then
                                    if full == nil then full = inventoryFull() end
                                end
                                if not (needsInv and full) then
                                    local part = partOf(it)
                                    local prompt = it:FindFirstChildWhichIsA("ProximityPrompt", true)
                                    if part and prompt and prompt.Enabled then
                                        targets[#targets + 1] = {part = part, prompt = prompt}
                                    end
                                end
                            end
                        end
                    end
                end

                if #targets > 0 then
                    if not collectingState then
                        collectingState = true
                        savedPosition = hrp.CFrame
                        if workspace.Gravity > 0 then
                            originalGravity = workspace.Gravity
                        end
                        workspace.Gravity = 0
                    end

                    local t = targets[1]
                    hrp.CFrame = CFrame.new(t.part.Position - Vector3.new(0, 7, 0))
                    task.wait(0.02)
                    if t.prompt and fireproximityprompt then
                        fireproximityprompt(t.prompt)
                    end
                else
                    endCollecting(hrp)
                end
            end)
        else
            endCollecting()
        end
    end
end)

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Pick Up Capsules",
    CurrentValue = false,
    Callback = function(v) PICK.caps = v autoCapsulesEnabled = v end,
})

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Pick Up Event Currency",
    CurrentValue = false,
    Callback = function(v) PICK.event = v end,
})

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Pick Up Heals",
    CurrentValue = false,
    Callback = function(v) PICK.heal = v end,
})

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Pick Up Extraction Items",
    CurrentValue = false,
    Callback = function(v) PICK.extr = v end,
})

ComponentBuilder:CreateToggle("Automations", {
    Name = "Auto Pick Up Tapes",
    CurrentValue = false,
    Callback = function(v) PICK.tape = v end,
})

local tpSkipMonster = true
local tpMonsterDist = 35
local tpFloatButtonActive = false
local tpFloatGui = nil

local tpAboveFloatButtonActive = false
local tpAboveFloatGui = nil

local function getClosestGen()
    local bestGen, shortestDist = nil, math.huge
    local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, g in ipairs(snap.gen) do
        local st = g:FindFirstChild("Stats")
        local completed = st and st:FindFirstChild("Completed") and st.Completed.Value == true
        if not completed then
            local part = plateOf(g)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    if tpSkipMonster then
                        local safe = true
                        for _, m in ipairs(snap.mon) do
                            local mPart = torsoOf(m)
                            if mPart and (mPart.Position - part.Position).Magnitude <= tpMonsterDist then
                                safe = false
                                break
                            end
                        end
                        if safe then
                            shortestDist = dist
                            bestGen = part
                        end
                    else
                        shortestDist = dist
                        bestGen = part
                    end
                end
            end
        end
    end
    return bestGen
end

local function getClosestTopPlate()
    local bestPart, shortestDist = nil, math.huge
    local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    for _, g in ipairs(snap.gen) do
        local st = g:FindFirstChild("Stats")
        local completed = st and st:FindFirstChild("Completed") and st.Completed.Value == true
        if not completed then
            local part = topPlateOf(g)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    if tpSkipMonster then
                        local safe = true
                        for _, m in ipairs(snap.mon) do
                            local mPart = torsoOf(m)
                            if mPart and (mPart.Position - part.Position).Magnitude <= tpMonsterDist then
                                safe = false
                                break
                            end
                        end
                        if safe then
                            shortestDist = dist
                            bestPart = part
                        end
                    else
                        shortestDist = dist
                        bestPart = part
                    end
                end
            end
        end
    end
    return bestPart
end

ComponentBuilder:CreateButton("Teleport", {
    Name = "TP To Generator",
    Callback = function()
        local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
        local targetPart = getClosestGen()
        if hrp and targetPart then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        end
    end,
})

ComponentBuilder:CreateButton("Teleport", {
    Name = "TP Above Gen",
    Callback = function()
        local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
        local targetPart = getClosestTopPlate()
        if hrp and targetPart then
            hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
        end
    end,
})

ComponentBuilder:CreateToggle("Teleport", {
    Name = "Skip Machines With Twisted Near",
    CurrentValue = true,
    Callback = function(v) tpSkipMonster = v end,
})

ComponentBuilder:CreateSlider("Teleport", {
    Name = "Twisted Distance",
    Min = 10,
    Max = 100,
    Default = 35,
    Step = 1,
    Callback = function(v) tpMonsterDist = v end,
})

ComponentBuilder:CreateToggle("Teleport", {
    Name = "TP Generator Button",
    CurrentValue = false,
    Callback = function(v)
        tpFloatButtonActive = v
        if v then
            if not tpFloatGui then
                tpFloatGui = mk("TextButton", {
                    Name = "TPGenButton",
                    Size = UDim2.fromOffset(110, 40),
                    Position = UDim2.new(0.5, -55, 0.85, 0),
                    BackgroundColor3 = BLUE,
                    Text = "TP Generator",
                    Font = Enum.Font.FredokaOne,
                    TextSize = 14,
                    TextColor3 = WHITE,
                    AutoButtonColor = true,
                    BorderSizePixel = 0,
                    ZIndex = 25,
                }, gui)
                round(tpFloatGui, 10)
                stroke(tpFloatGui, 2)
                local dragState = makeDraggable(tpFloatGui)
                
                tpFloatGui.Activated:Connect(function()
                    if dragState.moved then return end
                    local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
                    local targetPart = getClosestGen()
                    if hrp and targetPart then
                        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    end
                end)
            end
            tpFloatGui.Visible = true
        else
            if tpFloatGui then
                tpFloatGui.Visible = false
            end
        end
    end,
})

ComponentBuilder:CreateToggle("Teleport", {
    Name = "TP Above Gen Button",
    CurrentValue = false,
    Callback = function(v)
        tpAboveFloatButtonActive = v
        if v then
            if not tpAboveFloatGui then
                tpAboveFloatGui = mk("TextButton", {
                    Name = "TPAboveGenButton",
                    Size = UDim2.fromOffset(110, 40),
                    Position = UDim2.new(0.5, -55, 0.78, 0),
                    BackgroundColor3 = BLUE,
                    Text = "TP Above Gen",
                    Font = Enum.Font.FredokaOne,
                    TextSize = 13,
                    TextColor3 = WHITE,
                    AutoButtonColor = true,
                    BorderSizePixel = 0,
                    ZIndex = 25,
                }, gui)
                round(tpAboveFloatGui, 10)
                stroke(tpAboveFloatGui, 2)
                local dragState = makeDraggable(tpAboveFloatGui)
                
                tpAboveFloatGui.Activated:Connect(function()
                    if dragState.moved then return end
                    local hrp = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
                    local targetPart = getClosestTopPlate()
                    if hrp and targetPart then
                        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                    end
                end)
            end
            tpAboveFloatGui.Visible = true
        else
            if tpAboveFloatGui then
                tpAboveFloatGui.Visible = false
            end
        end
    end,
})

local footImg = mk("ImageLabel", {
    Position = UDim2.fromOffset(14, 222),
    Size = UDim2.fromOffset(64, 64),
    BackgroundColor3 = WHITE,
    Image = IMG,
    ScaleType = Enum.ScaleType.Fit,
    BorderSizePixel = 0,
}, main)
round(footImg, 8)
grad(stroke(footImg, 2.5), CYAN, BLUE, 45)

local openBtn = mk("ImageButton", {
    Name = "Open",
    Size = UDim2.fromOffset(54, 54),
    Position = UDim2.new(0, 12, 0.4, 0),
    BackgroundColor3 = BG,
    Image = IMG,
    ScaleType = Enum.ScaleType.Fit,
    AutoButtonColor = false,
    BorderSizePixel = 0,
    Active = true,
}, gui)
round(openBtn, 4)
local openStroke = stroke(openBtn, 3)
local oGrad = grad(openStroke, WHITE, Color3.fromRGB(160, 215, 255), 45)

do
    local activeOpenInput, moved = nil, false
    local sPos, sBtn
    openBtn.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not activeOpenInput then
            activeOpenInput = input
            moved = false
            sPos = input.Position
            sBtn = openBtn.Position
        end
    end)
    
    genv.TishaConn2 = UIS.InputChanged:Connect(function(input)
        if input == activeOpenInput then
            local d = input.Position - sPos
            if d.Magnitude > 8 then moved = true end
            if moved then
                openBtn.Position = UDim2.new(sBtn.X.Scale, sBtn.X.Offset + d.X,
                    sBtn.Y.Scale, sBtn.Y.Offset + d.Y)
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input == activeOpenInput then
            if not moved then main.Visible = not main.Visible end
            activeOpenInput = nil
        end
    end)
end

closeBtn.Activated:Connect(function()
    main.Visible = false
end)

genv.TishaConn = RS.Heartbeat:Connect(function()
    local r = (tick() * 45) % 360
    if main.Visible then mGrad.Rotation = r end
    oGrad.Rotation = r
end)

local notifFrame = mk("Frame", {
    Size = UDim2.fromOffset(260, 50),
    Position = UDim2.new(1, 20, 1, -70),
    BackgroundColor3 = BG,
    BorderSizePixel = 0,
    ZIndex = 10,
}, gui)
round(notifFrame, 12)
grad(notifFrame, Color3.fromRGB(252, 254, 255), Color3.fromRGB(210, 234, 255), 90)
local nStroke = stroke(notifFrame, 2)
grad(nStroke, CYAN, BLUE, 45)

local notifText = mk("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "tisha's cleaner gui loaded",
    Font = Enum.Font.FredokaOne,
    TextSize = 13,
    TextColor3 = TEXT,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
}, notifFrame)

local notifClose = mk("TextButton", {
    Size = UDim2.fromOffset(24, 24),
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    BackgroundColor3 = WHITE,
    Text = "X",
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextColor3 = BLUE,
    AutoButtonColor = true,
    BorderSizePixel = 0,
    ZIndex = 12,
}, notifFrame)
round(notifClose, 12)
grad(stroke(notifClose, 1.5), CYAN, BLUE, 45)

local function removeNotif()
    local tweenOut = TweenService:Create(notifFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, 20, 1, -70)
    })
    tweenOut:Play()
    tweenOut.Completed:Connect(function()
        pcall(function() notifFrame:Destroy() end)
    end)
end

notifClose.Activated:Connect(removeNotif)

task.spawn(function()
    task.wait(0.1)
    local tweenIn = TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -275, 1, -70)
    })
    tweenIn:Play()
    
    task.wait(7)
    removeNotif()
end)
