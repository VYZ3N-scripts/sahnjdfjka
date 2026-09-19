local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local GrabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
local CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")

if not CreateLine then
    GrabEvents = ReplicatedStorage:WaitForChild("GrabEvents", 10)
    CreateLine = GrabEvents and GrabEvents:FindFirstChild("CreateGrabLine")
end

if not CreateLine then
    warn("[lag] CreateGrabLine not found in ReplicatedStorage.GrabEvents")
    return
end

_G.MonsterLagEnabled = true

local function getSpawnLocation()
    local LP = Players.LocalPlayer
    return Workspace:FindFirstChild("SpawnLocation")
        or Workspace:FindFirstChild("Spawn")
        or (LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
end

task.spawn(function()
    while _G.MonsterLagEnabled and CreateLine do
        local spawnLocation = getSpawnLocation()
        if spawnLocation then
            local randomX = math.random(-9e9, 9e9)
            local randomZ = math.random(-9e9, 9e9)
            CreateLine:FireServer(spawnLocation, CFrame.new(randomX, 0, randomZ))
        end
        task.wait()
    end
end)
