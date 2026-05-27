local pubsub = {
	listeners = {},
}

function pubsub:on(event, fn)
	assert(type(event) == "string", "event must be a string")
	assert(type(fn) == "function", "listener must be a function")

	self.listeners[event] = self.listeners[event] or {}
	table.insert(self.listeners[event], fn)

	return function()
		self:off(event, fn)
	end
end

function pubsub:off(event, fn)
	local list = self.listeners[event]
	if not list then
		return
	end

	for i = #list, 1, -1 do
		if list[i] == fn then
			table.remove(list, i)
			return
		end
	end
end

function pubsub:emit(event, ...)
	local list = self.listeners[event]
	if not list then
		return
	end

	local snapshot = {}
	for i = 1, #list do
		snapshot[i] = list[i]
	end

	for i = 1, #snapshot do
		snapshot[i](...)
	end
end

return pubsub
