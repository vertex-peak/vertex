if not game:IsLoaded() then 
    game.Loaded:Wait()
end

getgenv().Services = setmetatable({}, {
    __index = function(self, index)
        local service = game:GetService(index)
        self[index] = service
        return service
    end
})

local Players = Services.Players
local HttpService = Services.HttpService
local VirtualUser = Services.VirtualUser
local LocalPlayer = Players.LocalPlayer

if game.PlaceId ~= 286090429 then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
    end)
end

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local requestData={cmd="INVITE_BROWSER",args={code="uunZyrPnhV"},nonce=HttpService:GenerateGUID(false)}
pcall(function()
    local req=syn and syn.request or http and http.request or http_request or request
    req({
        Url="http://127.0.0.1:6463/rpc?v=1",
        Method="POST",
        Headers={["Content-Type"]="application/json",["Origin"]="https://discord.com"},
        Body=HttpService:JSONEncode(requestData)
    })
end)

if not shared.VertexLoaded then
    getgenv().module=loadstring(game:HttpGet("https://raw.smokingscripts.org/module"))()
    shared.VertexLoaded=true

    local function loadRemote(url)
        local ok,content=pcall(game.HttpGet,game,url)
        if not ok then return false end
        local fn=loadstring(content)
        if not fn then return false end
        return pcall(fn)
    end

    local placeScript="https://raw.githubusercontent.com/vertex-peak/vertex/main/modules/"..game.PlaceId..".lua"
    if not loadRemote(placeScript) then
        loadRemote("https://raw.githubusercontent.com/vertex-peak/vertex/main/universal")
    end
end
