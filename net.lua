require "pubnub"

local net = {}

local SUB_KEY = "demo"
local PUB_KEY = "demo"
local SEC_KEY = nil

local AES_KEY = string.char(
	0x00, 0x01, 0x02, 0x03,
	0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0A, 0x0B,
	0x0C, 0x0D, 0x0E, 0x0F
)

local myId, oppId

local function dispatch (type, args)
	args        = args or {}
	args.name   = "net"
	args.type   = type
	args.myId   = myId
	args.oppId  = oppId
	Runtime:dispatchEvent(args)
end

function net.init ()
	net.pn = pubnub.new({
		subscribe_key = SUB_KEY,
		publish_key   = PUB_KEY,
		secret_key    = SEC_KEY,
		cipher_key    = nil,
		ssl           = false,
		origin        = "pubsub.pubnub.com"
	})
end

function net.join (_myId, _oppId)
	myId = _myId
	oppId = _oppId
	net.pn:subscribe({
		channel   = "game_"..myId,
		errorback = function (reason)
			dispatch("error", {
				details = reason
			})
		end,
		connect   = function ()
			dispatch("join")
		end,
		callback  = function (message)
			dispatch("receive", {
				message = message
			})
		end
	})
end

function net.leave ()
	net.pn:unsubscribe({
		channel = "game_"..myId
	})
	myId  = nil
	oppId = nil
end

function net.listen (callback)
	Runtime:addEventListener("net", callback)
end

function net.unlisten (callback)
	Runtime:removeEventListener("net", callback)
end

function net.send (message)
	net.pn:publish({
		channel  = "game_"..oppId,
		message  = message,
		callback = function (result)
			dispatch("send", {
				result = result
			})
		end
	})
end

return net
