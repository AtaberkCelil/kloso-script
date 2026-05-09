-- [[ KLOSO HUB - FLING MODULE ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local Fling = {
    Enabled = false,
    Target = nil, -- Specific Player
    FlingAll = false,
    FlingRange = 20,
    RotationSpeed = 10000 -- Massive rotation for fling
}

local function GetHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHum(char)
    return char and char:FindFirstChild("Humanoid")
end

local function FlingPlayer(targetPlayer)
    if not LP.Character or not GetHRP(LP.Character) then return end
    local targetChar = targetPlayer.Character
    local targetHRP = GetHRP(targetChar)
    local targetHum = GetHum(targetChar)
    
    if targetHRP and targetHum and targetHum.Health > 0 then
        local myHRP = GetHRP(LP.Character)
        local origCFrame = myHRP.CFrame
        
        -- Disable collisions to avoid flinging self
        for _, v in pairs(LP.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
        
        -- Set massive rotation
        myHRP.RotVelocity = Vector3.new(0, Fling.RotationSpeed, 0)
        
        -- TP to target and push
        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1)
        task.wait(0.1)
        myHRP.Velocity = Vector3.new(0, Fling.RotationSpeed, 0)
        
        -- Return or continue
        if not Fling.Enabled then
            myHRP.CFrame = origCFrame
            myHRP.RotVelocity = Vector3.new(0, 0, 0)
            myHRP.Velocity = Vector3.new(0, 0, 0)
        end
    end
end

task.spawn(function()
    while task.wait() do
        if Fling.Enabled then
            if Fling.Target and Fling.Target.Parent then
                FlingPlayer(Fling.Target)
            elseif Fling.FlingAll then
                for _, p in pairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character and GetHRP(p.Character) then
                        local dist = (GetHRP(LP.Character).Position - GetHRP(p.Character).Position).Magnitude
                        if dist < Fling.FlingRange then
                            FlingPlayer(p)
                        end
                    end
                end
            end
        end
    end
end)

return Fling
