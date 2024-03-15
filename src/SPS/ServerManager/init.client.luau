local Services = require(workspace.Services)
require(Services.rs.modules.XPackage)
local XShared = require(Services.rs.modules.XPackage.XShared)

local ServerManager = require(script.Manager)
ServerManager.init(function(ServerAdded)
    for _,v in ServerAdded do
        ServerManager.addServer(v)
    end
end)

