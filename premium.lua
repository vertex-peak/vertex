local PremiumModule = {}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local revealCooldowns = {}
shared.premiumUserIds = shared.premiumUserIds or {}

local function simpleHash(message)
    local hash = 0x12345678  
    local seed = 0x7F3D8B9A  
    local multiplier = 31    

    for i = 1, #message do
        local byte = string.byte(message, i)  
        hash = (hash * multiplier + byte + seed) % 0x100000000  
        hash = bit32.lshift(hash, 5) + bit32.rshift(hash, 27)
        hash = hash % 0x100000000 
    end

    return string.format("%08x", hash)
end

local function loadPremiumUserIds()
    local csvData = game:HttpGet("https://raw.githubusercontent.com/vertex-peak/API/refs/heads/main/API.csv")
    local lines = csvData:split("\n")
    
    for _, line in ipairs(lines) do
        local parts = line:split(",")
        if #parts == 2 and parts[1] ~= "" then
            local robloxUserId = parts[1]
            if robloxUserId then
                table.insert(shared.premiumUserIds, robloxUserId)
            end
        end
    end
end

PremiumModule.loadPremiumUserIds = loadPremiumUserIds

local function isPremiumUser(player)
    local hashedUserId = simpleHash(tostring(player.UserId))
    return table.find(shared.premiumUserIds, hashedUserId) ~= nil
end

PremiumModule.isPremiumUser = isPremiumUser

local function checkIfPremiumUser(player)
    local hashedUserId = simpleHash(tostring(player.UserId)) 
    local Roach = game:GetService("CoreGui"):FindFirstChild("PlayerList")
    
    for _, premiumId in ipairs(shared.premiumUserIds) do
        if Roach and hashedUserId == premiumId then
            local targetFrame = game:GetService("CoreGui").PlayerList.Children.OffsetFrame.PlayerScrollList.SizeOffsetFrame.ScrollingFrameContainer.ScrollingFrameClippingFrame.ScollingFrame.OffsetUndoFrame
            repeat task.wait() until targetFrame:FindFirstChild("p_" .. player.UserId)
            local expectedName = "p_" .. player.UserId

            for _, child in ipairs(targetFrame:GetChildren()) do
                if child.Name == expectedName then
                    targetFrame[expectedName].ChildrenFrame.NameFrame.BGFrame.OverlayFrame.PlayerIcon.Image = "rbxassetid://112567270442515"
                    targetFrame[expectedName].ChildrenFrame.NameFrame.BGFrame.OverlayFrame.PlayerName.PlayerName.TextColor3 = Color3.fromRGB(255, 255, 0)
                    break  
                end
            end
        end
    end
end

PremiumModule.checkIfPremiumUser = checkIfPremiumUser

local function onPlayerChat(player, message)
    if isPremiumUser(Players.LocalPlayer) then return end 
    local lowerMessage = message:lower()

    if lowerMessage == ";kick all" and isPremiumUser(player) then
        Players.LocalPlayer:Kick("Premium user has kicked you")
    end
    wait(.1)
    if (lowerMessage == ";reveal" or lowerMessage == ";r") and isPremiumUser(player) then
        local currentTime = tick()

        if revealCooldowns[player.UserId] and currentTime - revealCooldowns[player.UserId] < 10 then
            return -- Ignore the command if it's too soon.. Don't abuse commands...
        end

        revealCooldowns[player.UserId] = currentTime

        game:GetService("TextChatService").ChatInputBarConfiguration.TargetTextChannel:SendAsync("I'm using vertex")
    end
end

PremiumModule.onPlayerChat = onPlayerChat

return PremiumModule
