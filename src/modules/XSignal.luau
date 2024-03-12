local Services = require(workspace.Services)

local Util = require(Services.rs.modules.Util)
local XThread = require(Services.rs.modules.XThread)

local newproxy,table,typeof = Util.newproxy,Util.table,Util.typeof

local IsServer = Services.run:IsServer()
local folder,Shared,Remote:Configuration,EventNspc
local Connect,Disconnect,Destroy,Once,Wait,Fire,Create --,Clean,Remove,Add
local new,wrap --,group
local __Signal,__signals,__Event,__events,__Connection,__connections = {},{},{},{},{},{},{} --__Group

--// Types
export type XRemote = {
	Fire: (self:XRemote,...any)->(),
	Destroy: (self:XRemote)->(),
	Signal: XSignal,
}

type RemoteMetaData = {
	type: "XRemote",
	Namespace: string,
	Instance: RemoteEvent,
}

export type XSignal = {
	Connect: (self:XSignal,func:(...any)->...any,PassConnection:boolean?)->XConnection,
	Wait: (self:XSignal,Length:number?)->(),
	Once: (self:XSignal,func:(...any)->())->XConnection,
}

type SignalMetaData = {
	type: "XEvent",
	Event: RBXScriptSignal,
	Connection: RBXScriptConnection?,
	Processing: number?,
	Listeners: {
		Connected: {[XConnection]:boolean?},
		Waiting: {[thread]:boolean?},
	}
}

export type XConnection = {
	Disconnect: (self:XConnection)->(),
}

type ConnectionMetaData = {
	type: "XConnection",
	Signal: XSignal,
	PassSelf: boolean?,
	Function: (...any)->(),
}

-- export type XGroup = {
-- 	type: "XGroup",
-- 	Clean: (self:XGroup)->(),
-- 	Remove: (self:XGroup,Connection:CanConnect)->(),
-- 	Add: <T>(self:XGroup,Connection:CanConnect)->T,
-- }

-- type XGroupMetaData = {
-- 	objects: {}
-- }

type CanConnect = XConnection|XThread.XThread

--// Functions

--/ Local
Create = function(Namespace,Preferred:string?)
	local signal = Instance.new(Preferred or "RemoteEvent")
	signal.Name = Namespace
	signal.Parent = Remote
	return signal
end

--/XRemote
Fire = function(self,To:{Player}|Player,...)
	local Meta = getmetatable(self)
	for _,v in if typeof(To) == "Player" then {To} else To do
        Meta.Instance:FireClient(v,...)
    end
end

Destroy = function(self)
	local Meta = getmetatable(self)
	if Meta.Connection then Meta.Connection:Disconnect() end
	Meta.__metatable = "Destroyed"
	for _,v in {Meta,self} do table.clear(v) table.freeze(v) end
	Meta.Instance:Destroy()
	__signals[Meta.Namespace] = nil
end

--/XSignal
Connect = function(self,func,pass)
	local Meta = getmetatable(self)::SignalMetaData
	local prox = newproxy(__Connection,{
		__private = {
			PassSelf = pass,
			Function = func,
			Event = self,
		},
		__public = {},
	})
	Meta.Listeners.Connected[prox] = true
	if not Meta.Connection then 
		Meta.Connection = Meta.Event:Connect(function(...)
			local T = os.clock()
			Meta.Processing = Meta.Processing or T
			for i,_ in Meta.Listeners.Connected do
				local pack = {nil,...}
				local M = getmetatable(i)
				if M.PassSelf then pack[1] = i else table.remove(pack,1) end
				task.defer(M.Function,unpack(pack))
			end
			for i,_ in Meta.Listeners.Waiting do
				coroutine.resume(i,...)
				Meta.Listeners.Waiting[i] = nil
			end
			Meta.Processing = nil
		end)
	end
	return prox
end

Once = function(self,func)
	local Sent = false
	local conn:XConnection
	conn = self:Connect(function(...)
		if Sent then return end
		Sent = true
		conn:Disconnect();
		func(...)
	end,false)
	return conn
end	

Wait = function(self,Length)
	local Current = XThread.wrap()
	local waitFor
	local conn: XConnection
	local pack
	if Length then
		waitFor = task.defer(function()
			task.wait(5)
			conn:Disconnect()
			Current:resume()
		end)
	end
	conn = self:Once(function(...)
		if waitFor then task.cancel(waitFor) end
		if ... ~=  nil then pack = {...} end
		Current:resume()
	end)
	Current:pause()
	if pack then
		return unpack(pack)
	end
end

--/ XConnection
Disconnect = function(self)
	local Meta = getmetatable(getmetatable(self).Event)
	Meta.Listeners.Connected[self] = nil
	if #Meta.Listeners.Connected~=0 or #Meta.Listeners.Waiting~=0 or not Meta.Connection then return end
	Meta.Connection:Disconnect()
	Meta.Connection = nil
end

--/XGroup Methods

-- Clean = function(self)
-- 	local Meta:XGroup = getmetatable(self)
-- 	Meta.cleaning = true
-- 	for i,_ in Meta.objects do
-- 		self:Remove(i,true)
-- 	end
-- 	Meta.cleaning = false
-- end

-- Remove = function(self,Object,ovr)
-- 	local OBJ = Object[1]
-- 	local Meta = getmetatable(self)
-- 	if Meta.cleaning and not ovr then return end
-- 	local t = typeof(OBJ)
-- 	if t == "XThread" then
-- 		task.cancel(OBJ)
-- 	elseif t == "XConnection" then
-- 		OBJ:Disconnect()
-- 	elseif t == "XGroup" then
-- 		OBJ:Clean()
-- 	else warn(`error type to disconnect, {t}`,OBJ) return end
-- 	Meta.objects[OBJ] = nil
-- end

-- Add = function(self,Object)
-- 	local Meta = getmetatable(self)
-- 	if Meta.__cleaning then return Object end
-- 	Meta.__objects[{Object}] = true	
-- 	return Object
-- end


if IsServer then
	EventNspc = "OnServerEvent"
	folder = Instance.new("Folder")
	folder.Name = "__comm"
	folder.Parent = Services.rs
	Shared = Instance.new("Configuration")
	Shared.Name = "Shared"
	Shared.Parent = folder
	Remote = Instance.new("Configuration")
	Remote.Name = "Remote"
	Remote.Parent = folder
else
	EventNspc = "OnClientEvent"
	folder = Services.rs:WaitForChild("__comm")
	Shared = folder:FindFirstChild("Shared")
	Remote = folder:FindFirstChild("Remote")
	Fire = function(self,...)
		local Meta = getmetatable(self)
		Meta.Instance:FireServer(...)
	end
	Destroy = function(self)
		local Meta = getmetatable(self)
		if Meta.Connection then Meta.Connection:Disconnect() end
		Meta.__metatable = "Destroyed"
		for _,v in {Meta,self} do table.clear(v) table.freeze(v) end
	end
	Create = function(Namespace)
		local signal = Remote:FindFirstChild(Namespace)
		if not signal then
			local thread = XThread.wrap()
			local conn = wrap(Remote.ChildAdded):Connect(function(self:XConnection,child)
				if child.Name == Namespace then
					thread:resume(child)
					self:Disconnect()
				end
			end,true)
            task.delay(5,function()
                conn:Disconnect()
                thread:resume()
            end)
			signal = thread:pause()
            if not signal then error(`Remote {Namespace} doesnt exist`,2) end		
		end
		return signal
	end
end

__Signal = {
	type = "XSignal",
	__methods = {
		Fire = Fire,
		Connect = Connect,
		Once = Once,
		Destroy = Destroy,
		Wait = Wait,
	},
}

--// Metadata

__Event = {
	type = "XEvent",
	__methods = {
		Once = Once,
		Wait = Wait,
		Connect = Connect,
	},
}

__Connection = {
	type = "XConnection",
	__methods = {
		Disconnect = Disconnect,
	},
}

-- __Group = {
-- 	type = "XGroup",
-- 	__methods = {
-- 		Clean = Clean,
-- 		Add = Add,
-- 		Remove = Remove,
-- 	},
-- 	objects = {},
-- 	cleaning = false,
-- 	__mode = "k",
-- }


--// Interface
new = function(Namespace:string,T:"UnreliableRemoteEvent"?): (XRemote,XSignal)
	local existing = __signals[Namespace]
	if existing then return existing,getmetatable(existing).Event end
	local signal = Create(Namespace,T)
	local ev = signal[EventNspc]
	local proxy:XRemote =newproxy(__Signal,{
		__private = {
			Namespace = Namespace,
			Instance = signal,
		},
		__public = {
			Signal = wrap(ev)
		},
	})
	__signals[Namespace] = proxy
	return proxy
end

wrap = function(Event:RBXScriptSignal):XSignal
	local existing = __events[EventNspc]
	if existing then return existing end
	local proxy:XSignal = newproxy(__Event,{
		__private = {
			Event = Event,
			Processing = nil,
			Listeners = {Connected = table.newmeta({}),Waiting = table.newmeta({})}
		},
		__public = {},
	})
	__events[Event] = proxy
	return proxy
end

-- group = function(): XGroup
-- 	return newproxy(__Group,{__private = {objects = {},cleaning = false}})
-- end

return {
	wrap = wrap,
	new = new,
	-- group = group,
}