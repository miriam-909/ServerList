local Services = require(workspace.Services)
local ServerManager = require(Services.rs.modules.ServerList)

while  task.wait(5) do
    print(ServerManager)
end