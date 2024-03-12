local Services = require(workspace.Services)
local XSignal = require(Services.rs.modules.XSignal)

local player = Services.players.LocalPlayer

local GUI = player.PlayerGui:WaitForChild("ServerList")
local Servers = GUI.Canvas.ServerCanvas.Servers

local ServerUpdate = XSignal.new("ServerUpdate")
local ServerConnection: XSignal.XConnection
local initialized = false

local module = {}

function module.init(callback:()->())
    if initialized then return end
    initialized = true
    ServerConnection = ServerUpdate.Signal:Connect(callback)
end

function module.destroy()
    if not initialized then return end

    ServerConnection:Disconnect()
    initialized = false
end

function module.addServer(Server:{
    id:string,
    players: {number}
})
    
    if Servers:FindFirstChild(Server.id) then return end
    local Clone = Servers.Template:Clone()
    Clone.Visible = true
    Clone.Name = Server.id
    Clone.PlayerCount.Text = `<b>PLAYER #:</b>  {#Server.players}/50`
    Clone.ServerID = `<b>SERVER ID:</b> {Server.id}`
    Clone.Parent = Servers
end

return module
