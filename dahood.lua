repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(o) return o end
local Players = cloneref(game:GetService("Players"))
local UIS = cloneref(game:GetService("UserInputService"))
local RS = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local WS = cloneref(game:GetService("Workspace"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local HttpService = cloneref(game:GetService("HttpService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local Lighting = cloneref(game:GetService("Lighting"))

local LP = Players.LocalPlayer
local Camera = WS.CurrentCamera
local Connections = {}

local Theme = {Accent=Color3.fromRGB(0,255,100),Bg=Color3.fromRGB(10,14,10),Card=Color3.fromRGB(18,24,18),Border=Color3.fromRGB(30,60,30),Text=Color3.fromRGB(240,250,240),Sub=Color3.fromRGB(160,180,160)}

local Settings = {
    AutoStomp = false, AutoBlock = false, AimLock = false,
    Hitbox = false, HitboxSize = 10, TargetStrafe = false, StrafeSpeed = 5,
    PlayerESP = false, CashESP = false, CashAura = false, Fullbright = false,
    Speed = false, SpeedVal = 50,
    Noclip = false, InfJump = false, Fly = false, FlySpeed = 100
}

-- Config System
local ConfigName = "KlosoHub_DaHood.json"
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

-- Fullbright
local function SetFullbright(on)
    if on then Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.FogEnd=100000 Lighting.GlobalShadows=false
    else Lighting.Brightness=1 Lighting.GlobalShadows=true end
end

local function Create(cl,p) local i=Instance.new(cl) for k,v in pairs(p) do if k~="Parent" then pcall(function() i[k]=v end) end end if p.Parent then i.Parent=p.Parent end return i end
local function Tw(o,g) TweenService:Create(o, TweenInfo.new(0.25, Enum.EasingStyle.Quart), g):Play() end

-- Auto Stomp
task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoStomp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
                    if p.Character.Humanoid.Health <= 15 then -- Roughly knocked health
                        local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                        if dist < 15 then
                            local args = { [1] = "Stomp" }
                            local combat = LP.Character:FindFirstChild("Combat")
                            if combat and combat:FindFirstChild("RemoteEvent") then
                                combat.RemoteEvent:FireServer(unpack(args))
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Block
task.spawn(function()
    while task.wait(0.1) do
        if Settings.AutoBlock and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local near = false
            for _,p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (LP.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 10 and p.Character:FindFirstChild("Combat") then
                        near = true break
                    end
                end
            end
            local combat = LP.Character:FindFirstChild("Combat")
            if combat and combat:FindFirstChild("RemoteEvent") then
                if near then combat.RemoteEvent:FireServer("Block", true) else combat.RemoteEvent:FireServer("Block", false) end
            end
        end
    end
end)

-- Aim Lock
local lockTarget = nil
task.spawn(function()
    while task.wait() do
        if Settings.AimLock and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            if not lockTarget or not lockTarget.Character or not lockTarget.Character:FindFirstChild("HumanoidRootPart") or not lockTarget.Character:FindFirstChild("Humanoid") or lockTarget.Character.Humanoid.Health <= 0 then
                local best,dist = nil,math.huge
                for _,p in pairs(Players:GetPlayers()) do
                    if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health>0 then
                        local d=(LP.Character.HumanoidRootPart.Position-p.Character.HumanoidRootPart.Position).Magnitude
                        if d<dist then best=p dist=d end
                    end
                end
                lockTarget = best
            end
            if lockTarget and lockTarget.Character and lockTarget.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockTarget.Character.HumanoidRootPart.Position)
            end
        end
    end
end)

-- Target Strafe
local strafeAngle = 0
task.spawn(function()
    while task.wait() do
        if Settings.TargetStrafe and lockTarget and lockTarget.Character and lockTarget.Character:FindFirstChild("HumanoidRootPart") and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            strafeAngle = strafeAngle + Settings.StrafeSpeed
            local rad = math.rad(strafeAngle)
            local tPos = lockTarget.Character.HumanoidRootPart.Position
            local offset = Vector3.new(math.cos(rad)*8, 0, math.sin(rad)*8)
            LP.Character.HumanoidRootPart.CFrame = CFrame.new(tPos+offset, tPos)
        end
    end
end)

-- Hitbox Expander
task.spawn(function()
    while task.wait(0.1) do
        if Settings.Hitbox then
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    p.Character.HumanoidRootPart.Size=Vector3.new(Settings.HitboxSize,Settings.HitboxSize,Settings.HitboxSize)
                    p.Character.HumanoidRootPart.Transparency=0.8
                    p.Character.HumanoidRootPart.CanCollide=false
                end
            end
        end
    end
end)

-- Cash Aura
task.spawn(function()
    while task.wait(0.5) do
        if Settings.CashAura and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = LP.Character.HumanoidRootPart
            local drops = WS:FindFirstChild("Ignored") and WS.Ignored:FindFirstChild("Drop") or WS
            for _,obj in pairs(drops:GetChildren()) do
                if obj.Name=="MoneyDrop" and obj:FindFirstChild("Handle") then
                    if (obj.Handle.Position-hrp.Position).Magnitude < 50 then
                        obj.Handle.CFrame = hrp.CFrame
                        if firetouchinterest then firetouchinterest(hrp,obj.Handle,0) firetouchinterest(hrp,obj.Handle,1) end
                    end
                end
            end
        end
    end
end)

-- Cash ESP
local cashHighlights = {}
local function UpdateCashESP()
    for _,v in pairs(cashHighlights) do if v and v.Parent then v:Destroy() end end cashHighlights = {}
    if not Settings.CashESP then return end
    if not WS:FindFirstChild("CashDrop") and not WS:FindFirstChild("Ignored") then return end
    
    local drops = WS:FindFirstChild("Ignored") and WS.Ignored:FindFirstChild("Drop") or WS
    for _,obj in pairs(drops:GetChildren()) do
        if obj.Name == "MoneyDrop" and obj:FindFirstChild("BillboardGui") and obj.BillboardGui:FindFirstChild("TextLabel") then
            local amt = obj.BillboardGui.TextLabel.Text
            local bb = Instance.new("BillboardGui") bb.Adornee = obj bb.Size = UDim2.new(0,100,0,30) bb.StudsOffset = Vector3.new(0,2,0) bb.AlwaysOnTop = true
            local tl = Instance.new("TextLabel",bb) tl.Size = UDim2.new(1,0,1,0) tl.BackgroundTransparency = 1 tl.Text = "💵 "..amt tl.TextColor3 = Color3.fromRGB(0,255,100) tl.TextSize = 14 tl.Font = Enum.Font.GothamBold tl.TextStrokeTransparency = 0
            bb.Parent = obj
            table.insert(cashHighlights, bb)
        end
    end
end
task.spawn(function() while task.wait(2) do if Settings.CashESP then UpdateCashESP() end end end)

-- Player ESP
local ESP_Objects = {}
local function GetESPObj(p)
    if not ESP_Objects[p] then
        ESP_Objects[p] = {Box=Drawing.new("Square"),BoxO=Drawing.new("Square"),Name=Drawing.new("Text"),HP=Drawing.new("Line"),HPO=Drawing.new("Line")}
        local o=ESP_Objects[p] o.Box.Thickness=1 o.Box.Filled=false o.BoxO.Thickness=3 o.BoxO.Filled=false o.BoxO.Color=Color3.new(0,0,0)
        o.Name.Size=14 o.Name.Center=true o.Name.Outline=true o.HP.Thickness=1 o.HPO.Thickness=3 o.HPO.Color=Color3.new(0,0,0)
    end return ESP_Objects[p]
end
local function HideESP(p) if ESP_Objects[p] then for _,v in pairs(ESP_Objects[p]) do v.Visible=false end end end
Players.PlayerRemoving:Connect(function(p) if ESP_Objects[p] then for _,v in pairs(ESP_Objects[p]) do v:Remove() end ESP_Objects[p]=nil end end)

Connections.RenderLoop = RS.RenderStepped:Connect(function()
    for _,p in pairs(Players:GetPlayers()) do
        if p==LP then continue end
        local char=p.Character
        if not Settings.PlayerESP or not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health<=0 then HideESP(p) continue end
        local hrp=char.HumanoidRootPart local hum=char.Humanoid
        local pos,onScreen=Camera:WorldToViewportPoint(hrp.Position) local obs=GetESPObj(p)
        if onScreen then
            local rp=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
            local hp2=Camera:WorldToViewportPoint(hrp.Position+Vector3.new(0,2.5,0))
            local bH=math.abs(hp2.Y-rp.Y) local bW=bH*0.6
            obs.BoxO.Size=Vector2.new(bW,bH) obs.BoxO.Position=Vector2.new(rp.X-bW/2,hp2.Y) obs.BoxO.Visible=true
            obs.Box.Size=Vector2.new(bW,bH) obs.Box.Position=Vector2.new(rp.X-bW/2,hp2.Y) obs.Box.Color=Theme.Accent obs.Box.Visible=true
            local hs=hum.Health/hum.MaxHealth
            obs.HPO.From=Vector2.new(rp.X-bW/2-5,hp2.Y) obs.HPO.To=Vector2.new(rp.X-bW/2-5,rp.Y) obs.HPO.Visible=true
            obs.HP.From=Vector2.new(rp.X-bW/2-5,rp.Y-(bH*hs)) obs.HP.To=Vector2.new(rp.X-bW/2-5,rp.Y) obs.HP.Color=Color3.fromHSV(math.clamp(hs*0.3,0.01,0.3),1,1) obs.HP.Visible=true
            obs.Name.Text=p.Name obs.Name.Position=Vector2.new(rp.X,hp2.Y-18) obs.Name.Color=Theme.Text obs.Name.Visible=true
        else HideESP(p) end
    end
end)

-- Fly & Movement
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

Connections.Jump=UIS.JumpRequest:Connect(function() if Settings.InfJump and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end)
Connections.MoveLoop=RS.Stepped:Connect(function()
    if Settings.Noclip and LP.Character then for _,v in pairs(LP.Character:GetDescendants()) do if v:IsA("BasePart") and v.CanCollide then v.CanCollide=false end end end
end)
task.spawn(function() while task.wait(0.5) do if Settings.Speed and LP.Character and LP.Character:FindFirstChild("Humanoid") then LP.Character.Humanoid.WalkSpeed=Settings.SpeedVal end end end)

-- UI
local oldGui=(gethui or function() return CoreGui end)():FindFirstChild("KlosoDaHood")
if oldGui then oldGui:Destroy() end
local Gui=Create("ScreenGui",{Parent=(gethui or function() return CoreGui end)(),Name="KlosoDaHood"})
local Main=Create("Frame",{Parent=Gui,Size=UDim2.fromOffset(500,380),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Theme.Bg,BorderSizePixel=0})
Create("UICorner",{Parent=Main,CornerRadius=UDim.new(0,8)}) Create("UIStroke",{Parent=Main,Color=Theme.Border,Thickness=1.5})
local Sidebar=Create("Frame",{Parent=Main,Size=UDim2.new(0,120,1,0),BackgroundColor3=Theme.Card,BorderSizePixel=0})
Create("UICorner",{Parent=Sidebar,CornerRadius=UDim.new(0,8)}) Create("Frame",{Parent=Sidebar,Size=UDim2.new(0,10,1,0),Position=UDim2.new(1,-10,0,0),BackgroundColor3=Theme.Card,BorderSizePixel=0})
Create("TextLabel",{Parent=Sidebar,Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Text="KLOSO DA HOOD",TextColor3=Theme.Accent,TextSize=14,Font=Enum.Font.GothamBold})
local Floating=Create("TextButton",{Parent=Gui,Size=UDim2.fromOffset(40,40),Position=UDim2.new(0,10,0.5,0),BackgroundColor3=Theme.Card,Text="K",TextColor3=Theme.Accent,TextSize=20,Font=Enum.Font.GothamBold,Visible=false})
Create("UICorner",{Parent=Floating,CornerRadius=UDim.new(1,0)}) Create("UIStroke",{Parent=Floating,Color=Theme.Accent,Thickness=2})
local function ToggleUI(on) Main.Visible=on Floating.Visible=not on end
Floating.MouseButton1Click:Connect(function() ToggleUI(true) end)

local TopButtons=Create("Frame",{Parent=Main,Size=UDim2.fromOffset(60,25),Position=UDim2.new(1,-65,0,10),BackgroundTransparency=1})
Create("UIListLayout",{Parent=TopButtons,FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,5)})
local function CreateTopBtn(t,c,cb) local b=Create("TextButton",{Parent=TopButtons,Size=UDim2.fromOffset(24,24),BackgroundColor3=Theme.Card,Text=t,TextColor3=c,TextSize=14,Font=Enum.Font.GothamBold}) Create("UICorner",{Parent=b,CornerRadius=UDim.new(0,6)}) Create("UIStroke",{Parent=b,Color=Theme.Border,Thickness=1}) b.MouseButton1Click:Connect(cb) return b end
local function CloseHub() Gui:Destroy() for _,p in pairs(Players:GetPlayers()) do HideESP(p) end for _,v in pairs(Connections) do pcall(function() v:Disconnect() end) end StopFly() for _,v in pairs(cashHighlights) do if v and v.Parent then v:Destroy() end end end
CreateTopBtn("-",Theme.Sub,function() ToggleUI(false) end) CreateTopBtn("×",Color3.fromRGB(255,80,80),CloseHub)
local MinBtn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,30),Position=UDim2.new(0,5,1,-75),BackgroundColor3=Theme.Bg,Text="Minimize",TextColor3=Theme.Sub,TextSize=12,Font=Enum.Font.GothamBold})
Create("UICorner",{Parent=MinBtn,CornerRadius=UDim.new(0,6)}) MinBtn.MouseButton1Click:Connect(function() ToggleUI(false) end)
local ClsBtn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,30),Position=UDim2.new(0,5,1,-40),BackgroundColor3=Color3.fromRGB(200,50,50),Text="Close Hub",TextColor3=Color3.new(1,1,1),TextSize=12,Font=Enum.Font.GothamBold})
Create("UICorner",{Parent=ClsBtn,CornerRadius=UDim.new(0,6)}) ClsBtn.MouseButton1Click:Connect(CloseHub)

local TabContainer=Create("Frame",{Parent=Main,Size=UDim2.new(1,-130,1,-20),Position=UDim2.new(0,130,0,10),BackgroundTransparency=1})
local Tabs={}
local function CreateTab(name) local btn=Create("TextButton",{Parent=Sidebar,Size=UDim2.new(1,-10,0,35),Position=UDim2.new(0,5,0,60+(#Tabs*40)),BackgroundColor3=Theme.Bg,Text=name,TextColor3=Theme.Sub,TextSize=12,Font=Enum.Font.GothamSemibold}) Create("UICorner",{Parent=btn,CornerRadius=UDim.new(0,6)}) local page=Create("ScrollingFrame",{Parent=TabContainer,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Visible=(#Tabs==0),ScrollBarThickness=0,CanvasSize=UDim2.new(0,0,5,0)}) Create("UIListLayout",{Parent=page,Padding=UDim.new(0,5)}) btn.MouseButton1Click:Connect(function() for _,t in pairs(Tabs) do t.Page.Visible=false Tw(t.Btn,{TextColor3=Theme.Sub}) end page.Visible=true Tw(btn,{TextColor3=Theme.Accent}) end) if #Tabs==0 then btn.TextColor3=Theme.Accent end table.insert(Tabs,{Btn=btn,Page=page}) return page end
local function Button(p,t,cb) local r=Create("Frame",{Parent=p,Size=UDim2.new(1,-5,0,35),BackgroundColor3=Theme.Card,BorderSizePixel=0}) Create("UICorner",{Parent=r,CornerRadius=UDim.new(0,6)}) local b=Create("TextButton",{Parent=r,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=t,TextColor3=Theme.Text,TextSize=12,Font=Enum.Font.GothamBold}) b.MouseButton1Click:Connect(cb) end

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

local CombatPage=CreateTab("Combat")
local VisPage=CreateTab("Visuals")
local MovePage=CreateTab("Movement")
local ConfigPage=CreateTab("Config")

Section(CombatPage,"Aim & Lock")
Toggle(CombatPage,"Aim Lock (Nearest)",false,function(v) Settings.AimLock=v if not v then lockTarget=nil end end)
Toggle(CombatPage,"Target Strafe",false,function(v) Settings.TargetStrafe=v end)
Slider(CombatPage,"Strafe Speed",1,15,5,function(v) Settings.StrafeSpeed=v end)

Section(CombatPage,"Combat Mods")
Toggle(CombatPage,"Auto Stomp",false,function(v) Settings.AutoStomp=v end)
Toggle(CombatPage,"Auto Block (Proximity)",false,function(v) Settings.AutoBlock=v end)
Toggle(CombatPage,"Hitbox Expander",false,function(v) Settings.Hitbox=v end)
Slider(CombatPage,"Hitbox Size",5,30,10,function(v) Settings.HitboxSize=v end)

Section(VisPage,"World ESP")
Toggle(VisPage,"Player ESP",false,function(v) Settings.PlayerESP=v end)
Toggle(VisPage,"Cash Drop ESP",false,function(v) Settings.CashESP=v if not v then UpdateCashESP() end end)
Toggle(VisPage,"Cash Aura (Auto Collect)",false,function(v) Settings.CashAura=v end)
Toggle(VisPage,"Fullbright",false,function(v) Settings.Fullbright=v SetFullbright(v) end)

Section(MovePage,"Character")
Toggle(MovePage,"Speed Hack",false,function(v) Settings.Speed=v end)
Slider(MovePage,"Speed Value",16,150,50,function(v) Settings.SpeedVal=v end)
Toggle(MovePage,"Infinite Jump",false,function(v) Settings.InfJump=v end)
Toggle(MovePage,"Noclip",false,function(v) Settings.Noclip=v end)
Toggle(MovePage,"Fly",false,function(v) Settings.Fly=v if v then StartFly() else StopFly() end end)
Slider(MovePage,"Fly Speed",10,200,50,function(v) Settings.FlySpeed=v end)

Section(ConfigPage,"Save & Load")
Button(ConfigPage,"Save Config",SaveConfig)
Button(ConfigPage,"Load Config",LoadConfig)

do local dr,ds,sp
    Connections.D1=Sidebar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true ds=i.Position sp=Main.Position end end)
    Connections.D2=UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then local d=i.Position-ds Tw(Main,{Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)}) end end)
    Connections.D3=Sidebar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
    Connections.D4=UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==Enum.KeyCode.RightShift then ToggleUI(not Main.Visible) end end)
end

print("[KLOSO DA HOOD] Loaded.")
