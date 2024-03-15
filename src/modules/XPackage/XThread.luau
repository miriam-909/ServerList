local Services = require(workspace.Services)
local Util = require(Services.rs.modules.Util)
local Types = require(Services.rs.modules.XPackage.__types)

export type XThread = Types.XThread 

local Threads = {Storage = {}}
local __Thread,__ThreadMeta = {},nil
local new,wrap,delay
local Construct,Destruct,default,andThen,await,status,cancel,resume,pause

default = function(f,meta,traceback,...)
    local ret = {pcall(f,...)}
    if not ret[1] then task.spawn(error,`\n{traceback}{table.concat(ret,"\n",2)}`) if meta.OnCancel then task.spawn(meta.OnCancel) end end
    table.remove(ret,1)
    for i,_ in meta.Listeners do
        local t = typeof(i)
        if t == "thread" then
            coroutine.resume(i,unpack(ret))
        elseif t == "function" then
            i(unpack(ret))
        end
    end
end

Construct = function(thread)
    local proxy:XThread,meta
    proxy,meta = Util.newproxy(__Thread,{
        __public = {thread = thread,dead = false},
        __private = {Listeners = {},}
    })
    Threads.Storage[proxy] = true
    proxy:andThen(function()
        Destruct(proxy)
    end)
    return proxy,meta
end

new = function(f,onc,...)
    local proxy:XThread,meta
    local traceback = debug.traceback("XThread Error",2)
    proxy,meta = Construct(coroutine.create(default))
    coroutine.resume(proxy.thread,f,meta,traceback,...)
    meta.OnCancel = onc
    return proxy
end

delay = function(t,f,onc,...)
    local proxy:XThread,meta
    local traceback = debug.traceback("XThread Error",2)
    proxy,meta = Construct(coroutine.create(default))
    task.delay(t,coroutine.resume,proxy.thread,f,meta,traceback,...)
    meta.OnCancel = onc
    return proxy
end

wrap = function():XThread
    return select(1,Construct(coroutine.running()))
end

Destruct = function(proxy:XThread)
    proxy.dead = true
    Threads.Storage[proxy] = nil
end

await = function(self,timeout)
    if self.dead then return 0 end
    local meta = getmetatable(self)
    local thread = coroutine.running()
    local aTimeout
    if timeout then
        aTimeout = delay(timeout,function()
            meta.Listeners[thread] = nil
        end)
    end
    meta.Listeners[thread] = true
    local pack = {coroutine.yield()}
    if timeout then aTimeout:cancel() end
    return unpack(pack)
end

andThen = function(self,f)
    if self.dead then new(f) return end
    local meta = getmetatable(self)
    meta.Listeners[f] = true
end

cancel = function(self,defer)
    if self.dead then return end
    local meta = getmetatable(self)
    task.cancel(self.thread)
    if meta.OnCancel then if defer then task.defer(meta.OnCancel) else meta.OnCancel() end end
    Destruct(self)
end

status = function(self)
    if self.dead then return "dead" end
    return coroutine.status(self.thread)
end

pause = function(_,...)
    return coroutine.yield(...)
end

resume = function(self,...)
    if self.dead then return end
    return coroutine.resume(self.thread,...)
end

__Thread = {
    type = "XThread",
    __methods = {
        cancel = cancel,
        await = await,
        andThen = andThen,
        resume = resume,
        pause = pause,
    },
    __indexMethods = {
        status = status,
    },
    __index = function(proxy,index)
        local meta = getmetatable(proxy)
        local indexMethod = meta.__indexMethods[index]
        return  meta.__methods[index] or (indexMethod and indexMethod(proxy)) or meta.__data.__public[index]
    end,
    __newindex = function(proxy,index,value)
        local meta = getmetatable(proxy)
        meta.__data.__public[index] = value
    end,
}

__ThreadMeta = {
    __newindex = function(meta,index,value)
        meta.__data.__private[index] = value
    end,
    __index = function(meta,index)
        return meta.__data.__private[index]
    end,
}

return {
    new = new,
    wrap = wrap,
    delay = delay,
}