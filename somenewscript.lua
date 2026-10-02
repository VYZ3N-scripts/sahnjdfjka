local TCS = game:GetService("TextChatService")
local RBXGeneral = TCS:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

local function autoSendChat(messageText)
	RBXGeneral:SendAsync(messageText)
end
autoSendChat("if u can see this my autochat script works")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
	Name = "wxnter's FTAP Script.",
	LoadingTitle = "wxnter's FTAP Script",
	LoadingSubtitle = "by wxnter",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "wxnterFTAP",
		FileName = "Config"
	},
	Discord = {
		Enabled = false,
	},
	KeySystem = false
})

local tab = window:CreateTab("Home", 93364949241311)

local SETTINGS_ANTI_GRAB = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local GHOST_SPEED = 16
local SYNC_TIMEOUT = 0.8
local CLEANUP_DELAY = 0.5

local grabEventsFolder = ReplicatedStorage:WaitForChild("GrabEvents", 30)
local characterEventsFolder = ReplicatedStorage:WaitForChild("CharacterEvents", 30)
local setNetworkOwnerEvent = grabEventsFolder and grabEventsFolder:WaitForChild("SetNetworkOwner", 5)
local destroyGrabLineEvent = grabEventsFolder and grabEventsFolder:WaitForChild("DestroyGrabLine", 5)
local ragdollRemoteEvent = characterEventsFolder and characterEventsFolder:WaitForChild("RagdollRemote", 5)
local struggleEvent = characterEventsFolder and characterEventsFolder:WaitForChild("Struggle", 5)
local isHeldValue = LocalPlayer:WaitForChild("IsHeld", 30)

local currentVisualClone = nil
local renderConnection = nil
local escapeConnection = nil
local teleportSpamConnection = nil
local jumpConnection = nil
local cleanupThread = nil

local MasterControl = nil
pcall(function()
	local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
	local PlayerModule = require(PlayerScripts:WaitForChild("PlayerModule"))
	MasterControl = PlayerModule:GetControls()
end)

local function stripPartVisibilityAndQuery(part)
	if part:IsA("BasePart") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
		part.CanQuery = false
		part.CastShadow = false
	elseif part:IsA("Decal") or part:IsA("Texture") then
		part.Transparency = 1
		part.LocalTransparencyModifier = 1
	end
end

local function applyPermanentStealth(character)
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		stripPartVisibilityAndQuery(desc)
	end
	character.DescendantAdded:Connect(stripPartVisibilityAndQuery)
end

RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if character then
		for _, desc in ipairs(character:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				desc.LocalTransparencyModifier = 1
				if desc:IsA("BasePart") then
					desc.CanQuery = false
				end
			end
		end
	end
	if currentVisualClone then
		for _, desc in ipairs(currentVisualClone:GetDescendants()) do
			if desc:IsA("BasePart") or desc:IsA("Decal") then
				desc.LocalTransparencyModifier = 1
				if desc:IsA("BasePart") then
					desc.CanQuery = false
				end
			end
		end
	end
end)

local function setMobileJumpButtonEnabled(enabled)
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end
	local touchGui = playerGui:FindFirstChild("TouchGui")
	if touchGui then
		local touchControlFrame = touchGui:FindFirstChild("TouchControlFrame")
		if touchControlFrame then
			local jumpButton = touchControlFrame:FindFirstChild("JumpButton")
			if jumpButton then
				jumpButton.Visible = enabled
				jumpButton.Active = enabled
			end
		end
	end
end

local function cleanupClone()
	if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
	if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
	if jumpConnection then jumpConnection:Disconnect() jumpConnection = nil end
	if currentVisualClone then
		currentVisualClone:Destroy()
		currentVisualClone = nil
	end
	local camera = workspace.CurrentCamera
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and camera then
		camera.CameraSubject = humanoid
	end
end

local function verifyAndSyncPosition(realHrp, targetCFrame, timeout)
	local startTime = os.clock()
	while (os.clock() - startTime) < timeout do
		if not realHrp or not realHrp.Parent then break end
		realHrp.Velocity = Vector3.zero
		realHrp.RotVelocity = Vector3.zero
		realHrp.CFrame = targetCFrame
		if (realHrp.Position - targetCFrame.Position).Magnitude < 0.5 then
			return true
		end
		task.wait()
	end
	return false
end

local function handleTerminationAndCleanup()
	if cleanupThread then
		task.cancel(cleanupThread)
		cleanupThread = nil
	end
	local character = LocalPlayer.Character
	local realHrp = character and character:FindFirstChild("HumanoidRootPart")
	
	if realHrp and currentVisualClone then
		local cloneHrp = currentVisualClone:FindFirstChild("HumanoidRootPart")
		if cloneHrp then
			if teleportSpamConnection then teleportSpamConnection:Disconnect() teleportSpamConnection = nil end
			if escapeConnection then escapeConnection:Disconnect() escapeConnection = nil end
			verifyAndSyncPosition(realHrp, cloneHrp.CFrame, SYNC_TIMEOUT)
		end
	end
	
	cleanupThread = task.spawn(function()
		task.wait(CLEANUP_DELAY)
		cleanupClone()
		cleanupThread = nil
	end)
end

local function AttemptNetworkShip(part)
	if not part or not part.Parent then return false end
	local partOwner = part:FindFirstChild("PartOwner")
	if partOwner and partOwner.Value == LocalPlayer.Name then return true end
	local character = LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	if setNetworkOwnerEvent then
		pcall(function()
			setNetworkOwnerEvent:FireServer(part, CFrame.lookAt(root.Position, part.Position))
		end)
	end
	for _ = 1, 5 do
		task.wait()
		local po = part:FindFirstChild("PartOwner")
		if po and po.Value == LocalPlayer.Name then return true end
	end
	return false
end

local function bindEscapeHooks(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	if not escapeConnection then
		escapeConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			hrp.AssemblyLinearVelocity = Vector3.zero
			if struggleEvent then pcall(function() struggleEvent:FireServer(LocalPlayer) end) end
			if ragdollRemoteEvent then pcall(function() ragdollRemoteEvent:FireServer(hrp, 0) end) end
		end)
	end
	if not teleportSpamConnection then
		teleportSpamConnection = RunService.Heartbeat:Connect(function()
			if not isHeldValue.Value then return end
			if currentVisualClone then
				local cloneHrpPart = currentVisualClone:FindFirstChild("HumanoidRootPart")
				if cloneHrpPart then
					hrp.Anchored = false
					if (hrp.Position - cloneHrpPart.Position).Magnitude > 0.02 then
						hrp.CFrame = cloneHrpPart.CFrame
					end
				end
			end
		end)
	end
end

local function createVisualClone(character)
	if cleanupThread and currentVisualClone then
		task.cancel(cleanupThread)
		cleanupThread = nil
		bindEscapeHooks(character)
		return
	end
	if currentVisualClone then cleanupClone() end
	character.Archivable = true
	local clone = character:Clone()
	character.Archivable = false
	local cloneHrp = clone:FindFirstChild("HumanoidRootPart")
	local cloneHumanoid = clone:FindFirstChildOfClass("Humanoid")
	local realHrp = character:FindFirstChild("HumanoidRootPart")
	if cloneHrp and realHrp then
		cloneHrp.CFrame = realHrp.CFrame
		cloneHrp.AssemblyLinearVelocity = Vector3.zero
		cloneHrp.AssemblyAngularVelocity = Vector3.zero
	end
	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("LuaSourceContainer") or desc:IsA("Sound") then
			desc:Destroy()
		else
			stripPartVisibilityAndQuery(desc)
			if desc:IsA("BasePart") then
				desc.CanTouch = false
				desc.CanQuery = false
				desc.CanCollide = (desc == cloneHrp)
			end
		end
	end
	for _, realPart in ipairs(character:GetDescendants()) do
		if realPart:IsA("BasePart") then
			for _, ghostPart in ipairs(clone:GetDescendants()) do
				if ghostPart:IsA("BasePart") then
					local noCollide = Instance.new("NoCollisionConstraint")
					noCollide.Part0 = realPart
					noCollide.Part1 = ghostPart
					noCollide.Parent = ghostPart
				end
			end
		end
	end
	if cloneHumanoid then
		cloneHumanoid.WalkSpeed = GHOST_SPEED
		cloneHumanoid.AutoRotate = true
		cloneHumanoid.PlatformStand = false
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		cloneHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		cloneHumanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
	clone.Parent = workspace
	currentVisualClone = clone
	local camera = workspace.CurrentCamera
	if cloneHumanoid and camera then
		camera.CameraSubject = cloneHumanoid
	end
	setMobileJumpButtonEnabled(true)
	jumpConnection = UserInputService.JumpRequest:Connect(function()
		if cloneHumanoid and cloneHumanoid.Health > 0 then
			cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
	renderConnection = RunService.RenderStepped:Connect(function()
		if not cloneHrp or not cloneHumanoid then return end
		local rawMoveVector = Vector3.zero
		if MasterControl and MasterControl.GetMoveVector then
			rawMoveVector = MasterControl:GetMoveVector()
		end
		if MasterControl and MasterControl.GetActiveController then
			local activeCtrl = MasterControl:GetActiveController()
			if activeCtrl and (activeCtrl.IsJumping or (activeCtrl.GetIsJumping and activeCtrl:GetIsJumping())) then
				cloneHumanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
		if rawMoveVector.Magnitude > 0 then
			local cameraCFrame = camera.CFrame
			local forward = Vector3.new(cameraCFrame.LookVector.X, 0, cameraCFrame.LookVector.Z).Unit
			local right = Vector3.new(cameraCFrame.RightVector.X, 0, cameraCFrame.RightVector.Z).Unit
			local worldMoveVector = (forward * -rawMoveVector.Z) + (right * rawMoveVector.X)
			if worldMoveVector.Magnitude > 0 then
				cloneHumanoid:Move(worldMoveVector.Unit, false)
			else
				cloneHumanoid:Move(Vector3.zero, false)
			end
		else
			cloneHumanoid:Move(Vector3.zero, false)
		end
	end)
	bindEscapeHooks(character)
end

local function setupPartOwnerListener(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end
	character.DescendantAdded:Connect(function(child)
		if not SETTINGS_ANTI_GRAB then return end
		if not (child:IsA("StringValue") and child.Name == "PartOwner" and child.Value) then return end
		if child.Value == LocalPlayer.Name then return end
		local grabbedPart = child.Parent
		if not grabbedPart or not grabbedPart:IsA("BasePart") then return end
		AttemptNetworkShip(hrp)
		if destroyGrabLineEvent then
			pcall(function()
				destroyGrabLineEvent:FireServer(grabbedPart)
			end)
		end
	end)
end

local function onCharacterAdded(character)
	applyPermanentStealth(character)
	setupPartOwnerListener(character)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

isHeldValue.Changed:Connect(function(isBeingHeld)
	if isBeingHeld and SETTINGS_ANTI_GRAB then
		local character = LocalPlayer.Character
		if character then
			createVisualClone(character)
		end
	else
		handleTerminationAndCleanup()
	end
end)

tab:CreateToggle({
	Name = "Anti Grab",
	CurrentValue = false,
	Flag = "AntiGrab",
	Callback = function(Value)
		SETTINGS_ANTI_GRAB = Value
		if not Value then
			handleTerminationAndCleanup()
		end
	end,
})

local tab2 = window:CreateTab("Credits", 4483362458)

tab2:CreateParagraph({
	Title = "Credits",
	Content = "Anti Grab was made by AI_SIMP"
})
