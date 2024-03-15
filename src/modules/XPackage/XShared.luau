local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local Types = require(Services.rs.modules.XPackage.__types)

local newproxy = Util.newproxy

local IsServer = Services.run:IsServer()

local XPackages = {}::{
	XThread: typeof(require(Services.rs.modules.XPackage.XThread)),
	XShared: typeof(require(Services.rs.modules.XPackage.XShared)),
	XSignal: typeof(require(Services.rs.modules.XPackage.XSignal)),
}

export type XShared = Types.XShared

type SharedMetaData = {
	Remote: Types.XRemote,
	Connection:  Types.XConnection,
	Initialized: boolean,
}

local __SharedData,__Shared = {},{}
local Push,Pull
local access

Push = function()
	
end

Pull = function()
	
end

__Shared = {
	type = "XShared",
	__methods = {
		Push = Push,
		Pull = Pull,
	}
}

access = function(Namespace:string):XShared
	local existing = __SharedData[Namespace]
	if existing then return existing end
	
	local proxy:XShared,meta:SharedMetaData = newproxy(__Shared,{
		__private = {
			Initialized = false,
			Remote = XPackages.XSignal.new(Namespace),
		},
		__public = {},
	})
	meta.Remote:Fire()
	meta.Connection = meta.Remote.Signal:Connect(function(Value)
		
	end)
	return proxy
end

if IsServer then

else

end

return {
	access = access,
	__packages = XPackages,
}