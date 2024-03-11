local Services = require(workspace.Services)
local XSignal = require(Services.rs.modules.XSignal)

local ServerUpdate = XSignal.new("ServerUpdate","UnreliableRemoteEvent")

ServerUpdate.Signal:Connect(function(...)
    print(...)
end)