local sprite = require "sprite"

local NUM_DANCES = 3

local spriteSheets, spriteSets

local view = {}

function view.load ()
	local tpDataPrime = require "res.anim.prime_anim"
	local tpDataPi    = require "res.anim.pi_anim"
	spriteSheets = {
		prime = sprite.newSpriteSheetFromData("res/anim/prime_anim.png", tpDataPrime.getSpriteSheetData()),
		pi    = sprite.newSpriteSheetFromData("res/anim/pi_anim.png", tpDataPi.getSpriteSheetData())
	}
	spriteSets = {
		prime = sprite.newSpriteSet(spriteSheets.prime, 1, 21),
		pi    = sprite.newSpriteSet(spriteSheets.pi, 1, 21)
	}
	package.loaded["res.anim.prime_anim"] = nil
	package.loaded["res.anim.pi_anim"]    = nil
	sprite.add(spriteSets.pi, "idle", 1, 8, 250, -2)
	sprite.add(spriteSets.pi, "dance1", 9, 4, 250, -1)
	sprite.add(spriteSets.pi, "dance2", 13, 4, 250, -1)
	sprite.add(spriteSets.pi, "dance3", 17, 5, 250, -1)
	sprite.add(spriteSets.prime, "idle", 1, 8, 250, -2)
	sprite.add(spriteSets.prime, "dance1", 9, 4, 250, -1)
	sprite.add(spriteSets.prime, "dance2", 13, 4, 250, -1)
	sprite.add(spriteSets.prime, "dance3", 17, 5, 250, -1)
end

function view.unload ()
	for name, spriteSheet in pairs(spriteSheets) do
		spriteSheet:removeSelf()
	end
	spriteSheets = nil
	spriteSets   = nil
end

function view.new (name)
	local self = sprite.newSprite(spriteSets[name])
	
	display.center(self)
	self:setReferencePoint(display.BottomCenterReferencePoint)
	
	local danceListener
	
	local function onAnimationEvent (event)
		if "end" == event.phase then
			self.xScale = 1
			self:idle()
			if danceListener then
				danceListener()
				danceListener = nil
			end
		end
	end
	self:addEventListener("sprite", onAnimationEvent)
	
	function self:idle ()
		self:prepare("idle")
		self:play()
	end
	
	function self:dance (id, onComplete)
		danceListener = onComplete
		if id > NUM_DANCES then
			id = id - NUM_DANCES
			self.xScale = -1
		end
		self:prepare("dance"..id)
		self:play()
	end
	
	function self:sendToFront (snap)
		local time = 250
		if snap then
			time = 0
		end
		transition.to(self, {
			time = time,
			x    = display.contentCenterX,
			onComplete = function ()
				self:toFront()
				transition.to(self, {
					time = time,
					xScale = 1.0,
					yScale = 1.0
				})
			end
		})
	end
	
	function self:sendToBack (snap)
		local time = 250
		if snap then
			time = 0
		end
		transition.to(self, {
			time = time,
			x    = display.contentCenterX + 200,
			onComplete = function ()
				self:toBack()
				transition.to(self, {
					time = time,
					xScale = 0.5,
					yScale = 0.5
				})
			end
		})
	end
	
	function destroy ()
		self:removeSelf()
		self = nil
	end
		
	return self
end

return view
