local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local XThread = require(Services.rs.modules.XThread)
local XSignal = require(Services.rs.modules.XSignal)
local ServerManager = require(Services.rs.modules.ServerList)

local ServerUpdate = XSignal.new("ServerUpdate","UnreliableRemoteEvent")
local LiveServers = {}
local ServerInfo = {}

local ClearServers = true

ServerManager.Callback = function()
	local UpdateInfo = {}
	for _,server in ServerManager.Active do
		local ChangedPlayers = {}
		local key = server.key
		LiveServers[key] = if ClearServers then nil else true
		local info = ServerInfo[key]  	
		if not info then ServerInfo[key] = {} info = ServerInfo[key] end
		for _,userid in server.value do
			if not info[userid] then
                XThread.new(Util.attempt,nil,Services.players.GetUserThumbnailAsync,2,Services.players,tonumber(userid),Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60):andThen(function(_,thumbnail)
                    info[userid] = thumbnail
					table.insert(ChangedPlayers,userid)
                end)
            end
        end 
		if #ChangedPlayers~=0 then UpdateInfo[key] = ChangedPlayers end
    end
	if ClearServers then
        for key in LiveServers do
			ServerInfo[key] = nil
        end
    end
	if next(UpdateInfo) then
		ServerUpdate:Fire(Services.players:GetPlayers(),UpdateInfo)
	end
	ClearServers = not ClearServers
end