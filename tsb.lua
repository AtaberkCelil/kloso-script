repeat task.wait() until game:IsLoaded()

-- [[ CORE SERVICES ]]
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RS = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local Lighting = cloneref(game:GetService("Lighting"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local WS = cloneref(game:GetService("Workspace"))
local CoreGui = cloneref(game:GetService("CoreGui"))

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()
local Camera = WS.CurrentCamera

print("[KLOSO TSB] Services Loaded.")

-- [[ THEME & SETTINGS ]]
local Theme = {
	Accent = Color3.fromRGB(255, 200, 50), -- Gold accent for TSB
	Bg = Color3.fromRGB(15, 15, 12),
	Card = Color3.fromRGB(25, 25, 20),
	Border = Color3.fromRGB(60, 60, 30),
	Text = Color3.fromRGB(250, 250, 240),
	Sub = Color3.fromRGB(180, 180, 150)
}

local Settings = {
	Combat = {
        KillAura = false,
        AutoBlock = false,
        AutoDash = false,
        AuraRange = 10,
		Hitbox = false,
		HitboxSize = 10,
		TeamCheck = false
	},
	Visuals = {
		ESP = false,
		Boxes = true,
        Names = true,
        Health = true,
		Distance = true
	},
	Movement = {
		Speed = false,
		SpeedVal = 25,
        Noclip = false,
        InfJump = false,
        Bhop = false
	},
	Menu = {
		ToggleKey = Enum.KeyCode.RightShift
	}
}

local Connections = {}

-- [[ UTILITIES ]]
local function Create(cl,p) 
	local i = Instance.new(cl) 
	for k,v in pairs(p) do if k~="Parent" then pcall(function() i[k]=v end) end end 
	if p.Parent then i.Parent=p.Parent end 
	return i 
end

local function Tw(o,g) TweenService:Create(o, TweenInfo.new(0.25, Enum.EasingStyle.Quart), g):Play() end

local function IsTeammate(p)
	if p.Team ~= nil and LP.Team ~= nil and p.Team == LP.Team then return true end
	return false
end

-- [[ TSB COMBAT LOGIC ]]
local function GetClosestToPlayer(range)
    local closest, shortest = nil, range
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local lpPos = LP.Character.HumanoidRootPart.Position
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
            if p.Character.Humanoid.Health > 0 then
                if Settings.Combat.TeamCheck and IsTeammate(p) then continue end
                local dist = (p.Character.HumanoidRootPart.Position - lpPos).Magnitude
                if dist < shortest then
                    closest = p
                    shortest = dist
                end
            end
        end
    end
    return closest
end

-- TSB Combat Loop
local lastPunch = 0
Connections.CombatLoop = RS.Stepped:Connect(function()
    -- Kill Aura (Auto Punch)
    if Settings.Combat.KillAura then
        local target = GetClosestToPlayer(Settings.Combat.AuraRange)
        if target then
            if tick() - lastPunch > 0.2 then
                -- Standard M1 simulator (often works by just clicking or firing virtual input)
                if mouse1click then mouse1click() end
                lastPunch = tick()
            end
        end
    end

    -- Hitbox Expander
    if Settings.Combat.Hitbox then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if Settings.Combat.TeamCheck and IsTeammate(p) then continue end
                p.Character.HumanoidRootPart.Size = Vector3.new(Settings.Combat.HitboxSize, Settings.Combat.HitboxSize, Settings.Combat.HitboxSize)
                p.Character.HumanoidRootPart.Transparency = 0.8
                p.Character.HumanoidRootPart.BrickColor = BrickColor.new("Bright yellow")
                p.Character.HumanoidRootPart.Material = Enum.Material.Neon
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
end)

-- [[ VISUALS LOGIC ]]
local ESP_Objects = {}
local function GetESPObj(p)
    if not ESP_Objects[p] then
        ESP_Objects[p] = {
            Box = Drawing.new("Square"), BoxOutline = Drawing.new("Square"),
            Name = Drawing.new("Text"), Health = Drawing.new("Line"), HealthOutline = Drawing.new("Line")
        }
        local o = ESP_Objects[p]
        o.Box.Thickness = 1 o.Box.Filled = false
        o.BoxOutline.Thickness = 3 o.BoxOutline.Filled = false o.BoxOutline.Color = Color3.new(0, 0, 0)
        o.Name.Size = 14 o.Name.Center = true o.Name.Outline = true
        o.Health.Thickness = 1 o.HealthOutline.Thickness = 3 o.HealthOutline.Color = Color3.new(0, 0, 0)
    end
    return ESP_Objects[p]
end

local function HideESP(p)
    if ESP_Objects[p] then for _, v in pairs(ESP_Objects[p]) do v.Visible = false end end
end

Players.PlayerRemoving:Connect(function(p)
    if ESP_Objects[p] then for _, v in pairs(ESP_Objects[p]) do v:Remove() end ESP_Objects[p] = nil end
end)

Connections.RenderLoop = RS.RenderStepped:Connect(function()
    -- ESP Loop
    for _, p in pairs(Players:GetPlayers()) do
        if p == LP then continue end
        local char = p.Character
        if not Settings.Visuals.ESP or not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            HideESP(p) continue
        end
        if Settings.Combat.TeamCheck and IsTeammate(p) then HideESP(p) continue end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local obs = GetESPObj(p)
        
        if onScreen then
            local rootPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
            local boxHeight = math.abs(headPos.Y - rootPos.Y)
            local boxWidth = boxHeight * 0.6
            local color = Theme.Accent
            
            if Settings.Visuals.Boxes then
                obs.BoxOutline.Size = Vector2.new(boxWidth, boxHeight) obs.BoxOutline.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y) obs.BoxOutline.Visible = true
                obs.Box.Size = Vector2.new(boxWidth, boxHeight) obs.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y) obs.Box.Color = color obs.Box.Visible = true
            else obs.Box.Visible = false obs.BoxOutline.Visible = false end
            
            if Settings.Visuals.Health then
                local healthScale = hum.Health / hum.MaxHealth
                obs.HealthOutline.From = Vector2.new(rootPos.X - boxWidth / 2 - 5, headPos.Y) obs.HealthOutline.To = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y) obs.HealthOutline.Visible = true
                obs.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y - (boxHeight * healthScale)) obs.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y)
                obs.Health.Color = Color3.fromHSV(math.clamp(healthScale * 0.3, 0.01, 0.3), 1, 1) obs.Health.Visible = true
            else obs.Health.Visible = false obs.HealthOutline.Visible = false end
            
            if Settings.Visuals.Names then
                local distStr = Settings.Visuals.Distance and string.format(" [%d]", (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or ""
                obs.Name.Text = p.Name .. distStr obs.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18) obs.Name.Color = Theme.Text obs.Name.Visible = true
            else obs.Name.Visible = false end
        else HideESP(p) end
    end
end)

-- Inf Jump
Connections.Jump = UIS.JumpRequest:Connect(function()
    if Settings.Movement.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Noclip & Bhop
Connections.MoveLoop = RS.Stepped:Connect(function()
    if Settings.Movement.Noclip and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
    end
    if Settings.Movement.Bhop and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        if LP.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then LP.Character.Humanoid.Jump = true end
    end
end)

-- Speed
task.spawn(function()
    while task.wait(0.5) do
        if Settings.Movement.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
			LP.Character.Humanoid.WalkSpeed = Settings.Movement.SpeedVal
		end
    end
end)

-- [[ UI SYSTEM ]]
local oldGui = (gethui or function() return CoreGui end)():FindFirstChild("KlosoTSB")
if oldGui then oldGui:Destroy() end

local Gui = Create("ScreenGui", {Parent = (gethui or function() return CoreGui end)(), Name = "KlosoTSB"})
local Main = Create("Frame", {Parent = Gui, Size = UDim2.fromOffset(500, 350), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0})
Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
Create("UIStroke", {Parent = Main, Color = Theme.Border, Thickness = 1.5})

-- Sidebar
local Sidebar = Create("Frame", {Parent = Main, Size = UDim2.new(0, 120, 1, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 8)})
Create("Frame", {Parent = Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})

local Title = Create("TextLabel", {Parent = Sidebar, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "KLOSO TSB", TextColor3 = Theme.Accent, TextSize = 16, Font = Enum.Font.GothamBold})

local Floating = Create("TextButton", {Parent = Gui, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 10, 0.5, 0), BackgroundColor3 = Theme.Card, Text = "K", TextColor3 = Theme.Accent, TextSize = 20, Font = Enum.Font.GothamBold, Visible = false})
Create("UICorner", {Parent = Floating, CornerRadius = UDim.new(1, 0)})
Create("UIStroke", {Parent = Floating, Color = Theme.Accent, Thickness = 2})

local function ToggleUI(on) Main.Visible = on Floating.Visible = not on end
Floating.MouseButton1Click:Connect(function() ToggleUI(true) end)

local TopButtons = Create("Frame", {Parent = Main, Size = UDim2.fromOffset(60, 25), Position = UDim2.new(1, -65, 0, 10), BackgroundTransparency = 1})
local UIList = Create("UIListLayout", {Parent = TopButtons, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5)})

local function CreateTopBtn(text, color, callback)
	local b = Create("TextButton", {Parent = TopButtons, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Card, Text = text, TextColor3 = color, TextSize = 14, Font = Enum.Font.GothamBold})
	Create("UICorner", {Parent = b, CornerRadius = UDim.new(0, 6)}) Create("UIStroke", {Parent = b, Color = Theme.Border, Thickness = 1})
	b.MouseButton1Click:Connect(callback)
	b.MouseEnter:Connect(function() Tw(b, {BackgroundColor3 = Theme.Border}) end)
	b.MouseLeave:Connect(function() Tw(b, {BackgroundColor3 = Theme.Card}) end)
	return b
end

CreateTopBtn("-", Theme.Sub, function() ToggleUI(false) end)
CreateTopBtn("×", Color3.fromRGB(255, 80, 80), function() 
	Gui:Destroy() for _, p in pairs(Players:GetPlayers()) do HideESP(p) end for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end
end)

local TabContainer = Create("Frame", {Parent = Main, Size = UDim2.new(1, -130, 1, -20), Position = UDim2.new(0, 130, 0, 10), BackgroundTransparency = 1})

-- Tab Management
local Tabs = {}
local function CreateTab(name)
	local btn = Create("TextButton", {Parent = Sidebar, Size = UDim2.new(1, -10, 0, 35), Position = UDim2.new(0, 5, 0, 60 + (#Tabs * 40)), BackgroundColor3 = Theme.Bg, Text = name, TextColor3 = Theme.Sub, TextSize = 12, Font = Enum.Font.GothamSemibold})
	Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
	local page = Create("ScrollingFrame", {Parent = TabContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = (#Tabs == 0), ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,3,0)})
	Create("UIListLayout", {Parent = page, Padding = UDim.new(0, 5)})
	
	btn.MouseButton1Click:Connect(function()
		for _,t in pairs(Tabs) do t.Page.Visible = false Tw(t.Btn, {TextColor3 = Theme.Sub}) end
		page.Visible = true Tw(btn, {TextColor3 = Theme.Accent})
	end)
	
	if #Tabs == 0 then btn.TextColor3 = Theme.Accent end
	table.insert(Tabs, {Btn = btn, Page = page}) return page
end

-- Components
local function Section(p, text) Create("TextLabel", {Parent = p, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}) end

local function Toggle(p, name, def, callback)
	local on = def
	local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}) Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	Create("TextLabel", {Parent = row, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	
	local toggle = Create("Frame", {Parent = row, Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = on and Theme.Accent or Theme.Border}) Create("UICorner", {Parent = toggle, CornerRadius = UDim.new(1, 0)})
	local dot = Create("Frame", {Parent = toggle, Size = UDim2.fromOffset(12, 12), Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Text}) Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})
	
	local btn = Create("TextButton", {Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
	btn.MouseButton1Click:Connect(function()
		on = not on Tw(toggle, {BackgroundColor3 = on and Theme.Accent or Theme.Border}) Tw(dot, {Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}) callback(on)
	end)
end

local function Slider(p, name, min, max, def, callback)
	local val = def
	local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 45), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}) Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	local label = Create("TextLabel", {Parent = row, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = name .. ": " .. val, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	local track = Create("Frame", {Parent = row, Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = Theme.Border})
	local fill = Create("Frame", {Parent = track, Size = UDim2.new(math.clamp((val-min)/(max-min), 0, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent})
	
	local drag = false
	local function update(i)
		local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		val = math.floor((min + (rel * (max-min))) * 100) / 100
		fill.Size = UDim2.new(rel, 0, 1, 0) label.Text = name .. ": " .. val callback(val)
	end
	
	local btn = Create("TextButton", {Parent = track, Size = UDim2.new(1, 0, 2, 0), Position = UDim2.new(0, 0, 0, -2), BackgroundTransparency = 1, Text = ""})
	btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true update(i) end end)
	btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
	Connections["Slider_"..name] = UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
end

-- Tabs
local CombatPage = CreateTab("Combat")
local VisualPage = CreateTab("Visuals")
local PlayerPage = CreateTab("Player")

-- Combat
Section(CombatPage, "Auto Fighting")
Toggle(CombatPage, "Kill Aura (Auto M1)", false, function(v) Settings.Combat.KillAura = v end)
Slider(CombatPage, "Aura Range", 5, 25, 10, function(v) Settings.Combat.AuraRange = v end)

Section(CombatPage, "Hitbox Manipulation")
Toggle(CombatPage, "Hitbox Expander", false, function(v) Settings.Combat.Hitbox = v end)
Slider(CombatPage, "Hitbox Size", 2, 50, 10, function(v) Settings.Combat.HitboxSize = v end)
Toggle(CombatPage, "Team Check", false, function(v) Settings.Combat.TeamCheck = v end)

-- Visuals
Toggle(VisualPage, "Master ESP", false, function(v) Settings.Visuals.ESP = v end)
Toggle(VisualPage, "Box ESP", true, function(v) Settings.Visuals.Boxes = v end)
Toggle(VisualPage, "Name ESP", true, function(v) Settings.Visuals.Names = v end)
Toggle(VisualPage, "Health ESP", true, function(v) Settings.Visuals.Health = v end)

-- Player
Toggle(PlayerPage, "Speed Modifier", false, function(v) Settings.Movement.Speed = v end)
Slider(PlayerPage, "Speed Value", 16, 250, 25, function(v) Settings.Movement.SpeedVal = v end)
Toggle(PlayerPage, "Infinite Jump", false, function(v) Settings.Movement.InfJump = v end)
Toggle(PlayerPage, "Bunny Hop (Bhop)", false, function(v) Settings.Movement.Bhop = v end)
Toggle(PlayerPage, "Noclip", false, function(v) Settings.Movement.Noclip = v end)

-- Dragging & Toggles
do
	local dr,ds,sp
	Connections.UI_DragStart = Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=true ds=i.Position sp=Main.Position end end)
	Connections.UI_Dragging = UIS.InputChanged:Connect(function(i) if dr and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-ds Tw(Main,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}) end end)
	Connections.UI_DragEnd = Sidebar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=false end end)
	Connections.UI_Toggle = UIS.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Settings.Menu.ToggleKey then ToggleUI(not Main.Visible) end end)
end

print("[KLOSO TSB] Initialization Complete.")
