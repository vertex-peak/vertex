if not game:IsLoaded() then 
    game.Loaded:Wait()
end
shared.VertexLoaded = true 
local module = loadstring(game:HttpGet("https://raw.smokingscripts.org/module"))()
local vertex = loadstring(game:HttpGet("https://raw.smokingscripts.org/Library"))()

repeat task.wait() until game.Players.LocalPlayer.PlayerGui:FindFirstChild("MainGUI")

local UIS = game:GetService("UserInputService")
local platform = UIS:GetPlatform()
local isPCPlatform = platform == Enum.Platform.Windows or platform == Enum.Platform.OSX
local isPCInput = UIS.KeyboardEnabled and UIS.MouseEnabled and not UIS.TouchEnabled

if not isPCPlatform and not isPCInput then
    size = UDim2.fromOffset(530, 395)
else 
    size = UDim2.fromOffset(580, 460)
end

local Players = Services.Players
local LocalPlayer = Players.LocalPlayer
local HttpService = Services.HttpService
local TeleportService = Services.TeleportService
local UserInputService = Services.UserInputService
local ReplicatedStorage = Services.ReplicatedStorage
local RunService = Services.RunService
local Murderer, Sheriff = nil, nil
local highlightedPlayers = {}
local currentTween, lastTeleportedCoin = nil, nil
local GunHook, speed = nil, nil

local Window = vertex:Window({
	Title = "vertex",
	Subtitle = "discord.gg/vxt",
	Size = size,
	DragStyle = 1,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.LeftControl,
	AcrylicBlur = false,
})

Vertex = Window:TabGroup()

shared.tabs = {
	Main = Vertex:Tab({ Name = "Main", Image = "rbxassetid://10734934585" }),
	Target = Vertex:Tab({ Name = "Target", Image = "rbxassetid://10709818534" }),
	Visual = Vertex:Tab({ Name = "Misc", Image = "rbxassetid://10709818399" }),
	Roles = Vertex:Tab({ Name = "Roles", Image = "rbxassetid://10747373426" }),
	Tracker = Vertex:Tab({ Name = "Webhook", Image = "rbxassetid://10709811110" }),
	Player = Vertex:Tab({ Name = "Player", Image = "rbxassetid://10747373176" }),
	Settings = Vertex:Tab({ Name = "Settings", Image = "rbxassetid://10734950309" })
}

repeat task.wait() until shared.loaded 

local function isMobileDevice()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function Equip(toolName)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local tool = LocalPlayer.Backpack:FindFirstChild(toolName)

    if humanoid and tool then
        humanoid:EquipTool(tool)
    end
end

local function TargetModel(target)
    for _, model in pairs(workspace:GetChildren()) do
        if model:IsA("Model") and not string.find(string.lower(model.Name), "lobby") then
        
            local coinContainer = model:FindFirstChild("CoinContainer")
            local spawnsFolder = model:FindFirstChild("Spawns")

            if target == "CoinContainer" and coinContainer then
                return coinContainer
            elseif target == "Spawns" and spawnsFolder then

                return spawnsFolder
            end
        end
    end
    return nil
end

local function findGunDrop()
    if TargetModel("Spawns") then 
        return TargetModel("Spawns").Parent:FindFirstChild("GunDrop") or false
    end
end

local function IsAlive(Player, roles)
    local role = roles and roles[Player.Name]
    local char = Player.Character

    if not role then
        return false
    end

    if not role.Killed and not role.Dead then
        return true
    end

    if char and char:FindFirstChild("HumanoidCloned") then
        return true 
    end

    return false 
end

local function Fetch(itemName)
    for _, player in ipairs(game.Players:GetPlayers()) do 
        if player.Backpack:FindFirstChild(itemName) or (player.Character and player.Character:FindFirstChild(itemName)) then
            return player.Name
        end
    end   
    return nil 
end

local function setCharacterAttributes(walkSpeed, jumpPower)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if humanoid then
        if walkSpeed then
            humanoid.WalkSpeed = walkSpeed
        end
        if jumpPower then
            humanoid.JumpPower = jumpPower
        end
    end
end

function CoinAttribute(part, CheckCoin)
    local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    local partPosition = part.Position
    local humanoidPosition = humanoid.Parent.PrimaryPart.Position
    
    if (partPosition - humanoidPosition).Magnitude <= 4 and shared.Premium then wait()
        firetouchinterest(part, LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), 1)
        wait(.1)
        firetouchinterest(part, LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), 0)
        part:Destroy()
    end
    if (partPosition - humanoidPosition).Magnitude <= 2 then wait(.1)
        part.Name = "vertex_collected"
    end

    if part:GetAttribute("Collected") ~= true and CheckCoin then 
        return true
    end
    return false 
end

local function TrackCoinBag()

    local elite = LocalPlayer:GetAttribute("Elite")
    local role = roles[LocalPlayer.Name]

    if role then
        local coins = tonumber(role.Coins) or 0
        
        if elite ~= nil and coins == 50 then
            return true
        elseif elite == nil and coins == 40 then
            return true
        end
    end

    return false
end

local function tween_teleport(TargetFrame, Time, SlowDown, fullywait, coin)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        
    if humanoidRootPart then
        if currentTween then
            currentTween:Cancel()
        end

        humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        humanoidRootPart.AssemblyAngularVelocity = Vector3.zero

        local distance = (humanoidRootPart.Position - TargetFrame.Position).Magnitude
        local speed = Time 
        local tweenDuration = math.clamp(distance / speed, 0.15, 5)

        local tweenInfo = TweenInfo.new(
            tweenDuration,
            SlowDown and Enum.EasingStyle.Quad or Enum.EasingStyle.Linear,
            SlowDown and Enum.EasingDirection.Out or Enum.EasingDirection.In
        )

        local move = Services.TweenService:Create(
            humanoidRootPart,
            tweenInfo,
            { CFrame = TargetFrame }
        )

        currentTween = move
        move:Play()

        if fullywait == true then 
            repeat
                task.wait()
                CoinAttribute(coin, true)
            until not CoinAttribute(coin, true)
               or TrackCoinBag()
               or not IsAlive(LocalPlayer, roles)
        end

        currentTween = nil
    end
end

function ShootMurderer()
    local murdererName = Murderer
    local player = game.Players.LocalPlayer
    if not player then return end

    local Gun = nil
    if player:FindFirstChild("Backpack") then
        Gun = player.Backpack:FindFirstChild("Gun")
    end
    if not Gun and player.Character then
        Gun = player.Character:FindFirstChild("Gun")
    end
    if not Gun then return end

    if not murdererName then return end
    local murderer = game.Players:FindFirstChild(murdererName)
    if not murderer or not murderer.Character then return end

    local murdererHRP = murderer.Character:FindFirstChild("HumanoidRootPart")
    local murdererHum = murderer.Character:FindFirstChild("Humanoid")
    if not murdererHRP or not murdererHum then return end

    local velocity = murdererHRP.AssemblyLinearVelocity or Vector3.new(0,0,0)
    local moveDir = murdererHum.MoveDirection or Vector3.new(0,0,0)
    local predictedPos = murdererHRP.Position + (velocity * Vector3.new(0, 0.5, 0)) * (2.8 / 15) + moveDir * 2.8
    local ohCFrame1
    local ohCFrame2 = CFrame.new(predictedPos)

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if Options.KillM:GetValue() then
        local rootAttachment = murdererHRP:FindFirstChild("RootAttachment")
        if rootAttachment then
            ohCFrame1 = rootAttachment.WorldCFrame * CFrame.new(0, 2, 0)
        else
            ohCFrame1 = murdererHRP.CFrame
        end
    else
        local gunShoulder = hrp:FindFirstChild("GunShoulderAttachment")
        if gunShoulder then
            ohCFrame1 = gunShoulder.WorldCFrame
        else
            ohCFrame1 = hrp.CFrame
        end
    end

    if Gun and Gun:FindFirstChild("Handle") then
        local handle = Gun.Handle
        if handle:FindFirstChild("Reload") and not handle.Reload.Playing then
            local shootEvent = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("Gun") and workspace[player.Name].Gun:FindFirstChild("Shoot")
            if shootEvent then
                shootEvent:FireServer(ohCFrame1, ohCFrame2)
            end
        end
    end
end

local function isPlayerVisible(player)
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local targetHRP = player.Character.HumanoidRootPart
        local rayDirection = (targetHRP.Position - rootPart.Position).Unit * 50
        
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local hit = workspace:Raycast(rootPart.Position, rayDirection, raycastParams)
        return not hit or hit.Instance.Parent == player.Character
    end
    
    return false
end

local function BodyVelocity()
    if not LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") then
        local bodyVelocity = Instance.new('BodyVelocity')
        bodyVelocity.Name = "BodyVelocity"
        bodyVelocity.velocity = Vector3.new(0, 0, 0)
        bodyVelocity.maxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Parent = LocalPlayer.Character.HumanoidRootPart
    end
end 

local function DestroyBody() 
    if LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity") then 
        LocalPlayer.Character.HumanoidRootPart:FindFirstChild("BodyVelocity"):Destroy()
    end
end

local function resetCharacter()
    pcall(function()
    if Options.Mode:GetValue() == "Nearest"  then 
        LocalPlayer.Character.Humanoid.Health = 0
    else 
        local character = LocalPlayer.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        for _, folder in pairs(workspace:GetChildren()) do
            if folder:IsA("Model") or folder:IsA("Folder") then
                if string.find(string.lower(folder.Name), "lobby") then
                    for _, object in pairs(folder:GetDescendants()) do
                        if object:IsA("SpawnLocation") then
                            tween_teleport(
                                CFrame.new(object.Position + Vector3.new(0, 5, 0)),
                                5000
                            )
                            return
                        end
                    end
                end
            end
        end
    end
    end)
end

local function findCoin(humanoidRootPart, mode)
    local closestCoin = nil
    local minimum_distance = math.huge
    local validCoins = {}
    local allCoins = {}
    local farCoins = {}  

    local murderer = game.Players:FindFirstChild(Murderer)
    local MurdererHumanoid = murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
    local murdererPosition = MurdererHumanoid and MurdererHumanoid.Position or nil

    for _, v in pairs(TargetModel("CoinContainer"):GetChildren()) do
        if CoinAttribute(v, true) and v.Name == "Coin_Server" and v:FindFirstChild("TouchInterest") and IsAlive(LocalPlayer, roles) then
            local partPosition = v.CoinVisual.Position
            local distance = (humanoidRootPart.Position - partPosition).Magnitude

            if murdererPosition then
                local murdererDistance = (partPosition - murdererPosition).Magnitude

                if murdererDistance >= 25 then
                    table.insert(farCoins, v)
                end

                if distance <= 50 then
                    table.insert(validCoins, v)
                end

                if distance < minimum_distance then
                    minimum_distance = distance
                    closestCoin = v
                end
            end
        end
    end

    if mode == "closest" then
        return closestCoin
    elseif mode == "random" then
        if #validCoins == 0 then
            if #farCoins > 0 then
                return farCoins[math.random(1, #farCoins)]
            end
        else
            if #validCoins > 0 then
                return validCoins[math.random(1, #validCoins)]
            end
        end
    end

    return nil
end

local speed 

local function teleportToCoin(targetCoin, humanoidRootPart)
    local targetPosition = targetCoin.CoinVisual.Position
    local distanceToTarget = (humanoidRootPart.Position - targetPosition).Magnitude
    local humanoid = LocalPlayer.Character:FindFirstChild('Humanoid')


    speed = 21

    
    if not TrackCoinBag() and CoinAttribute(targetCoin, true) then 
        local targetCFrame = CFrame.new(targetPosition.X, targetPosition.Y, targetPosition.Z)

        if Options.Mode:GetValue() == "Randomize" then 
            if distanceToTarget > 200 then 
                humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 10, 0)
                wait(2)
                tween_teleport(targetCFrame * CFrame.new(0, 1.5, 0), distanceToTarget > 200 and speed or speed, false)
            else 
            tween_teleport(targetCFrame * CFrame.new(0, 1.5, 0), 20, true, true, targetCoin)
            end
        else
            if distanceToTarget > 200 then 
                humanoidRootPart.CFrame = targetCFrame * CFrame.new(0, 10, 0)
                wait(2)
                tween_teleport(targetCFrame * CFrame.new(0, 1.5, 0), distanceToTarget > 200 and 5000 or speed, false)
            else
                tween_teleport(targetCFrame * CFrame.new(0, 1.5, 0), distanceToTarget > 20 and speed or speed, false)

            end
        end
    end
end

local function AutoFarm()
    local success, result = pcall(function()
        local character = LocalPlayer.Character
        local humanoid = character:FindFirstChild('Humanoid')
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not Murderer then 
            DestroyBody() 
            return
        end

        if TrackCoinBag() and humanoidRootPart and humanoid.Health > 0 and IsAlive(LocalPlayer, roles) and ((not Options.KillAll:GetValue() and not Options.KillM:GetValue() and not Options.AutoShoot:GetValue()) or (Murderer ~= LocalPlayer.Name and Sheriff ~= LocalPlayer.Name)) then
            resetCharacter()
            return 
        end 

        if Options.AutoFarm:GetValue() and IsAlive(LocalPlayer, roles) then 
            local targetCoin
            if Options.Mode:GetValue() == "Nearest" or Options.Mode:GetValue() == "Nearest + XP Farm" then 
                targetCoin = findCoin(humanoidRootPart, "closest")
            else
                targetCoin = findCoin(humanoidRootPart, "random")
            end

            if targetCoin then

                if not humanoidRootPart then return end 

                if lastTeleportedCoin ~= targetCoin then
                    BodyVelocity()
                    teleportToCoin(targetCoin, humanoidRootPart)
                    lastTeleportedCoin = targetCoin  
                end
            end
        end
    end)
end

local function ManageHighlights()
    for _, player in pairs(Services.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                local highlight = player.Character:FindFirstChild("Highlight")

                if not highlight then
                    highlight = Instance.new("Highlight", player.Character)
                    highlightedPlayers[player] = highlight
                end

                if IsAlive(player, roles) then
                    local role = roles[player.Name]
                    if role then
                        if role.Role == "Murderer" then
                            highlight.FillColor = Color3.fromRGB(225, 0, 0)
                        elseif role.Role == "Sheriff" or role.Role == "Hero" then
                            highlight.FillColor = Color3.fromRGB(0, 0, 225)
                        else
                            highlight.FillColor = Color3.fromRGB(76, 215, 134)
                        end
                    else
                        highlight.FillColor = Color3.fromRGB(76, 215, 134)
                    end
                else
                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                end
            else
                local highlight = highlightedPlayers[player]
                if highlight then
                    highlight:Destroy()
                    highlightedPlayers[player] = nil
                end
            end
        end
    end
end

local function createUsernameTag(player)
    if player == game.Players.LocalPlayer then
        return
    end

    local character = player.Character
    if character and character:FindFirstChild("Head") then
        local head = character.Head
        
        if not head:FindFirstChild("UsernameTag") then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "UsernameTag"  
            billboard.Adornee = head
            billboard.Parent = head
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0) 
            billboard.AlwaysOnTop = true 

            local textLabel = Instance.new("TextLabel")
            textLabel.Parent = billboard
            textLabel.Text = player.Name
            textLabel.TextSize = 20
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            textLabel.TextStrokeTransparency = 0.5
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.Font = Enum.Font.SourceSansBold
        end
    end
end

local function DestroyHighlights()
    for player, highlight in pairs(highlightedPlayers) do
        if highlight then
            highlight:Destroy()
            highlightedPlayers[player] = nil
        end
    end

    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Head") then
                local head = character.Head
                if head:FindFirstChild("UsernameTag") then
                    head:FindFirstChild("UsernameTag"):Destroy()
                end
            end
        end
    end
end

local function NoclipLoop()
    if LocalPlayer.Character ~= nil then
        for _, child in pairs(LocalPlayer.Character:GetDescendants()) do
            if child:IsA("BasePart") and child.CanCollide == true and IsAlive(LocalPlayer, roles) then
                child.CanCollide = false
            end
        end
    end
end

local AutoFarm = shared.Main:Toggle("AutoFarm", "Auto Farm", function(value)  
    if value then 
        Noclipping = RunService.Stepped:Connect(NoclipLoop)
    end
    repeat task.wait() 
        AutoFarm()
    until not Options.AutoFarm:GetValue()
    Noclipping:Disconnect()
    DestroyBody() 
end)

local Dropdown = shared.Main:Dropdown({
	Name = "Farm Mode",
	Multi = false,
	Required = true,
	Options = {"Nearest + XP Farm", "Nearest", "Randomize"},
	Default = 2,
	Callback = function(Value)
        DestroyBody() 
	end,
}, "Mode")

local autoFarmToggle = shared.Main:Toggle("AutoGrab", "Automatically Grab Gun", function(value) 
    if value then
        repeat task.wait()
            pcall(function()
                if Murderer then
                    local murderer = game.Players:FindFirstChild(Murderer)
                    local MurdererHumanoid = murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart")
                    local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
                    if IsAlive(LocalPlayer, roles) and Murderer ~= LocalPlayer.Name and Humanoid and findGunDrop() and (TrackCoinBag() or not Options.AutoFarm:GetValue()) then
                        local distance = (MurdererHumanoid.Position - findGunDrop().Position).magnitude
                        local gunDrop = findGunDrop()
        
                        if gunDrop then
                            gunDrop.CFrame = Humanoid.CFrame
                        end
                    end
                end
            end)
        until not Options.AutoGrab:GetValue()
    end
end)

local Target = shared.Target:Dropdown({
    Name = "Target",
    Search = true,
    Multi = false,
    Required = false,
    Options = {}, 
    Default = {},
    Callback = function(Value)
    end,
}, "Target")


local autoFarmToggle = shared.Target:Toggle("TargetFling", "Fling Target", function(value)
    if value then
        repeat
            task.wait()
            local targetName = Options.Target:GetValue()
            local target = Options.Target:GetValue() and game.Players:FindFirstChild(targetName)
            if target then
                module:fling(target)
            end
            task.wait(3)
        until not Options.TargetFling:GetValue()
    end
end)


shared.Target:Toggle("Spectate", "Spectate Target", function(value)
    if value then
        repeat task.wait()
            local targetName = Options.Target:GetValue()
            local targetPlayer = game.Players:FindFirstChild(targetName)

            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                game.Workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Head
            end

        until not Options.Spectate:GetValue()
        local character = game.Players.LocalPlayer.Character
        if character then
            game.Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
			game.Workspace.CurrentCamera.CameraType = "Custom"
        end
    end
end)

local autoFarmToggle = shared.Target:Toggle("Annoy", "Loop Go To Target", function(value) 
    if value then
        repeat task.wait()
            local success, err = pcall(function()
                local character = game.Players.LocalPlayer.Character
                if not character or not character:FindFirstChild("HumanoidRootPart") then
                    return
                end
        
                local targetName = Options.Target:GetValue()
                local target = workspace:FindFirstChild(targetName)
                
                if target and target:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                end
            end)
        until not Options.Annoy:GetValue()
    end
end)

shared.Target:Button({
    Name = "Teleport To Target",
    Callback = function()
        local character = game.Players.LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end

        local targetName = Options.Target:GetValue()
        local target = workspace:FindFirstChild(targetName)
        
        if target and target:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
        end
    end,
})

shared.Target:Divider()

local autoFarmToggle = shared.Target:Toggle("FlingSheriff", "Fling Sheriff", function(value) 
    if value then
        repeat task.wait()
            local success, err = pcall(function()
                local target = Sheriff and game.Players:FindFirstChild(Sheriff) 
                if Sheriff ~= LocalPlayer.Name then 
                    module:fling(target)
                    wait(3)
                end
            end)
        until not Options.FlingSheriff:GetValue()
    end
end)

local autoFarmToggle = shared.Target:Toggle("FlingMurderer", "Fling Murderer", function(value) 
    if value then
        repeat task.wait()
            local success, err = pcall(function()
                local target = Murderer and game.Players:FindFirstChild(Murderer) 
                if target and Murderer ~= LocalPlayer.Name then 
                    module:fling(target)
                    wait(3)
                end
            end)
        until not Options.FlingMurderer:GetValue()
    end
end)

local function updateDropdownOptions()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then 
            Target:InsertOptions({player.Name})
        end
    end
end

local PlayerAddedConnection = Players.PlayerAdded:Connect(function(player)
    Target:InsertOptions({player.Name})
end)

local PlayerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    Target:RemoveOptions({player.Name})
end)

updateDropdownOptions()

local DodgeKnife = shared.Main:Toggle("DodgeKnife", "Dodge Thrown Knife", function(value) 
    if value then
        repeat task.wait()
            pcall(function()
                for _, child in ipairs(workspace:GetChildren()) do
                    if child.Name == "ThrowingKnife" then
                        local bladePosition = child:FindFirstChild("BladePosition")
                        local knifeVisual = child:FindFirstChild("KnifeVisual")
                        
                        if bladePosition then
                            local distance = (bladePosition.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            
                            if distance <= 15 then                                
                                local originalPosition = LocalPlayer.Character.HumanoidRootPart.Position
            
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(originalPosition.X, originalPosition.Y + 100, originalPosition.Z)
                                
                                wait(.2)
                                
                                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(originalPosition)
                            end
                        end
                    end
                end
            end)
        until not Options.DodgeKnife:GetValue()
    end
end)

local autoFarmToggle = shared.Main:Toggle("EndRound", "Auto End Round", function(value) 
    if value then
        Window:Notify({Title = 'Notification', Description = 'Flings Murderer when you are not in the round.', Duration = 5 })
        repeat task.wait()
            local murderer = Murderer and game.Players:FindFirstChild(Murderer) 
            if murderer and not IsAlive(LocalPlayer, roles) and Murderer ~= LocalPlayer.Name then 
                module:fling(murderer)
                wait(3)
            end
        until not Options.EndRound:GetValue()
    end
end)

shared.Main:Divider()

shared.Main:Button({
    Name = "Teleport To Lobby",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character
        if not character then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- Find any lobby-like model in workspace
        for _, folder in pairs(workspace:GetChildren()) do
            if folder:IsA("Model") or folder:IsA("Folder") then
                if string.find(string.lower(folder.Name), "lobby") then
                    -- Look for a SpawnLocation inside it
                    for _, object in pairs(folder:GetDescendants()) do
                        if object:IsA("SpawnLocation") then
                            tween_teleport(
                                CFrame.new(object.Position + Vector3.new(0, 5, 0)),
                                5000
                            )
                            return
                        end
                    end
                end
            end
        end
    end,
})


shared.Main:Button({
	Name = "Teleport To Map",
	Callback = function()
        if not TargetModel("Spawns") then Window:Notify({Title = 'Notification', Description = 'Map does not exist.', Duration = 5}) return end
        for _, spawn in ipairs(TargetModel("Spawns"):GetDescendants()) do
            tween_teleport(spawn.CFrame * CFrame.new(0, 5, 0) , 5000) 
            return 
        end
    end,
})

shared.Visual:Toggle("Chams", "Player Chams", function(value) 
    if value then 
        repeat task.wait()
            ManageHighlights()
        until not Options.Chams:GetValue() 
        DestroyHighlights()
    end
end)

shared.Visual:Toggle("GunDropCham", "Gun Cham", function(value) 
    while value do 
        task.wait()
        local gunDrop = findGunDrop()
        if gunDrop then
            local esp = gunDrop:FindFirstChild("GunESP")
            if not esp then
                esp = Instance.new("Highlight")
                esp.Name = "GunESP"
                esp.FillTransparency = 0.5
                esp.FillColor = Color3.new(128/255, 225/255, 0) 
                esp.OutlineColor = Color3.new(0, 163/255, 0)
                esp.OutlineTransparency = 0
                esp.Parent = gunDrop
            end
        end
    end
end)

shared.Visual:Toggle("Render", "3DRendering", function(value) 
    if value then
        UserInputService.WindowFocusReleased:Connect(function() 
            if Options.Render:GetValue() then
                RunService:Set3dRenderingEnabled(false)
            end
        end)
        UserInputService.WindowFocused:Connect(function() 
            RunService:Set3dRenderingEnabled(true)
        end)
    end
end)

shared.Visual:Toggle("Names", "Name ESP", function(value) 
    while Options.Names:GetValue() do task.wait(0.5) 
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Character then
                createUsernameTag(player)
            end
        end
    end
    DestroyHighlights()
end)

shared.Visual:Divider()

local Dropdown = shared.Visual:Dropdown({
	Name = "Emote",
	Multi = false,
	Required = true,
	Options = {"ninja", "dab", "floss", "headless", "zen", "zombie", "sit"},
	Default = 1,
	Callback = function(Value)
	end,
}, "Emote")

shared.Visual:Toggle("AutoEmote", "Auto Emote", function(value) 
    while Options.AutoEmote:GetValue() do task.wait(.1) 
        pcall(function()
        module:emote(Options.Emote:GetValue())
        end)
    end
end)

local autoFarmToggle = shared.Roles:Toggle("KillAura", "Kill Aura", function(value) 
    if value then 
        repeat
            task.wait()
            local success, result = pcall(function() 
                local Knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
                local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
                
                for _, v in ipairs(game.Players:GetPlayers()) do
                    if v ~= LocalPlayer and v.Character and Knife and IsAlive(v, roles) then
                        local EnemyRoot = v.Character:FindFirstChild("HumanoidRootPart")
                        if EnemyRoot then
                            local EnemyPosition = EnemyRoot.Position
                            local EnemyDistance = (EnemyPosition - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            
                            if EnemyDistance <= Options.AuraDistance:GetValue() and Knife and Murderer == LocalPlayer.Name then
                                Equip("Knife")
                                
                                game:GetService("Players").LocalPlayer.Character.Knife.Events.HandleTouched:FireServer(EnemyRoot)
                            end
                        end
                    end  
                end
            end)
        until not Options.KillAura:GetValue()
    end
end)

local sliderInstance = shared.Roles:Slider("AuraDistance", "Aura Distance", 5, 50, 5, "Percent", function(value)  
end)

function KillAll()
    local success, result = pcall(function()
        local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Knife")
        Equip("Knife")

        for _, player in ipairs(game.Players:GetPlayers()) do
            game:GetService("Players").LocalPlayer.Character.Knife.Events.HandleTouched:FireServer(workspace[player.Name].HumanoidRootPart)
        end
    end)
end

local autoFarmToggle = shared.Roles:Toggle("KillAll", "Auto Kill All", function(value) 
    if value then
        repeat task.wait()
            if Murderer and (TrackCoinBag() or not Options.AutoFarm:GetValue()) and Murderer == LocalPlayer.Name then 
                KillAll() 
            end 
        until not Options.KillAll:GetValue()
    end
end)

shared.Roles:Divider()

shared.Roles:Toggle("SilentAim", "Silent Aim", function(value) 
    if value then
        local shootConnection

        repeat task.wait()
            local character = LocalPlayer.Character
            if not character then continue end

            local gun = character:FindFirstChild("Gun")

            -- Disconnect if gun is missing
            if not gun and shootConnection then
                shootConnection:Disconnect()
                shootConnection = nil
            end

            -- Only connect if gun exists and player is Sheriff and not already connected
            if gun and Sheriff == LocalPlayer.Name and not shootConnection then
                shootConnection = gun.Activated:Connect(function()
                    local murdererPlayer = Murderer and game.Players:FindFirstChild(tostring(Murderer))
                    if not murdererPlayer or not murdererPlayer.Character then return end

                    local Root = murdererPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not Root then return end

                    local ohCFrame1
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local rootAttachment = hrp:FindFirstChild("RootAttachment")
                        if rootAttachment then
                            ohCFrame1 = rootAttachment.WorldCFrame
                        else
                            ohCFrame1 = hrp.CFrame
                        end
                    else
                        ohCFrame1 = character:GetPrimaryPartCFrame()
                    end

                    local ohCFrame2 = Root.CFrame
                    local gunObj = character:FindFirstChild("Gun")
                    if gunObj and gunObj:FindFirstChild("Shoot") then
                        gunObj.Shoot:FireServer(ohCFrame1, ohCFrame2)
                    end
                end)
            end
        until not Options.SilentAim:GetValue()

        if shootConnection then 
            shootConnection:Disconnect()
            shootConnection = nil
        end
    end
end)

local KillMurderer = shared.Roles:Toggle(
    "KillM",
    "Kill Murderer (Blatant)"
    function(value)
        if value then
            repeat
                if TrackCoinBag() or not Options.AutoFarm:GetValue() then 
                task.wait()
                Equip("Gun")
                ShootMurderer()
                end
            until not Options.KillM:GetValue()
        end
    end
)

local autoFarmToggle = shared.Roles:Toggle("AutoShoot", "Auto Shoot Murderer", function(value) 
    if value then
        repeat task.wait()
            local success, result = pcall(function()
                if Murderer and Sheriff and Sheriff == LocalPlayer.Name then
                    local murderer = game.Players:FindFirstChild(Murderer)

                    if murderer and isPlayerVisible(murderer) and not Options.KillM:GetValue() and (TrackCoinBag() or not Options.AutoFarm:GetValue()) then
                        Equip("Gun")
                        ShootMurderer() 
                    end
                end
            end)
        until not Options.AutoShoot:GetValue()
    end
end)

shared.Roles:Keybind("ShootBind", "Shoot Murderer", function(binded) 
    pcall(function()
        warn("SEX")
        Equip("Gun") 
        ShootMurderer()  
    end)
end)

local webhook = shared.Tracker:Input({
	Name = "Webhook",
	Placeholder = "Webhook",
	AcceptedCharacters = "All",
	Callback = function(input)
	end,
	onChanged = function(input)
	end,
}, "Webhook")

shared.Tracker:Divider()

shared.Tracker:Toggle("CoinTracker", "Coin Tracker", function(value) 
end)

local WebhookTime = shared.Tracker:Input({
    Name = "Minutes To Send Webhook",
    Placeholder = "minutes",
    AcceptedCharacters = "Numeric",
    Callback = function(input)
        local minutes = tonumber(input)
        if minutes then
            Options.WebhookTimeInSeconds = minutes * 60
        end
    end,
}, "WebhookTime")

local TrackLabel = shared.Tracker:SubLabel({
    Text = "Coin Tracker is turned off."
})

shared.Tracker:Divider()

local Unbox = shared.Tracker:Toggle("BoxNotification", "Unbox Notification", function(value)
    if value then
        local ShopRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Shop")
        local ItemService = require(ReplicatedStorage:WaitForChild("ClientServices"):WaitForChild("ItemService"))
        local Database = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

        local function getThumbnailUrl(rbxThumb)
            local requestMethod = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if not rbxThumb then return nil end
            local assetId = tostring(rbxThumb):match("id=(%d+)")
            if not assetId then return nil end

            local res = requestMethod({
                Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=150x150&format=Png&isCircular=false",
                Method = "GET"
            })

            if not res or not res.Body then return nil end

            local data = HttpService:JSONDecode(res.Body)
            return data.data and data.data[1] and data.data[1].imageUrl or nil
        end

        unboxConnection = ShopRemotes.BoxController.Event:Connect(function(rewards)
            local OSTime = os.time()
            local Time = os.date("!*t", OSTime)

            for _, reward in ipairs(rewards) do
                local itemId = reward.RewardedItemId
                local mysteryBoxId = reward.MysteryBoxId

                local itemInfo = ItemService:GetDisplayInfo(itemId, "Weapons")
                local rarity = Database.Weapons[itemId] and Database.Weapons[itemId].Rarity or "Unknown"
                local chromaValue = itemInfo.Chroma and true or false
                local imageUrl = getThumbnailUrl(itemInfo.Image)

                local success, err = pcall(function()
                    local requestMethod = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

                    requestMethod({
                        Url = webhook:GetInput(),
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = HttpService:JSONEncode({
                            username = "Unbox Notification",
                            avatar_url = "https://cdn.discordapp.com/avatars/1408303089513009162/1fa188f8e9af284340171e003fd30bf4.webp?size=80",
                            content = chromaValue and "@everyone" or "",
                            embeds = {{
                                title = "Mystery Box Unboxed",
                                description =
                                    "**Name:** " .. tostring(itemInfo.Name) .. "\n" ..
                                    "**Rarity:** " .. tostring(rarity) .. "\n" ..
                                    "**Mystery Box:** " .. tostring(mysteryBoxId) .. "\n" ..
                                    "**Chroma:** `" .. tostring(chromaValue) .. "`",
                                thumbnail = imageUrl and { url = imageUrl } or nil,
                                timestamp = string.format(
                                    "%d-%d-%dT%02d:%02d:%02dZ",
                                    Time.year, Time.month, Time.day,
                                    Time.hour, Time.min, Time.sec
                                ),
                                footer = { text = "Powered by Vertex" }
                            }}
                        })
                    })
                end)
            end
        end)
    else
        if unboxConnection then
            unboxConnection:Disconnect()
            unboxConnection = nil
        end
    end
end)


local WalkSpeed = shared.Player:Toggle("WalkSpeed", "Walk Speed", function(value) 
    if value then
        repeat task.wait()
            setCharacterAttributes(Options.WalkSpeedSlider:GetValue())
        until not Options.WalkSpeed:GetValue()
        setCharacterAttributes(16)
    end
end)

local sliderInstance = shared.Player:Slider("WalkSpeedSlider", "Walk Speed", 16, 100, 16, "Percent", function(value)  
end)

local JumpPower = shared.Player:Toggle("Jump", "Jump Power", function(value) 
    if value then
        repeat task.wait()
            setCharacterAttributes(nil, Options.JumpPower:GetValue())
        until not Options.Jump:GetValue()
        setCharacterAttributes(nil, 50)
    end
end)

local sliderInstance = shared.Player:Slider("JumpPower", "Jump Power", 50, 100, 50, "Percent", function(value)  
end)

shared.Player:Divider()

local invis_on = false
local Invisible = shared.Player:Keybind("Invis", "Invisible [FE]", function(binded)
    if binded then
        invis_on = not invis_on 
        if invis_on then
            local savedpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            wait(0)
            game.Players.LocalPlayer.Character:MoveTo(Vector3.new(-25, 6000, 100)) 
            wait(0.35)
            local Seat = Instance.new('Seat', game.Workspace)
            Seat.Anchored = false
            Seat.CanCollide = false
            Seat.Name = 'invischair'
            Seat.Transparency = 1
            Seat.Position = Vector3.new(-25.95, 84, 3537.55)
            local Weld = Instance.new("Weld", Seat)
            Weld.Part0 = Seat
            Weld.Part1 = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or game.Players.LocalPlayer.Character.HumanoidRootPart
            wait()
            Seat.CFrame = savedpos
            Window:Notify({Title = 'Notification', Description = 'Invis enabled', Duration = 5})
        else
            local invisChair = workspace:FindFirstChild('invischair')
            if invisChair then
                Window:Notify({Title = 'Notification', Description = 'Invis disabled', Duration = 5})
                invisChair:Remove()
            end
        end
    end
end)

local characterAddedConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    invis_on = false 
    local invisChair = workspace:FindFirstChild("invischair")
    if invisChair then
        Window:Notify({
            Title = 'Notification', 
            Description = 'Invis has been disabled due to a character reset', 
            Duration = 9
        })
        invisChair:Remove()
    end
end)

local AntiFling = shared.Player:Toggle("AntiFling", "Anti Fling", function(value) 
    if value then 
        antifling = RunService.Stepped:Connect(function()
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, v in pairs(player.Character:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide == true and not Options.TargetFling:GetValue() then
                            v.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
    repeat task.wait() until not Options.AntiFling:GetValue() 
    antifling:Disconnect()
end)

local Trade = ReplicatedStorage:WaitForChild("Trade")
local DeclineTrade = Trade:FindFirstChild("DeclineTrade")

if not DeclineTrade or not DeclineTrade:IsA("RemoteEvent") then
    LocalPlayer:Kick("Security Alert:\nUnauthorized trade behavior detected.\n\nFor your safety, please use our official script.\nJoin our Discord for support:\nhttps://discord.gg/hY4RQDXrd7")
	return
end

DeclineTrade.AncestryChanged:Connect(function(_, parent)
	if not parent then
		LocalPlayer:Kick("Security Alert:\nUnauthorized trade behavior detected.\n\nFor your safety, please use our official script.\nJoin our Discord for support:\nhttps://discord.gg/hY4RQDXrd7")
	end
end)

local UpdateTrade = Trade:WaitForChild("UpdateTrade")

local updateConnection
local dialogOpen = false

DeclineTrade:FireServer()

updateConnection = UpdateTrade.OnClientEvent:Connect(function(...)
	if DeclineTrade.Parent then
		DeclineTrade:FireServer()
	else
		LocalPlayer:Kick("Security Alert:\nUnauthorized trade behavior detected.\n\nFor your safety, please use our official script.\nJoin our Discord for support:\nhttps://discord.gg/hY4RQDXrd7")
		return
	end

	if dialogOpen then
		return
	end

	dialogOpen = true

	Window:Dialog({
		Title = "WARNING",
		Description =
			"We detected items being added to a trade.\n\n" ..
			"If you did NOT see a trade UI appear on your screen, " ..
			"this may indicate a malicious or unauthorized script.\n\n" ..
			"Only use official and trusted sources.\n\n" ..
			"Official Discord:\nhttps://discord.gg/hY4RQDXrd7",
		Buttons = {
			{
				Name = "Keep Anti-Stealer Enabled",
				Callback = function()
					dialogOpen = false
				end,
			},
			{
				Name = "Disable Anti-Stealer",
				Callback = function()
					if updateConnection then
						updateConnection:Disconnect()
						updateConnection = nil
					end
					dialogOpen = false
				end
			}
		}
	})
end)

local CoinCollected = Services.ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("Gameplay"):FindFirstChild("CoinCollected")

local INTERVAL = Options.WebhookTimeInSeconds or 60
local coinsEarned = {}
local lastBagCounts = {}

local CollectedCoins = CoinCollected.OnClientEvent:Connect(function(bagName, currentCoins, maxCoins)
    coinsEarned[bagName] = coinsEarned[bagName] or 0
    lastBagCounts[bagName] = lastBagCounts[bagName] or 0

    local delta = currentCoins - lastBagCounts[bagName]
    if delta > 0 then
        coinsEarned[bagName] += delta
    end

    lastBagCounts[bagName] = currentCoins
end)

local function sendWebhook(CoinsCollected, BagName)
    local OSTime = os.time()
    local Time = os.date("!*t", OSTime)

    local success, err = pcall(function()
        local requestMethod = syn and syn.request or http and http.request or http_request or (fluxus and fluxus.request) or request
        local intervalSeconds = Options.WebhookTimeInSeconds or 60
        local intervalMinutes = intervalSeconds / 60
        local displayMinutes = intervalMinutes % 1 == 0 and intervalMinutes or tonumber(string.format("%.1f", intervalMinutes))
        local minuteLabel = displayMinutes == 1 and "Minute" or "Minutes"
        local timeLabel = tostring(displayMinutes) .. " " .. minuteLabel
        local hourlyEstimate = (CoinsCollected / intervalSeconds) * 3600

        requestMethod({
            Url = webhook:GetInput(),
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                username = "Coin Tracker",
                avatar_url = "https://cdn.discordapp.com/avatars/1408303089513009162/1fa188f8e9af284340171e003fd30bf4.webp?size=80",
                embeds = {{
                    title = "**Player Currency Tracker**",
                    color = 16777215,
                    fields = {
                        { name = "Bag:", value = BagName, inline = false },
                        { name = "Coins Collected in " .. timeLabel .. ":", value = tostring(CoinsCollected), inline = false },
                        { name = "Estimated Coins per Hour:", value = tostring(math.floor(hourlyEstimate)), inline = false }
                    },
                    timestamp = string.format(
                        "%d-%d-%dT%02d:%02d:%02dZ",
                        Time.year, Time.month, Time.day,
                        Time.hour, Time.min, Time.sec
                    ),
                    footer = { text = "Powered by Vertex" } 
                }}
            })
        })
    end)
end

spawn(function()
    while wait() do
        if shared.VertexLoaded ~= true then 
            return
        end

        if Options.CoinTracker:GetValue() then

            local countdown = Options.WebhookTimeInSeconds or 60
            while countdown > 0 and Options.CoinTracker:GetValue() do
                TrackLabel:UpdateName("Webhook being sent in " .. countdown .. " seconds")
                task.wait(1)
                countdown -= 1
            end

            if Options.CoinTracker:GetValue() then
                TrackLabel:UpdateName("Webhook sending...")

                for bagName, collected in pairs(coinsEarned) do
                    if collected > 0 then
                        sendWebhook(collected, bagName)
                    end
                end

                TrackLabel:UpdateName("Webhook sent!")

                table.clear(coinsEarned)
            end
        else
            TrackLabel:UpdateName("Coin Tracker is turned off.")
            table.clear(coinsEarned)
            table.clear(lastBagCounts)
        end
    end
end)


if not success then
    Window:Notify({Title = 'Notification', Description = 'Silent Aim is not supported', Duration = 5})
end


coroutine.wrap(function()
    while true do task.wait(.1)
        if shared.VertexLoaded ~= true then 
            if unboxConnection then 
                unboxConnection:Disconnect() 
            end
            CollectedCoins:Disconnect()
            updateConnection:Disconnect()
            characterAddedConnection:Disconnect()
            PlayerAddedConnection:Disconnect()
            PlayerRemovingConnection:Disconnect()
			shared.speed = nil
            return
        end
        local success, err = pcall(function()
            Murderer = Fetch("Knife")
            Sheriff = Fetch("Gun")
            roles = Services.ReplicatedStorage:FindFirstChild("GetPlayerData", true):InvokeServer()
        end)
    end
end)()

shared.tabs.Main:Select(shared.Main)
shared.tabs.Settings:InsertConfigSection("Left", Window)
vertex:LoadConfig(game.PlaceId)			

local VOID_Y = workspace.FallenPartsDestroyHeight
local MAX_Y = 5000
local LIMIT_TIME = 5

local outOfBoundsStart = nil
local lastPlatformCFrame = nil

local function getPlatformPosition(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not root or not humanoid then
        return nil
    end

    if humanoid.FloorMaterial == Enum.Material.Air then
        return nil
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}

    local result = workspace:Raycast(
        root.Position,
        Vector3.new(0, -10, 0),
        params
    )

    if result and result.Instance:IsA("BasePart") then
        return root.CFrame
    end

    return nil
end

while task.wait(0.1) do
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if root then
        local y = root.Position.Y

        local inVoid = y < VOID_Y
        local tooHigh = y > MAX_Y
        local outOfBounds = inVoid or tooHigh


        if not outOfBounds then
            local platformPosition = getPlatformPosition(character)

            if platformPosition then
                lastPlatformCFrame = platformPosition
            end

            outOfBoundsStart = nil
        else
            if not outOfBoundsStart then
                outOfBoundsStart = os.clock()
            end

            local elapsed = os.clock() - outOfBoundsStart

            if elapsed >= LIMIT_TIME then

                if lastPlatformCFrame then
                    root.CFrame = lastPlatformCFrame + Vector3.new(0, 4, 0)

                    root.AssemblyLinearVelocity = Vector3.zero
                    root.AssemblyAngularVelocity = Vector3.zero

                end

                outOfBoundsStart = nil
            end
        end
    else
        outOfBoundsStart = nil
    end
end
	
