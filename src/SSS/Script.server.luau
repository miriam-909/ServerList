local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local XThread = require(Services.rs.modules.XThread)
local ServerManager = require(Services.rs.modules.ServerList)

ServerManager.Callback = function()
    for _,server in ServerManager.Active do
		for _,userid in server.value do
            XThread.new(Util.attempt,nil,Services.players.GetUserThumbnailAsync,2,Services.players,tonumber(userid),Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60):andThen(function(_,r)
                print(r)
            end)
        end 
    end
end