local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local Types = require(Services.rs.modules.XPackage.__types)

local newproxy = Util.newproxy

local XPackages = {}::{
	XThread: typeof(require(Services.rs.modules.XPackage.XThread)),
	XShared: typeof(require(Services.rs.modules.XPackage.XShared)),
	XSignal: typeof(require(Services.rs.modules.XPackage.XSignal)),
}

local T,F = utf8.char(1),utf8.char(0)

export type XShared = Types.XShared

type SharedMetaData = {
	Remote: Types.XRemote,
	Connection:  Types.XConnection,
	Initialized: boolean,
	State: Types.XConnection?,
	AwaitingPush: {Types.XThread},
	Value:any,

}

local __SharedData,__Shared,__Strict = {},{},{}
local Push,Pull
local access


Push = function(self:XShared,index,value)
	local meta:SharedMetaData = getmetatable(self)
	if not meta.Initialized then return end
	meta.Remote:Fire(index,value)
	local thread = XPackages.XThread.wrap()
	table.insert(meta.AwaitingPush,thread)
	return thread:pause()
end

Pull = function(self:XShared)
	local meta:SharedMetaData = getmetatable(self)
	if not meta.Initialized then return end

end

__Shared = {
	type = "XShared",
	__methods = {
		Push = Push,
		Pull = Pull,
	},
	__index = function(self:XShared,index)
		local meta = getmetatable(self)
		return meta.__methods[index] or meta.__data.__public[index]
	end,
	__newindex = function(self:XShared,index,value)
		local meta:SharedMetaData = getmetatable(self)
		meta.__public[index] = value
		meta.Remote:Fire(index,value)
	end,
}
__Strict = {
	__newindex = function(self:XShared,index,value)
		local meta:SharedMetaData = getmetatable(self)
		meta.__public[index] = value
		self:Push(index,value)
	end,
}

access = function(Namespace:string,Mode:("strict"|"nonstrict")?,yieldFor:boolean?):XShared
	local existing = __SharedData[Namespace]
	if existing then return existing end
	local proxy:XShared,meta:SharedMetaData = newproxy(if Mode == "strict" then Util.table.combine(__Shared,__Strict) else  __Shared ,{
		__private = {
			Initialized = false,
			Remote = XPackages.XSignal.new(Namespace),
		},
		__public = {
			Mode = Mode or "nonstrict",
			Value = 500,
		},
	})
	--meta.Remote:Fire()
	meta.Connection = meta.Remote.Signal:Connect(function(Response,data)
		if not meta.Initialized then
			meta.__public.Value = data
			meta.Initialized = true
			if yieldFor then
				
			end
			return
		end
		if Response == T or Response == F then
			for _,v in meta.AwaitingPush do
				v:resume(Response==F)
			end
			return
		end
		meta.__public.Value[data[1]] = data[2]
	end)
	return proxy
end

return {
	access = access,
	__packages = XPackages,
}