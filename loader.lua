-- [[ KLOSO HUB - UNIVERSAL LOADER ]]
repeat task.wait() until game:IsLoaded()

local CoreGui = (gethui or function() return game:GetService("CoreGui") end)()
local placeId = game.PlaceId

local LoaderUI = Instance.new("ScreenGui", CoreGui)
LoaderUI.Name = "KlosoLoader"

local Main = Instance.new("Frame", LoaderUI)
Main.Size = UDim2.fromOffset(300, 100)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(15, 12, 20)
Main.BorderSizePixel = 0

local Corner = Instance.new("UICorner", Main)
Corner.CornerRadius = UDim.new(0, 8)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(160, 120, 255)
Stroke.Thickness = 2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0.6, 0)
Title.BackgroundTransparency = 1
Title.Text = "KLOSO HUB"
Title.TextColor3 = Color3.fromRGB(160, 120, 255)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold

local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, 0, 0.4, 0)
Status.Position = UDim2.new(0, 0, 0.6, 0)
Status.BackgroundTransparency = 1
Status.Text = "Detecting Game..."
Status.TextColor3 = Color3.fromRGB(200, 200, 200)
Status.TextSize = 14
Status.Font = Enum.Font.GothamSemibold

task.wait(1.5)

local SupportedGames = {
    [17625359962] = {Name = "Rivals", File = "kloso-rivals.lua"},
    [286090429]   = {Name = "Arsenal", File = "arsenal.lua"},
    [10449761463] = {Name = "The Strongest Battlegrounds", File = "tsb.lua"},
    [189707]      = {Name = "Natural Disaster Survival", File = "nds.lua"},
    [2753915549]  = {Name = "Blox Fruits", File = "bloxfruits.lua"},
    [142823291]   = {Name = "Murder Mystery 2", File = "mm2.lua"},
    [2788229376]  = {Name = "Da Hood", File = "dahood.lua"}
}

local BASE_URL = "https://raw.githubusercontent.com/AtaberkCelil/kloso-script/main/"
local gameData = SupportedGames[placeId]

if gameData then
    Status.Text = "Loading " .. gameData.Name .. "..."
    task.wait(1)
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
    Status.Text = "Loading Universal Hub..."
    Status.TextColor3 = Color3.fromRGB(0, 180, 255)
    task.wait(1)
    LoaderUI:Destroy()
    
    local success, err = pcall(function()
        loadstring(game:HttpGet(BASE_URL .. "universal.lua"))()
    end)
    if not success then
        warn("[KLOSO HUB] Failed to load universal: " .. tostring(err))
    end
end
