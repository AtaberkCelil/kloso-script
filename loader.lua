-- [[ KLOSO HUB v2.5 - UNIVERSAL LOADER ]]
repeat task.wait() until game:IsLoaded()

local CoreGui = (gethui or function() return game:GetService("CoreGui") end)()
local placeId = game.PlaceId
local TweenService = game:GetService("TweenService")

local LoaderUI = Instance.new("ScreenGui", CoreGui)
LoaderUI.Name = "KlosoLoader"

local Main = Instance.new("Frame", LoaderUI)
Main.Size = UDim2.fromOffset(320, 120)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(12, 10, 18)
Main.BackgroundTransparency = 1
Main.BorderSizePixel = 0

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(160, 120, 255)
Stroke.Thickness = 2
Stroke.Transparency = 1

-- Fade in
TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {BackgroundTransparency = 0}):Play()
TweenService:Create(Stroke, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Transparency = 0}):Play()

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1
Title.Text = "KLOSO HUB"
Title.TextColor3 = Color3.fromRGB(160, 120, 255)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextTransparency = 1
TweenService:Create(Title, TweenInfo.new(0.6, Enum.EasingStyle.Quart), {TextTransparency = 0}):Play()

local Version = Instance.new("TextLabel", Main)
Version.Size = UDim2.new(1, 0, 0, 15)
Version.Position = UDim2.new(0, 0, 0, 42)
Version.BackgroundTransparency = 1
Version.Text = "v2.5 • Premium Edition"
Version.TextColor3 = Color3.fromRGB(120, 100, 180)
Version.TextSize = 10
Version.Font = Enum.Font.GothamSemibold

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 65)
Status.BackgroundTransparency = 1
Status.Text = "Initializing..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.TextSize = 12
Status.Font = Enum.Font.GothamSemibold
Status.TextXAlignment = Enum.TextXAlignment.Left

-- Progress bar
local BarBg = Instance.new("Frame", Main)
BarBg.Size = UDim2.new(1, -20, 0, 4)
BarBg.Position = UDim2.new(0, 10, 0, 90)
BarBg.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
BarBg.BorderSizePixel = 0
Instance.new("UICorner", BarBg).CornerRadius = UDim.new(1, 0)

local BarFill = Instance.new("Frame", BarBg)
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(160, 120, 255)
BarFill.BorderSizePixel = 0
Instance.new("UICorner", BarFill).CornerRadius = UDim.new(1, 0)

-- Glow effect
local Glow = Instance.new("ImageLabel", Main)
Glow.Size = UDim2.new(1, 40, 1, 40)
Glow.Position = UDim2.new(0.5, 0, 0.5, 0)
Glow.AnchorPoint = Vector2.new(0.5, 0.5)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = Color3.fromRGB(160, 120, 255)
Glow.ImageTransparency = 0.85
Glow.ZIndex = -1

local function setProgress(pct, text)
    Status.Text = text
    TweenService:Create(BarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
end

task.wait(0.3)
setProgress(0.2, "Detecting Game...")
task.wait(0.5)

local SupportedGames = {
    [17625359962] = {Name = "Rivals", File = "kloso-rivals.lua"},
    [286090429]   = {Name = "Arsenal", File = "arsenal.lua"},
    [10449761463] = {Name = "The Strongest Battlegrounds", File = "tsb.lua"},
    [189707]      = {Name = "Natural Disaster Survival", File = "nds.lua"},
    [2753915549]  = {Name = "Blox Fruits", File = "bloxfruits.lua"},
    [142823291]   = {Name = "Murder Mystery 2", File = "mm2.lua"},
    [2788229376]  = {Name = "Da Hood", File = "dahood.lua"},
    [6872265039]  = {Name = "Bedwars", File = "bedwars.lua"}
}

local BASE_URL = "https://raw.githubusercontent.com/AtaberkCelil/kloso-script/main/"
local gameData = SupportedGames[placeId]

if gameData then
    setProgress(0.5, "Found: " .. gameData.Name)
    task.wait(0.5)
    setProgress(0.8, "Loading " .. gameData.Name .. " module...")
    task.wait(0.5)
    setProgress(1, "Injecting...")
    task.wait(0.3)
    
    -- Fade out
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    for _, v in pairs(Main:GetDescendants()) do
        pcall(function() TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1, ImageTransparency = 1, BackgroundTransparency = 1}):Play() end)
    end
    task.wait(0.4)
    LoaderUI:Destroy()
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(BASE_URL .. gameData.File))()
    end)
    
    if not success then
        warn("[KLOSO HUB] Failed to load game script: " .. tostring(err))
        warn("[KLOSO HUB] Falling back to Universal...")
        pcall(function() loadstring(game:HttpGet(BASE_URL .. "universal.lua"))() end)
    end
else
    setProgress(0.5, "No game-specific module found")
    task.wait(0.4)
    setProgress(0.8, "Loading Universal Hub...")
    task.wait(0.4)
    setProgress(1, "Injecting...")
    task.wait(0.3)
    
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
    for _, v in pairs(Main:GetDescendants()) do
        pcall(function() TweenService:Create(v, TweenInfo.new(0.3), {TextTransparency = 1, ImageTransparency = 1, BackgroundTransparency = 1}):Play() end)
    end
    task.wait(0.4)
    LoaderUI:Destroy()
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(BASE_URL .. "universal.lua"))()
    end)
    if not success then
        warn("[KLOSO HUB] Failed to load universal: " .. tostring(err))
    end
end
