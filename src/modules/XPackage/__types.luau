export type XThread = {
	thread: thread,
	dead:boolean,
	status: "normal"|"suspended"|"running",
	await: <T...>(self:XThread,timeout:number?)->T...,
	andThen: <args...,ret...>(self:XThread,Function:(args...)->ret...)->nil,
	cancel: (self:XThread,defer:boolean?)->nil,
	resume: (self:XThread,...any)->nil,
	pause: (self:XThread,...any)->nil,
}
export type XRemote = {
	Fire: (self:XRemote,...any)->(),
	Destroy: (self:XRemote)->(),
	Signal: XEvent,
}
export type XEvent = {
	Connect: (self:XEvent,func:(...any)->...any,PassConnection:boolean?)->XConnection,
	Wait: (self:XEvent,Length:number?)->(),
	Once: (self:XEvent,func:(...any)->())->XConnection,
}
export type XConnection = {
	Disconnect: (self:XConnection)->(),
}
export type XGroup = {
	type: "XGroup",
	Clean: (self:XGroup)->(),
	Remove: (self:XGroup,Connection:XConnection|XThread)->(),
	Add: <T>(self:XGroup,Connection:XConnection|XThread)->T,
}
export type XShared = {
	Push: (self:XShared)->boolean,
	Pull: (self:XShared)->...any?,
	Value: any,
}

return nil