local ServerManager = require(script.Manager)
ServerManager.init(function(ServerAdded)
    print(ServerAdded)
    for _,v in ServerAdded do
        ServerManager.addServer(v)
    end
end)

