local Services = require(workspace.Services)

local EventNamespace

if Services.run:IsServer() then
	EventNamespace = "OnServerEvent"

	local folder = Instance.new("Folder")
	folder.Name = "XPackage"
	folder.Parent = Services.rs

    local XSignal = Instance.new("Configuration")
	XSignal.Name = "XRemote"
	XSignal.Parent = folder

    local XShared = Instance.new("Configuration")
	XShared.Name = "XShared"
	XShared.Parent = folder

	local Event = Instance.new("RemoteEvent")
	Event.Name = "ServerClient"
	Event.Parent = XShared
else
	EventNamespace = "OnClientEvent"
end

local XPackage = {
   XSignal = require(script.XSignal),
   XShared = require(script.XShared),
   XThread = require(script.XThread),
}

for i,v in XPackage do
	v.EventNamespace = EventNamespace
    for i2,v2 in XPackage do
        if i2 == i or not v.__packages then continue end
        v.__packages[i2] = v2
    end
end

return XPackage

--[[

local XPackages = {}::{
	XThread: typeof(require(Services.rs.modules.XPackage.XThread)),
	XShared: typeof(require(Services.rs.modules.XPackage.XShared)),
	XSignal: typeof(require(Services.rs.modules.XPackage.XSignal)),
}
]]