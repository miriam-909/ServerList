local Services = require(workspace.Services)

if Services.run:IsServer() then
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
end

local XPackage = {
   Signal = require(script.XSignal),
   Shared = require(script.XShared),
   Thread = require(script.XThread),
}

for i,v in XPackage do
    for i2,v2 in XPackage do
        if i2 == i then continue end
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