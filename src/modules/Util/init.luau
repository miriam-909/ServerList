local ts = game:GetService("TweenService")
local cp = game:GetService("ContentProvider")

local function ExtendGlobal<G,E>(global:G,extends:E):E
	local copy = table.clone(global)
	for i,v in extends do
		copy[i] = v
	end
	return extends
end

local function Recurse(t,f)
	for i,v in t do
		local search = f(i,v)
		if not search then  t[i] = tostring(v) continue end
		Recurse(search,f)
	end
end

--EXTENDS
local _table = {}
local _math = {}
local _string = {}
local _ui = {}
local _tween = {}
local _debug = {}
local _vector3 = {}
local _misc = {}

--Types

type __math = {bezier: <T>(t:number,...T&(Vector3|Vector2))->T}

--------------------------------------------

--GlobalReplacements
local _newproxy
do
	local function __index(proxy,index) 
		local meta = getmetatable(proxy)
		return meta.__methods[index] or meta.__data.__public[index]
	end
	local __privatemeta = {
		__newindex = function(meta,index,value)
			meta.__data.__private[index] = value
		end,
		__index = function(meta,index)
			return (meta.__data.__private[index]~=nil and meta.__data.__private[index]) or meta.__data.__public[index]
		end,
	}

	_newproxy = function(metadata,data:{}?)
		local proxy = newproxy(true)
		local meta = getmetatable(proxy)
		for i,v in _table.clone(metadata,true) do 
            meta[i] = v 
        end
		meta.__index = metadata.__index or __index
		meta.__data = data
		if data then setmetatable(meta,__privatemeta) end
		return proxy,meta
	end
end

do 
	local f = function()end
	local locked = {
		__metatable = "Locked meta.",
		__newindex = f,
		__index = f,
	}
	function _lockmeta(t)
		local meta = _getmetatable(t)
		for i in locked do
			meta[i] = locked
		end
	end
end

function _typeof(v):string
	local t = typeof(v)
	if t ~= "userdata" then return t end
	return getmetatable(v).type
end

function _print(...)
	local pack = {...}
	Recurse(pack,function(i,v)
		local t = typeof(v) 
		if t == "userdata" then 
			pack[i] = getmetatable(v)
			return pack[i]
		elseif t == "table" then
			return v
		end
		return
	end)
	local stack = {}
	for match in string.gmatch(debug.traceback(),"%a+:%d+") do
		table.insert(stack,match)
	end
	table.remove(stack,1)
	print(unpack(pack),` - {table.concat(_table.reverse(stack)," - ")}`)
end

function _getmetatable(self)
	return getmetatable(self)
end

--------------------------------------------

--Modules


--Table
function _table.istable(t)
	return typeof(t) == "table"
end

do
	local function Return(self,f)
		local custom = self.__methods[`__{f}`]
		if custom then return custom() end
	end
	
	function _table.newmeta<T,M>(t:T,methods:M?):T
		local tbl = table.clone(t)
		local meta = {}
		
		meta = {
			__newindex = function(self,index,value)
				if self[index] == value or Return(meta,"newindex") then return end
				if value ~= nil then
					meta.__hidden.i+=1
				elseif meta.__hidden.i~=0 then
					meta.__hidden.i-=1
				end
				meta.__data[index] = value
			end,
			__index = function(_,index)
				return meta.__data[index]
			end,
			__len = function()
				return meta.__hidden.i
			end,
			__iter = function()
				return next,meta.__data
			end,
			__methods = methods or {},
			__hidden = {
				i=0,
			},
			__data = tbl,
		}
		for _ in tbl do
			meta.__hidden.i += 1
		end
		return _newproxy(meta)
	end
end

function _table.random<I,T>(tbl: {[I]:T}): T
	if tbl[1] then return tbl[math.random(1,#tbl)] end
	local c = {}
	for i,_ in table.clone(tbl) do
		table.insert(c,i)
	end
	local randomIndex = _table.random(c)
	return tbl[randomIndex],randomIndex
end

do
	local function wrap(toCopy)
		local clone = table.clone(toCopy)
		for i,v in clone do
			if not _table.istable(v) then continue end
			clone[i] = wrap(v)
		end
		return clone
	end
	function _table.clone<T>(tbl:T,deep:boolean?):T
		if not deep then return table.clone(tbl) end
		return wrap(tbl)
	end
end


function _table.combine<O,F>(other:O,favour:F,Replace:boolean?): F&O
	for i,v in table.clone(other) do
		if favour[i] and not Replace then continue end
		favour[i] = v
	end
	return favour
end

function _table.add<F,O>(favour:F,other:O):F&O
	for _,v in table.clone(other) do
		table.insert(favour,v)
	end
	return favour
end

function _table.reconcile<T,P>(tbl:T,template:P):P&T
	return _table.combine(template,tbl)
end

function _table.reverse<T>(tbl:{T}):{T}
	local c = {}
	for i=#tbl,1,-1 do
		table.insert(c,tbl[i])
	end
	return c
end


--String
function _string.seperateCaps(str:string,inbetween:string?)
	inbetween = inbetween or " "
	return str:gsub("(%u)",`{inbetween}%1`):gsub(`^{inbetween}`,"")
end

--Math
function _math.round(num:number,decimalPlaces:number?)
	local mult = 10^(decimalPlaces or 0)
	return math.round(num*mult)/mult
end

function _math.random(num1:number,num2:number,dp:number?)
	if not num1 then return math.random() end
	local mult = 10^(dp or 0)
	return math.random(num1*mult,num2*mult)/mult
end

function _math.lerp(a:number,b:number,t:number)
	return a + (b - a) * t
end

function _math.fiftyfifty()
	return math.random(1,2)==1
end

function _math.deg<T>(value:T):T
	local t = typeof(value)
	if t=="number" then
		return math.deg(value)
	elseif t=="Vector3" then
		return Vector3.new(math.deg(value.X),math.deg(value.Y),math.deg(value.Z))
	elseif t=="Vector2" then
		return Vector2.new(math.deg(value.X),math.deg(value.Y))
	end
	error(`{value} is not valid for math.deg`)
end

function _math.bezier(t,...)
	local pack = {...}
	local nxt = {}
	for i=#pack,2,-1 do
		local point = pack[i]
		local node = i-1
		nxt[node] = pack[node]:Lerp(point,t)
	end
	return if #nxt>1 then _math.bezier(t,unpack(nxt)) else nxt[1]
end

--OtherUtility

--Ui
function _ui.scrollToBottom(ui: ScrollingFrame)
	return _tween.new(ui,TweenInfo.new(.18,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CanvasPosition = Vector2.new(0,ui.AbsoluteCanvasSize.Y-ui.AbsoluteWindowSize.Y)})
end

function _ui.animate(signal,f:(Vector2)->nil,onc:(()->nil)?,increment:number,max:number,startFrom:Vector2?,reverse:boolean?)
	local x
	local y
	local start
	local goal
	if reverse then
		start = max-increment
		x = max
		y = max
		goal = 0
		max = 0
		increment *= -1
	else
		start = 0
		x = 0
		y = 0
		goal = max
	end
	if startFrom then x = startFrom.X y = startFrom.Y end
	local conn conn = signal:Connect(function()
		x+=increment
		if x == goal then 
			if y == goal then
				conn:Disconnect()
				if onc then onc() end
				return
			end
			x=start 
			y+=increment 
		end
		f(Vector2.new(x,y))
	end)
	return conn
end

do
	local function calc(child:GuiObject,parent:GuiObject)
		
		local cPos = _ui.getBounds(child)
		local cSizeX,cSizeY = child.AbsoluteSize.X,child.AbsoluteSize.Y
		local cPosX:number,cPosY:number = cPos.X.Offset,cPos.Y.Offset
		
		local pPos = _ui.getBounds(parent)
		local pSizeX,pSizeY = parent.AbsoluteSize.X,parent.AbsoluteSize.Y
		local pPosX,pPosY = pPos.X.Offset,pPos.Y.Offset
		

		local Compensate=UDim2.new()
		Compensate += UDim2.fromOffset(if cPosX<pPosX then cPosX+(cPosX-pPosX) 
			elseif cPosX+cSizeX>pPosX+pSizeX then cPosX-(cPosX-pPosX)
			else 0,
			if cPosY-cSizeY<pPosY-pSizeY then cPosY+(cPosY-pPosY)
			elseif cPosY>pPosY then cPosY-(cPosY-pPosY)
			else 0)
		return Compensate
	end	
	
	function _ui.isWithin(child:GuiObject,parent:GuiObject):boolean
		return not not calc(child,parent)
	end
	
	function _ui.forceWithin(child,parent)
		local compensate = calc(child,parent)
		child.Position += compensate
	end
end

function _ui.getBounds(ui:GuiObject,normalize:boolean?)
	local topLeft = if normalize then UDim2.fromOffset(0,0) else UDim2.fromOffset(ui.AbsolutePosition.X,ui.AbsolutePosition.Y)
	return topLeft,topLeft+UDim2.fromOffset(ui.AbsoluteSize.X,ui.AbsoluteSize.Y)
end

function _ui.randomIn(ui:GuiObject)
	local TL,BR = _ui.getBounds(ui,true)
	return UDim2.fromOffset(math.random(TL.X.Offset,BR.X.Offset),math.random(TL.Y.Offset,BR.Y.Offset))
end

function _ui.vec2toUdim2(v2:Vector2)
	return UDim2.fromOffset(v2.X,v2.Y)
end

function _ui.udim2toVec2(udim:UDim2)
	return Vector2.new(udim.X.Offset,udim.Y.Offset)
end

--Tween
function _tween.new(inst:Instance,Info:TweenInfo,Properties:{})
	local t = ts:Create(inst,Info,Properties)
	t:Play()
	return t
end

function _tween.once(i,...)
	_tween.new(i,...).Completed:Once(function()
		i:Destroy()
	end)
end

--Vector3

function _vector3.clamp(v:Vector3,lower,upper,x:boolean?,y:boolean?,z:boolean?)
	return Vector3.new(if x then v.X else math.clamp(v.X,lower,upper),if y then v.Y else math.clamp(v.Y,lower,upper),if z then v.Z else math.clamp(v.Z,lower,upper))
end

--Misc
function _misc.preload(ToLoad: {[number]: any},callback:(()->nil)?)
	return cp:PreloadAsync(ToLoad,callback)
end

--------------------------------------------

local Util= {
	ui = _ui,
	tween = _tween,
	misc = _misc,
	newproxy = _newproxy,	
	easings = require(script.easings),
	debug = ExtendGlobal(debug,_debug)::typeof(debug)&typeof(_debug),
	math = ExtendGlobal(math,_math)::__math&typeof(math)&typeof(_math),
	table = ExtendGlobal(table,_table)::typeof(table)&typeof(_table),
	string = ExtendGlobal(string,_string)::typeof(string)&typeof(string),
	Vector3 = ExtendGlobal(Vector3,_vector3)::typeof(Vector3)&typeof(Vector3),
	attempt = function(func:()->(),iters,...)
		iters = iters or 10
		local i,err = 0,nil
		while i<=iters do
			if i ~=0 then task.wait(1*i) end
			i+=1
			local t: {any} = {pcall(func,...)}
			if not t[1] then err = t[2] warn(err,...) continue end
			table.remove(t,1)
			return true,unpack(t)
		end
		warn(err,debug.info(2,"s"))
		return false,err
	end,
	print = _print,
	typeof = _typeof,
}


for i,v in Util do
	if not _table.istable(v) or table.isfrozen(v) then continue end
	Util[i] = table.freeze(v)
end

return Util
	