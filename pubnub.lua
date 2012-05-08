--- pubnub.lua
--
-- Modified pubnub API to better handle AES encryption and utility functions such as uuid.
-- https://github.com/paulmoore/pubnub-api
--
-- @author Paul Moore

require "crypto"
require "aeslua"
require "base64"

local json = require "json"

pubnub      = {}
local LIMIT = 1700

function pubnub.new(init)
    local self          = init
    local subscriptions = {}

    -- SSL ENABLED?
    if self.ssl then 
        self.origin = "https://" .. self.origin
    else
        self.origin = "http://" .. self.origin
    end

    function self:publish(args)
        local callback = args.callback or function() end

        if not (args.channel and args.message) then
            return callback({ nil, "Missing Channel and/or Message" })
        end

		local encrypted, err = self:_encrypt(args.message)
		if not encrypted then
			return callback({nil, err or "Unknown Error"})
		end

        local channel   = args.channel
        local message   = json.encode( encrypted )
        local signature = "0"

        -- SIGN PUBLISHED MESSAGE?
        if self.secret_key then
            signature = crypto.hmac( crypto.sha256, table.concat( {
                self.publish_key,
                self.subscribe_key,
                self.secret_key,
                channel,
                message
            }, "/" ), self.secret_key )
        end

        -- MESSAGE TOO LONG?
        if string.len(message) > LIMIT then
            return callback({ nil, "Message Too Long (" .. LIMIT .. ")" })
        end

        -- PUBLISH MESSAGE
        self:_request({
            callback = function(response)
                if not response then
                    return callback({ nil, "Connection Lost" })
                end
                callback(response)
            end,
            request  = {
                "publish",
                self.publish_key,
                self.subscribe_key,
                signature,
                self:_encode(channel),
                "0",
                self:_encode(message)
            }
        })
    end

    function self:subscribe(args)
        local channel   = args.channel
        local callback  = callback or args.callback
        local errorback = args['errorback'] or function() end
        local connectcb = args['connect'] or function() end
        local timetoken = 0

        if not channel then return print("Missing Channel") end
        if not callback then return print("Missing Callback") end

        -- NEW CHANNEL?
        if not subscriptions[channel] then
            subscriptions[channel] = {}
        end

        -- ENSURE SINGLE CONNECTION
        if (subscriptions[channel].connected) then
            return print("Already Connected")
        end

        subscriptions[channel].connected = 1
        subscriptions[channel].first     = nil

        -- SUBSCRIPTION RECURSION 
        local function substabizel()
            -- STOP CONNECTION?
            if not subscriptions[channel].connected then return end

            -- CONNECT TO PUBNUB SUBSCRIBE SERVERS
            self:_request({
                callback = function(response)
                    -- STOP CONNECTION?
                    if not subscriptions[channel].connected then return end

                    -- CONNECTED CALLBACK
                    if not subscriptions[channel].first then
                        subscriptions[channel].first = true
                        connectcb()
                    end

                    -- PROBLEM?
                    if not response then
                        -- ENSURE CONNECTED
                        return self:time({
                            callback = function(time)
                                if not time then
                                    timer.performWithDelay( 1000, substabizel )
                                    return errorback("Lost Network Connection")
                                end
                                timer.performWithDelay( 10, substabizel )
                            end
                        })
                    end

                    timetoken = response[2]
                    timer.performWithDelay( 1, substabizel )

                    for i, message in ipairs(response[1]) do
						local decrypted, err = self:_decrypt(message)
						if decrypted then
							callback( decrypted )
						else
                        	errorback( err or "Unknown Error" )
						end
                    end
                end,
                request = {
                    "subscribe",
                    self.subscribe_key,
                    self:_encode(channel),
                    "0",
                    timetoken
                }
            })
        end

        -- BEGIN SUBSCRIPTION (LISTEN FOR MESSAGES)
        substabizel()
        
    end

    function self:unsubscribe(args)
        local channel = args.channel
        if not subscriptions[channel] then return nil end

        -- DISCONNECT
        subscriptions[channel].connected = nil
        subscriptions[channel].first     = nil
    end

    function self:history(args)
        if not (args.callback and args.channel) then
            return print("Missing History Callback and/or Channel")
        end

        local limit    = args.limit
        local channel  = args.channel
        local callback = args.callback

        if not limit then limit = 10 end

        self:_request({
            callback = function( messages )
				if messages then
					for i, message in ipairs(messages) do
						local decrypted, err = self:_decrypt(message)
						if decrypted then
	            			messages[i] = decrypted
						else
							print("Error decrypting message: "..tostring(err))
						end
	        		end
				end
				args.callback(messages)
			end,
            request  = {
                'history',
                self.subscribe_key,
                self:_encode(channel),
                '0',
                limit
            }
        })
    end

    function self:time(args)
        if not args.callback then
            return print("Missing Time Callback")
        end

        self:_request({
            request  = { "time", "0" },
            callback = function(response)
                if response then
                    return args.callback(response[1])
                end
                args.callback(nil)
            end
        })
    end

	function self:uuid(args)
		if not args.callback then
			return print("Missing UUID Callback")
		end
		
		local SSL = ""
		if self.ssl then
			SSL = "s"
		end
		
		self:_request({
			origin = "http"..SSL.."://pubnub-prod.appspot.com",
			request = { "uuid" },
			callback = function(response)
				if response then
					return args.callback(response[1])
				end
				args.callback(nil)
			end
		})
	end

    function self:_request(args)
        -- APPEND PUBNUB CLOUD ORIGIN 
        table.insert( args.request, 1, args.origin or self.origin )

        local url = table.concat( args.request, "/" )

        network.request( url, "GET", function(event)
            if (event.isError) then
                return args.callback(nil)
            end

            status, message = pcall( json.decode, event.response )

            if status then
                return args.callback(message)
            else
                return args.callback(nil)
            end
        end )
    end

    function self:_encode(str)
        str = string.gsub( str, "([^%w])", function(c)
            return string.format( "%%%02X", string.byte(c) )
        end )
        return str
    end

    function self:_map( func, array )
        local new_array = {}
        for i,v in ipairs(array) do
            new_array[i] = func(v)
        end
        return new_array
    end

	function self:_encrypt ( message )
		if self.cipher_key then
			local raw = json.encode(message)
			local encrypted = aeslua.encrypt(self.cipher_key, raw, aeslua.AES128, aeslua.CBCMODE)
			if not encrypted then
				return nil, "Could not encrypt message string: "..tostring(raw)
			end
			local status, encoded = pcall(base64.encode, encrypted)
			if not status then
				return nil, encoded
			end
			return { encoded }
		end
		return message
	end
	
	function self:_decrypt ( message )
		if self.cipher_key and #message == 1 then
			local encoded = message[1]
			local status, decoded = pcall(base64.decode, encoded)
			if not status then
				return nil, decoded
			end
			local decrypted = aeslua.decrypt(self.cipher_key, decoded, aeslua.AES128, aeslua.CBCMODE)
			local plain
			status, plain = pcall(json.decode, decrypted)
			if not status then
				return nil, plain
			end
			return plain
		end
		return message
	end

    -- RETURN NEW PUBNUB OBJECT
    return self
end
