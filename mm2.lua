repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RS = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local WS = cloneref(game:GetService("Workspace"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local Connections = {}

local Theme = {Accent=Color3.fromRGB(200,50,80),Bg=Color3.fromRGB(14,10,12),Card=Color3.fromRGB(24,18,22),Border=Color3.fromRGB(60,30,40),Text=Color3.fromRGB(250,240,245),Sub=Color3.fromRGB(180,160,170)}

local HttpService = cloneref(game:GetService("HttpService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local Lighting = cloneref(game:GetService("Lighting"))

local Settings = {
    MurdererESP = true, SheriffESP = true,
    PlayerESP = false, CoinESP = false,
    AutoCoin = false, FlingMurderer = false, FlingAll = false,
    GrabGun = false, XRay = false, MurdAlert = false, Fullbright = false,
    Speed = false, SpeedVal = 25,
    Noclip = false, InfJump = false, Fly = false, FlySpeed = 50,
    Waypoints = {
        Lobby = {0, 50, 0}, -- Placeholder, will add real lobby pos
        Map = {0, 100, 0}
    }
}

local ConfigName = "KlosoHub_MM2.json"
local function SaveConfig()
    pcall(function()
        if not isfolder("KlosoHub") then makefolder("KlosoHub") end
        writefile("KlosoHub/"..ConfigName, HttpService:JSONEncode(Settings))
        StarterGui:SetCore("SendNotification",{Title="KLOSO",Text="Config Saved!",Duration=2})
    end)
end
local function LoadConfig()
    pcall(function()
        if isfile("KlosoHub/"..ConfigName) then
            local d = HttpService:JSONDecode(readfile("KlosoHub/"..ConfigName))
            for k,v in pairs(d) do Settings[k]=v end
            StarterGui:SetCore("SendNotification",{Title="KLOSO",Text="Config Loaded!",Duration=2})
        end
    end)
end
local function SetFullbright(on)
    if on then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=100000 Lighting.GlobalShadows=false
    else Lighting.Brightness=1 Lighting.GlobalShadows=true end
end

local function Create(cl,p) local i=Instance.new(cl) for k,v in pairs(p) do if k~="Parent" then pcall(function() i[k]=v end) end end if p.Parent then i.Parent=p.Parent end return i end
local function Tw(o,g) TweenService:Create(o, TweenInfo.new(0.25, Enum.EasingStyle.Quart), g):Play() end

-- Role Detection
local function GetRole(player)
    if player and player:FindFirstChild("Backpack") then
        for _,tool in pairs(player.Backpack:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" or tool.Name:lower():find("knife") then return "Murderer" end
                if tool.Name == "Gun" or tool.Name == "Revolver" or tool.Name:lower():find("gun") then return "Sheriff" end
            end
        end
    end
    if player.Character then
        for _,tool in pairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name == "Knife" or tool.Name:lower():find("knife") then return "Murderer" end
                if tool.Name == "Gun" or tool.Name == "Revolver" or tool.Name:lower():find("gun") then return "Sheriff" end
            end
        end
    end
    return "Innocent"
end

-- ESP
local ESP_Objects = {}
local function GetESPObj(p)
    if not ESP_Objects[p] then
        ESP_Objects[p] = {Box=Drawing.new("Square"),BoxO=Drawing.new("Square"),Name=Drawing.new("Text"),Role=Drawing.new("Text")}
        local o=ESP_Objects[p] o.Box.Thickness=1 o.Box.Filled=false o.BoxO.Thickness=3 o.BoxO.Filled=false o.BoxO.Color=Color3.new(0,0,0)
        o.Name.Size=14 o.Name.Center=true o.Name.Outline=true o.Role.Size=12 o.Role.Center=true o.Role.Outline=true
    end return ESP_Objects[p]
end
local function HideESP(p) if ESP_Objects[p] then for _,v in pairs(ESP_Objects[p]) do v.Visible=false end end end
Players.PlayerRemoving:Connect(function(p) if ESP_Objects[p] then for _,v in pairs(ESP_Objects[p]) do v:Remove() end ESP_Objects[p]=nil end end)

Connections.RenderLoop = RS.RenderStepped:Connect(function()
    for _,p in pairs(Players:GetPlayers()) do
        if p==LP then continue end
        local char=p.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health<=0 then HideESP(p) continue end
        local role = GetRole(p)
        local showThis = false
        if role == "Murderer" and Settings.MurdererESP then showThis = true end
        if role == "Sheriff" and Settings.SheriffESP then showThis = true end
        if Settings.PlayerESP then showThis = true end
        if not showThis then HideESP(p) continue end
        
        local hrp=char.HumanoidRootPart
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position) local obs=GetESPObj(p)
        if onScreen then
            local rp=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
            local hp2=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,2.5,0))
            local bH=math.abs(hp2.Y-rp.Y) local bW=bH*0.6
            local color = role=="Murderer" and Color3.fromRGB(255,0,0) or role=="Sheriff" and Color3.fromRGB(0,100,255) or Color3.fromRGB(0,200,0)
            obs.BoxO.Size=Vector2.new(bW,bH) obs.BoxO.Position=Vector2.new(rp.X-bW/2,hp2.Y) obs.BoxO.Visible=true
            obs.Box.Size=Vector2.new(bW,bH) obs.Box.Position=Vector2.new(rp.X-bW/2,hp2.Y) obs.Box.Color=color obs.Box.Visible=true
            obs.Name.Text=p.Name obs.Name.Position=Vector2.new(rp.X,hp2.Y-18) obs.Name.Color=Theme.Text obs.Name.Visible=true
            obs.Role.Text="["..role.."]" obs.Role.Position=Vector2.new(rp.X,rp.Y+5) obs.Role.Color=color obs.Role.Visible=true
        else HideESP(p) end
    end
end)

-- Coin ESP via Highlight
local coinHighlights = {}
local function UpdateCoinESP()
    for _,v in pairs(coinHighlights) do if v and v.Parent then v:Destroy() end end coinHighlights={}
    if not Settings.CoinESP then return end
    
    local function highlight(obj)
        if obj:IsA("BasePart") then
            local h=Instance.new("Highlight") h.FillColor=Color3.fromRGB(255,215,0) h.OutlineColor=Color3.fromRGB(255,255,100) h.FillTransparency=0.5 h.Adornee=obj h.Parent=obj
            table.insert(coinHighlights,h)
        end
    end

    local normal = WS:FindFirstChild("Normal")
    if normal and normal:FindFirstChild("CoinContainer") then
        for _, c in pairs(normal.CoinContainer:GetDescendants()) do
            if c.Name == "Coin" or c.Name == "Snowflake" or c.Name == "Gem" then highlight(c) end
        end
    else
        for _,obj in pairs(WS:GetDescendants()) do
            if (obj.Name:lower():find("coin") or obj.Name:lower():find("gem") or obj.Name:lower():find("snowflake")) and obj:IsA("BasePart") then
                highlight(obj)
            end
        end
    end
end
task.spawn(function() while task.wait(5) do if Settings.CoinESP then UpdateCoinESP() end end end)

-- Improved Auto Coin
local collecting = false
task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoCoin and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and not collecting then
            collecting = true
            local hrp = LP.Character.HumanoidRootPart
            local coins = {}
            
            -- Search for coins
            for _,v in pairs(WS:GetDescendants()) do
                if (v.Name == "Coin" or v.Name == "Snowflake" or v.Name == "Gem") and v:IsA("BasePart") and v.Transparency < 1 then
                    table.insert(coins, v)
                end
            end
            
            for _, c in pairs(coins) do
                if not Settings.AutoCoin then break end
                if c and c.Parent and c.Transparency < 1 then
                    local targetPos = c.Position
                    -- Fly to coin logic (smooth CFrame)
                    local dist = (hrp.Position - targetPos).Magnitude
                    if dist > 5 then
                        hrp.CFrame = CFrame.new(targetPos)
                    end
                    if firetouchinterest then firetouchinterest(hrp, c, 0) firetouchinterest(hrp, c, 1) end
                    task.wait(0.1)
                end
            end
            collecting = false
        end
    end
end)

-- Gun Grab (pick up dropped gun)
task.spawn(function()
    while task.wait(0.2) do
        if Settings.GrabGun and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _,tool in pairs(WS:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name=="Gun" or tool.Name=="Revolver" or tool.Name:lower():find("gun")) and tool:FindFirstChild("Handle") then
                    LP.Character.HumanoidRootPart.CFrame = tool.Handle.CFrame
                    if firetouchinterest then firetouchinterest(LP.Character.HumanoidRootPart,tool.Handle,0) firetouchinterest(LP.Character.HumanoidRootPart,tool.Handle,1) end
                end
            end
        end
    end
end)

-- X-Ray Vision
local xrayParts = {}
local function SetXRay(on)
    if on then
        for _,p in pairs(WS:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency < 0.5 and not p.Parent:FindFirstChild("Humanoid") then
                xrayParts[p] = p.Transparency
                p.Transparency = 0.7
            end
        end
    else
        for p,t in pairs(xrayParts) do pcall(function() p.Transparency = t end) end
        xrayParts = {}
    end
end

-- Murderer Proximity Alert
local lastAlertTick = 0
task.spawn(function()
    while task.wait(0.5) do
        if Settings.MurdAlert and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LP and GetRole(p)=="Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 30 and tick()-lastAlertTick > 5 then
                        StarterGui:SetCore("SendNotification",{Title="⚠️ DANGER",Text="Murderer is "..math.floor(dist).." studs away!",Duration=3})
                        lastAlertTick = tick()
                    end
                end
            end
        end
    end
end)

-- Fling Logic (MM2 Specific)
local function FlingPlayer(target)
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = LP.Character.HumanoidRootPart
    local tHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if tHRP then
        local oldPos = hrp.CFrame
        for _, v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        hrp.RotVelocity = Vector3.new(0, 10000, 0)
        hrp.CFrame = tHRP.CFrame * CFrame.new(0, 0, 1)
        task.wait(0.1)
        hrp.Velocity = Vector3.new(0, 10000, 0)
    end
end

task.spawn(function()
    while task.wait() do
        if Settings.FlingAll then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then FlingPlayer(p) end
            end
        elseif Settings.FlingMurderer then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and GetRole(p) == "Murderer" then FlingPlayer(p) end
            end
        end
    end
end)

-- Role Notification at round start
task.spawn(function()
    while task.wait(3) do
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LP then
                local role = GetRole(p)
                if role ~= "Innocent" then
                    pcall(function() StarterGui:SetCore("SendNotification",{Title="Role Detected",Text=p.Name.." is the "..role,Duration=5}) end)
                end
            end
        end
        task.wait(15)
    end
end)

-- Fling Murderer
local FlingVel
task.spawn(function()
    while task.wait(0.05) do
        if Settings.FlingMurderer and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local murderer = nil
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
                    if GetRole(p) == "Murderer" then
                        murderer = p
                        break
                    end
                end
            end
            
            if murderer then
                local hrp = LP.Character.HumanoidRootPart
                if not FlingVel then
                    FlingVel = Instance.new("BodyAngularVelocity") 
                    FlingVel.AngularVelocity = Vector3.new(99999,99999,99999) 
                    FlingVel.MaxTorque = Vector3.new(math.huge,math.huge,math.huge) 
                    FlingVel.P = 100000 
                    FlingVel.Parent = hrp
                else
                    FlingVel.Parent = hrp
                end
                -- Teleport into them to fling
                hrp.CFrame = murderer.Character.HumanoidRootPart.CFrame
            else
                if FlingVel then FlingVel:Destroy() FlingVel = nil end
            end
        else
            if FlingVel then FlingVel:Destroy() FlingVel = nil end
        end
    end
end)

-- Fly
local flyBV,flyBG,flying=nil,nil,false
local function StartFly()
    if not LP.Character or not LP.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp=LP.Character.HumanoidRootPart flying=true
    flyBV=Instance.new("BodyVelocity",hrp) flyBV.MaxForce=Vector3.new(math.huge,math.huge,math.huge) flyBV.Velocity=Vector3.new(0,0,0)
    flyBG=Instance.new("BodyGyro",hrp) flyBG.MaxTorque=Vector3.new(math.huge,math.huge,math.huge) flyBG.D=200 flyBG.P=10000
    Connections.FlyLoop=RS.RenderStepped:Connect(function()
        if not flying or not flyBV or not flyBV.Parent then return end
        local dir=Vector3.new(0,0,0) local cf=Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir=dir+cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir=dir-cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir=dir-cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir=dir+cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
        flyBV.Velocity=dir*Settings.FlySpeed flyBG.CFrame=cf
    end)
end
local function StopFly() flying=false if flyBV then flyBV:Destroy() flyBV=nil end if flyBG then flyBG:Destroy() flyBG=nil end if Connections.FlyLoop then Connections.FlyLoop:Disconnect() end end

-- Movement
Connections.Jump=UIS.JumpRequest:Connect(function() if Settings.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
Connections.MoveLoop=RS.Stepped:Connect(function()
    if Settings.Noclip and LP.Character then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end end end
end)
task.spawn(function() while task.wait(0.5) do if Settings.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.WalkSpeed=Settings.SpeedVal end end end)

-- UI
local oldGui=(gethui or function() return CoreGui end)():FindFirstChild("KlosoMM2")
if oldGui then oldGui:Destroy() end
local Gui=Create("ScreenGui",{Parent=(gethui or function() return CoreGui end)(),Name="KlosoMM2"})
local Main=Create("Frame",{Parent=Gui,Size=UDim2.fromOffset(500,380),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Theme.Bg,BorderSizePixel=0})
Create("UICorner",{Parent=Main,CornerRadius=UDim.new(0,8)}) Create("UIStroke",{Parent=Main,Color=Theme.Border,Thickness=1.5})
local Sidebar=Create("Frame",{Parent=Main,Size=UDim2.new(0,120,1,0),BackgroundColor3=Theme.Card,BorderSizePixel=0})
Create("UICorner",{Parent=Sidebar,CornerRadius=UDim.new(0,8)}) Create("Frame",{Parent=Sidebar,Size=UDim2.new(0,10,1,0),Position=UDim2.new(1,-10,0,0),BackgroundColor3=Theme.Card,BorderSizePixel=0})
Create("TextLabel",{Parent=Sidebar,Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Text="KLOSO MM2",TextColor3=Theme.Accent,TextSize=16,Font=Enum.Font.GothamBold})
local Floating=Create("TextButton",{Parent=Gui,Size=UDim2.fromOffset(40,40),Position=UDim2.new(0,10,0.5,0),BackgroundColor3=Theme.Card,Text="K",TextColor3=Theme.Accent,TextSize=20,Font=Enum.Font.GothamBold,Visible=false})
Create("UICorner",{Parent=Floating,CornerRadius=UDim.new(1,0)}) Create("UIStroke",{Parent=Floating,Color=Theme.Accent,Thickness=2})
local function ToggleUI(on) Main.Visible=on Floating.Visible=not on end
Floating.MouseButton1Click:Connect(function() ToggleUI(true) end)

local TopButtons=Create("Frame",{Parent=Main,Size=UDim2.fromOffset(60,25),Position=UDim2.new(1,-65,0,10),BackgroundTransparency=1})
Create("UIListLayout",{Parent=TopButtons,FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,5)})
local function CreateTopBtn(t,c,cb) local b=Create("TextButton",{Parent=TopButtons,Size=UDim2.fromOffset(24,24),BackgroundColor3=Theme.Card,Text=t,TextColor3=c,TextSize=14,Font=Enum.Font.GothamBold}) Create("UICorner",{Parent=b,CornerRadius=UDim.new(0,6)}) Create("UIStroke",{Parent=b,Color=Theme.Border,Thickness=1}) b.MouseButton1Click:Connect(cb) return b end
local function CloseHub() Gui:Destroy() for _,p in pairs(Players:GetPlayers()) do HideESP(p) end for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end StopFly() for _,v in pairs(coinHighlights) do if v and v.Parent then v:Destroy() end end end
CreateTopBtn("-",Theme.Sub,function() ToggleUI(false) end) CreateTopBtn("×",Color3.fromRGB(255,80,80),CloseHub)
local MinBtn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,30),Position=UDim2.new(0,5,1,-75),BackgroundColor3=Theme.Bg,Text="Minimize",TextColor3=Theme.Sub,TextSize=12,Font=Enum.Font.GothamBold})
Create("UICorner",{Parent=MinBtn,CornerRadius=UDim.new(0,6)}) MinBtn.MouseButton1Click:Connect(function() ToggleUI(false) end)
local ClsBtn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,30),Position=UDim2.new(0,5,1,-40),BackgroundColor3=Color3.fromRGB(200,50,50),Text="Close Hub",TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.GothamBold})
Create("UICorner",{Parent=ClsBtn,CornerRadius=UDim.new(0,6)}) ClsBtn.MouseButton1Click:Connect(CloseHub)

local TabContainer=Create("Frame",{Parent=Main,Size=UDim2.new(1,-130,1,-20),Position=UDim2.new(0,130,0,10),BackgroundTransparency=1})
local Tabs={}
local function CreateTab(name) local btn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,35),Position=UDim2.new(0,5,0,60+(#Tabs*40)),BackgroundColor3=Theme.Bg,Text=name,TextColor3=Theme.Sub,TextSize=12,Font=Enum.Font.GothamSemibold}) Create("UICorner",{Parent=btn,CornerRadius=UDim.new(0,6)}) local page=Create("ScrollingFrame",{Parent=TabContainer,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=(#Tabs==0),ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,3,0)}) Create("UIListLayout",{Parent=page,Padding=UDim.new(0,5)}) btn.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do t.Page.Visible=false Tw(t.Btn,{TextColor3=Theme.Sub}) end page.Visible=true Tw(btn,{TextColor3=Theme.Accent}) end) if #Tabs==0 then btn.TextColor3=Theme.Accent end table.insert(Tabs,{Btn=btn,Page=page}) return page end

local function Section(p,t) Create("TextLabel",{Parent=p,Size=UDim2.new(1,0,0,25),BackgroundTransparency=1,Text=t,TextColor3=Theme.Accent,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left}) end
local function Toggle(p,name,def,cb)
    local on=def local row=Create("Frame",{Parent=p,Size=UDim2.new(1,-5,0,35),BackgroundColor3=Theme.Card,BorderSizePixel=0}) Create("UICorner",{Parent=row,CornerRadius=UDim.new(0,6)})
    Create("TextLabel",{Parent=row,Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=name,TextColor3=Theme.Text,TextSize=12,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left})
    local tgl=Create("Frame",{Parent=row,Size=UDim2.fromOffset(30,16),Position=UDim2.new(1,-40,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=on and Theme.Accent or Theme.Border}) Create("UICorner",{Parent=tgl,CornerRadius=UDim.new(1,0)})
    local dot=Create("Frame",{Parent=tgl,Size=UDim2.fromOffset(12,12),Position=on and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=Theme.Text}) Create("UICorner",{Parent=dot,CornerRadius=UDim.new(1,0)})
    local btn=Create("TextButton",{Parent=row,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""})
    btn.MouseButton1Click:Connect(function() on=not on Tw(tgl,{BackgroundColor3=on and Theme.Accent or Theme.Border}) Tw(dot,{Position=on and UDim2.new(1,-14,0.5,0) or UDim2.new(0,2,0.5,0)}) cb(on) end)
end
local function Slider(p,name,min,max,def,cb)
    local val=def local row=Create("Frame",{Parent=p,Size=UDim2.new(1,-5,0,45),BackgroundColor3=Theme.Card,BorderSizePixel=0}) Create("UICorner",{Parent=row,CornerRadius=UDim.new(0,6)})
    local label=Create("TextLabel",{Parent=row,Size=UDim2.new(1,-20,0,20),Position=UDim2.new(0,10,0,2),BackgroundTransparency=1,Text=name..": "..val,TextColor3=Theme.Text,TextSize=11,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left})
    local track=Create("Frame",{Parent=row,Size=UDim2.new(1,-20,0,4),Position=UDim2.new(0,10,0,30),BackgroundColor3=Theme.Border})
    local fill=Create("Frame",{Parent=track,Size=UDim2.new(math.clamp((val-min)/(max-min),0,1),0,1,0),BackgroundColor3=Theme.Accent})
    local drag=false
    local function update(i) local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1) val=math.floor((min+(rel*(max-min)))*100)/100 fill.Size=UDim2.new(rel,0,1,0) label.Text=name..": "..val cb(val) end
    local btn=Create("TextButton",{Parent=track,Size=UDim2.new(1,0,2,0),Position=UDim2.new(0,0,0,-2),BackgroundTransparency=1,Text=""})
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true update(i) end end)
    btn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
    Connections["Slider_"..name]=UIS.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i) end end)
end

local FarmPage=CreateTab("Auto Farm")
local FlingPage=CreateTab("Fling")
local WorldPage=CreateTab("World")
local RolePage=CreateTab("Roles")
local VisPage=CreateTab("Visuals")
local MovePage=CreateTab("Movement")

Section(FarmPage,"Automation")
Toggle(FarmPage,"Auto Collect Coins (Fly)",false,function(v) Settings.AutoCoin=v end)
Toggle(FarmPage,"Auto Grab Gun",false,function(v) Settings.GrabGun=v end)

Section(FlingPage,"Kill Players")
Toggle(FlingPage,"Fling Murderer",false,function(v) Settings.FlingMurderer=v end)
Toggle(FlingPage,"Fling All Players",false,function(v) Settings.FlingAll = v end)
Button(FlingPage,"Fling Nearest",function()
    local best,dist = nil,math.huge
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d=(LP.Character.HumanoidRootPart.Position-p.Character.HumanoidRootPart.Position).Magnitude
            if d<dist then best=p dist=d end
        end
    end
    if best then FlingPlayer(best) end
end)

Section(WorldPage,"Teleport Menu")
Button(WorldPage,"Teleport to Lobby",function()
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        LP.Character.HumanoidRootPart.CFrame = CFrame.new(-108, 140, 10) -- Lobby coords
    end
end)
Button(WorldPage,"Teleport to Map",function()
    local map = WS:FindFirstChild("Normal")
    if map then
        LP.Character.HumanoidRootPart.CFrame = map:GetModelCFrame() + Vector3.new(0, 5, 0)
    end
end)
Button(WorldPage,"Teleport to Voting Area",function()
    LP.Character.HumanoidRootPart.CFrame = CFrame.new(-108, 140, 60)
end)

Section(RolePage,"Role Detection ESP")
Toggle(RolePage,"Murderer ESP (Red)",true,function(v) Settings.MurdererESP=v end)
Toggle(RolePage,"Sheriff ESP (Blue)",true,function(v) Settings.SheriffESP=v end)
Toggle(RolePage,"All Players ESP",false,function(v) Settings.PlayerESP=v end)
Toggle(RolePage,"Murderer Proximity Alert",false,function(v) Settings.MurdAlert=v end)

Section(VisPage,"World ESP")
Toggle(VisPage,"Coin/Gem ESP",false,function(v) Settings.CoinESP=v if not v then UpdateCoinESP() end end)
Toggle(VisPage,"X-Ray Vision",false,function(v) Settings.XRay=v SetXRay(v) end)
Toggle(VisPage,"Fullbright",false,function(v) Settings.Fullbright=v SetFullbright(v) end)

Section(MovePage,"Character")
Toggle(MovePage,"Speed Hack",false,function(v) Settings.Speed=v end)
Slider(MovePage,"Speed Value",16,100,25,function(v) Settings.SpeedVal=v end)
Toggle(MovePage,"Infinite Jump",false,function(v) Settings.InfJump=v end)
Toggle(MovePage,"Noclip",false,function(v) Settings.Noclip=v end)
Toggle(MovePage,"Fly",false,function(v) Settings.Fly=v if v then StartFly() else StopFly() end end)
Slider(MovePage,"Fly Speed",10,200,50,function(v) Settings.FlySpeed=v end)

do local dr,ds,sp
    Connections.D1=Sidebar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true ds=i.Position sp=Main.Position end end)
    Connections.D2=UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds Tw(Main,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}) end end)
    Connections.D3=Sidebar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
    Connections.D4=UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Enum.KeyCode.RightShift then ToggleUI(not Main.Visible) end end)
end

print("[KLOSO MM2] Loaded.")
