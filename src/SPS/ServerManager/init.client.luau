local ServerManager = require(script.Manager)
ServerManager.init(function(ServerAdded)
    ServerManager.addServer(ServerAdded)
end)

