local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local state = {
    plotName = "Plot3",
    autoTP = false,
    ownerOnly = true,
    hasTriggered = false,
    lastCFrame = nil,
    timeValue = nil,
}

local Window = Rayfield:CreateWindow({
    Name = "inf time",
    LoadingTitle = "inf time",
    LoadingSubtitle = "inf time ykyk",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false
    },
    KeySystem = false
})

local MainTab = Window:CreateTab("inf time", 4483362458)

local function RayNotify(title, msg)
    Rayfield:Notify({
        Title = title,
        Content = msg,
        Duration = 3,
        Image = 4483362458
    })
end

local function CheckPlotOwner(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false, "Plots missing" end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false, plotName .. " missing" end
    local ownerName = ""
    local plotSign = plot:FindFirstChild("PlotSign")
    if plotSign then
        local ownersFolder = plotSign:FindFirstChild("ThisPlotsOwners")
        if ownersFolder then
            for _, child in ipairs(ownersFolder:GetChildren()) do
                if child:IsA("StringValue") or child:IsA("ObjectValue") then
                    local v = tostring(child.Value)
                    if v ~= "" then ownerName = v break end
                end
                if child.Name == "Value" then
                    ownerName = tostring(child.Value)
                    break
                end
            end
            local valObj = ownersFolder:FindFirstChild("Value")
            if valObj then ownerName = tostring(valObj.Value) end
        end
    end
    if ownerName == "" then
        for _, desc in ipairs(plot:GetDescendants()) do
            if (desc.Name == "Value" or desc.Name == "Owner") and (desc:IsA("StringValue") or desc:IsA("ObjectValue")) then
                ownerName = tostring(desc.Value)
                if ownerName ~= "" then break end
            end
        end
    end
    if ownerName == LocalPlayer.Name or ownerName == "VyzenAlt" or ownerName == "VYZEN_NN" then
        return true, ownerName
    end
    return false, ownerName ~= "" and ownerName or "None"
end

local function FindTimeRemaining(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        local plot = plots:FindFirstChild(plotName or "Plot3")
        if plot then
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc.Name == "TimeRemainingNum" and (desc:IsA("IntValue") or desc:IsA("NumberValue")) then
                    return desc
                end
            end
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.Name == "TimeRemainingNum" and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            return v
        end
    end
    return nil
end

local function TeleportToPlotHouse(plotName)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local plots = workspace:FindFirstChild("Plots")
    local plot = plots and plots:FindFirstChild(plotName or "Plot3")
    if not plot then
        RayNotify("Teleport Error", (plotName or "Plot3") .. " not found")
        return
    end
    local house = plot:FindFirstChild("House", true)
    if not house then
        RayNotify("Teleport Error", "House not found")
        return
    end
    local targets = {"BigFatTree", "BigSkinTree", "FireLog", "Deck", "Chimney", "Chimney2", "BottomTrim"}
    local targetPart = nil
    for _, name in ipairs(targets) do
        local obj = house:FindFirstChild(name, true)
        if obj then
            if obj:IsA("BasePart") then targetPart = obj break end
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then targetPart = part break end
        end
    end
    if not targetPart then
        targetPart = house:FindFirstChildWhichIsA("BasePart", true)
    end
    if targetPart then
        hrp.CFrame = targetPart.CFrame + Vector3.new(0, 8, 0)
        RayNotify("Teleported", "Landed on " .. targetPart.Name)
    else
        hrp.CFrame = house:GetPivot() + Vector3.new(0, 10, 0)
        RayNotify("Teleported", "Used House pivot")
    end
    task.delay(2, function()
        if state.lastCFrame and character and character.Parent and hrp and hrp.Parent then
            hrp.CFrame = state.lastCFrame
            RayNotify("Returned", "Returned to original position")
        end
    end)
end

local function CheckAndTeleport()
    if not state.timeValue or not state.timeValue.Parent then
        state.timeValue = FindTimeRemaining(state.plotName)
    end
    local isOwner = CheckPlotOwner(state.plotName)
    if state.timeValue then
        local val = state.timeValue.Value
        if val > 9 then
            state.hasTriggered = false
        end
        if val == 8 and not state.hasTriggered then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then state.lastCFrame = hrp.CFrame end
        end
        if val <= 6 and not state.hasTriggered then
            if (not state.ownerOnly) or isOwner then
                state.hasTriggered = true
                RayNotify("Auto TP Triggered", "Timer: " .. tostring(val) .. "s - TPing to house")
                TeleportToPlotHouse(state.plotName)
                return true
            end
        end
    end
    return false
end

local StatusParagraph = MainTab:CreateParagraph({
    Title = "Plot Status",
    Content = state.plotName .. " | Timer: N/A | Owner: ..."
})

MainTab:CreateDropdown({
    Name = "Select Plot Target",
    Options = {"Plot1", "Plot2", "Plot3", "Plot4", "Plot5"},
    CurrentOption = {state.plotName},
    MultipleOptions = false,
    Flag = "PlotSelect",
    Callback = function(Option)
        local selected = typeof(Option) == "table" and Option[1] or Option
        state.plotName = selected
        state.timeValue = nil
        state.hasTriggered = false
        RayNotify("Plot Changed", "Selected " .. selected)
    end,
})

MainTab:CreateToggle({
    Name = "Auto TP (Timer <= 6s)",
    CurrentValue = state.autoTP,
    Flag = "AutoTPToggle",
    Callback = function(Value)
        state.autoTP = Value
        state.hasTriggered = false
        state.timeValue = FindTimeRemaining(state.plotName)
        RayNotify("Auto TP", Value and ("Watching " .. state.plotName) or "Auto TP Disabled")
    end,
})

MainTab:CreateToggle({
    Name = "Only When I Own Plot",
    CurrentValue = state.ownerOnly,
    Flag = "OwnerOnlyToggle",
    Callback = function(Value)
        state.ownerOnly = Value
    end,
})

MainTab:CreateButton({
    Name = "Force TP To House Now",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then state.lastCFrame = hrp.CFrame end
        TeleportToPlotHouse(state.plotName)
    end,
})

task.spawn(function()
    local lastStatusUpdate = 0
    while true do
        if state.autoTP then
            CheckAndTeleport()
        else
            if not state.timeValue or not state.timeValue.Parent then
                state.timeValue = FindTimeRemaining(state.plotName)
            end
        end
        local now = tick()
        if now - lastStatusUpdate > 0.5 then
            lastStatusUpdate = now
            local isOwner, ownerInfo = CheckPlotOwner(state.plotName)
            local val = (state.timeValue and state.timeValue.Parent) and state.timeValue.Value or "N/A"
            
            StatusParagraph:Set({
                Title = "Plot Status",
                Content = state.plotName .. " | Timer: " .. tostring(val) .. "s | Owner: " .. tostring(ownerInfo)
            })
        end
        task.wait(0.15)
    end
end)
