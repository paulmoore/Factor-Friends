--- net.lua
--
-- The net module manages client-to-facebook and client-to-client connections.
--
-- @author Paul Moore
--
-- Copyright (c) 2012 Strange Ideas Software
--
-- This file is part of Factor Friends.
--
-- Factor Friends is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- Factor Friends is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with Factor Friends.  If not, see <http://www.gnu.org/licenses/>.

require "pubnub"

local facebook = require "facebook"
local json     = require "json"

local net = {}

-- The registered Facebook AppId.
local FB_APP_ID = "223466991100849"

-- Pubnub keys.
local SUB_KEY = "demo"
local PUB_KEY = "demo"
local SEC_KEY = nil

-- Encryption key, not yet used.
local AES_KEY = string.char(
	0x00, 0x01, 0x02, 0x03,
	0x04, 0x05, 0x06, 0x07,
	0x08, 0x09, 0x0A, 0x0B,
	0x0C, 0x0D, 0x0E, 0x0F
)

-- Important while using Pubnub demo keys.
local CHANNEL_PREFIX = "factorfriends_"

local pn

local fbToken, fbUser, fbFriends

--- Dispatches a net event through the Runtime object.
local function dispatch (type, args)
	args        = args or {}
	args.name   = "net"
	args.type   = type
	Runtime:dispatchEvent(args)
end

--- Opens a connection to the active user's channel, to begin receiving messages.
local function join ()
	pn:subscribe({
		channel   = CHANNEL_PREFIX..fbUser.id,
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

--- Closes the active user's channel.
local function unjoin ()
	pn:unsubscribe({
		channel = CHANNEL_PREFIX..fbUser.id
	})
end

local function onFacebookEvent (event)
	if "session" == event.type then
        if "login" == event.phase then
			-- Logged in, now we need our data and our friends data.
			fbToken = event.token
            facebook.request("me", "GET")
			facebook.request("me/friends", "GET")
        elseif "loginFailed" == event.phase then
			dispatch("error", {details = "Can't login to Facebook!"})
		elseif "loginCancelled" == event.phase then
			dispatch("error", {details = "Login cancelled."})
		elseif "logout" == event.phase then
			unjoin()
			fbToken   = nil
			fbUser    = nil
			fbFriends = nil
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
			-- Dispatch the login event only once we have all the data we need (me + friends).
			if fbUser and fbFriends then
				join()
				dispatch("login")
			end
		end
	end
end

--- Initializes the net module.
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

--- Deinitializes the net module.
function net.deinit ()
	net.logout()
	pn = nil
end

--- Begins the login procedure to Facebook.
function net.login ()
	facebook.login(FB_APP_ID, onFacebookEvent)
end

--- Begins the logout procedure to Facebook.
function net.logout ()
	facebook.logout()
end

--- Returns an indexed table of the active user's friends.
function net.friends ()
	return fbFriends
end

--- Returns the corrosponding friend table for a given Facebook id.
function net.friendForId (id)
	for i, f in ipairs(net.friends()) do
		if f.id == id then
			return f
		end
	end
end

--- Returns the active user's table.
function net.user ()
	return fbUser
end

--- Returns true if there is an active user, false otherwise.
function net.isLoggedIn ()
	return fbToken ~= nil
end

--- Adds an event listener (table or function) for Runtime 'net' events.
function net.listen (callback)
	Runtime:addEventListener("net", callback)
end

--- Removes an event listener (table or function) for Runtime 'net' events.
function net.unlisten (callback)
	Runtime:removeEventListener("net", callback)
end

--- Sends a message to another user with this App.
--
-- @param fbId The Facebook id of the user.
-- @param message The message to send.  No need to include your id, as it is already included as a senderId.
function net.send (fbId, message)
	message.senderId = fbUser.id
	pn:publish({
		channel  = CHANNEL_PREFIX..fbId,
		message  = message,
		callback = function (result)
			dispatch("send", {result = result})
		end
	})
end

return net
