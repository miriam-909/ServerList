local Services = require(workspace.Services)
local ServerManager = require(Services.rs.modules.ServerList)
ServerManager.Callback = function()
    for _,v in ServerManager.Active do
        print(v)
    end
end
while  task.wait(5) do
    print(ServerManager)
end