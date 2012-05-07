require "pubnub"

local facebook = require "facebook"
local json     = require "json"

local net = {}

local FB_APP_ID = "223466991100849"

local SUB_KEY = "demo"
local PUB_KEY = "demo"
local SEC_KEY = nil

local AES_KEY = string.char(
	0x00, 0x01, 0x02, 0x03,
	0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0A, 0x0B,
	0x0C, 0x0D, 0x0E, 0x0F
)

local pn

local fbToken, fbUser, fbFriends

local function dispatch (type, args)
	args        = args or {}
	args.name   = "net"
	args.type   = type
	args.myId   = myId
	args.oppId  = oppId
	Runtime:dispatchEvent(args)
end

local function join ()
	pn:subscribe({
		channel   = "factorfriends_"..fbUser.id,
		errorback = function (reason)
			dispatch("error", {details = reason})
		end,
		connect   = function ()
			dispatch("join")
		end,
		callback  = function (message)
			dispatch("receive", {message = message})
		end
	})
end

local function unjoin ()
	pn:unsubscribe({
		channel = "factorfriends_"..fbUser.id
	})
end

local function onFacebookEvent (event)
	if "session" == event.type then
        if "login" == event.phase then
			fbToken = event.token
            facebook.request("me", "GET")
			facebook.request("me/friends", "GET")
        elseif "loginFailed" == event.phase then
			dispatch("error", {details = "Can't login to Facebook!"})
		elseif "loginCancelled" == event.phase then
			dispatch("error", {details = "Login cancelled."})
		elseif "logout" == event.phase then
			fbToken   = nil
			fbUser    = nil
			fbFriends = nil
			unjoin()
			dispatch("logout")
    	end
	elseif "request" == event.type then
		if event.isError then
			dispatch("error", {details = "Can't load Facebook data!"})
			net.logout()
		else
			local response = json.decode(event.response)
			if response.id then
				fbUser = response
			elseif response.data then
				fbFriends = response.data
			end
			if fbUser and fbFriends then
				join()
				dispatch("login")
			end
		end
	end
end

function net.init ()
	pn = pubnub.new({
		subscribe_key = SUB_KEY,
		publish_key   = PUB_KEY,
		secret_key    = SEC_KEY,
		cipher_key    = nil,
		ssl           = false,
		origin        = "pubsub.pubnub.com"
	})
end

function net.deinit ()
	net.logout()
	pn = nil
end

function net.login ()
	facebook.login(FB_APP_ID, onFacebookEvent)
	
	fbUser = {id = "12345", name = "Paul Moore", gender = "male"}
	fbFriends = {
		{
			name = "Cody Vigue",
			id   = "517015515"
		}
	}
	fbToken = "123abc"
	join()
	dispatch("login")
end

function net.logout ()
	facebook.logout()
end

function net.friends ()
	return fbFriends
end

function net.user ()
	return fbUser
end

function net.isLoggedIn ()
	return fbToken ~= nil
end

function net.listen (callback)
	Runtime:addEventListener("net", callback)
end

function net.unlisten (callback)
	Runtime:removeEventListener("net", callback)
end

function net.send (fbId, message)
	message.senderId = fbUser.id
	pn:publish({
		channel  = "factorfriends_"..fbId,
		message  = message,
		callback = function (result)
			dispatch("send", {result = result})
		end
	})
end

return net
