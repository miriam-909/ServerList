local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local XThread = require(Services.rs.modules.XThread)

local ServerStore = Services.mss:GetSortedMap("Servers")
local Servers,Players = {Active = {}}::{Active:{},Callback:()->()},{}
local JOB_ID = Services.https:GenerateGUID(false)

--// Functions
--/ Local
local PlayersChanged = false
local function AddPlayer(player:Player)
	PlayersChanged = true
	table.insert(Players,player.UserId)
end
local function RemovePlayer(player)
	PlayersChanged = true
	table.remove(Players,table.find(Players,player.UserId))
end
local function UploadPlayers()
	Util.attempt(ServerStore.SetAsync,20,ServerStore,JOB_ID,Players,604800)
end


--Initialize self
for _,v in Services.players:GetPlayers() do AddPlayer(v) end
Services.players.PlayerAdded:Connect(AddPlayer)

Services.players.PlayerRemoving:Connect(RemovePlayer)
game:BindToClose(function() Util.attempt(ServerStore.RemoveAsync,20,ServerStore,JOB_ID) end)
UploadPlayers()

--[[
1000+(100*experience players) rpm
500 player scenario; 5e4 rpm
50 servers of 10
1 rps of quota 49 * 50 = 2450 
1 ups of quota 1 * 50 = 50 
//
2500 of 5e4 rpm
]]

print(JOB_ID)

XThread.new(function()
	while task.wait(1) do
		local serverCache
		repeat
			local _,rr = Util.attempt(ServerStore.GetRangeAsync,20,ServerStore,Enum.SortDirection.Ascending,200)
			if serverCache then for _,v in rr do table.insert(serverCache,v) end else serverCache = rr end		
			print(_,rr)
		until #rr ~= 200
		
		table.sort(serverCache,function(a,b)
			return #a.value > #b.value
		end)
		Servers.Active = serverCache
		if Servers.Callback then task.spawn(Servers.Callback) end
		if PlayersChanged then UploadPlayers() PlayersChanged = false end
	end
end,function()
	for _,v in Services.players:GetPlayers() do
		v:Kick("Error fetching server data, closing server...")
	end
end)


return Servers