local Services = require(workspace.Services)

local Servers = {}

Servers.Read = function()
    
end

Servers.Write = function()
    
end

--Initialize self

local ServerStore = Services.mss:GetSortedMap("Servers")

local function attempt(func:()->(),iters,...)
	iters = iters or 10
	local i,err = 0,nil
	while i<=iters do
		if i ~=0 then task.wait(1*i) end
		i+=1
		local t: {any} = {pcall(func,...)}
		if not t[1] then err = t[2] continue end
		table.remove(t,1)
		return true,unpack(t)
	end
	warn(err,debug.info(2,"s"))
	return false,err
end

local ss,sr = attempt(ServerStore.SetAsync,20,ServerStore.SetAsync,Services.https:GenerateGUID(false),{},604800)
local rs,rr = attempt(ServerStore.ListItemsAsync,20,ServerStore,100)
print(rs,rr)
return Servers