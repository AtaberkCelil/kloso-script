repeat task.wait() until game:IsLoaded()

-- [[ CORE SERVICES ]]
local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RS = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local WS = cloneref(game:GetService("Workspace"))
local HttpService = cloneref(game:GetService("HttpService"))
local StarterGui = cloneref(game:GetService("StarterGui"))

local LP = Players.LocalPlayer

print("[KLOSO NDS] Services Loaded.")

-- [[ THEME & SETTINGS ]]
local Theme = {
	Accent = Color3.fromRGB(40, 200, 120),
	Bg = Color3.fromRGB(10, 15, 12),
	Card = Color3.fromRGB(18, 25, 20),
	Border = Color3.fromRGB(30, 50, 40),
	Text = Color3.fromRGB(240, 250, 245),
	Sub = Color3.fromRGB(150, 180, 160)
}

local Settings = {
	Survival = {
        AutoSafeZone = false,
        NoFallDamage = false,
        WaterWalk = false
	},
	Movement = {
		Speed = false,
		SpeedVal = 16,
        Jump = false,
        JumpVal = 50,
        Noclip = false,
        InfJump = false,
        Fling = false
	},
	Menu = {
		ToggleKey = Enum.KeyCode.RightShift
	}
}

local Connections = {}

-- [[ CONFIG SYSTEM ]]
local ConfigName = "KlosoHub_NDS.json"
local function SaveConfig()
    pcall(function()
        if not isfolder("KlosoHub") then makefolder("KlosoHub") end
        local toSave = {
            Survival = { AutoSafeZone = Settings.Survival.AutoSafeZone, NoFallDamage = Settings.Survival.NoFallDamage, WaterWalk = Settings.Survival.WaterWalk },
            Movement = { Speed = Settings.Movement.Speed, SpeedVal = Settings.Movement.SpeedVal, Jump = Settings.Movement.Jump, JumpVal = Settings.Movement.JumpVal, Noclip = Settings.Movement.Noclip, InfJump = Settings.Movement.InfJump }
        }
        writefile("KlosoHub/" .. ConfigName, HttpService:JSONEncode(toSave))
        StarterGui:SetCore("SendNotification", {Title="KLOSO HUB", Text="Config Saved!", Duration=3})
    end)
end

local function LoadConfig()
    pcall(function()
        if isfile("KlosoHub/" .. ConfigName) then
            local decoded = HttpService:JSONDecode(readfile("KlosoHub/" .. ConfigName))
            if decoded.Survival then
                Settings.Survival.AutoSafeZone = decoded.Survival.AutoSafeZone or false
                Settings.Survival.NoFallDamage = decoded.Survival.NoFallDamage or false
                Settings.Survival.WaterWalk = decoded.Survival.WaterWalk or false
            end
            if decoded.Movement then
                Settings.Movement.Speed = decoded.Movement.Speed or false
                Settings.Movement.SpeedVal = decoded.Movement.SpeedVal or 16
                Settings.Movement.Jump = decoded.Movement.Jump or false
                Settings.Movement.JumpVal = decoded.Movement.JumpVal or 50
                Settings.Movement.Noclip = decoded.Movement.Noclip or false
                Settings.Movement.InfJump = decoded.Movement.InfJump or false
            end
            StarterGui:SetCore("SendNotification", {Title="KLOSO HUB", Text="Config Loaded! Reopen UI to see changes.", Duration=3})
        end
    end)
end

-- [[ UTILITIES ]]
local function Create(cl,p) 
	local i = Instance.new(cl) 
	for k,v in pairs(p) do if k~="Parent" then pcall(function() i[k]=v end) end end 
	if p.Parent then i.Parent=p.Parent end 
	return i 
end

local function Tw(o,g) TweenService:Create(o, TweenInfo.new(0.25, Enum.EasingStyle.Quart), g):Play() end

-- [[ SURVIVAL LOGIC ]]
local SafePlatform = nil
local WaterPlatform = nil

local function CreateSafePlatform()
    if SafePlatform then return end
    SafePlatform = Instance.new("Part")
    SafePlatform.Size = Vector3.new(50, 2, 50)
    SafePlatform.Position = Vector3.new(0, 1500, 0)
    SafePlatform.Anchored = true
    SafePlatform.Transparency = 0.5
    SafePlatform.BrickColor = BrickColor.new("Lime green")
    SafePlatform.Parent = WS
end

local function CreateWaterPlatform()
    if WaterPlatform then return end
    WaterPlatform = Instance.new("Part")
    WaterPlatform.Size = Vector3.new(10, 2, 10)
    WaterPlatform.Anchored = true
    WaterPlatform.Transparency = 1
    WaterPlatform.Parent = WS
end

Connections.SurvivalLoop = RS.Stepped:Connect(function()
    if not LP.Character then return end
    local char = LP.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if Settings.Survival.AutoSafeZone then
        CreateSafePlatform()
        if hrp and (hrp.Position.Y < 1400) then
            hrp.CFrame = SafePlatform.CFrame + Vector3.new(0, 5, 0)
        end
    else
        if SafePlatform then SafePlatform:Destroy() SafePlatform = nil end
    end
    
    if Settings.Survival.WaterWalk then
        CreateWaterPlatform()
        if hrp then
            if hrp.Position.Y < 15 and hrp.Position.Y > 0 then
                WaterPlatform.CFrame = CFrame.new(hrp.Position.X, 3.5, hrp.Position.Z)
                WaterPlatform.CanCollide = true
            else
                WaterPlatform.CanCollide = false
            end
        end
    else
        if WaterPlatform then WaterPlatform:Destroy() WaterPlatform = nil end
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(1)
    if Settings.Survival.NoFallDamage then
        local fallScript = char:FindFirstChild("FallDamage") or char:FindFirstChild("FallDamageScript")
        if fallScript then fallScript:Destroy() end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Settings.Survival.NoFallDamage and LP.Character then
            local fallScript = LP.Character:FindFirstChild("FallDamage") or LP.Character:FindFirstChild("FallDamageScript")
            if fallScript then fallScript:Destroy() end
        end
    end
end)

-- [[ MOVEMENT LOGIC ]]
Connections.MoveLoop = RS.Stepped:Connect(function()
    if Settings.Movement.Noclip and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end end
    end
end)

Connections.Jump = UIS.JumpRequest:Connect(function()
    if Settings.Movement.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then 
        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if LP.Character and LP.Character:FindFirstChild("Humanoid") then
            if Settings.Movement.Speed then
                LP.Character.Humanoid.WalkSpeed = Settings.Movement.SpeedVal
            end
            if Settings.Movement.Jump then
                LP.Character.Humanoid.JumpPower = Settings.Movement.JumpVal
                LP.Character.Humanoid.UseJumpPower = true
            end
        end
    end
end)

local FlingVel = nil
Connections.FlingLoop = RS.Stepped:Connect(function()
    if Settings.Movement.Fling and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LP.Character.HumanoidRootPart
        if not FlingVel then
            FlingVel = Instance.new("BodyAngularVelocity")
            FlingVel.AngularVelocity = Vector3.new(99999, 99999, 99999)
            FlingVel.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            FlingVel.P = 100000
            FlingVel.Parent = hrp
        else
            FlingVel.Parent = hrp
        end
        -- Keep character upright somewhat if needed, or just let them spin
    else
        if FlingVel then FlingVel:Destroy() FlingVel = nil end
    end
end)


-- [[ UI SYSTEM ]]
local oldGui = (gethui or function() return CoreGui end)():FindFirstChild("KlosoNDS")
if oldGui then oldGui:Destroy() end

local Gui = Create("ScreenGui", {Parent = (gethui or function() return CoreGui end)(), Name = "KlosoNDS"})
local Main = Create("Frame", {Parent = Gui, Size = UDim2.fromOffset(500, 350), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0})
Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)}) Create("UIStroke", {Parent = Main, Color = Theme.Border, Thickness = 1.5})

local Sidebar = Create("Frame", {Parent = Main, Size = UDim2.new(0, 120, 1, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 8)}) Create("Frame", {Parent = Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
local Title = Create("TextLabel", {Parent = Sidebar, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "KLOSO NDS", TextColor3 = Theme.Accent, TextSize = 16, Font = Enum.Font.GothamBold})

local Floating = Create("TextButton", {Parent = Gui, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 10, 0.5, 0), BackgroundColor3 = Theme.Card, Text = "K", TextColor3 = Theme.Accent, TextSize = 20, Font = Enum.Font.GothamBold, Visible = false})
Create("UICorner", {Parent = Floating, CornerRadius = UDim.new(1, 0)}) Create("UIStroke", {Parent = Floating, Color = Theme.Accent, Thickness = 2})

local function ToggleUI(on) Main.Visible = on Floating.Visible = not on end
Floating.MouseButton1Click:Connect(function() ToggleUI(true) end)

local TopButtons = Create("Frame", {Parent = Main, Size = UDim2.fromOffset(60, 25), Position = UDim2.new(1, -65, 0, 10), BackgroundTransparency = 1})
local UIList = Create("UIListLayout", {Parent = TopButtons, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5)})

local function CreateTopBtn(text, color, callback)
	local b = Create("TextButton", {Parent = TopButtons, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Card, Text = text, TextColor3 = color, TextSize = 14, Font = Enum.Font.GothamBold})
	Create("UICorner", {Parent = b, CornerRadius = UDim.new(0, 6)}) Create("UIStroke", {Parent = b, Color = Theme.Border, Thickness = 1})
	b.MouseButton1Click:Connect(callback) b.MouseEnter:Connect(function() Tw(b, {BackgroundColor3 = Theme.Border}) end) b.MouseLeave:Connect(function() Tw(b, {BackgroundColor3 = Theme.Card}) end)
	return b
end

local function CloseHub()
	Gui:Destroy() 
    if SafePlatform then SafePlatform:Destroy() end
    if WaterPlatform then WaterPlatform:Destroy() end
    for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end
end

CreateTopBtn("-", Theme.Sub, function() ToggleUI(false) end)
CreateTopBtn("×", Color3.fromRGB(255, 80, 80), CloseHub)

-- Explicit Sidebar Buttons
local MinimizeBtn = Create("TextButton", {Parent = Sidebar, Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 1, -75), BackgroundColor3 = Theme.Bg, Text = "Minimize", TextColor3 = Theme.Sub, TextSize = 12, Font = Enum.Font.GothamBold})
Create("UICorner", {Parent = MinimizeBtn, CornerRadius = UDim.new(0, 6)})
MinimizeBtn.MouseButton1Click:Connect(function() ToggleUI(false) end)

local CloseBtn = Create("TextButton", {Parent = Sidebar, Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 1, -40), BackgroundColor3 = Color3.fromRGB(200, 50, 50), Text = "Close Hub", TextColor3 = Color3.new(1,1,1), TextSize = 12, Font = Enum.Font.GothamBold})
Create("UICorner", {Parent = CloseBtn, CornerRadius = UDim.new(0, 6)})
CloseBtn.MouseButton1Click:Connect(CloseHub)

local TabContainer = Create("Frame", {Parent = Main, Size = UDim2.new(1, -130, 1, -20), Position = UDim2.new(0, 130, 0, 10), BackgroundTransparency = 1})
local Tabs = {}
local function CreateTab(name)
	local btn = Create("TextButton", {Parent = Sidebar, Size = UDim2.new(1, -10, 0, 35), Position = UDim2.new(0, 5, 0, 60 + (#Tabs * 40)), BackgroundColor3 = Theme.Bg, Text = name, TextColor3 = Theme.Sub, TextSize = 12, Font = Enum.Font.GothamSemibold})
	Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 6)})
	local page = Create("ScrollingFrame", {Parent = TabContainer, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = (#Tabs == 0), ScrollBarThickness = 0, CanvasSize = UDim2.new(0,0,3,0)})
	Create("UIListLayout", {Parent = page, Padding = UDim.new(0, 5)})
	btn.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do t.Page.Visible = false Tw(t.Btn, {TextColor3 = Theme.Sub}) end page.Visible = true Tw(btn, {TextColor3 = Theme.Accent}) end)
	if #Tabs == 0 then btn.TextColor3 = Theme.Accent end table.insert(Tabs, {Btn = btn, Page = page}) return page
end

local function Section(p, text) Create("TextLabel", {Parent = p, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left}) end
local function Button(p, text, callback)
    local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}) Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
    local btn = Create("TextButton", {Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamBold})
    btn.MouseButton1Click:Connect(callback)
end
local function Toggle(p, name, def, callback)
	local on = def local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}) Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	Create("TextLabel", {Parent = row, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	local toggle = Create("Frame", {Parent = row, Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = on and Theme.Accent or Theme.Border}) Create("UICorner", {Parent = toggle, CornerRadius = UDim.new(1, 0)})
	local dot = Create("Frame", {Parent = toggle, Size = UDim2.fromOffset(12, 12), Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Text}) Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})
	local btn = Create("TextButton", {Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
	btn.MouseButton1Click:Connect(function() on = not on Tw(toggle, {BackgroundColor3 = on and Theme.Accent or Theme.Border}) Tw(dot, {Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}) callback(on) end)
end
local function Slider(p, name, min, max, def, callback)
	local val = def local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 45), BackgroundColor3 = Theme.Card, BorderSizePixel = 0}) Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	local label = Create("TextLabel", {Parent = row, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = name .. ": " .. val, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	local track = Create("Frame", {Parent = row, Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = Theme.Border}) local fill = Create("Frame", {Parent = track, Size = UDim2.new(math.clamp((val-min)/(max-min), 0, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent})
	local drag = false
	local function update(i)
		local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1) val = math.floor((min + (rel * (max-min))) * 100) / 100
		fill.Size = UDim2.new(rel, 0, 1, 0) label.Text = name .. ": " .. val callback(val)
	end
	local btn = Create("TextButton", {Parent = track, Size = UDim2.new(1, 0, 2, 0), Position = UDim2.new(0, 0, 0, -2), BackgroundTransparency = 1, Text = ""})
	btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true update(i) end end)
	btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
	Connections["Slider_"..name] = UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
end

-- Tabs
local SurvivalPage = CreateTab("Survival")
local PlayerPage = CreateTab("Movement")
local ConfigPage = CreateTab("Config")

-- Survival Features
Section(SurvivalPage, "God Mods")
Toggle(SurvivalPage, "Auto Farm / Safe Zone", false, function(v) Settings.Survival.AutoSafeZone = v end)
Toggle(SurvivalPage, "Remove Fall Damage", false, function(v) Settings.Survival.NoFallDamage = v end)
Toggle(SurvivalPage, "Walk on Water", false, function(v) Settings.Survival.WaterWalk = v end)

-- Movement
Section(PlayerPage, "Character Mods")
Toggle(PlayerPage, "WalkSpeed Hack", false, function(v) Settings.Movement.Speed = v end)
Slider(PlayerPage, "Speed Value", 16, 150, 25, function(v) Settings.Movement.SpeedVal = v end)
Toggle(PlayerPage, "JumpPower Hack", false, function(v) Settings.Movement.Jump = v end)
Slider(PlayerPage, "Jump Value", 50, 300, 80, function(v) Settings.Movement.JumpVal = v end)
Toggle(PlayerPage, "Infinite Jump", false, function(v) Settings.Movement.InfJump = v end)
Toggle(PlayerPage, "Noclip", false, function(v) Settings.Movement.Noclip = v end)

Section(PlayerPage, "Admin Tools")
Toggle(PlayerPage, "Enable Fling (Spin)", false, function(v) Settings.Movement.Fling = v end)
Button(PlayerPage, "Load Infinite Yield", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

-- Config
Section(ConfigPage, "Configuration System")
Button(ConfigPage, "Save Settings to Workspace", SaveConfig)
Button(ConfigPage, "Load Settings from Workspace", LoadConfig)

-- Dragging
do
	local dr,ds,sp
	Connections.UI_DragStart = Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=true ds=i.Position sp=Main.Position end end)
	Connections.UI_Dragging = UIS.InputChanged:Connect(function(i) if dr and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-ds Tw(Main,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}) end end)
	Connections.UI_DragEnd = Sidebar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=false end end)
	Connections.UI_Toggle = UIS.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Settings.Menu.ToggleKey then ToggleUI(not Main.Visible) end end)
end

print("[KLOSO NDS] Initialization Complete.")
