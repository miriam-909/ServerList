local ServerManager = require(script.Manager)
ServerManager.init(function(ServerAdded)
    print(ServerAdded)
    --ServerManager.addServer(ServerAdded)
end)

