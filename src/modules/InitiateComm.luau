if IsServer then
	EventNspc = "OnServerEvent"
	folder = Instance.new("Folder")
	folder.Name = "__comm"
	folder.Parent = Services.rs
	Comm = Instance.new("RemoteEvent")
	Comm.Name = "Comm"
	Comm.Parent = Shared
	Remote = Instance.new("Configuration")
	Remote.Name = "Remote"
	Remote.Parent = folder
else
	EventNspc = "OnClientEvent"
	folder = Services.rs:WaitForChild("__comm")
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

