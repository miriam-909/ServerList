local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local newproxy,typeof,table = Util.newproxy,Util.typeof,Util.table

--// Types
export type XStore = {
    Value: {},
    Options: StoreOptions,
}

type XStoreMeta = {
    type: "XStore",
}&StoreOptions&StoreData

type StoreData = {
    For:  Player,
    ID: string,
}

type StoreOptions = {
    UpdateIncrement: number,
}

--// Vars
local Open,Close

local ImmutableOptions = {
    UpdateIncrement = "number",
}

local DataTemplate = {}

--// Functions

Close = function(self:XStore)
    local meta = getmetatable(self)::XStoreMeta

end

--/ Local

--// Interface

--/ Metadata
local __StoreMeta = {
    type = "XStore",
    __methods = {
        Close = Close,
    },
}

local __InterfaceMetaData = {
    __newindex = function(self,index,value)
        local OptionType = ImmutableOptions[index]
        local ValueType = typeof(value)
        assert(OptionType,`Invalid index {index} to XStore options}`)
        assert(ValueType==OptionType,`Invalid type for index {index} of XStore. Expected {OptionType}, got {ValueType}`)
        rawset(self,index,value)
    end
}

--/ Functions
Open = function(For:Player,Options:StoreOptions):XStore
    local t = {}
    local proxy:XStore = newproxy(__StoreMeta,{
        __public = {
            Value = table.reconcile(t,DataTemplate),
            Options = setmetatable({},__InterfaceMetaData),
        },
        __private = table.combine({
            For = For,
            ID = Services.https:GenerateGUID(false)
        },Options or {}),
    })
    return proxy
end



return {Open = Open,}
