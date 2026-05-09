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

print("[KLOSO] Services Loaded.")

-- [[ THEME & SETTINGS ]]
local Theme = {
	Accent = Color3.fromRGB(160, 120, 255),
	Bg = Color3.fromRGB(12, 10, 18),
	Card = Color3.fromRGB(20, 17, 28),
	Border = Color3.fromRGB(45, 38, 60),
	Text = Color3.fromRGB(240, 240, 250),
	Sub = Color3.fromRGB(160, 155, 175)
}

local Settings = {
	Combat = {
		Aimbot = false,
		SilentAim = false,
		AutoShoot = false,
        TriggerBot = false,
        Crosshair = false,
		Smoothing = 0.5,
		FOV = 150,
		Prediction = false,
		PredFactor = 0.05,
		TeamCheck = true,
		WallCheck = false,
		Hitbox = false,
		HitboxSize = 12,
		TargetPart = "Head"
	},
	Visuals = {
		ESP = false,
		Boxes = true,
        Names = true,
        Health = true,
		Skeletons = false,
		Tracers = false,
		Distance = true,
		Fullbright = false
	},
	Movement = {
		Speed = false,
		SpeedVal = 50,
		Fly = false,
		FlySpeed = 80,
        Noclip = false,
        InfJump = false,
        Bhop = false
	},
	Menu = {
		ToggleKey = Enum.KeyCode.RightShift,
		AimbotKey = Enum.UserInputType.MouseButton2
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

local function Tw(o,g) 
	TweenService:Create(o, TweenInfo.new(0.25, Enum.EasingStyle.Quart), g):Play() 
end

local function Notify(t,tx) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=tx,Duration=3}) end) end

-- [[ DRAWING OBJECTS ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Color = Theme.Accent
FOVCircle.Visible = false

local CrosshairX = Drawing.new("Line")
CrosshairX.Thickness = 2
CrosshairX.Color = Theme.Accent
CrosshairX.Visible = false

local CrosshairY = Drawing.new("Line")
CrosshairY.Thickness = 2
CrosshairY.Color = Theme.Accent
CrosshairY.Visible = false

-- [[ COMBAT LOGIC ]]
local function IsVisible(p)
	if not Settings.Combat.WallCheck then return true end
	local char = p.Character
	if not char or not char:FindFirstChild(Settings.Combat.TargetPart) then return false end
	local part = char[Settings.Combat.TargetPart]
	local castPoints = {part.Position}
	local ignoreList = {LP.Character, Camera}
	local result = Camera:GetPartsObscuringTarget(castPoints, ignoreList)
	return #result == 0
end

local function IsTeammate(p)
	-- Standard Roblox Teams
	if p.Team ~= nil and LP.Team ~= nil and p.Team == LP.Team then return true end
	
	-- Custom Attribute Check
	local pTeam = p:GetAttribute("Team") or p:GetAttribute("TeamID")
	local lpTeam = LP:GetAttribute("Team") or LP:GetAttribute("TeamID")
	if pTeam and lpTeam and pTeam == lpTeam then return true end
	
	-- Custom Tag Check
	if p.Character and (p.Character:FindFirstChild("TeammateLabel") or p.Character:FindFirstChild("FriendlyIndicator")) then return true end
	
	-- Folder Check
	if p.Character and p.Character.Parent and LP.Character and LP.Character.Parent then
		if p.Character.Parent.Name:lower():find("team") and p.Character.Parent == LP.Character.Parent then
			return true
		end
	end
	
	-- Fallback: TeamColor
	if p.TeamColor == LP.TeamColor and not p.Neutral and p.TeamColor ~= BrickColor.new("Medium stone grey") then 
		return true 
	end
	
	return false
end

local function GetClosestPlayer()
	local closest, shortest = nil, Settings.Combat.FOV
	local mousePos = UIS:GetMouseLocation()
	
	for _, p in Players:GetPlayers() do
		if p ~= LP and p.Character then
			local char = p.Character
			local targetPart = char:FindFirstChild(Settings.Combat.TargetPart) or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
			if not targetPart then continue end
			
			local hum = char:FindFirstChild("Humanoid")
			if hum and hum.Health <= 0 then continue end
			
			if Settings.Combat.TeamCheck and IsTeammate(p) then continue end
			if not IsVisible(p) then continue end
			
			local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
			if onScreen then
				local dist = (mousePos - Vector2.new(pos.X, pos.Y)).Magnitude
				if dist < shortest then
					closest = p
					shortest = dist
				end
			end
		end
	end
	return closest
end

-- Silent Aim Hook
local oldNC
if hookmetamethod and getnamecallmethod and checkcaller then
    local success, err = pcall(function()
        oldNC = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if Settings.Combat.SilentAim and not checkcaller() and (method == "FindPartOnRayWithIgnoreList" or method == "Raycast") then
                local target = GetClosestPlayer()
                if target and target.Character and target.Character:FindFirstChild(Settings.Combat.TargetPart) then
                    local targetPart = target.Character[Settings.Combat.TargetPart]
                    local origin = Camera.CFrame.Position
                    local direction = (targetPart.Position - origin).Unit * 1000
                    
                    if method == "Raycast" then
                        args[2] = direction
                    else
                        args[1] = Ray.new(origin, direction)
                    end
                    return oldNC(self, unpack(args))
                end
            end
            return oldNC(self, ...)
        end)
    end)
end

-- TriggerBot logic
local lastTrigger = 0
RS.RenderStepped:Connect(function()
    if Settings.Combat.TriggerBot then
        local target = Mouse.Target
        if target and target.Parent then
            local p = Players:GetPlayerFromCharacter(target.Parent)
            if p and p ~= LP and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                if not Settings.Combat.TeamCheck or not IsTeammate(p) then
                    if tick() - lastTrigger > 0.1 then
                        if mouse1click then mouse1click() end
                        lastTrigger = tick()
                    end
                end
            end
        end
    end
end)

-- Main Aimbot & ESP Render Loop
local ESP_Objects = {}
local ESP_Skeletons = {}

local function GetESPObj(p)
    if not ESP_Objects[p] then
        ESP_Objects[p] = {
            Box = Drawing.new("Square"),
            BoxOutline = Drawing.new("Square"),
            Tracer = Drawing.new("Line"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Line"),
            HealthOutline = Drawing.new("Line")
        }
        
        local o = ESP_Objects[p]
        o.Box.Thickness = 1
        o.Box.Filled = false
        
        o.BoxOutline.Thickness = 3
        o.BoxOutline.Filled = false
        o.BoxOutline.Color = Color3.new(0, 0, 0)
        
        o.Tracer.Thickness = 1
        
        o.Name.Size = 14
        o.Name.Center = true
        o.Name.Outline = true
        
        o.Health.Thickness = 1
        o.HealthOutline.Thickness = 3
        o.HealthOutline.Color = Color3.new(0, 0, 0)
    end
    return ESP_Objects[p]
end

local function GetSkeleton(p)
    if not ESP_Skeletons[p] then
        ESP_Skeletons[p] = {}
        for i = 1, 14 do
            local l = Drawing.new("Line")
            l.Thickness = 1
            l.Visible = false
            table.insert(ESP_Skeletons[p], l)
        end
    end
    return ESP_Skeletons[p]
end

local function HideESP(p)
    if ESP_Objects[p] then
        for _, v in pairs(ESP_Objects[p]) do v.Visible = false end
    end
    if ESP_Skeletons[p] then
        for _, v in pairs(ESP_Skeletons[p]) do v.Visible = false end
    end
end

Players.PlayerRemoving:Connect(function(p)
    if ESP_Objects[p] then
        for _, v in pairs(ESP_Objects[p]) do v:Remove() end
        ESP_Objects[p] = nil
    end
    if ESP_Skeletons[p] then
        for _, v in pairs(ESP_Skeletons[p]) do v:Remove() end
        ESP_Skeletons[p] = nil
    end
end)

Connections.RenderLoop = RS.RenderStepped:Connect(function()
	-- Aimbot FOV
	if Settings.Combat.Aimbot or Settings.Combat.SilentAim then
		local mousePos = UIS:GetMouseLocation()
		FOVCircle.Visible = true
		FOVCircle.Position = mousePos
		FOVCircle.Radius = Settings.Combat.FOV
		FOVCircle.Color = Theme.Accent

		local target = GetClosestPlayer()
		
		-- Auto Shoot
		if Settings.Combat.AutoShoot and target then
			task.spawn(function()
				if mouse1click then mouse1click() end
			end)
		end

		-- Camera Aimbot
		if Settings.Combat.Aimbot and UIS:IsMouseButtonPressed(Settings.Menu.AimbotKey) then
			if target then
				local targetPart = target.Character[Settings.Combat.TargetPart]
				local aimPos = targetPart.Position
				
				if Settings.Combat.Prediction then
					local hrp = target.Character:FindFirstChild("HumanoidRootPart")
					if hrp then aimPos = aimPos + (hrp.Velocity * Settings.Combat.PredFactor) end
				end
				
				local smooth = math.clamp(1 - Settings.Combat.Smoothing, 0.01, 1)
				Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, aimPos), smooth)
			end
		end
	else
		FOVCircle.Visible = false
	end

    -- Crosshair
    if Settings.Combat.Crosshair then
        local center = Camera.ViewportSize / 2
        local s = 8
        CrosshairX.From = center - Vector2.new(s, 0)
        CrosshairX.To = center + Vector2.new(s, 0)
        CrosshairY.From = center - Vector2.new(0, s)
        CrosshairY.To = center + Vector2.new(0, s)
        CrosshairX.Color = Theme.Accent
        CrosshairY.Color = Theme.Accent
        CrosshairX.Visible = true
        CrosshairY.Visible = true
    else
        CrosshairX.Visible = false
        CrosshairY.Visible = false
    end

    -- ESP Loop
    for _, p in pairs(Players:GetPlayers()) do
        if p == LP then continue end
        
        local char = p.Character
        if not Settings.Visuals.ESP or not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then
            HideESP(p)
            continue
        end
        
        local hrp = char.HumanoidRootPart
        local hum = char.Humanoid
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        
        local obs = GetESPObj(p)
        
        if onScreen then
            local rootPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
            
            local boxHeight = math.abs(headPos.Y - rootPos.Y)
            local boxWidth = boxHeight * 0.6
            
            local color = IsTeammate(p) and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
            
            if Settings.Visuals.Boxes then
                obs.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                obs.BoxOutline.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y)
                obs.BoxOutline.Visible = true
                
                obs.Box.Size = Vector2.new(boxWidth, boxHeight)
                obs.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, headPos.Y)
                obs.Box.Color = color
                obs.Box.Visible = true
            else
                obs.Box.Visible = false
                obs.BoxOutline.Visible = false
            end
            
            if Settings.Visuals.Health then
                local healthScale = hum.Health / hum.MaxHealth
                obs.HealthOutline.From = Vector2.new(rootPos.X - boxWidth / 2 - 5, headPos.Y)
                obs.HealthOutline.To = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y)
                obs.HealthOutline.Visible = true
                
                obs.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y - (boxHeight * healthScale))
                obs.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 5, rootPos.Y)
                obs.Health.Color = Color3.fromHSV(math.clamp(healthScale * 0.3, 0.01, 0.3), 1, 1)
                obs.Health.Visible = true
            else
                obs.Health.Visible = false
                obs.HealthOutline.Visible = false
            end
            
            if Settings.Visuals.Names then
                local distStr = Settings.Visuals.Distance and string.format(" [%d]", (LP.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or ""
                obs.Name.Text = p.Name .. distStr
                obs.Name.Position = Vector2.new(rootPos.X, headPos.Y - 18)
                obs.Name.Color = Theme.Text
                obs.Name.Visible = true
            else
                obs.Name.Visible = false
            end
            
            if Settings.Visuals.Tracers then
                obs.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                obs.Tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                obs.Tracer.Color = color
                obs.Tracer.Visible = true
            else
                obs.Tracer.Visible = false
            end
            
            -- Skeletons
            if Settings.Visuals.Skeletons then
                local skel = GetSkeleton(p)
                local joints = {
                    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
                    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
                    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
                    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
                    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
                }
                for i, j in pairs(joints) do
                    local p1 = char:FindFirstChild(j[1])
                    local p2 = char:FindFirstChild(j[2])
                    if p1 and p2 then
                        local v1, o1 = Camera:WorldToViewportPoint(p1.Position)
                        local v2, o2 = Camera:WorldToViewportPoint(p2.Position)
                        if o1 and o2 then
                            skel[i].From = Vector2.new(v1.X, v1.Y)
                            skel[i].To = Vector2.new(v2.X, v2.Y)
                            skel[i].Color = color
                            skel[i].Visible = true
                        else
                            skel[i].Visible = false
                        end
                    else
                        skel[i].Visible = false
                    end
                end
            else
                if ESP_Skeletons[p] then for _, v in pairs(ESP_Skeletons[p]) do v.Visible = false end end
            end
            
        else
            HideESP(p)
        end
    end
end)

-- [[ MOVEMENT LOGIC ]]
local flyBV, flyBP
local function ToggleFly(on)
	Settings.Movement.Fly = on
	if on then
		local char = LP.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then return end
		local hrp = char.HumanoidRootPart
		flyBV = Create("BodyVelocity", {Parent = hrp, Velocity = Vector3.new(0, 0, 0), MaxForce = Vector3.new(math.huge, math.huge, math.huge)})
		flyBP = Create("BodyGyro", {Parent = hrp, D = 200, MaxTorque = Vector3.new(math.huge, math.huge, math.huge)})
		Connections.fly = RS.RenderStepped:Connect(function()
			local dir = Vector3.new(0, 0, 0)
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
			flyBV.Velocity = dir * Settings.Movement.FlySpeed
			flyBP.CFrame = Camera.CFrame
		end)
	else
		if flyBV then flyBV:Destroy() end
		if flyBP then flyBP:Destroy() end
		if Connections.fly then Connections.fly:Disconnect() end
	end
end

-- Inf Jump
Connections.Jump = UIS.JumpRequest:Connect(function()
    if Settings.Movement.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip & Bhop Loop
Connections.MoveLoop = RS.Stepped:Connect(function()
    if Settings.Movement.Noclip and LP.Character then
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then
                v.CanCollide = false
            end
        end
    end
    if Settings.Movement.Bhop and LP.Character and LP.Character:FindFirstChild("Humanoid") then
        if LP.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LP.Character.Humanoid.Jump = true
        end
    end
end)

-- [[ UI SYSTEM ]]
local oldGui = (gethui or function() return CoreGui end)():FindFirstChild("KlosoPro")
if oldGui then oldGui:Destroy() end

local Gui = Create("ScreenGui", {Parent = (gethui or function() return CoreGui end)(), Name = "KlosoPro"})
local Main = Create("Frame", {Parent = Gui, Size = UDim2.fromOffset(500, 350), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0})
Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
Create("UIStroke", {Parent = Main, Color = Theme.Border, Thickness = 1.5})

-- Sidebar
local Sidebar = Create("Frame", {Parent = Main, Size = UDim2.new(0, 120, 1, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
Create("UICorner", {Parent = Sidebar, CornerRadius = UDim.new(0, 8)})
Create("Frame", {Parent = Sidebar, Size = UDim2.new(0, 10, 1, 0), Position = UDim2.new(1, -10, 0, 0), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})

local Title = Create("TextLabel", {Parent = Sidebar, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "KLOSO PRO", TextColor3 = Theme.Accent, TextSize = 16, Font = Enum.Font.GothamBold})

-- Floating Toggle
local Floating = Create("TextButton", {Parent = Gui, Size = UDim2.fromOffset(40, 40), Position = UDim2.new(0, 10, 0.5, 0), BackgroundColor3 = Theme.Card, Text = "K", TextColor3 = Theme.Accent, TextSize = 20, Font = Enum.Font.GothamBold, Visible = false})
Create("UICorner", {Parent = Floating, CornerRadius = UDim.new(1, 0)})
Create("UIStroke", {Parent = Floating, Color = Theme.Accent, Thickness = 2})

local function ToggleUI(on)
	Main.Visible = on
	Floating.Visible = not on
end

Floating.MouseButton1Click:Connect(function() ToggleUI(true) end)

local TopButtons = Create("Frame", {Parent = Main, Size = UDim2.fromOffset(60, 25), Position = UDim2.new(1, -65, 0, 10), BackgroundTransparency = 1})
local UIList = Create("UIListLayout", {Parent = TopButtons, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5)})

local function CreateTopBtn(text, color, callback)
	local b = Create("TextButton", {Parent = TopButtons, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Card, Text = text, TextColor3 = color, TextSize = 14, Font = Enum.Font.GothamBold})
	Create("UICorner", {Parent = b, CornerRadius = UDim.new(0, 6)})
	Create("UIStroke", {Parent = b, Color = Theme.Border, Thickness = 1})
	b.MouseButton1Click:Connect(callback)
	
	b.MouseEnter:Connect(function() Tw(b, {BackgroundColor3 = Theme.Border}) end)
	b.MouseLeave:Connect(function() Tw(b, {BackgroundColor3 = Theme.Card}) end)
	return b
end

CreateTopBtn("-", Theme.Sub, function() ToggleUI(false) end)
CreateTopBtn("×", Color3.fromRGB(255, 80, 80), function() 
	Gui:Destroy() 
	FOVCircle.Visible = false
    CrosshairX.Visible = false
    CrosshairY.Visible = false
    for _, p in pairs(Players:GetPlayers()) do HideESP(p) end
	for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end
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
		page.Visible = true
		Tw(btn, {TextColor3 = Theme.Accent})
	end)
	
	if #Tabs == 0 then btn.TextColor3 = Theme.Accent end
	table.insert(Tabs, {Btn = btn, Page = page})
	return page
end

-- Components
local function Section(p, text)
	Create("TextLabel", {Parent = p, Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = text, TextColor3 = Theme.Accent, TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left})
end

local function Toggle(p, name, def, callback)
	local on = def
	local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
	Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	Create("TextLabel", {Parent = row, Size = UDim2.new(1, -50, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	
	local toggle = Create("Frame", {Parent = row, Size = UDim2.fromOffset(30, 16), Position = UDim2.new(1, -40, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = on and Theme.Accent or Theme.Border})
	Create("UICorner", {Parent = toggle, CornerRadius = UDim.new(1, 0)})
	local dot = Create("Frame", {Parent = toggle, Size = UDim2.fromOffset(12, 12), Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Text})
	Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})
	
	local btn = Create("TextButton", {Parent = row, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = ""})
	btn.MouseButton1Click:Connect(function()
		on = not on
		Tw(toggle, {BackgroundColor3 = on and Theme.Accent or Theme.Border})
		Tw(dot, {Position = on and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)})
		callback(on)
	end)
end

local function Slider(p, name, min, max, def, callback)
	local val = def
	local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 45), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
	Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	local label = Create("TextLabel", {Parent = row, Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 10, 0, 2), BackgroundTransparency = 1, Text = name .. ": " .. val, TextColor3 = Theme.Text, TextSize = 11, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	
	local track = Create("Frame", {Parent = row, Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 0, 30), BackgroundColor3 = Theme.Border})
	local fill = Create("Frame", {Parent = track, Size = UDim2.new(math.clamp((val-min)/(max-min), 0, 1), 0, 1, 0), BackgroundColor3 = Theme.Accent})
	
	local drag = false
	local function update(i)
		local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		val = math.floor((min + (rel * (max-min))) * 100) / 100
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = name .. ": " .. val
		callback(val)
	end
	
	local btn = Create("TextButton", {Parent = track, Size = UDim2.new(1, 0, 2, 0), Position = UDim2.new(0, 0, 0, -2), BackgroundTransparency = 1, Text = ""})
	btn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true update(i) end end)
	btn.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)
	Connections["Slider_"..name] = UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then update(i) end end)
end

local function Keybind(p, name, def, callback)
	local bound = def
	local binding = false
	local row = Create("Frame", {Parent = p, Size = UDim2.new(1, -5, 0, 35), BackgroundColor3 = Theme.Card, BorderSizePixel = 0})
	Create("UICorner", {Parent = row, CornerRadius = UDim.new(0, 6)})
	Create("TextLabel", {Parent = row, Size = UDim2.new(1, -100, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, TextSize = 12, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left})
	
	local btn = Create("TextButton", {Parent = row, Size = UDim2.fromOffset(80, 24), Position = UDim2.new(1, -90, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Border, Text = bound.Name, TextColor3 = Theme.Text, TextSize = 10, Font = Enum.Font.GothamBold})
	Create("UICorner", {Parent = btn, CornerRadius = UDim.new(0, 4)})
	
	btn.MouseButton1Click:Connect(function()
		binding = true
		btn.Text = "..."
		local conn
		conn = UIS.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then
				local k = (i.UserInputType == Enum.UserInputType.Keyboard) and i.KeyCode or i.UserInputType
				if k == Enum.KeyCode.Backspace then
					bound = Enum.KeyCode.Unknown
				else
					bound = k
				end
				btn.Text = bound.Name
				binding = false
				callback(bound)
				conn:Disconnect()
			end
		end)
	end)
end

-- Tabs
local CombatPage = CreateTab("Combat")
local VisualPage = CreateTab("Visuals")
local MovePage = CreateTab("Movement")
local PlayerPage = CreateTab("Player")
local SettingsPage = CreateTab("Settings")

-- Combat
Toggle(CombatPage, "Aimbot Master", false, function(v) Settings.Combat.Aimbot = v end)
Toggle(CombatPage, "Silent Aim", false, function(v) Settings.Combat.SilentAim = v end)
Toggle(CombatPage, "TriggerBot", false, function(v) Settings.Combat.TriggerBot = v end)
Toggle(CombatPage, "Auto Shoot", false, function(v) Settings.Combat.AutoShoot = v end)
Section(CombatPage, "Targeting")
Toggle(CombatPage, "Team Check", true, function(v) Settings.Combat.TeamCheck = v end)
Toggle(CombatPage, "Wall Check", false, function(v) Settings.Combat.WallCheck = v end)
Toggle(CombatPage, "Custom Crosshair", false, function(v) Settings.Combat.Crosshair = v end)
Slider(CombatPage, "FOV Radius", 30, 800, 150, function(v) Settings.Combat.FOV = v end)
Slider(CombatPage, "Smoothing", 0.01, 1, 0.5, function(v) Settings.Combat.Smoothing = v end)
Toggle(CombatPage, "Prediction", false, function(v) Settings.Combat.Prediction = v end)
Slider(CombatPage, "Pred Factor", 0.01, 0.5, 0.05, function(v) Settings.Combat.PredFactor = v end)
Toggle(CombatPage, "Hitbox Expander", false, function(v) Settings.Combat.Hitbox = v end)
Slider(CombatPage, "Hitbox Size", 2, 50, 12, function(v) Settings.Combat.HitboxSize = v end)

-- Visuals
Toggle(VisualPage, "Master ESP", false, function(v) Settings.Visuals.ESP = v end)
Toggle(VisualPage, "Box ESP", true, function(v) Settings.Visuals.Boxes = v end)
Toggle(VisualPage, "Name ESP", true, function(v) Settings.Visuals.Names = v end)
Toggle(VisualPage, "Health ESP", true, function(v) Settings.Visuals.Health = v end)
Toggle(VisualPage, "Skeleton ESP", false, function(v) Settings.Visuals.Skeletons = v end)
Toggle(VisualPage, "Tracers", false, function(v) Settings.Visuals.Tracers = v end)
Toggle(VisualPage, "Distance View", true, function(v) Settings.Visuals.Distance = v end)
Toggle(VisualPage, "World Fullbright", false, function(v) 
	Lighting.Brightness = v and 2 or 1 
	Lighting.ClockTime = v and 14 or 12
	Lighting.GlobalShadows = not v
end)

-- Movement
Toggle(MovePage, "Speed Manipulator", false, function(v) Settings.Movement.Speed = v end)
Slider(MovePage, "Speed Value", 16, 250, 50, function(v) Settings.Movement.SpeedVal = v end)
Toggle(MovePage, "Fly Mode", false, ToggleFly)
Slider(MovePage, "Fly Speed", 10, 300, 80, function(v) Settings.Movement.FlySpeed = v end)

-- Player
Toggle(PlayerPage, "Infinite Jump", false, function(v) Settings.Movement.InfJump = v end)
Toggle(PlayerPage, "Bunny Hop (Bhop)", false, function(v) Settings.Movement.Bhop = v end)
Toggle(PlayerPage, "Noclip", false, function(v) Settings.Movement.Noclip = v end)

-- Settings
Section(SettingsPage, "Menu Configuration")
Keybind(SettingsPage, "Menu Toggle", Enum.KeyCode.RightShift, function(v) Settings.Menu.ToggleKey = v end)
Keybind(SettingsPage, "Aimbot Key", Enum.UserInputType.MouseButton2, function(v) Settings.Menu.AimbotKey = v end)

Section(SettingsPage, "Colors & Theme")
Slider(SettingsPage, "Accent R", 0, 255, 160, function(v) 
	Theme.Accent = Color3.fromRGB(v, Theme.Accent.G * 255, Theme.Accent.B * 255) 
	Title.TextColor3 = Theme.Accent 
	FOVCircle.Color = Theme.Accent
    CrosshairX.Color = Theme.Accent
    CrosshairY.Color = Theme.Accent
end)
Slider(SettingsPage, "Accent G", 0, 255, 120, function(v) 
	Theme.Accent = Color3.fromRGB(Theme.Accent.R * 255, v, Theme.Accent.B * 255) 
	Title.TextColor3 = Theme.Accent 
	FOVCircle.Color = Theme.Accent
    CrosshairX.Color = Theme.Accent
    CrosshairY.Color = Theme.Accent
end)
Slider(SettingsPage, "Accent B", 0, 255, 255, function(v) 
	Theme.Accent = Color3.fromRGB(Theme.Accent.R * 255, Theme.Accent.G * 255, v) 
	Title.TextColor3 = Theme.Accent 
	FOVCircle.Color = Theme.Accent
    CrosshairX.Color = Theme.Accent
    CrosshairY.Color = Theme.Accent
end)

-- Keybinds & Dragging
do
	local dr,ds,sp
	Connections.UI_DragStart = Sidebar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=true ds=i.Position sp=Main.Position end end)
	Connections.UI_Dragging = UIS.InputChanged:Connect(function(i) if dr and i.UserInputType == Enum.UserInputType.MouseMovement then local d=i.Position-ds Tw(Main,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}) end end)
	Connections.UI_DragEnd = Sidebar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dr=false end end)
	Connections.UI_Toggle = UIS.InputBegan:Connect(function(i, g) if not g and i.KeyCode == Settings.Menu.ToggleKey then ToggleUI(not Main.Visible) end end)
end

-- Loops
task.spawn(function()
	while task.wait(0.5) do
		if Settings.Combat.Hitbox then
			for _,p in pairs(Players:GetPlayers()) do
				if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
					p.Character.HumanoidRootPart.Size = Vector3.new(Settings.Combat.HitboxSize, Settings.Combat.HitboxSize, Settings.Combat.HitboxSize)
					p.Character.HumanoidRootPart.Transparency = 0.7
				end
			end
		end
		if Settings.Movement.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then
			LP.Character.Humanoid.WalkSpeed = Settings.Movement.SpeedVal
		end
	end
end)

print("[KLOSO] Initialization Complete.")
Notify("KLOSO PRO", "Extended features loaded. UI ready.")
