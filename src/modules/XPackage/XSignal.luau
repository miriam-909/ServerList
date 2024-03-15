local Services = require(workspace.Services)

local Util = require(Services.rs.modules.Util)
local Types = require(Services.rs.modules.XPackage.__types)

local XPackages = {}::{
	XThread: typeof(require(Services.rs.modules.XPackage.XThread)),
	XShared: typeof(require(Services.rs.modules.XPackage.XShared)),
}

export type XRemote = Types.XRemote
export type XEvent = Types.XEvent
export type XConnection = Types.XConnection
export type XGroup = Types.XGroup

local newproxy,table,typeof = Util.newproxy,Util.table,Util.typeof
local Remote,EventNspc = Services.rs.XPackage.XRemote,nil

local new,wrap
local Create

--/ Local
Create = function(Namespace,Preferred:string?)
	local signal = Instance.new(Preferred or "RemoteEvent")
	signal.Name = Namespace
	signal.Parent = Remote
	return signal
end

--/XConnection

local __Connection
local Disconnect

type ConnectionMetaData = {
	type: "XConnection",
	Event: XEvent,
	PassSelf: boolean?,
	Function: (...any)->(),
}

Disconnect = function(self)
	local Meta = getmetatable(getmetatable(self).Event)
	Meta.Listeners.Connected[self] = nil
	if #Meta.Listeners.Connected~=0 or #Meta.Listeners.Waiting~=0 or not Meta.Connection then return end
	Meta.Connection:Disconnect()
	Meta.Connection = nil
end

__Connection = {
	type = "XConnection",
	__methods = {
		Disconnect = Disconnect,
	},
}

------------------------------------------------------------------------------------------------------------------------------------

--/XEvent

local __Event,__events = {},{}
local Connect,Once,Wait

type EventMetaData = {
	type: "XEvent",
	Event: RBXScriptSignal,
	Connection: RBXScriptConnection?,
	Processing: number?,
	Listeners: {
		Connected: {[XConnection]:boolean?},
		Waiting: {[thread]:boolean?},
	}
}

Connect = function(self,func,pass)
	local Meta = getmetatable(self)::EventMetaData
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
	local Current = XPackages.XThread.wrap()
	local waitFor
	local conn: XConnection
	if Length then
		waitFor = task.defer(function()
			task.wait(5)
			conn:Disconnect()
			Current:resume()
		end)
	end
	conn = self:Once(function(...)
		if waitFor then task.cancel(waitFor) end
		Current:resume(... and {...})
	end)
	local ret = Current:pause()
	if ret then
		return unpack(ret)
	end
end

__Event = {
	type = "XEvent",
	__methods = {
		Once = Once,
		Wait = Wait,
		Connect = Connect,
	},
}

------------------------------------------------------------------------------------------------------------------------------------

--/XRemote
local __Remote,__remotes = {},{}
local Fire,Destroy

type RemoteMetaData = {
	type: "XRemote",
	Namespace: string,
	Instance: RemoteEvent,
}

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
	__remotes[Meta.Namespace] = nil
end

__Remote = {
	type = "XRemote",
	__methods = {
		Fire = Fire,
		Connect = Connect,
		Once = Once,
		Destroy = Destroy,
		Wait = Wait,
	},
}

new = function(Namespace:string,T:"UnreliableRemoteEvent"?): (XRemote,XEvent)
	local existing = __remotes[Namespace]
	if existing then return existing,getmetatable(existing).Event end
	local signal = Create(Namespace,T)
	local ev = signal[EventNspc]
	local proxy:XRemote =newproxy(__Remote,{
		__private = {
			Namespace = Namespace,
			Instance = signal,
		},
		__public = {
			Signal = wrap(ev)
		},
	})
	__remotes[Namespace] = proxy
	return proxy
end

------------------------------------------------------------------------------------------------------------------------------------

--[[
--/XGroup

local __Group = {}
local Clean,Remove,Add

type XGroupMetaData = {
	objects: {}
}

Clean = function(self)
	local Meta:XGroup = getmetatable(self)
	Meta.cleaning = true
	for i,_ in Meta.objects do
		self:Remove(i,true)
	end
	Meta.cleaning = false
end

Remove = function(self,Object,ovr)
	local OBJ = Object[1]
	local Meta = getmetatable(self)
	if Meta.cleaning and not ovr then return end
	local t = typeof(OBJ)
	if t == "XThread" then
		task.cancel(OBJ)
	elseif t == "XConnection" then
		OBJ:Disconnect()
	elseif t == "XGroup" then
		OBJ:Clean()
	else warn(`error type to disconnect, {t}`,OBJ) return end
	Meta.objects[OBJ] = nil
end

Add = function(self,Object)
	local Meta = getmetatable(self)
	if Meta.__cleaning then return Object end
	Meta.__objects[{Object}] = true	
	return Object
end


__Group = {
	type = "XGroup",
	__methods = {
		Clean = Clean,
		Add = Add,
		Remove = Remove,
	},
	objects = {},
	cleaning = false,
	__mode = "k",
}


]]

------------------------------------------------------------------------------------------------------------------------------------



if Services.run:IsClient() then
	EventNspc = "OnClientEvent"
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
			local thread = XPackages.XThread.wrap()
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
else
	EventNspc = "OnServerEvent"
end


--// Interface
new = function(Namespace:string,T:"UnreliableRemoteEvent"?): (XRemote,XEvent)
	local existing = __remotes[Namespace]
	if existing then return existing,getmetatable(existing).Event end
	local signal = Create(Namespace,T)
	local ev = signal[EventNspc]
	local proxy:XRemote =newproxy(__Remote,{
		__private = {
			Namespace = Namespace,
			Instance = signal,
		},
		__public = {
			Signal = wrap(ev)
		},
	})
	__remotes[Namespace] = proxy
	return proxy
end

wrap = function(Event:RBXScriptSignal):XEvent
	local existing = __events[EventNspc]
	if existing then return existing end
	local proxy:XEvent = newproxy(__Event,{
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
	__packages = XPackages,
	-- group = group,
}