local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local XThread = require(Services.rs.modules.XThread)
local ServerManager = require(Services.rs.modules.ServerList)

ServerManager.Callback = function()
    for _,server in ServerManager.Active do
        for _,userid in server do
            XThread.new(Util.attempt,2,Services.players,userid,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size60x60):andThen(function(s,r)
                print(s,r)
            end)
        end 
    end
end
